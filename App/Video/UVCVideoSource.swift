import KoubutsuCore

/// External USB Video Class capture source (e.g. a Switch 2 USB-C capture adapter or an HDMI capture card).
///
/// Placeholder until Major 5: conforms to `VideoSource` so the rest of the app can already offer and switch
/// to it, and reports that no device is available.
final class UVCVideoSource: VideoSource, @unchecked Sendable {
    typealias Frame = VideoFrame

    let kind = VideoSourceKind.uvcCapture
    let displayName = "USB capture device"
    private let handlers = SourceHandlers<VideoFrame>()

    func setFrameHandler(_ handler: (@Sendable (VideoFrame) -> Void)?) { handlers.setFrameHandler(handler) }
    func setEventHandler(_ handler: (@Sendable (VideoSourceEvent) -> Void)?) { handlers.setEventHandler(handler) }

    func start() async throws(VideoSourceError) {
        handlers.emit(.stateChanged(.failed(.noDeviceAvailable)))
        throw .noDeviceAvailable
    }

    func stop() async {
        handlers.emit(.stateChanged(.stopped))
    }
}
