/// Pixel dimensions of a frame.
public struct PixelSize: Sendable, Hashable, Codable, CustomStringConvertible {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public static let zero = PixelSize(width: 0, height: 0)

    public var aspectRatio: Double { height == 0 ? 0 : Double(width) / Double(height) }

    public var description: String { "\(width)x\(height)" }
}

/// Timing and identity of one video frame, preserved end to end through display, OCR and translation.
public struct FrameTiming: Sendable, Hashable {
    /// Monotonic per-source frame counter, starting at 0 when the source starts.
    public var sequence: UInt64
    /// Presentation timestamp in the source's media timeline (restarts when a test video loops).
    public var presentationTime: MediaTime
    /// Host-clock time the frame became available to the app (capture time for live sources).
    public var hostTime: HostTime
    /// Identifies the source session that produced the frame; changes on every `start()`.
    public var sourceSessionID: UInt64

    public init(sequence: UInt64, presentationTime: MediaTime, hostTime: HostTime, sourceSessionID: UInt64) {
        self.sequence = sequence
        self.presentationTime = presentationTime
        self.hostTime = hostTime
        self.sourceSessionID = sourceSessionID
    }
}

/// Anything carrying frame timing and pixel dimensions. The app's `VideoFrame` (CVPixelBuffer-backed)
/// conforms; core logic stays generic so it is testable without CoreVideo.
public protocol TimedFrame: Sendable {
    var timing: FrameTiming { get }
    var size: PixelSize { get }
}
