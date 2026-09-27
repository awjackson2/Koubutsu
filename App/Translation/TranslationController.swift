import Foundation
import KoubutsuCore
import Observation
import Translation

/// Text shown to the user: a stable Japanese block and its translation state.
struct DisplayedText: Identifiable, Hashable {
    enum Status: Hashable {
        case translating
        case translated(String, fromCache: Bool, latency: Double)
        case failed(String)
        case unavailable
    }

    var stable: StableText
    var status: Status
    /// English of this block's previous text, shown while its current text translates (no flash of Japanese).
    var previousTranslation: String?
    var id: UUID { stable.trackID }

    var translation: String? {
        if case .translated(let text, _, _) = status { text } else { nil }
    }

    /// What to show over the block right now.
    var visibleTranslation: String? { translation ?? previousTranslation }
}

/// Main-actor state machine from OCR results to displayed translations:
/// OCR result → stabilizer → (history, translation coordinator) → `displayed`.
@MainActor
@Observable
final class TranslationController {
    private(set) var displayed: [DisplayedText] = []
    private(set) var history = DialogueHistory()
    @ObservationIgnored private var lastMediaTime: Double?
    private(set) var availability: TranslationAvailability?
    private(set) var statusMessage: String?
    /// Set to request the system language download prompt (consumed by the view's `translationTask`).
    var downloadConfiguration: TranslationSession.Configuration?

    var sourceLanguage = "ja"
    var targetLanguage = "en"
    var quality: TranslationQuality = .lowLatency
    var isEnabled = true

    private var stabilizer = TextStabilizer()
    private var reportedDuplicates = 0
    private let coordinator: TranslationCoordinator
    private let metrics: PipelineMetrics
    private let clock: any HostClock
    private let resetService: @Sendable () async -> Void

    init(service: any KoubutsuCore.TranslationService, metrics: PipelineMetrics, clock: any HostClock,
         resetService: @escaping @Sendable () async -> Void = {}) {
        coordinator = TranslationCoordinator(service: service, metrics: metrics, clock: clock)
        self.metrics = metrics
        self.clock = clock
        self.resetService = resetService
    }

    var providerName: String { coordinator.providerName }
    var cacheStatistics: TranslationCache.Statistics { coordinator.cache.statistics }

    func refreshAvailability() async {
        apply(await coordinator.availability(source: sourceLanguage, target: targetLanguage))
    }

    /// The single place availability changes, so the notice (and its Download button) always matches it —
    /// including when a request discovers the languages are missing after startup reported them installed (10.7.2).
    private func apply(_ value: TranslationAvailability) {
        availability = value
        switch value {
        case .installed: statusMessage = nil
        case .needsDownload: statusMessage = "Japanese → English translation needs a one-time language download."
        case .unsupported: statusMessage = "Japanese → English translation is not supported on this device."
        case .unknown(let reason): statusMessage = "Translation availability unknown: \(reason)"
        }
    }

    /// Short reason shown in the transcript for a line without a translation.
    private static func failureLabel(for availability: TranslationAvailability) -> String {
        switch availability {
        case .needsDownload: "LANGUAGE NOT DOWNLOADED"
        case .unsupported: "NOT SUPPORTED ON THIS DEVICE"
        case .installed, .unknown: "UNAVAILABLE"
        }
    }

    func requestDownload() {
        downloadConfiguration = TranslationSession.Configuration(source: Locale.Language(identifier: sourceLanguage),
                                                                 target: Locale.Language(identifier: targetLanguage))
    }

    /// Runs the system download prompt on the session SwiftUI provides. Nonisolated: the framework call must
    /// not run while holding the main actor's reference to the session.
    nonisolated static func prepareDownload(_ session: UncheckedSendableBox<TranslationSession>) async -> String? {
        do {
            try await session.value.prepareTranslation()
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func downloadFinished(error: String?) async {
        downloadConfiguration = nil
        if let error { statusMessage = "Language download failed: \(error)" }
        await resetService()
        await refreshAvailability()
        retryUntranslated()
    }

    /// Source stopped or playback jumped: forget what was on screen.
    func reset() {
        stabilizer.reset()
        displayed.removeAll()
        lastMediaTime = nil
    }

    func clearHistory() { history.removeAll() }

    /// One-off translation of arbitrary text (study mode). Nil when translation is unavailable or fails.
    func translate(text: String) async -> String? {
        let (source, target, quality) = (sourceLanguage, targetLanguage, quality)
        return try? await coordinator.translate(text: text, sourceLanguage: source, targetLanguage: target,
                                                quality: quality)
    }

    /// Feeds one OCR result. Cheap: stabilization runs inline; translation runs in child tasks.
    func process(_ result: OCRResult) {
        let mediaTime = result.frame.presentationTime.seconds
        if let last = lastMediaTime, mediaTime < last - 1 {
            // Media time went backwards (loop or seek): what was on screen is gone.
            reset()
        }
        lastMediaTime = mediaTime
        let events = stabilizer.process(result)
        let duplicates = stabilizer.duplicateDetections - reportedDuplicates
        if duplicates > 0 {
            metrics.duplicateTextDetected(count: duplicates)
            reportedDuplicates = stabilizer.duplicateDetections
        }
        for event in events {
            switch event {
            case .stabilized(let stable):
                history.record(stable)
                let carried = displayed.first { $0.id == stable.trackID }?.visibleTranslation
                upsert(DisplayedText(stable: stable, status: .translating, previousTranslation: carried))
                translate(stable)
            case .invalidated:
                // The block's text changed; its new text is stabilized in the same result (instant defaults)
                // and replaces the entry, keeping the old English visible until the new one arrives.
                break
            case .removed(let trackID):
                displayed.removeAll { $0.id == trackID }
            }
        }
        followTrackedGeometry()
    }

    /// Keeps each shown box on its text's latest position (text boxes slide, fade in, or are first read
    /// partially); the text itself is unchanged, so no new translation is needed.
    private func followTrackedGeometry() {
        for track in stabilizer.tracks {
            guard let index = displayed.firstIndex(where: { $0.id == track.id }),
                  displayed[index].stable.key == track.block.key,
                  displayed[index].stable.boundingBox != track.block.boundingBox else { continue }
            displayed[index].stable.boundingBox = track.block.boundingBox
            displayed[index].stable.lines = track.block.lines
        }
    }

    private func upsert(_ item: DisplayedText) {
        if let index = displayed.firstIndex(where: { $0.id == item.id }) {
            displayed[index] = item
        } else {
            displayed.append(item)
        }
        displayed.sort { ($0.stable.boundingBox.minY, $0.stable.boundingBox.minX)
            < ($1.stable.boundingBox.minY, $1.stable.boundingBox.minX) }
    }

    private func translate(_ stable: StableText) {
        guard isEnabled else { return }
        if let availability, availability != .installed {
            if case .unknown = availability {} else {
                setStatus(.unavailable, for: stable)
                history.setFailure(Self.failureLabel(for: availability), for: stable.id)
                return
            }
        }
        let context = TranslationContext(previousDialogue: history.context(before: stable.id),
                                         screenRegion: stable.boundingBox)
        let (source, target, quality) = (sourceLanguage, targetLanguage, quality)
        Task {
            do throws(KoubutsuCore.TranslationError) {
                let result = try await coordinator.translate(stable, sourceLanguage: source, targetLanguage: target,
                                                             quality: quality, context: context)
                history.setTranslation(result.translation, provider: result.provider, for: stable.id)
                // A success after a transient failure clears its notice (a missing-language notice stays until
                // the download finishes and availability is refreshed).
                if availability == nil || availability == .installed { statusMessage = nil }
                if setStatus(.translated(result.translation, fromCache: result.fromCache,
                                         latency: result.translationDuration), for: stable) {
                    metrics.translationDisplayed(frameHostTime: stable.firstSeenFrame.hostTime, at: clock.now())
                }
            } catch {
                switch error {
                case .notInstalled:
                    apply(.needsDownload)
                    history.setFailure(Self.failureLabel(for: .needsDownload), for: stable.id)
                case .unsupportedLanguagePair:
                    apply(.unsupported)
                    history.setFailure(Self.failureLabel(for: .unsupported), for: stable.id)
                case .cancelled, .nothingToTranslate:
                    break
                case .unavailable, .failed:
                    // Keep the reason visible: the displayed item disappears with its text, the notice does not.
                    statusMessage = error.description
                    history.setFailure("FAILED: " + error.description, for: stable.id)
                }
                setStatus(.failed(error.description), for: stable)
            }
        }
    }

    /// Updates the item only if it still shows this exact text. Returns whether it was shown.
    @discardableResult
    private func setStatus(_ status: DisplayedText.Status, for stable: StableText) -> Bool {
        guard let index = displayed.firstIndex(where: { $0.stable.id == stable.id }) else { return false }
        displayed[index].status = status
        return true
    }

    private func retryUntranslated() {
        for item in displayed where item.translation == nil {
            setStatus(.translating, for: item.stable)
            translate(item.stable)
        }
    }
}
