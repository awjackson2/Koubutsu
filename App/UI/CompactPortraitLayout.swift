import KoubutsuCore
import SwiftUI

extension RootView {
    /// iPhone portrait and narrow windows (10.3.0). Outside full screen: a slim housing header, the video at full
    /// width under it, and the bars and panels stacked in the region below the video, never over it. Full screen:
    /// the video centred vertically at full width; a tap reveals the same chrome in the region below it.
    /// All geometry comes from `VideoStageLayout` (rule 6).
    func compactPortraitLayout(_ geometry: GeometryProxy, safe: VideoStageLayout.StageInsets) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        let stage = isFullScreen
            ? VideoStageLayout.centered(containerWidth: width, containerHeight: height)
            : VideoStageLayout.framed(containerWidth: width, containerHeight: height,
                                      insets: VideoStageLayout.windowedInsets(for: .compactPortrait, safe: safe))
        let region = VideoStageLayout.chromeRegion(below: stage, containerWidth: width, containerHeight: height,
                                                   gap: isFullScreen ? 0 : VideoStageLayout.compactChromeGap,
                                                   bottomInset: safe.bottom)
        let panelMinHeight = isFullScreen ? 0 : VideoStageLayout.compactPanelMinHeight(regionHeight: region.height)
        return ZStack(alignment: .topLeading) {
            Color.black
            if !isFullScreen {
                CompactMonitorFrame(stage: stage.cgRect, header: VideoStageLayout.compactHeader(above: stage).cgRect,
                                    sourceLabel: model.selection?.label, isRunning: model.isRunning)
                    // The housing texture runs on under the home indicator; the chrome stops above it.
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.opacity)
            }
            interactiveStage(stage)
            if showsChrome {
                compactPortraitChrome(panelMinHeight: panelMinHeight)
                    .frame(width: region.width, height: region.height, alignment: .bottom)
                    .offset(x: region.x, y: region.y)
                    .transition(.opacity)
            }
        }
    }

    /// Whether a panel that shares the chrome region's height (translation or Japanese text list) is showing.
    private var showsFlexiblePanel: Bool {
        model.settings.displayMode != .overlay || model.settings.showRecognizedText
    }

    /// The chrome stacked below the stage. Study mode: the study panel directly under the video, filling the whole
    /// region (10.5.0; `StudyPanel` takes the offered height in compact portrait). Otherwise the transport bar,
    /// the panels sharing the remaining height and the control bar at the bottom. With no sharing panel the housing
    /// shows through between the bars (outside full screen), or the bars sit together at the bottom (full screen).
    @ViewBuilder private func compactPortraitChrome(panelMinHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            if study.isActive {
                studyPanel
            } else {
                if isFullScreen && !showsFlexiblePanel { Spacer(minLength: 0) }
                transportBar
                Group {
                    panels(translationHeight: nil, recognizedHeight: nil)
                }
                .frame(minHeight: panelMinHeight)
                // Housing filler: the info deck when there is room (10.7.0), else the monitor housing drawn
                // behind the chrome shows through here.
                if !isFullScreen && !showsFlexiblePanel { portraitDeckFiller }
                controlBar
            }
        }
        .simultaneousGesture(TapGesture().onEnded { scheduleChromeHide() })
    }

    /// The flexible space between the transport and control bars (10.7.0): the portrait info deck when it is at
    /// least `VideoStageLayout.portraitDeckMinHeight` tall, otherwise empty so the housing shows through. Like the
    /// `Spacer` it replaces, the reader takes whatever height the bars leave.
    private var portraitDeckFiller: some View {
        GeometryReader { filler in
            if VideoStageLayout.showsPortraitDeck(fillerHeight: Double(filler.size.height)) {
                PortraitDeck(model: model, deck: deck, openReview: { showingReview = true })
                    .frame(width: filler.size.width, height: filler.size.height)
                    .transition(.opacity)
            }
        }
    }
}
