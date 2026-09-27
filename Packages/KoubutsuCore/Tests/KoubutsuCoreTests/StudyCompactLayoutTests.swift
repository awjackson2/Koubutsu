import Foundation
import Testing
@testable import KoubutsuCore

/// Study mode on compact layouts (10.5.0): the landscape study strip, the loupe, and tap tolerances converted
/// through the coordinate layer.
struct StudyCompactLayoutTests {
    private typealias Insets = VideoStageLayout.StageInsets

    private func landscapeStage(width: Double, height: Double, safe: Insets) -> PlaneRect {
        let insets = VideoStageLayout.windowedInsets(for: .compactLandscape, safe: safe)
        return VideoStageLayout.framed(containerWidth: width, containerHeight: height, insets: insets)
    }

    // MARK: Landscape strip

    @Test(arguments: [(667.0, 375.0, 0.0, 0.0, 0.0), (852, 393, 59, 21, 59), (956, 440, 62, 21, 62)])
    func landscapeStripCoversAtMostFortyPercentOfTheStage(width: Double, height: Double, left: Double,
                                                         bottom: Double, right: Double) {
        let stage = landscapeStage(width: width, height: height,
                                   safe: Insets(top: 0, left: left, bottom: bottom, right: right))
        let strip = VideoStageLayout.overlayStudyPanelHeight(stageHeight: stage.height, collapsed: false)
        #expect(strip <= stage.height * VideoStageLayout.overlayStudyFraction + 1e-9)
        // Room for the one-line header and at least one scrolling row below it.
        #expect(strip >= VideoStageLayout.studyPanelCollapsedHeight + 44)
        // Much less than the old fixed 210 pt panel.
        #expect(strip < VideoStageLayout.regularStudyPanelHeight * 0.8)
    }

    @Test func collapsedStripIsTheHeaderOnly() {
        #expect(VideoStageLayout.overlayStudyPanelHeight(stageHeight: 360, collapsed: true)
                == VideoStageLayout.studyPanelCollapsedHeight)
        // A tiny stage never squeezes the strip below its header.
        #expect(VideoStageLayout.overlayStudyPanelHeight(stageHeight: 100, collapsed: false)
                == VideoStageLayout.studyPanelCollapsedHeight)
    }

    // MARK: Loupe, tap travel, tap slop

    @Test func loupeKeepsItsIPadSizeAndShrinksOnShortStages() {
        // iPad full-width stages are 400+ pt tall.
        #expect(VideoStageLayout.studyLoupeSize(stageHeight: 640) == 130)
        #expect(VideoStageLayout.studyLoupeSize(stageHeight: 420) == 130)
        // iPhone portrait (375 wide) and landscape stages.
        #expect(abs(VideoStageLayout.studyLoupeSize(stageHeight: 211) - 94.95) < 1e-9)
        #expect(VideoStageLayout.studyLoupeSize(stageHeight: 360) == 130)
        #expect(VideoStageLayout.studyLoupeSize(stageHeight: -5) == 0)
    }

    @Test func regularTapToleranceUnchanged() {
        #expect(VideoStageLayout.studyTapTravel(for: .regular) == 12)
        #expect(VideoStageLayout.studyMinimumTapSlop(for: .regular) == 0)
        for layout in [LayoutClass.compactPortrait, .compactLandscape] {
            #expect(VideoStageLayout.studyTapTravel(for: layout) < 12)
            #expect(VideoStageLayout.studyMinimumTapSlop(for: layout) > 0)
        }
    }

    @Test func normalizedLengthFollowsTheDisplayedVideo() {
        // 16:9 source in a 375×211 view: displayed 375 wide, 210.9375 tall.
        let mapper = CoordinateMapper(sourceSize: PixelSize(width: 1920, height: 1080), viewWidth: 375,
                                      viewHeight: 211, contentMode: .aspectFit)
        let length = mapper.normalizedLength(fromView: 10)
        #expect(abs(length.x - 10 / 375) < 1e-12)
        #expect(abs(length.y - 10 / 210.9375) < 1e-12)
        // 4:3 source pillarboxed in the same view: the displayed width shrinks, so x grows.
        let pillarbox = CoordinateMapper(sourceSize: PixelSize(width: 640, height: 480), viewWidth: 375,
                                         viewHeight: 211, contentMode: .aspectFit)
        #expect(abs(pillarbox.normalizedLength(fromView: 10).x - 10 / (211 * 4 / 3)) < 1e-9)
        let degenerate = CoordinateMapper(sourceSize: PixelSize(width: 0, height: 0), viewWidth: 375,
                                          viewHeight: 211)
        #expect(degenerate.normalizedLength(fromView: 10) == (0, 0))
    }

    // MARK: Tap snapping on a small video

    /// A line about 5 pt tall on a 375-pt-wide video.
    private let thinLine = line("この先には強い敵", x: 0.1, y: 0.7, w: 0.2, h: 0.025)
    private let mapper = CoordinateMapper(sourceSize: PixelSize(width: 1920, height: 1080), viewWidth: 375,
                                          viewHeight: 211, contentMode: .aspectFit)

    @Test func tapJustOutsideAThinLineHitsOnlyWithTheCompactMinimum() throws {
        let selection = StudySelection(observations: [thinLine])
        // 6 pt below the line, over 強 (index 5 of 8 equal characters over 0.2).
        let x = 0.1 + 0.025 * 5.5
        let point = NormalizedPoint(x: x, y: 0.725 + 6 / 210.9375)
        #expect(selection.character(at: point) == nil)

        let slop = mapper.normalizedLength(fromView: VideoStageLayout.studyMinimumTapSlop(for: .compactPortrait))
        let hit = selection.character(at: point, minimumSlopX: slop.x, minimumSlopY: slop.y)
        #expect(hit?.text == "強")
        let centre = try #require(selection.characterCentre(at: point, minimumSlopX: slop.x, minimumSlopY: slop.y))
        #expect(abs(centre.x - x) < 1e-9)
        #expect(abs(centre.y - 0.7125) < 1e-9)
        // The snapped centre resolves to the same character without any minimum (what StudySession.tap uses).
        #expect(selection.character(at: centre) == hit)

        // Far away still misses.
        #expect(selection.characterCentre(at: NormalizedPoint(x: 0.9, y: 0.1), minimumSlopX: slop.x,
                                          minimumSlopY: slop.y) == nil)
    }

    @Test func zeroMinimumMatchesTheOriginalTap() {
        let lines = [line("この先には強い敵", x: 0.1, y: 0.7, w: 0.4, h: 0.05),
                     line("HPが10回復", x: 0.1, y: 0.78, w: 0.3, h: 0.05)]
        let selection = StudySelection(observations: lines)
        for point in [NormalizedPoint(x: 0.375, y: 0.725), NormalizedPoint(x: 0.2, y: 0.76),
                      NormalizedPoint(x: 0.39, y: 0.81), NormalizedPoint(x: 0.6, y: 0.9)] {
            #expect(selection.character(at: point, minimumSlopX: 0, minimumSlopY: 0) == selection.character(at: point))
        }
    }

    @Test func minimumPicksTheNearerOfTwoCloseLines() {
        let upper = line("上の行", x: 0.1, y: 0.70, w: 0.1, h: 0.025)
        let lower = line("下の行", x: 0.1, y: 0.76, w: 0.1, h: 0.025)
        let selection = StudySelection(observations: [upper, lower])
        let slop = mapper.normalizedLength(fromView: 10)
        // Between the lines, closer to the lower one.
        let hit = selection.character(at: NormalizedPoint(x: 0.115, y: 0.75), minimumSlopX: slop.x,
                                      minimumSlopY: slop.y)
        #expect(hit?.lineText == "下の行")
    }
}
