import Synchronization

/// A capacity-one asynchronous mailbox. Producers never block; a newer value displaces an undelivered
/// older one (counted as dropped). A single consumer awaits `next()`.
///
/// This is the pipeline's backpressure primitive: OCR always works on the newest sampled frame and work can
/// never queue up behind a slow recognizer.
public final class LatestValueMailbox<Value: Sendable>: Sendable {
    public struct Statistics: Sendable, Equatable {
        public var offered: Int = 0
        public var delivered: Int = 0
        public var dropped: Int = 0
        public var pending: Int = 0

        public init() {}
    }

    private struct State {
        var value: Value?
        var waiter: CheckedContinuation<Value?, Never>?
        var closed = false
        var stats = Statistics()
    }

    private enum OfferAction {
        case resume(CheckedContinuation<Value?, Never>)
        case stored(Value?)
        case rejected
    }

    private let state = Mutex(State())

    public init() {}

    /// Offers a value. Returns the displaced (dropped) value, if any.
    @discardableResult
    public func offer(_ value: Value) -> Value? {
        let action: OfferAction = state.withLock { s in
            if s.closed { return .rejected }
            s.stats.offered += 1
            if let waiter = s.waiter {
                s.waiter = nil
                s.stats.delivered += 1
                return .resume(waiter)
            }
            let displaced = s.value
            if displaced != nil { s.stats.dropped += 1 }
            s.value = value
            s.stats.pending = 1
            return .stored(displaced)
        }
        switch action {
        case .resume(let waiter):
            waiter.resume(returning: value)
            return nil
        case .stored(let displaced):
            return displaced
        case .rejected:
            return nil
        }
    }

    /// Waits for the next value. Returns nil once the mailbox is closed or the task is cancelled.
    public func next() async -> Value? {
        if let immediate = takeIfAvailable() { return immediate.value }
        return await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Value?, Never>) in
                let resumeNow: Value?? = state.withLock { s in
                    if let v = s.value {
                        s.value = nil
                        s.stats.pending = 0
                        s.stats.delivered += 1
                        return .some(v)
                    }
                    if s.closed || Task.isCancelled { return .some(nil) }
                    precondition(s.waiter == nil, "LatestValueMailbox supports a single consumer")
                    s.waiter = continuation
                    return .none
                }
                if let resumeNow { continuation.resume(returning: resumeNow) }
            }
        } onCancel: {
            let waiter = state.withLock { s -> CheckedContinuation<Value?, Never>? in
                defer { s.waiter = nil }
                return s.waiter
            }
            waiter?.resume(returning: nil)
        }
    }

    /// Non-blocking take.
    public func tryTake() -> Value? { takeIfAvailable()?.value }

    private struct Taken { var value: Value? }

    private func takeIfAvailable() -> Taken? {
        state.withLock { s in
            if let v = s.value {
                s.value = nil
                s.stats.pending = 0
                s.stats.delivered += 1
                return Taken(value: v)
            }
            if s.closed { return Taken(value: nil) }
            return nil
        }
    }

    /// Closes the mailbox: pending value is discarded, waiting consumer receives nil, further offers are ignored.
    public func close() {
        let waiter = state.withLock { s -> CheckedContinuation<Value?, Never>? in
            s.closed = true
            if s.value != nil { s.stats.dropped += 1 }
            s.value = nil
            s.stats.pending = 0
            defer { s.waiter = nil }
            return s.waiter
        }
        waiter?.resume(returning: nil)
    }

    public var statistics: Statistics { state.withLock { $0.stats } }
}
