/// Decides which frames are sampled for OCR, targeting a rate in samples per second.
///
/// Sampling keys on host arrival time rather than presentation time: presentation time restarts when a test
/// video loops, and host time is what latency is measured in. The sampler keeps phase so the long-run rate
/// matches the target even when the frame interval does not divide the sampling interval evenly.
public struct FrameSampler: Sendable {
    public private(set) var targetRate: Double
    private var nextDue: Double?

    /// - Parameter targetRate: samples per second; values <= 0 disable sampling.
    public init(targetRate: Double) {
        self.targetRate = targetRate
    }

    public var interval: Double { targetRate > 0 ? 1.0 / targetRate : .infinity }

    public mutating func setTargetRate(_ rate: Double) {
        guard rate != targetRate else { return }
        targetRate = rate
        nextDue = nil
    }

    public mutating func reset() { nextDue = nil }

    /// Returns true when the frame arriving at `time` should be sampled.
    public mutating func shouldSample(at time: HostTime) -> Bool {
        guard targetRate > 0 else { return false }
        let t = time.seconds
        guard let due = nextDue else {
            nextDue = t + interval
            return true
        }
        // Clock went backwards or stalled far beyond one interval (source restart, app suspended): resync.
        if t < due - interval || t > due + 4 * interval {
            nextDue = t + interval
            return true
        }
        // Tolerance of 1/4 frame at 60 FPS absorbs arrival jitter without skipping a whole frame.
        guard t >= due - 0.004 else { return false }
        nextDue = due + interval
        if nextDue! <= t { nextDue = t + interval }
        return true
    }
}
