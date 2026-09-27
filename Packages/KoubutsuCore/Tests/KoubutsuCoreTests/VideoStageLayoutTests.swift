import Testing
@testable import KoubutsuCore

struct VideoStageLayoutTests {
    @Test func landscapeIPadLeavesSpaceBelow() {
        let stage = VideoStageLayout.stage(containerWidth: 1366, containerHeight: 1004)
        #expect(stage == PlaneRect(x: 0, y: 0, width: 1366, height: 1366 * 9 / 16))
    }

    @Test func shortContainerClampsHeightAndCentres() {
        let stage = VideoStageLayout.stage(containerWidth: 2000, containerHeight: 900)
        #expect(stage.height == 900)
        #expect(abs(stage.width - 1600) < 1e-9)
        #expect(abs(stage.x - 200) < 1e-9)
    }

    @Test func dependsOnlyOnContainer() {
        let a = VideoStageLayout.stage(containerWidth: 1024, containerHeight: 1300)
        let b = VideoStageLayout.stage(containerWidth: 1024, containerHeight: 1300)
        #expect(a == b)
        #expect(VideoStageLayout.stage(containerWidth: 0, containerHeight: 100) == .zero)
    }

    @Test func framedStageSitsInsideTheHousing() {
        let insets = VideoStageLayout.windowedInsets(safeTop: 24)
        #expect(insets.top == 62)
        let stage = VideoStageLayout.framed(containerWidth: 1180, containerHeight: 820, insets: insets)
        #expect(stage.x == 18)
        #expect(stage.y == 62)
        #expect(abs(stage.width - 1144) < 1e-9)
        #expect(abs(stage.height - 1144 * 9 / 16) < 1e-9)
    }

    @Test func framedStageClampsAndCentresInShortContainers() {
        let insets = VideoStageLayout.StageInsets(top: 50, left: 20, bottom: 10, right: 20)
        let stage = VideoStageLayout.framed(containerWidth: 2000, containerHeight: 960, insets: insets)
        #expect(stage.height == 900)
        #expect(abs(stage.width - 1600) < 1e-9)
        #expect(abs(stage.x - 200) < 1e-9)
        #expect(stage.y == 50)
    }

    @Test func windowedInsetsFloorTheStatusBar() {
        #expect(VideoStageLayout.windowedInsets(safeTop: 0).top == 62)
        #expect(VideoStageLayout.windowedInsets(safeTop: 32).top == 70)
        #expect(VideoStageLayout.framed(containerWidth: 30, containerHeight: 100,
                                        insets: VideoStageLayout.windowedInsets(safeTop: 0)) == .zero)
    }
}
