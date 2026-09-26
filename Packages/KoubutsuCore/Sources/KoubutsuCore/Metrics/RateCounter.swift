/// Events-per-second over a sliding window of host time.
public struct RateCounter: Sendable {
    public let window: Double
    private var times: [Double] = []
    private var head = 0
    public private(set) var total: Int = 0

    public init(window: Double = 1.0) {
        precondition(window > 0)
        self.window = window
    }

    public mutating func record(at time: HostTime) {
        times.append(time.seconds)
        total += 1
        trim(before: time.seconds - window)
    }

    /// Events per second over the window ending at `time`.
    public mutating func rate(at time: HostTime) -> Double {
        trim(before: time.seconds - window)
        return Double(times.count - head) / window
    }

    private mutating func trim(before cutoff: Double) {
        while head < times.count, times[head] <= cutoff { head += 1 }
        if head > 256, head * 2 > times.count {
            times.removeFirst(head)
            head = 0
        }
    }
}
