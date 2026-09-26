import KoubutsuCore
import CoreMedia
import QuartzCore

/// Host clock in the `CACurrentMediaTime()` domain (mach absolute time), the same clock capture sample
/// buffers and `AVPlayerItemVideoOutput.itemTime(forHostTime:)` use.
struct AppleHostClock: HostClock {
    func now() -> HostTime { HostTime(seconds: CACurrentMediaTime()) }
}

extension MediaTime {
    init(_ time: CMTime) {
        if time.isValid, time.timescale > 0 {
            self.init(value: time.value, timescale: time.timescale)
        } else {
            self = .zero
        }
    }

    var cmTime: CMTime { CMTime(value: value, timescale: timescale) }
}
