/// A rational media timestamp, mirroring CoreMedia's `CMTime` without depending on it.
///
/// Presentation timestamps from video files and capture devices are rational; keeping them rational
/// avoids drift when converting back to `CMTime` for display.
public struct MediaTime: Sendable, Hashable, Comparable, CustomStringConvertible {
    public var value: Int64
    public var timescale: Int32

    public init(value: Int64, timescale: Int32) {
        precondition(timescale > 0, "MediaTime timescale must be positive")
        self.value = value
        self.timescale = timescale
    }

    public init(seconds: Double, preferredTimescale: Int32 = 600) {
        self.init(value: Int64((seconds * Double(preferredTimescale)).rounded()), timescale: preferredTimescale)
    }

    public static let zero = MediaTime(value: 0, timescale: 1)

    public var seconds: Double { Double(value) / Double(timescale) }

    public static func < (lhs: MediaTime, rhs: MediaTime) -> Bool {
        // Cross-multiplication in Double is exact for timestamps well beyond any session length.
        Double(lhs.value) * Double(rhs.timescale) < Double(rhs.value) * Double(lhs.timescale)
    }

    public static func == (lhs: MediaTime, rhs: MediaTime) -> Bool {
        Double(lhs.value) * Double(rhs.timescale) == Double(rhs.value) * Double(lhs.timescale)
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(seconds) }

    public var description: String { String(format: "%.3fs", seconds) }
}

/// A reading of the monotonic host clock, in seconds.
///
/// On Apple platforms this is the `CMClockGetHostTimeClock()` / `CACurrentMediaTime()` domain, which is also
/// the domain capture sample buffers are stamped in. All latency measurements in the pipeline use it.
public struct HostTime: Sendable, Hashable, Comparable, CustomStringConvertible {
    public var seconds: Double

    public init(seconds: Double) { self.seconds = seconds }

    public static func < (lhs: HostTime, rhs: HostTime) -> Bool { lhs.seconds < rhs.seconds }

    public static func - (lhs: HostTime, rhs: HostTime) -> Double { lhs.seconds - rhs.seconds }

    public func adding(_ seconds: Double) -> HostTime { HostTime(seconds: self.seconds + seconds) }

    public var description: String { String(format: "host %.4fs", seconds) }
}

/// Source of `HostTime`. Injected so timing logic is deterministic under test.
public protocol HostClock: Sendable {
    func now() -> HostTime
}

/// Monotonic clock built on `ContinuousClock`, for contexts without an Apple host clock (tests, Linux).
public struct ContinuousHostClock: HostClock {
    private let origin = ContinuousClock.now

    public init() {}

    public func now() -> HostTime {
        let elapsed = ContinuousClock.now - origin
        let (seconds, attoseconds) = elapsed.components
        return HostTime(seconds: Double(seconds) + Double(attoseconds) * 1e-18)
    }
}
