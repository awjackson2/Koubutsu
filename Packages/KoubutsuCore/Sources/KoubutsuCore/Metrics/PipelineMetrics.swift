import Synchronization

/// Point-in-time view of pipeline health, sampled by the UI at a low rate.
public struct PipelineMetricsSnapshot: Sendable, Equatable {
    public var framesReceivedPerSecond: Double = 0
    public var framesDisplayedPerSecond: Double = 0
    public var framesSampledPerSecond: Double = 0
    public var ocrProcessedPerSecond: Double = 0
    public var totalFramesReceived: Int = 0
    public var totalFramesDisplayed: Int = 0
    public var totalOCRProcessed: Int = 0
    public var ocrDroppedFrames: Int = 0
    public var ocrInFlight: Bool = false
    public var ocrFailures: Int = 0
    /// Vision request duration.
    public var ocrLatency: LatencySummary = .empty
    /// Frame host time → OCR result available.
    public var captureToOCRLatency: LatencySummary = .empty
    public var translationLatency: LatencySummary = .empty
    public var captureToTranslationLatency: LatencySummary = .empty
    public var translationCacheHits: Int = 0
    public var translationCacheMisses: Int = 0
    public var translationRequests: Int = 0
    public var translationFailures: Int = 0
    public var duplicateTextDetections: Int = 0
    public var lastFrameTiming: FrameTiming?

    public init() {}

    public var translationCacheHitRate: Double? {
        let lookups = translationCacheHits + translationCacheMisses
        return lookups == 0 ? nil : Double(translationCacheHits) / Double(lookups)
    }
}

/// Thread-safe collector for pipeline metrics. Recording is cheap (a lock and an append) so it may be
/// called from the frame delivery queue at 60 FPS.
public final class PipelineMetrics: Sendable {
    private struct State {
        var received = RateCounter()
        var displayed = RateCounter()
        var sampled = RateCounter()
        var ocrProcessed = RateCounter()
        var ocrLatency = LatencyStats()
        var captureToOCR = LatencyStats()
        var translationLatency = LatencyStats()
        var captureToTranslation = LatencyStats()
        var ocrDropped = 0
        var ocrInFlight = false
        var ocrFailures = 0
        var cacheHits = 0
        var cacheMisses = 0
        var translationRequests = 0
        var translationFailures = 0
        var duplicateText = 0
        var lastFrameTiming: FrameTiming?
    }

    private let state = Mutex(State())
    public let clock: any HostClock

    public init(clock: any HostClock) {
        self.clock = clock
    }

    public func frameReceived(_ timing: FrameTiming) {
        state.withLock {
            $0.received.record(at: timing.hostTime)
            $0.lastFrameTiming = timing
        }
    }

    public func frameDisplayed(at time: HostTime) { state.withLock { $0.displayed.record(at: time) } }
    public func frameSampled(at time: HostTime) { state.withLock { $0.sampled.record(at: time) } }
    public func ocrFrameDropped(count: Int = 1) { state.withLock { $0.ocrDropped += count } }
    public func ocrStarted() { state.withLock { $0.ocrInFlight = true } }

    public func ocrFinished(frameHostTime: HostTime, started: HostTime, finished: HostTime) {
        state.withLock {
            $0.ocrInFlight = false
            $0.ocrProcessed.record(at: finished)
            $0.ocrLatency.record(finished - started)
            $0.captureToOCR.record(finished - frameHostTime)
        }
    }

    public func ocrFailed() {
        state.withLock {
            $0.ocrInFlight = false
            $0.ocrFailures += 1
        }
    }

    public func duplicateTextDetected() { state.withLock { $0.duplicateText += 1 } }
    public func translationCacheHit() { state.withLock { $0.cacheHits += 1 } }
    public func translationCacheMiss() { state.withLock { $0.cacheMisses += 1 } }

    public func translationFinished(frameHostTime: HostTime, started: HostTime, finished: HostTime) {
        state.withLock {
            $0.translationRequests += 1
            $0.translationLatency.record(finished - started)
            $0.captureToTranslation.record(finished - frameHostTime)
        }
    }

    public func translationFailed() {
        state.withLock {
            $0.translationRequests += 1
            $0.translationFailures += 1
        }
    }

    public func snapshot() -> PipelineMetricsSnapshot {
        let now = clock.now()
        return state.withLock { s in
            var snap = PipelineMetricsSnapshot()
            snap.framesReceivedPerSecond = s.received.rate(at: now)
            snap.framesDisplayedPerSecond = s.displayed.rate(at: now)
            snap.framesSampledPerSecond = s.sampled.rate(at: now)
            snap.ocrProcessedPerSecond = s.ocrProcessed.rate(at: now)
            snap.totalFramesReceived = s.received.total
            snap.totalFramesDisplayed = s.displayed.total
            snap.totalOCRProcessed = s.ocrProcessed.total
            snap.ocrDroppedFrames = s.ocrDropped
            snap.ocrInFlight = s.ocrInFlight
            snap.ocrFailures = s.ocrFailures
            snap.ocrLatency = s.ocrLatency.summary
            snap.captureToOCRLatency = s.captureToOCR.summary
            snap.translationLatency = s.translationLatency.summary
            snap.captureToTranslationLatency = s.captureToTranslation.summary
            snap.translationCacheHits = s.cacheHits
            snap.translationCacheMisses = s.cacheMisses
            snap.translationRequests = s.translationRequests
            snap.translationFailures = s.translationFailures
            snap.duplicateTextDetections = s.duplicateText
            snap.lastFrameTiming = s.lastFrameTiming
            return snap
        }
    }

    public func reset() { state.withLock { $0 = State() } }
}
