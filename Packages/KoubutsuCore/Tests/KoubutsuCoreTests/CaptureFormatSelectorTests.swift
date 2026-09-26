import Testing
@testable import KoubutsuCore

struct CaptureFormatSelectorTests {
    let f = CaptureFormatSelector.fourCC
    func c(_ i: Int, _ w: Int, _ h: Int, _ fps: Double, _ fmt: String) -> CaptureFormatCandidate {
        CaptureFormatCandidate(index: i, size: .init(width: w, height: h), minFrameRate: 5, maxFrameRate: fps,
                               pixelFormat: CaptureFormatSelector.fourCC(fmt))
    }

    @Test func fourCCEncoding() {
        #expect(f("420v") == 0x3432_3076)
    }

    @Test func prefersExact1080p60YUV() {
        let s = CaptureFormatSelector().select(from: [
            c(0, 3840, 2160, 30, "420v"), c(1, 1920, 1080, 60, "dmb1"), c(2, 1920, 1080, 60, "420v"),
            c(3, 1280, 720, 60, "420v"), c(4, 1920, 1080, 30, "420v"),
        ])
        #expect(s?.candidate.index == 2)
        #expect(s?.frameRate == 60)
        #expect(s?.meetsTarget == true)
    }

    @Test func frameRateBeatsResolution() {
        // A 1080p30-only device with a 720p60 mode: keep 60 FPS for gameplay smoothness.
        let s = CaptureFormatSelector().select(from: [c(0, 1920, 1080, 30, "420v"), c(1, 1280, 720, 60, "420v")])
        #expect(s?.candidate.index == 1)
        #expect(s?.meetsTarget == false)
    }

    @Test func ntscRateCountsAsSixty() {
        let s = CaptureFormatSelector().select(from: [c(0, 1920, 1080, 59.94, "yuvs"), c(1, 1280, 720, 60, "420v")])
        #expect(s?.candidate.index == 0)
        #expect(abs((s?.frameRate ?? 0) - 59.94) < 1e-9)
    }

    @Test func mjpegOnlyDeviceStillSelected() {
        let s = CaptureFormatSelector().select(from: [c(0, 1920, 1080, 60, "dmb1")])
        #expect(s?.candidate.index == 0)
    }

    @Test func emptyYieldsNil() {
        #expect(CaptureFormatSelector().select(from: []) == nil)
    }
}
