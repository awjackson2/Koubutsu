import Foundation
import KoubutsuCore
import Translation

/// On-device translation with Apple's Translation framework.
///
/// Uses `TranslationSession(installedSource:target:)` (iPadOS 26), which works outside SwiftUI but requires
/// the language pair to be installed. When it is not, `availability` reports `.needsDownload` and the UI
/// offers the system download prompt (`TranslationDownloadModifier`). Text never leaves the device.
actor AppleTranslationService: KoubutsuCore.TranslationService {
    nonisolated let providerName = "Apple Translation (on-device)"
    nonisolated let sendsDataOffDevice = false
    nonisolated let usesContext = false

    private var sessions: [String: UncheckedSendableBox<TranslationSession>] = [:]

    func availability(source: String, target: String) async -> TranslationAvailability {
        let status = await LanguageAvailability().status(from: Locale.Language(identifier: source),
                                                          to: Locale.Language(identifier: target))
        switch status {
        case .installed: return .installed
        case .supported: return .needsDownload
        case .unsupported: return .unsupported
        @unknown default: return .unknown("unrecognized availability status")
        }
    }

    func translate(_ request: TranslationRequest) async throws(KoubutsuCore.TranslationError) -> String {
        let text = TextNormalizer.display(request.text)
        guard !text.isEmpty else { throw .nothingToTranslate }
        let session = session(for: request)
        do {
            return try await Self.run(session, text).targetText
        } catch {
            sessions[Self.sessionKey(request)] = nil
            throw Self.map(error, request)
        }
    }

    /// Drops cached sessions (e.g. after the user downloads languages).
    func reset() {
        for session in sessions.values { session.value.cancel() }
        sessions.removeAll()
    }

    private func session(for request: TranslationRequest) -> UncheckedSendableBox<TranslationSession> {
        let key = Self.sessionKey(request)
        if let existing = sessions[key] { return existing }
        let source = Locale.Language(identifier: request.sourceLanguage)
        let target = Locale.Language(identifier: request.targetLanguage)
        let session: TranslationSession
        if #available(iOS 26.4, *) {
            let strategy: TranslationSession.Strategy = request.quality == .highFidelity ? .highFidelity : .lowLatency
            session = TranslationSession(installedSource: source, target: target, preferredStrategy: strategy)
        } else {
            session = TranslationSession(installedSource: source, target: target)
        }
        let box = UncheckedSendableBox(session)
        sessions[key] = box
        return box
    }

    private nonisolated static func run(_ session: UncheckedSendableBox<TranslationSession>,
                                        _ text: String) async throws -> TranslationSession.Response {
        try await session.value.translate(text)
    }

    private static func sessionKey(_ request: TranslationRequest) -> String {
        "\(request.sourceLanguage)>\(request.targetLanguage)>\(request.quality.rawValue)"
    }

    private static func map(_ error: any Error, _ request: TranslationRequest) -> KoubutsuCore.TranslationError {
        if error is CancellationError { return .cancelled }
        switch error {
        case Translation.TranslationError.notInstalled:
            return .notInstalled(source: request.sourceLanguage, target: request.targetLanguage)
        case Translation.TranslationError.unsupportedLanguagePairing,
             Translation.TranslationError.unsupportedSourceLanguage,
             Translation.TranslationError.unsupportedTargetLanguage:
            return .unsupportedLanguagePair(source: request.sourceLanguage, target: request.targetLanguage)
        case Translation.TranslationError.nothingToTranslate:
            return .nothingToTranslate
        case Translation.TranslationError.alreadyCancelled:
            return .cancelled
        default:
            return .failed(error.localizedDescription)
        }
    }
}
