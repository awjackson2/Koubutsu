import Testing
@testable import KoubutsuCore

/// Compact portrait geometry (10.3.0): slim header above the stage, chrome region below it, centred full screen.
struct CompactPortraitLayoutTests {
    private typealias Insets = VideoStageLayout.StageInsets

    private func windowedStage(width: Double, height: Double, safe: Insets) -> PlaneRect {
        let insets = VideoStageLayout.windowedInsets(for: .compactPortrait, safe: safe)
        return VideoStageLayout.framed(containerWidth: width, containerHeight: height, insets: insets)
    }

    @Test func headerSitsDirectlyAboveTheStageUnderTheStatusBar() {
        let stage = windowedStage(width: 393, height: 852, safe: Insets(top: 59, left: 0, bottom: 34, right: 0))
        let header = VideoStageLayout.compactHeader(above: stage)
        #expect(header.y == 59)
        #expect(header.height == VideoStageLayout.compactHeaderHeight)
        #expect(header.maxY == stage.y)
        #expect(header.x == stage.x)
        #expect(header.width == stage.width)
    }

    @Test(arguments: [(375.0, 667.0, 20.0, 0.0), (393, 852, 59, 34), (440, 956, 62, 34), (320, 1024, 24, 20)])
    func chromeRegionNeverOverlapsTheStage(width: Double, height: Double, safeTop: Double, safeBottom: Double) {
        let stage = windowedStage(width: width, height: height,
                                  safe: Insets(top: safeTop, left: 0, bottom: safeBottom, right: 0))
        let region = VideoStageLayout.chromeRegion(below: stage, containerWidth: width, containerHeight: height,
                                                   bottomInset: safeBottom)
        #expect(!region.intersects(stage))
        #expect(region.y == stage.maxY + VideoStageLayout.compactChromeGap)
        #expect(region.x == 0)
        #expect(region.width == width)
        #expect(abs(region.maxY - (height - safeBottom)) < 1e-9)
        // Every iPhone portrait size leaves room for both panels at their minimum.
        #expect(VideoStageLayout.compactPanelMinHeight(regionHeight: region.height)
                == VideoStageLayout.compactPanelMinHeight)
    }

    @Test func iPhoneSEChromeRegionHeight() {
        let stage = windowedStage(width: 375, height: 667, safe: Insets(top: 20, left: 0, bottom: 0, right: 0))
        #expect(stage.y == 44)
        #expect(abs(stage.width - 363) < 1e-9)
        let region = VideoStageLayout.chromeRegion(below: stage, containerWidth: 375, containerHeight: 667)
        #expect(abs(region.height - (667 - 44 - 363 * 9 / 16 - 6)) < 1e-9)
    }

    @Test func chromeRegionCollapsesWhenTheStageFillsTheContainer() {
        let stage = PlaneRect(x: 0, y: 0, width: 400, height: 500)
        let region = VideoStageLayout.chromeRegion(below: stage, containerWidth: 400, containerHeight: 500)
        #expect(region.height == 0)
        #expect(region.y == 500)
    }

    @Test func panelsDropTheirMinimumInShortRegions() {
        #expect(VideoStageLayout.compactPanelMinHeight(regionHeight: 276) == 88)
        #expect(VideoStageLayout.compactPanelMinHeight(regionHeight: 275) == 0)
        #expect(VideoStageLayout.compactPanelMinHeight(regionHeight: 120) == 0)
    }

    @Test func fullScreenStageIsCentredVerticallyAtFullWidth() {
        let stage = VideoStageLayout.centered(containerWidth: 393, containerHeight: 852)
        #expect(stage.x == 0)
        #expect(stage.width == 393)
        #expect(abs(stage.height - 393 * 9 / 16) < 1e-9)
        #expect(abs(stage.y - (852 - stage.height) / 2) < 1e-9)
        let region = VideoStageLayout.chromeRegion(below: stage, containerWidth: 393, containerHeight: 852, gap: 0)
        #expect(region.y == stage.maxY)
        #expect(!region.intersects(stage))
    }

    @Test func centredMatchesFramedHorizontallyAndHandlesEmptyContainers() {
        let insets = Insets(top: 10, left: 6, bottom: 30, right: 6)
        let framed = VideoStageLayout.framed(containerWidth: 390, containerHeight: 800, insets: insets)
        let centred = VideoStageLayout.centered(containerWidth: 390, containerHeight: 800, insets: insets)
        #expect(centred.x == framed.x)
        #expect(centred.width == framed.width)
        #expect(abs(centred.y - (10 + (760 - framed.height) / 2)) < 1e-9)
        #expect(VideoStageLayout.centered(containerWidth: 0, containerHeight: 800) == .zero)
    }
}
