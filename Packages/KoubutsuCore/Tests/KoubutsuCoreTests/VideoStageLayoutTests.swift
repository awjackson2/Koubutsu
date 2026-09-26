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
}
