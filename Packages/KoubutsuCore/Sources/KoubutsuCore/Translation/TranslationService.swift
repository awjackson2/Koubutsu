import Foundation

/// A previously shown line, used as translation context.
public struct DialogueContextLine: Sendable, Hashable, Codable {
    public var source: String
    public var translation: String?

    public init(source: String, translation: String?) {
        self.source = source
        self.translation = translation
    }
}

/// Everything beyond the text itself that a translator may use. Simple translators ignore it; context-aware
/// ones (LLM, custom models) can use previous dialogue, speaker, or other signals.
public struct TranslationContext: Sendable, Hashable, Codable {
    public var previousDialogue: [DialogueContextLine]
    public var speaker: String?
    public var gameTitle: String?
    /// Where on screen the text is (dialogue box vs menu), normalized top-left origin.
    public var screenRegion: NormalizedRect?
    /// Spoken dialogue transcribed from game audio, when available (future).
    public var audioTranscript: String?

    public init(previousDialogue: [DialogueContextLine] = [], speaker: String? = nil, gameTitle: String? = nil,
                screenRegion: NormalizedRect? = nil, audioTranscript: String? = nil) {
        self.previousDialogue = previousDialogue
        self.speaker = speaker
        self.gameTitle = gameTitle
        self.screenRegion = screenRegion
        self.audioTranscript = audioTranscript
    }

    public static let none = TranslationContext()
}

public enum TranslationQuality: String, Sendable, Codable, Hashable, CaseIterable {
    case lowLatency
    case highFidelity
}

public struct TranslationRequest: Sendable, Hashable {
    public var text: String
    public var sourceLanguage: String
    public var targetLanguage: String
    public var quality: TranslationQuality
    public var context: TranslationContext

    public init(text: String, sourceLanguage: String = "ja", targetLanguage: String = "en",
                quality: TranslationQuality = .lowLatency, context: TranslationContext = .none) {
        self.text = text
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.quality = quality
        self.context = context
    }
}

public enum TranslationAvailability: Sendable, Hashable {
    /// Ready to translate on device.
    case installed
    /// Supported, but language assets must be downloaded first.
    case needsDownload
    case unsupported
    /// The service could not determine availability (e.g. unavailable in this environment).
    case unknown(String)
}

public enum TranslationError: Error, Sendable, Hashable, CustomStringConvertible {
    case unsupportedLanguagePair(source: String, target: String)
    case notInstalled(source: String, target: String)
    case nothingToTranslate
    case cancelled
    case unavailable(String)
    case failed(String)

    public var description: String {
        switch self {
        case .unsupportedLanguagePair(let s, let t): "Translation \(s)→\(t) is not supported."
        case .notInstalled(let s, let t): "Translation languages \(s)→\(t) are not downloaded."
        case .nothingToTranslate: "Nothing to translate."
        case .cancelled: "Translation cancelled."
        case .unavailable(let reason): "Translation unavailable: \(reason)"
        case .failed(let reason): "Translation failed: \(reason)"
        }
    }
}

/// A translation backend. Implementations: Apple Translation (on device); future: other local or cloud
/// translators. Cloud implementations must declare `sendsDataOffDevice` so the UI can require consent.
public protocol TranslationService: Sendable {
    var providerName: String { get }
    var sendsDataOffDevice: Bool { get }
    var usesContext: Bool { get }

    func availability(source: String, target: String) async -> TranslationAvailability
    func translate(_ request: TranslationRequest) async throws(TranslationError) -> String
}
