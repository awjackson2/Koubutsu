import Testing
@testable import KoubutsuCore

/// Wraps the mutating call so it can be used inside `#expect`.
private func sample(_ sampler: inout FrameSampler, _ t: Double) -> Bool {
    sampler.shouldSample(at: HostTime(seconds: t))
}

struct FrameSamplerTests {
    private func sampledIndices(rate: Double, fps: Double, frames: Int, jitter: (Int) -> Double = { _ in 0 }) -> [Int] {
        var sampler = FrameSampler(targetRate: rate)
        return (0..<frames).filter { i in
            sampler.shouldSample(at: HostTime(seconds: 100 + Double(i) / fps + jitter(i)))
        }
    }

    @Test func sixtyToFiveSamplesEveryTwelfthFrame() {
        let idx = sampledIndices(rate: 5, fps: 60, frames: 120)
        #expect(idx == [0, 12, 24, 36, 48, 60, 72, 84, 96, 108])
    }

    @Test func ntscRateHoldsLongRunAverage() {
        let idx = sampledIndices(rate: 5, fps: 59.94, frames: 600)
        #expect((49...51).contains(idx.count))
    }

    @Test func toleratesArrivalJitter() {
        let idx = sampledIndices(rate: 5, fps: 60, frames: 600) { i in (i % 2 == 0 ? 0.002 : -0.002) }
        #expect((49...51).contains(idx.count))
    }

    @Test func zeroRateDisablesSampling() {
        #expect(sampledIndices(rate: 0, fps: 60, frames: 60).isEmpty)
    }

    @Test func resyncsWhenClockGoesBackwards() {
        var sampler = FrameSampler(targetRate: 5)
        #expect(sample(&sampler, 10))
        #expect(!sample(&sampler, 10.05))
        #expect(sample(&sampler, 2))
    }

    @Test func resyncsAfterStall() {
        var sampler = FrameSampler(targetRate: 5)
        #expect(sample(&sampler, 0))
        #expect(sample(&sampler, 30))
        #expect(!sample(&sampler, 30.1))
        #expect(sample(&sampler, 30.2))
    }

    @Test func rateChangeTakesEffectImmediately() {
        var sampler = FrameSampler(targetRate: 2)
        #expect(sample(&sampler, 0))
        #expect(!sample(&sampler, 0.2))
        sampler.setTargetRate(10)
        #expect(sample(&sampler, 0.21))
        #expect(sample(&sampler, 0.31))
    }
}
