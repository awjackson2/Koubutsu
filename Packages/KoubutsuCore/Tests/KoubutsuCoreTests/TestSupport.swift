import Synchronization
@testable import KoubutsuCore

final class ManualClock: HostClock {
    private let time = Mutex(0.0)
    init(_ start: Double = 0) { time.withLock { $0 = start } }
    func now() -> HostTime { HostTime(seconds: time.withLock { $0 }) }
    func advance(_ seconds: Double) { time.withLock { $0 += seconds } }
    func set(_ seconds: Double) { time.withLock { $0 = seconds } }
}

struct FakeFrame: TimedFrame {
    var timing: FrameTiming
    var size = PixelSize(width: 1920, height: 1080)

    init(sequence: UInt64, host: Double) {
        timing = FrameTiming(sequence: sequence, presentationTime: MediaTime(seconds: host),
                             hostTime: HostTime(seconds: host), sourceSessionID: 1)
    }
}
