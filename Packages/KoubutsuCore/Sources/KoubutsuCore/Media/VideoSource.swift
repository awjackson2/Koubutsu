/// Where frames come from. Downstream code must not branch on this except for display/diagnostics.
public enum VideoSourceKind: String, Sendable, Codable, CaseIterable {
    case testVideo
    case uvcCapture

    public var displayName: String {
        switch self {
        case .testVideo: "Test video"
        case .uvcCapture: "UVC capture"
        }
    }
}

public enum VideoSourceError: Error, Sendable, Equatable, CustomStringConvertible {
    case mediaMissing(String)
    case mediaUnreadable(String)
    case unsupportedFormat(String)
    case noDeviceAvailable
    case deviceDisconnected(String)
    case permissionDenied
    case configurationFailed(String)
    case unavailableOnThisPlatform(String)

    public var description: String {
        switch self {
        case .mediaMissing(let name): "Video file not found: \(name)"
        case .mediaUnreadable(let reason): "Video could not be read: \(reason)"
        case .unsupportedFormat(let reason): "Unsupported video format: \(reason)"
        case .noDeviceAvailable: "No external capture device is connected."
        case .deviceDisconnected(let name): "Capture device disconnected: \(name)"
        case .permissionDenied: "Camera access is not permitted. Enable it in Settings."
        case .configurationFailed(let reason): "Capture configuration failed: \(reason)"
        case .unavailableOnThisPlatform(let reason): "Unavailable: \(reason)"
        }
    }
}

public enum VideoSourceState: Sendable, Equatable {
    case idle
    case starting
    case running
    case stopped
    case failed(VideoSourceError)

    public var isActive: Bool { self == .starting || self == .running }
}

/// Format the source is currently producing.
public struct VideoFormat: Sendable, Equatable {
    public var size: PixelSize
    /// Nominal frames per second reported by the media or device (e.g. 59.94).
    public var nominalFrameRate: Double
    /// FourCC pixel format (e.g. '420v', 'BGRA'), 0 when unknown.
    public var pixelFormat: UInt32

    public init(size: PixelSize, nominalFrameRate: Double, pixelFormat: UInt32 = 0) {
        self.size = size
        self.nominalFrameRate = nominalFrameRate
        self.pixelFormat = pixelFormat
    }

    public var pixelFormatString: String {
        guard pixelFormat != 0 else { return "?" }
        let bytes = [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: pixelFormat >> $0) }
        return String(decoding: bytes, as: UTF8.self)
    }
}

public enum VideoSourceEvent: Sendable, Equatable {
    case stateChanged(VideoSourceState)
    case formatChanged(VideoFormat)
}

/// A producer of timed video frames: a prerecorded file, a UVC capture device, or a test double.
///
/// Frames are delivered synchronously on the source's own delivery queue so the display path has no
/// buffering hop. Handlers must return quickly; slow consumers (OCR) must decouple via
/// `LatestValueMailbox` rather than block delivery.
///
/// Audio (UAC) will be exposed alongside video by capture sources in a later Major, stamped in the same
/// `HostTime` domain so it can be synchronized with frames.
public protocol VideoSource<Frame>: AnyObject, Sendable {
    associatedtype Frame: TimedFrame

    var kind: VideoSourceKind { get }
    var displayName: String { get }

    /// Sets the frame handler. Called on the source's delivery queue for every frame.
    func setFrameHandler(_ handler: (@Sendable (Frame) -> Void)?)
    /// Sets the event handler (state/format changes). Called on an arbitrary queue.
    func setEventHandler(_ handler: (@Sendable (VideoSourceEvent) -> Void)?)

    func start() async throws(VideoSourceError)
    func stop() async
}
