import KoubutsuCore
import Synchronization

/// The single fan-out point between a video source and its consumers.
///
/// Runs on the source's delivery queue for every frame and does constant, non-blocking work:
/// display enqueue first, then bookkeeping, then an O(1) offer to the processing tap. Asynchronous consumers
/// (OCR) attach through `SampledFrameTap` and can never slow this path down.
final class FramePipeline: Sendable {
    let renderer: SampleBufferRenderer
    let metrics: PipelineMetrics
    private let clock: any HostClock
    private let tap = Mutex<SampledFrameTap?>(nil)
    /// Most recent frame, for study mode's freeze. Holding one frame reference is O(1) on the delivery path.
    private let latest = Mutex<VideoFrame?>(nil)

    var latestFrame: VideoFrame? { latest.withLock { $0 } }

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

    /// Installs (or removes) the processing tap. The previous tap is closed.
    func setProcessingTap(_ newTap: SampledFrameTap?) {
        let old = tap.withLock { t -> SampledFrameTap? in
            defer { t = newTap }
            return t
        }
        old?.close()
    }

    func handle(_ frame: VideoFrame) {
        renderer.enqueue(frame)
        latest.withLock { $0 = frame }
        metrics.frameDisplayed(at: clock.now())
        metrics.frameReceived(frame.timing)
        tap.withLock { $0 }?.offer(frame)
    }
}
