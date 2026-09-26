import KoubutsuCore
import Synchronization

/// Thread-safe storage for a source's frame and event handlers.
final class SourceHandlers<Frame: Sendable>: Sendable {
    private let frame = Mutex<(@Sendable (Frame) -> Void)?>(nil)
    private let event = Mutex<(@Sendable (VideoSourceEvent) -> Void)?>(nil)

    func setFrameHandler(_ handler: (@Sendable (Frame) -> Void)?) { frame.withLock { $0 = handler } }
    func setEventHandler(_ handler: (@Sendable (VideoSourceEvent) -> Void)?) { event.withLock { $0 = handler } }

    func deliver(_ value: Frame) { frame.withLock { $0 }?(value) }
    func emit(_ value: VideoSourceEvent) { event.withLock { $0 }?(value) }
}

/// Monotonic source-session identifiers, unique for the app's lifetime.
enum SourceSession {
    private static let counter = Atomic<UInt64>(0)
    static func next() -> UInt64 { counter.add(1, ordering: .relaxed).newValue }
}

/// Carries a non-Sendable reference across an isolation boundary where the caller guarantees exclusive,
/// thread-safe use (e.g. an `AVPlayerItemVideoOutput` handed from the main actor to its pull queue).
struct UncheckedSendableBox<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) { self.value = value }
}
