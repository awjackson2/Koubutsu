import Testing
@testable import KoubutsuCore

struct MetricsTests {
    @Test func rateCounterWindow() {
        var counter = RateCounter(window: 1)
        for i in 0..<120 { counter.record(at: HostTime(seconds: Double(i) / 60)) }
        let live = counter.rate(at: HostTime(seconds: 119.0 / 60))
        let idle = counter.rate(at: HostTime(seconds: 10))
        #expect(abs(live - 60) <= 1)
        #expect(idle == 0)
        #expect(counter.total == 120)
    }

    @Test func latencyPercentiles() {
        var stats = LatencyStats(capacity: 100)
        for i in 1...100 { stats.record(Double(i) / 1000) }
        #expect(stats.percentile(50) == 0.050)
        #expect(stats.percentile(95) == 0.095)
        #expect(stats.max == 0.1)
        #expect(stats.last == 0.1)
        stats.record(1.0)
        #expect(stats.max == 1.0)
        #expect(stats.min == 0.002)
        #expect(stats.count == 101)
    }

    @Test func pipelineSnapshot() {
        let clock = ManualClock(0)
        let metrics = PipelineMetrics(clock: clock)
        for i in 0..<60 {
            let t = Double(i) / 60
            metrics.frameReceived(FakeFrame(sequence: UInt64(i), host: t).timing)
            metrics.frameDisplayed(at: HostTime(seconds: t))
        }
        metrics.ocrStarted()
        metrics.ocrFinished(frameHostTime: HostTime(seconds: 0.5), started: HostTime(seconds: 0.52),
                            finished: HostTime(seconds: 0.6))
        metrics.ocrFrameDropped(count: 3)
        metrics.translationCacheHit()
        metrics.translationCacheMiss()
        metrics.translationCacheHit()
        clock.set(59.0 / 60)
        let snap = metrics.snapshot()
        #expect(abs(snap.framesReceivedPerSecond - 60) <= 1)
        #expect(snap.totalFramesDisplayed == 60)
        #expect(snap.ocrDroppedFrames == 3)
        #expect(!snap.ocrInFlight)
        #expect(abs(snap.ocrLatency.last! - 0.08) < 1e-9)
        #expect(abs(snap.captureToOCRLatency.last! - 0.1) < 1e-9)
        #expect(snap.translationCacheHitRate == 2.0 / 3.0)
        #expect(snap.lastFrameTiming?.sequence == 59)
    }
}
