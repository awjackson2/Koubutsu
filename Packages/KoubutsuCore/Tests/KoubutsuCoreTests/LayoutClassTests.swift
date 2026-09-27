import Testing
@testable import KoubutsuCore

struct LayoutClassTests {
    private typealias Insets = VideoStageLayout.StageInsets

    @Test(arguments: [(375.0, 667.0), (393, 852), (440, 956), (320, 1024)])
    func narrowTallWindowsAreCompactPortrait(width: Double, height: Double) {
        #expect(LayoutClass.classify(width: width, height: height) == .compactPortrait)
    }

    @Test(arguments: [(667.0, 375.0), (852, 393), (956, 440), (1180, 480)])
    func shortWindowsAreCompactLandscape(width: Double, height: Double) {
        #expect(LayoutClass.classify(width: width, height: height) == .compactLandscape)
    }

    @Test(arguments: [(1180.0, 820.0), (820, 1180), (744, 1133), (1366, 1024), (694, 820)])
    func iPadWindowsAreRegular(width: Double, height: Double) {
        #expect(LayoutClass.classify(width: width, height: height) == .regular)
        #expect(!LayoutClass.classify(width: width, height: height).isCompact)
    }

    @Test func regularInsetsAreUnchanged() {
        let safe = Insets(top: 24, left: 0, bottom: 20, right: 0)
        #expect(VideoStageLayout.windowedInsets(for: .regular, safe: safe) == VideoStageLayout.windowedInsets(safeTop: 24))
    }

    @Test func compactPortraitStageSpansTheWidthUnderASlimHeader() {
        // iPhone 15 portrait: status bar 59, home indicator 34.
        let insets = VideoStageLayout.windowedInsets(for: .compactPortrait,
                                                     safe: Insets(top: 59, left: 0, bottom: 34, right: 0))
        #expect(insets == Insets(top: 83, left: 6, bottom: 34, right: 6))
        let stage = VideoStageLayout.framed(containerWidth: 393, containerHeight: 852, insets: insets)
        #expect(stage.x == 6)
        #expect(stage.y == 83)
        #expect(abs(stage.width - 381) < 1e-9)
    }

    @Test func compactLandscapeStageClearsTheIslandAndHomeIndicator() {
        // iPhone 15 landscape: 59 pt safe area on both sides, 21 pt home indicator, no status bar.
        let safe = Insets(top: 0, left: 59, bottom: 21, right: 59)
        let insets = VideoStageLayout.windowedInsets(for: .compactLandscape, safe: safe)
        let stage = VideoStageLayout.framed(containerWidth: 852, containerHeight: 393, insets: insets)
        #expect(stage.y == 4)
        #expect(abs(stage.height - (393 - 4 - 21)) < 1e-9)
        #expect(stage.x >= 59)
        #expect(stage.x + stage.width <= 852 - 59 + 1e-9)
    }
}
