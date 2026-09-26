import Foundation
import Synchronization

/// A dedicated high-priority thread that calls `tick` at a fixed interval.
///
/// Used instead of a dispatch timer for pulling test-video frames so the delivery path runs on a thread with
/// a known, generous stack (dispatch workers have ~512 KB) and is not subject to worker-pool scheduling.
final class PullThread: Sendable {
    private let stopped = Atomic<Bool>(false)
    private let interval: Double
    private let tick: @Sendable () -> Void

    init(interval: Double, name: String, tick: @escaping @Sendable () -> Void) {
        self.interval = interval
        self.tick = tick
        let thread = Thread { [self] in self.run() }
        thread.name = name
        thread.qualityOfService = .userInteractive
        thread.stackSize = 8 << 20
        thread.start()
    }

    func cancel() { stopped.store(true, ordering: .releasing) }

    private func run() {
        var next = CFAbsoluteTimeGetCurrent()
        while !stopped.load(ordering: .acquiring) {
            autoreleasepool { tick() }
            next += interval
            let now = CFAbsoluteTimeGetCurrent()
            if next < now { next = now } // fell behind: do not try to catch up with a burst
            Thread.sleep(forTimeInterval: next - now)
        }
    }
}
