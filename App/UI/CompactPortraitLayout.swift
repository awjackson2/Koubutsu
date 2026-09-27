import KoubutsuCore
import SwiftUI

extension RootView {
    /// iPhone portrait and narrow windows (10.3.0). Placeholder until 10.3.0 lands: the regular arrangement.
    func compactPortraitLayout(_ geometry: GeometryProxy) -> some View {
        let insets = isFullScreen ? VideoStageLayout.StageInsets.zero
            : VideoStageLayout.windowedInsets(safeTop: geometry.safeAreaInsets.top)
        let stage = VideoStageLayout.framed(containerWidth: geometry.size.width,
                                            containerHeight: geometry.size.height, insets: insets)
        return ZStack(alignment: .topLeading) {
            Color.black
            interactiveStage(stage)
            if showsChrome {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    chrome
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .transition(.opacity)
            }
        }
    }
}
