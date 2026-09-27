/// Circuit breaker for a failing translation provider (10.7.4). After `threshold` consecutive failures further
/// requests pause for a delay that doubles on each further failure up to `maximumDelay`; one success closes it.
/// Times are seconds on any monotonic or wall clock the caller uses consistently.
public struct TranslationBackoff: Sendable, Equatable {
    public let threshold: Int
    public let initialDelay: Double
    public let maximumDelay: Double

    public private(set) var consecutiveFailures = 0
    /// Requests before this time are skipped; nil while the breaker is closed.
    public private(set) var pausedUntil: Double?

    public init(threshold: Int = 3, initialDelay: Double = 15, maximumDelay: Double = 120) {
        precondition(threshold > 0 && initialDelay > 0 && maximumDelay >= initialDelay)
        self.threshold = threshold
        self.initialDelay = initialDelay
        self.maximumDelay = maximumDelay
    }

    /// Whether a request may be attempted at `now`.
    public func allows(at now: Double) -> Bool {
        guard let pausedUntil else { return true }
        return now >= pausedUntil
    }

    /// Seconds until requests are allowed again (0 when allowed).
    public func remaining(at now: Double) -> Double {
        guard let pausedUntil else { return 0 }
        return max(0, pausedUntil - now)
    }

    public mutating func recordSuccess() {
        consecutiveFailures = 0
        pausedUntil = nil
    }

    /// Records a failure; returns the pause started by it (nil while still under the threshold).
    @discardableResult
    public mutating func recordFailure(at now: Double) -> Double? {
        consecutiveFailures += 1
        guard consecutiveFailures >= threshold else { return nil }
        let doublings = consecutiveFailures - threshold
        let delay = min(maximumDelay, initialDelay * Double(1 << min(doublings, 16)))
        pausedUntil = now + delay
        return delay
    }

    /// Clears the breaker (languages downloaded, source restarted).
    public mutating func reset() {
        recordSuccess()
    }
}
