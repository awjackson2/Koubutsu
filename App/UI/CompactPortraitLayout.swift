import KoubutsuCore
import SwiftUI

extension RootView {
    /// iPhone portrait and narrow windows (10.3.0). Outside full screen: a slim housing header, the video at full
    /// width under it, and the bars and panels stacked in the region below the video, never over it. Full screen:
    /// the video centred vertically at full width; a tap reveals the same chrome in the region below it.
    /// All geometry comes from `VideoStageLayout` (rule 6).
    func compactPortraitLayout(_ geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        let safeArea = geometry.safeAreaInsets
        let safe = VideoStageLayout.StageInsets(top: safeArea.top, left: safeArea.leading,
                                                bottom: safeArea.bottom, right: safeArea.trailing)
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

    /// The chrome stacked below the stage. Study mode: the study panel directly under the video (10.5.0 refines
    /// it). Otherwise the transport bar, the panels sharing the remaining height and the control bar at the
    /// bottom. With no sharing panel the housing shows through between the bars (outside full screen), or the
    /// bars sit together at the bottom (full screen).
    @ViewBuilder private func compactPortraitChrome(panelMinHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            if study.isActive {
                if isFullScreen { Spacer(minLength: 0) }
                studyPanel
                if !isFullScreen { Spacer(minLength: 0) }
            } else {
                if isFullScreen && !showsFlexiblePanel { Spacer(minLength: 0) }
                transportBar
                Group {
                    panels(translationHeight: nil, recognizedHeight: nil)
                }
                .frame(minHeight: panelMinHeight)
                // Housing filler: the monitor housing drawn behind the chrome shows through here.
                if !isFullScreen && !showsFlexiblePanel { Spacer(minLength: 0) }
                controlBar
            }
        }
        .simultaneousGesture(TapGesture().onEnded { scheduleChromeHide() })
    }
}
