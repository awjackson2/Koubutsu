public enum OCRQuality: String, Sendable, Codable, CaseIterable, Hashable {
    case fast
    case accurate
}

public struct OCRConfiguration: Sendable, Hashable, Codable {
    /// BCP-47 language identifiers in priority order.
    public var languages: [String]
    public var quality: OCRQuality
    public var usesLanguageCorrection: Bool
    /// Minimum text height as a fraction of image height; 0 lets the recognizer decide.
    public var minimumTextHeight: Double
    /// Region to recognize, normalized top-left origin; nil = full frame.
    public var regionOfInterest: NormalizedRect?
    /// Observations below this confidence are discarded.
    public var minimumConfidence: Float
    public var maximumCandidates: Int

    public init(languages: [String] = ["ja-JP"], quality: OCRQuality = .accurate,
                usesLanguageCorrection: Bool = true, minimumTextHeight: Double = 0,
                regionOfInterest: NormalizedRect? = nil, minimumConfidence: Float = 0.3,
                maximumCandidates: Int = 3) {
        self.languages = languages
        self.quality = quality
        self.usesLanguageCorrection = usesLanguageCorrection
        self.minimumTextHeight = minimumTextHeight
        self.regionOfInterest = regionOfInterest
        self.minimumConfidence = minimumConfidence
        self.maximumCandidates = maximumCandidates
    }

    public static let japanese = OCRConfiguration()
}

public enum OCRError: Error, Sendable, Equatable, CustomStringConvertible {
    case languageUnsupported(String)
    case recognitionFailed(String)
    case cancelled

    public var description: String {
        switch self {
        case .languageUnsupported(let lang): "OCR language not supported on this device: \(lang)"
        case .recognitionFailed(let reason): "OCR failed: \(reason)"
        case .cancelled: "OCR cancelled"
        }
    }
}

/// Text recognizer abstraction. The production implementation wraps Apple Vision.
public protocol OCRService<Frame>: Sendable {
    associatedtype Frame: TimedFrame

    /// Languages the recognizer supports at the given quality.
    func supportedLanguages(quality: OCRQuality) async -> [String]

    func recognize(_ frame: Frame, configuration: OCRConfiguration) async throws(OCRError) -> OCRResult
}
