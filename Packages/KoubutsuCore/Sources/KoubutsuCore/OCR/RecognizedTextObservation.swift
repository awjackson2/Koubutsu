import Foundation

/// One line/block of text recognized in a frame. Keeps everything later features need: location for
/// overlays, confidence for stabilization, alternative candidates for learning mode and correction.
public struct RecognizedTextObservation: Sendable, Hashable, Identifiable {
    public struct Candidate: Sendable, Hashable {
        public var text: String
        public var confidence: Float

        public init(text: String, confidence: Float) {
            self.text = text
            self.confidence = confidence
        }
    }

    public var id: UUID
    public var text: String
    public var confidence: Float
    /// Axis-aligned bounds in normalized top-left-origin frame coordinates.
    public var boundingBox: NormalizedRect
    /// Corner points when the recognizer provides them (text may be rotated/skewed).
    public var quad: NormalizedQuad?
    /// Top candidates including the chosen one at index 0.
    public var candidates: [Candidate]
    public var frame: FrameTiming
    /// One box per character (grapheme) of `text`, when requested (`OCRConfiguration.characterBoxes`).
    public var characterBoxes: [NormalizedRect]?

    public init(id: UUID = UUID(), text: String, confidence: Float, boundingBox: NormalizedRect,
                quad: NormalizedQuad? = nil, candidates: [Candidate] = [], frame: FrameTiming,
                characterBoxes: [NormalizedRect]? = nil) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.quad = quad
        self.candidates = candidates
        self.frame = frame
        self.characterBoxes = characterBoxes
    }
}

/// The outcome of recognizing one frame.
public struct OCRResult: Sendable, Hashable {
    public var frame: FrameTiming
    public var frameSize: PixelSize
    public var observations: [RecognizedTextObservation]
    public var started: HostTime
    public var finished: HostTime
    public var configuration: OCRConfiguration

    public init(frame: FrameTiming, frameSize: PixelSize, observations: [RecognizedTextObservation],
                started: HostTime, finished: HostTime, configuration: OCRConfiguration) {
        self.frame = frame
        self.frameSize = frameSize
        self.observations = observations
        self.started = started
        self.finished = finished
        self.configuration = configuration
    }

    /// Duration of the recognition request itself.
    public var recognitionDuration: Double { finished - started }
    /// Frame availability → result.
    public var captureToResultLatency: Double { finished - frame.hostTime }
}
