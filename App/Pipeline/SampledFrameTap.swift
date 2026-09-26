import KoubutsuCore
import Synchronization

/// A rate-limited, backpressured view of the frame stream for one asynchronous consumer (e.g. OCR).
///
/// `offer` runs on the source's delivery queue: a sampler check and at most one mailbox offer. The consumer
/// awaits `next()` and always receives the newest sampled frame; frames it could not keep up with are dropped
/// and counted, never queued.
final class SampledFrameTap: Sendable {
    private let sampler: Mutex<FrameSampler>
    private let mailbox = LatestValueMailbox<VideoFrame>()
    private let metrics: PipelineMetrics?

    init(rate: Double, metrics: PipelineMetrics?) {
        sampler = Mutex(FrameSampler(targetRate: rate))
        self.metrics = metrics
    }

    var rate: Double { sampler.withLock { $0.targetRate } }

    func setRate(_ rate: Double) { sampler.withLock { $0.setTargetRate(rate) } }

    /// Delivery-queue entry point.
    func offer(_ frame: VideoFrame) {
        let sample = sampler.withLock { $0.shouldSample(at: frame.timing.hostTime) }
        guard sample else { return }
        metrics?.frameSampled(at: frame.timing.hostTime)
        if let displaced = mailbox.offer(frame) {
            metrics?.ocrFrameDropped()
            FrameReleaser.release(displaced)
        }
    }

    /// Consumer entry point. Returns nil after `close()` or task cancellation.
    func next() async -> VideoFrame? { await mailbox.next() }

    func close() { mailbox.close() }

    var statistics: LatestValueMailbox<VideoFrame>.Statistics { mailbox.statistics }
}
