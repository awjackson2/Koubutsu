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
    var id: UUID { stable.trackID }

    var translation: String? {
        if case .translated(let text, _, _) = status { text } else { nil }
    }
}

/// Main-actor state machine from OCR results to displayed translations:
/// OCR result → stabilizer → (history, translation coordinator) → `displayed`.
@MainActor
@Observable
final class TranslationController {
    private(set) var displayed: [DisplayedText] = []
    private(set) var history = DialogueHistory()
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
        let value = await coordinator.availability(source: sourceLanguage, target: targetLanguage)
        availability = value
        switch value {
        case .installed: statusMessage = nil
        case .needsDownload: statusMessage = "Japanese → English translation needs a one-time language download."
        case .unsupported: statusMessage = "Japanese → English translation is not supported on this device."
        case .unknown(let reason): statusMessage = "Translation availability unknown: \(reason)"
        }
    }

    func requestDownload() {
        downloadConfiguration = TranslationSession.Configuration(source: Locale.Language(identifier: sourceLanguage),
                                                                 target: Locale.Language(identifier: targetLanguage))
    }

    func downloadFinished(error: String?) async {
        downloadConfiguration = nil
        if let error { statusMessage = "Language download failed: \(error)" }
        await resetService()
        await refreshAvailability()
        retryUntranslated()
    }

    func reset() {
        stabilizer.reset()
        displayed.removeAll()
    }

    func clearHistory() { history.removeAll() }

    /// Feeds one OCR result. Cheap: stabilization runs inline; translation runs in child tasks.
    func process(_ result: OCRResult) {
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
                upsert(DisplayedText(stable: stable, status: .translating))
                translate(stable)
            case .removed(let trackID):
                displayed.removeAll { $0.id == trackID }
            }
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
                if setStatus(.translated(result.translation, fromCache: result.fromCache,
                                         latency: result.translationDuration), for: stable) {
                    metrics.translationDisplayed(frameHostTime: stable.firstSeenFrame.hostTime, at: clock.now())
                }
            } catch {
                if case .notInstalled = error { availability = .needsDownload }
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
