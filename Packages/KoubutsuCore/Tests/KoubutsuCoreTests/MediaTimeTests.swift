import Testing
@testable import KoubutsuCore

struct MediaTimeTests {
    @Test func rationalComparison() {
        #expect(MediaTime(value: 1, timescale: 2) == MediaTime(value: 300, timescale: 600))
        #expect(MediaTime(value: 1001, timescale: 60000) < MediaTime(value: 1, timescale: 59))
        #expect(MediaTime(seconds: 1.5).seconds == 1.5)
    }

    @Test func pixelFormatString() {
        let fmt = VideoFormat(size: .init(width: 1920, height: 1080), nominalFrameRate: 59.94, pixelFormat: 0x3432_3076)
        #expect(fmt.pixelFormatString == "420v")
    }

    @Test func continuousClockIsMonotonic() {
        let clock = ContinuousHostClock()
        let a = clock.now(), b = clock.now()
        #expect(b >= a)
    }
}
