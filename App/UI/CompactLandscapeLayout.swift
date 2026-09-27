import KoubutsuCore
import SwiftUI

extension RootView {
    /// iPhone landscape and short windows (10.4.0). The video fills the available height inside the safe area
    /// (clear of the Dynamic Island/notch and the home indicator), with no monitor housing: a 1 pt paper hairline
    /// frames it outside full screen. The bars and panels are a bottom-anchored overlay revealed by a tap on the
    /// video and hidden after 4 s (kept up while VoiceOver runs or study mode is active); while they are hidden a
    /// small OSD tab shows that controls exist. Full screen is the same minus the hairline and the tab.
    func compactLandscapeLayout(_ geometry: GeometryProxy, safe: VideoStageLayout.StageInsets) -> some View {
        let insets = VideoStageLayout.windowedInsets(for: .compactLandscape, safe: safe)
        let stage = VideoStageLayout.framed(containerWidth: geometry.size.width,
                                            containerHeight: geometry.size.height, insets: insets)
        let chromeInsets = VideoStageLayout.overlayChromeInsets(safe: safe)
        let chromeShown = chromeRevealed || study.isActive
        return ZStack(alignment: .topLeading) {
            Color.black
            interactiveStage(stage, onTap: { compactLandscapeStageTapped() })
            if !isFullScreen {
                Rectangle()
                    .strokeBorder(K.paper, lineWidth: 1)
                    .frame(width: stage.width + 2, height: stage.height + 2)
                    .offset(x: stage.x - 1, y: stage.y - 1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }
            if !chromeShown && !isFullScreen {
                controlsTab
                    .frame(width: stage.width, height: stage.height, alignment: .bottom)
                    .offset(x: stage.x, y: stage.y)
                    .transition(.opacity)
            }
            if chromeShown {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    landscapeChrome(stageHeight: stage.height)
                }
                .padding(.leading, chromeInsets.left)
                .padding(.trailing, chromeInsets.right)
                .padding(.bottom, chromeInsets.bottom)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: chromeShown)
        .onChange(of: voiceOverEnabled) { _, enabled in
            // VoiceOver started: never pull the controls away from under it.
            if enabled { hideChromeTask?.cancel() }
        }
    }

    /// Transport bar, panels and control bar; the panels share at most what is left of 60 % of the stage height
    /// once the bars are placed, so the video stays mostly visible. Study mode shows only the study strip
    /// (10.5.0): at most `VideoStageLayout.overlayStudyFraction` (40 %) of the stage height, collapsible to its
    /// header, so the frozen frame above it stays visible and selectable. The chrome stays up and the CONTROLS tab
    /// hidden for the whole of study mode (`chromeShown`).
    private func landscapeChrome(stageHeight: Double) -> some View {
        let barsHeight = Self.landscapeControlBarHeight + (model.playback != nil ? Self.landscapeTransportBarHeight : 0)
        let panelBudget = VideoStageLayout.overlayPanelBudget(stageHeight: stageHeight, barsHeight: barsHeight)
        return VStack(spacing: 0) {
            if study.isActive {
                studyPanel(overlayStageHeight: stageHeight)
            } else {
                transportBar
                if panelBudget > 0 {
                    VStack(spacing: 0) {
                        panels(translationHeight: nil, recognizedHeight: nil)
                    }
                    .frame(maxHeight: panelBudget)
                    .clipped()
                }
                controlBar
            }
        }
        // Any touch on the chrome restarts the 4 s timer.
        .simultaneousGesture(TapGesture().onEnded { scheduleCompactLandscapeChromeHide() })
    }

    /// Always-visible hint (outside full screen) that a tap brings up the controls; itself a 44 pt button.
    private var controlsTab: some View {
        Button {
            revealCompactLandscapeChrome()
        } label: {
            HStack(spacing: 6) {
                PixelIcon("chevron", size: 12)
                    .rotationEffect(.degrees(-90))
                Text("CONTROLS")
                    .font(K.osd(12))
            }
            .foregroundStyle(K.paper.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(K.ink.opacity(0.7))
            .overlay { Rectangle().strokeBorder(K.paper.opacity(0.35), lineWidth: 1) }
            .frame(minWidth: KIconButtonStyle.minimumTarget, minHeight: KIconButtonStyle.minimumTarget,
                   alignment: .bottom)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 4)
        .accessibilityLabel("Show controls")
    }

    /// Stage tap in compact landscape: toggles the chrome (windowed and full screen alike). Study mode owns taps on
    /// the stage while it is active.
    func compactLandscapeStageTapped() {
        guard !study.isActive else { return }
        chromeRevealed.toggle()
        scheduleCompactLandscapeChromeHide()
    }

    func revealCompactLandscapeChrome() {
        chromeRevealed = true
        scheduleCompactLandscapeChromeHide()
    }

    /// Hides revealed chrome after 4 s, as full screen does; never while VoiceOver runs.
    func scheduleCompactLandscapeChromeHide() {
        hideChromeTask?.cancel()
        guard chromeRevealed, !voiceOverEnabled else { return }
        hideChromeTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            chromeRevealed = false
        }
    }

    /// Bar heights used to budget the panels: 44 pt targets, plus 2 pt padding above and below on the control bar.
    private static var landscapeControlBarHeight: Double { Double(KIconButtonStyle.minimumTarget) + 4 }
    private static var landscapeTransportBarHeight: Double { Double(KIconButtonStyle.minimumTarget) }
}
