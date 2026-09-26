/// User-facing settings. Codable and tolerant of missing keys so new settings can be added without
/// invalidating stored values.
public struct AppSettings: Sendable, Hashable, Codable {
    public enum OCRRate: Double, Sendable, Codable, CaseIterable, Hashable {
        case fps2 = 2, fps5 = 5, fps10 = 10, fps15 = 15
        public var label: String { "\(Int(rawValue)) FPS" }
    }

    public enum DisplayMode: String, Sendable, Codable, CaseIterable, Hashable {
        case panel
        case overlay
        case panelAndOverlay
    }

    public enum TranslationMode: String, Sendable, Codable, CaseIterable, Hashable {
        case lowLatency
        case higherQuality
    }

    /// What the overlay draws over recognized Japanese.
    public enum OverlayStyle: String, Sendable, Codable, CaseIterable, Hashable {
        /// Replace the Japanese with English in place.
        case english
        /// Keep the Japanese; readings above kanji, words being learned underlined.
        case furigana
    }

    public enum RegionOfInterestMode: String, Sendable, Codable, CaseIterable, Hashable {
        case fullFrame
        case dialogue
        case custom
    }

    public var sourceLanguage: String = "ja"
    public var targetLanguage: String = "en"
    public var ocrRate: OCRRate = .fps10
    public var ocrQuality: OCRQuality = .accurate
    public var translationMode: TranslationMode = .lowLatency
    public var displayMode: DisplayMode = .overlay
    public var showOriginalText: Bool = true
    public var showTranslation: Bool = true
    public var showOCRBoxes: Bool = false
    public var showDebugStatistics: Bool = false
    /// The list of recognized Japanese lines under the video.
    public var showRecognizedText: Bool = false
    /// Keep the screen on while a source is running.
    public var keepScreenAwake: Bool = true
    /// Size of the English in replacement boxes, relative to the default (clamped to `overlayTextScaleRange`).
    public var overlayTextScale: Double = 1.0
    public var overlayStyle: OverlayStyle = .english
    public var regionOfInterestMode: RegionOfInterestMode = .fullFrame
    public var customRegionOfInterest: NormalizedRect = .init(x: 0, y: 0.6, width: 1, height: 0.4)
    public var loopTestVideo: Bool = true
    /// Switch to a USB capture device automatically when one is connected.
    public var autoSwitchToCapture: Bool = true
    /// Play the capture device's (UAC) audio through the iPad.
    public var playCaptureAudio: Bool = true
    /// Capture audio volume, 0...1.
    public var captureAudioVolume: Double = 1.0

    public init() {}

    public static let overlayTextScaleRange: ClosedRange<Double> = 0.8...1.5

    /// The dialogue region used by `.dialogue`: bottom 40% of the frame, where most games draw text boxes.
    public static let dialogueRegion = NormalizedRect(x: 0, y: 0.6, width: 1, height: 0.4)

    public var effectiveRegionOfInterest: NormalizedRect? {
        switch regionOfInterestMode {
        case .fullFrame: nil
        case .dialogue: Self.dialogueRegion
        case .custom: customRegionOfInterest.clamped
        }
    }

    public var ocrConfiguration: OCRConfiguration {
        OCRConfiguration(languages: [sourceLanguage == "ja" ? "ja-JP" : sourceLanguage],
                         quality: ocrQuality, regionOfInterest: effectiveRegionOfInterest)
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings.init as () -> AppSettings
        var s = d()
        s.sourceLanguage = try c.decodeIfPresent(String.self, forKey: .sourceLanguage) ?? s.sourceLanguage
        s.targetLanguage = try c.decodeIfPresent(String.self, forKey: .targetLanguage) ?? s.targetLanguage
        s.ocrRate = (try? c.decodeIfPresent(OCRRate.self, forKey: .ocrRate)) ?? s.ocrRate
        s.ocrQuality = (try? c.decodeIfPresent(OCRQuality.self, forKey: .ocrQuality)) ?? s.ocrQuality
        s.translationMode = (try? c.decodeIfPresent(TranslationMode.self, forKey: .translationMode)) ?? s.translationMode
        s.displayMode = (try? c.decodeIfPresent(DisplayMode.self, forKey: .displayMode)) ?? s.displayMode
        s.showOriginalText = try c.decodeIfPresent(Bool.self, forKey: .showOriginalText) ?? s.showOriginalText
        s.showTranslation = try c.decodeIfPresent(Bool.self, forKey: .showTranslation) ?? s.showTranslation
        s.showOCRBoxes = try c.decodeIfPresent(Bool.self, forKey: .showOCRBoxes) ?? s.showOCRBoxes
        s.showDebugStatistics = try c.decodeIfPresent(Bool.self, forKey: .showDebugStatistics) ?? s.showDebugStatistics
        s.showRecognizedText = try c.decodeIfPresent(Bool.self, forKey: .showRecognizedText) ?? s.showRecognizedText
        s.keepScreenAwake = try c.decodeIfPresent(Bool.self, forKey: .keepScreenAwake) ?? s.keepScreenAwake
        let textScale = try c.decodeIfPresent(Double.self, forKey: .overlayTextScale) ?? s.overlayTextScale
        s.overlayTextScale = min(max(textScale, Self.overlayTextScaleRange.lowerBound), Self.overlayTextScaleRange.upperBound)
        s.overlayStyle = (try? c.decodeIfPresent(OverlayStyle.self, forKey: .overlayStyle)) ?? s.overlayStyle
        s.regionOfInterestMode = (try? c.decodeIfPresent(RegionOfInterestMode.self, forKey: .regionOfInterestMode)) ?? s.regionOfInterestMode
        s.customRegionOfInterest = try c.decodeIfPresent(NormalizedRect.self, forKey: .customRegionOfInterest) ?? s.customRegionOfInterest
        s.loopTestVideo = try c.decodeIfPresent(Bool.self, forKey: .loopTestVideo) ?? s.loopTestVideo
        s.autoSwitchToCapture = try c.decodeIfPresent(Bool.self, forKey: .autoSwitchToCapture) ?? s.autoSwitchToCapture
        s.playCaptureAudio = try c.decodeIfPresent(Bool.self, forKey: .playCaptureAudio) ?? s.playCaptureAudio
        let volume = try c.decodeIfPresent(Double.self, forKey: .captureAudioVolume) ?? s.captureAudioVolume
        s.captureAudioVolume = min(max(volume, 0), 1)
        self = s
    }
}
