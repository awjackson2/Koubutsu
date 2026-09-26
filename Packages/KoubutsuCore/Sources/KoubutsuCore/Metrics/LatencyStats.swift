/// Rolling statistics over the most recent latency samples, in seconds.
public struct LatencyStats: Sendable, Equatable {
    public let capacity: Int
    private var samples: [Double] = []
    private var cursor = 0
    public private(set) var count: Int = 0
    public private(set) var last: Double?

    public init(capacity: Int = 120) {
        precondition(capacity > 0)
        self.capacity = capacity
        samples.reserveCapacity(capacity)
    }

    public mutating func record(_ seconds: Double) {
        last = seconds
        count += 1
        if samples.count < capacity {
            samples.append(seconds)
        } else {
            samples[cursor] = seconds
            cursor = (cursor + 1) % capacity
        }
    }

    public var isEmpty: Bool { samples.isEmpty }
    public var mean: Double? { samples.isEmpty ? nil : samples.reduce(0, +) / Double(samples.count) }
    public var max: Double? { samples.max() }
    public var min: Double? { samples.min() }

    /// Nearest-rank percentile, `p` in 0...100.
    public func percentile(_ p: Double) -> Double? {
        guard !samples.isEmpty else { return nil }
        let sorted = samples.sorted()
        let rank = Int((p / 100 * Double(sorted.count)).rounded(.up))
        return sorted[Swift.max(0, Swift.min(sorted.count - 1, rank - 1))]
    }

    public var summary: LatencySummary {
        LatencySummary(last: last, mean: mean, p50: percentile(50), p95: percentile(95), max: max, count: count)
    }
}

public struct LatencySummary: Sendable, Equatable {
    public var last: Double?
    public var mean: Double?
    public var p50: Double?
    public var p95: Double?
    public var max: Double?
    public var count: Int

    public static let empty = LatencySummary(last: nil, mean: nil, p50: nil, p95: nil, max: nil, count: 0)
}
