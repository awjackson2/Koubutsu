import KoubutsuCore

/// The single fan-out point between a video source and its consumers.
///
/// Runs on the source's delivery queue for every frame and does constant, non-blocking work:
/// display enqueue first, then bookkeeping. Asynchronous consumers (OCR) attach through a mailbox and can
/// never slow this path down.
final class FramePipeline: Sendable {
    let renderer: SampleBufferRenderer
    let metrics: PipelineMetrics
    private let clock: any HostClock

    init(renderer: SampleBufferRenderer, metrics: PipelineMetrics, clock: any HostClock) {
        self.renderer = renderer
        self.metrics = metrics
        self.clock = clock
    }

    func attach(to source: any VideoSource<VideoFrame>) {
        source.setFrameHandler { [weak self] frame in self?.handle(frame) }
    }

    func detach(from source: any VideoSource<VideoFrame>) {
        source.setFrameHandler(nil)
    }

    func handle(_ frame: VideoFrame) {
        renderer.enqueue(frame)
        metrics.frameDisplayed(at: clock.now())
        metrics.frameReceived(frame.timing)
    }
}
