import Testing
@testable import KoubutsuCore

struct PlaybackTests {
    @Test func clockFormatting() {
        #expect(MediaTimeFormat.clock(0) == "0:00")
        #expect(MediaTimeFormat.clock(65.9) == "1:05")
        #expect(MediaTimeFormat.clock(600) == "10:00")
        #expect(MediaTimeFormat.clock(3725) == "1:02:05")
    }

    @Test func srtFormatting() {
        #expect(MediaTimeFormat.srt(0) == "00:00:00,000")
        #expect(MediaTimeFormat.srt(61.2345) == "00:01:01,235")
        #expect(MediaTimeFormat.srt(3600.5) == "01:00:00,500")
    }

    @Test func statusClampAndProgress() {
        let s = PlaybackStatus(isPlaying: true, currentTime: 150, duration: 600, loops: false)
        #expect(s.progress == 0.25)
        #expect(s.clamped(-5) == 0)
        #expect(abs(s.clamped(700) - 599.95) < 1e-9)
    }
}
