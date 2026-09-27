import KoubutsuCore
import SwiftUI
import Translation
import UIKit
import UniformTypeIdentifiers

struct RootView: View {
    @State var model = AppModel()
    @State var showingImporter = false
    @State var showingSettings = false
    @State var showingRecentLines = false
    @State var showingWordBank = false
    @State var showingReview = false
    /// Full screen hides every bar and panel; the video stage itself never changes (7.6.4).
    @State var isFullScreen = LaunchOptions.current.fullScreen
    /// In full screen, controls revealed by a tap (auto-hidden).
    @State var chromeRevealed = false
    @State var hideChromeTask: Task<Void, Never>?
    /// Press-and-hold on the video: show the original Japanese.
    @State var peeking = false
    @State var study = StudySession()
    @State var readingAids = ReadingAidModel()
    @State var booting = !LaunchOptions.current.skipBoot
    /// A file source was playing when study mode froze it.
    @State var resumeAfterStudy = false
    @Environment(\.scenePhase) private var scenePhase

    var showsChrome: Bool { !isFullScreen || chromeRevealed || study.isActive }

    var body: some View {
        GeometryReader { geometry in
            let layoutClass = LayoutClass.classify(width: geometry.size.width, height: geometry.size.height)
            Group {
                // One layout per class (10.3.0 seam): regular is the iPad layout; the compact layouts live in
                // CompactPortraitLayout.swift and CompactLandscapeLayout.swift.
                switch layoutClass {
                case .regular: regularLayout(geometry)
                case .compactPortrait: compactPortraitLayout(geometry)
                case .compactLandscape: compactLandscapeLayout(geometry)
                }
            }
            .environment(\.layoutClass, layoutClass)
            .background { KeyboardShortcuts(model: model, actions: shortcutActions) }
            .overlay {
                if booting {
                    BootSequenceView { withAnimation(.easeOut(duration: 0.2)) { booting = false } }
                        .transition(.opacity)
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea(edges: .top)
        .preferredColorScheme(.dark)
        .tint(K.red)
        .font(K.osd(16))
        .persistentSystemOverlays(.hidden)
        .statusBarHidden(isFullScreen)
        .animation(.easeInOut(duration: 0.2), value: showsChrome)
        .animation(K.reveal, value: isFullScreen)
        .animation(K.reveal, value: study.isActive)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie]) { result in
            if case .success(let url) = result {
                Task { await model.importVideo(from: url) }
            }
        }
        .translationTask(model.translation.downloadConfiguration) { [translationController = model.translation] session in
            let failure = await TranslationController.prepareDownload(UncheckedSendableBox(session))
            await translationController.downloadFinished(error: failure)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: $model.settings)
        }
        .sheet(isPresented: $showingRecentLines) {
            RecentLinesView(controller: model.translation)
        }
        .sheet(isPresented: $showingWordBank) {
            WordBankView(bank: model.wordBank, store: model.dictionary.store) {
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    showingReview = true
                }
            }
        }
        .sheet(isPresented: $showingReview) {
            ReviewView(bank: model.wordBank)
        }
        .task {
            await model.start()
            await model.applyLaunchPlayback()
        }
        .task { await applyLaunchStudy() }
        .task { applyLaunchSheets() }
        .task { applyLaunchOrientation() }
        .onChange(of: scenePhase) { _, phase in
            Task { await model.scenePhaseChanged(phase) }
        }
        .onChange(of: model.wordBank.bank, initial: true) { _, bank in
            readingAids.setVocabulary(known: bank.knownHeadwords, learning: bank.learningHeadwords)
        }
        .onChange(of: model.dictionary.state) { _, _ in
            readingAids.setVocabulary(known: model.wordBank.bank.knownHeadwords,
                                      learning: model.wordBank.bank.learningHeadwords)
        }
        .onChange(of: model.settings.keepScreenAwake && model.isRunning, initial: true) { _, awake in
            UIApplication.shared.isIdleTimerDisabled = awake
        }
    }

    /// iPad: the stage depends only on the window (and full screen): chrome below overlays it and never resizes
    /// the video. Outside full screen it sits inside the monitor housing (9.4.0).
    private func regularLayout(_ geometry: GeometryProxy) -> some View {
        let insets = isFullScreen ? VideoStageLayout.StageInsets.zero
            : VideoStageLayout.windowedInsets(safeTop: geometry.safeAreaInsets.top)
        let stage = VideoStageLayout.framed(containerWidth: geometry.size.width,
                                            containerHeight: geometry.size.height, insets: insets)
        return ZStack(alignment: .topLeading) {
            Color.black
            if !isFullScreen {
                MonitorFrame(stage: stage.cgRect, sourceLabel: model.selection?.label, isRunning: model.isRunning,
                             bottomInset: insets.bottom)
                    .transition(.opacity)
            }
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

    /// The video stage placed at `stage` (container coordinates) with its tap (reveal chrome in full screen) and
    /// press-and-hold (peek at the original) gestures. Shared by every layout.
    func interactiveStage(_ stage: PlaneRect) -> some View {
        videoStage
            .frame(width: stage.width, height: stage.height)
            .contentShape(Rectangle())
            .onTapGesture { stageTapped() }
            .onLongPressGesture(minimumDuration: 0.25, maximumDistance: 30) {
                if !study.isActive { peeking = true }
            } onPressingChanged: { pressing in
                if !pressing { peeking = false }
            }
            .offset(x: stage.x, y: stage.y)
    }

    private var shortcutActions: KeyboardShortcuts.Actions {
        KeyboardShortcuts.Actions(
            toggleFullScreen: { toggleFullScreen() },
            toggleEnglish: { cycleOverlay() },
            toggleStudy: { Task { await toggleStudy() } },
            showWordBank: { showingWordBank = true },
            showReview: { showingReview = true },
            showRecentLines: { showingRecentLines = true },
            showSettings: { showingSettings = true })
    }

    /// English → furigana → original Japanese → English.
    func cycleOverlay() {
        if !model.settings.showTranslation {
            model.settings.showTranslation = true
            model.settings.overlayStyle = .english
        } else if model.settings.overlayStyle == .english {
            model.settings.overlayStyle = .furigana
        } else {
            model.settings.showTranslation = false
        }
    }

    func toggleStudy() async {
        if study.isActive {
            study.end()
            if resumeAfterStudy { await model.resumeAfterStudy() }
            resumeAfterStudy = false
            return
        }
        guard let frame = model.pipeline.latestFrame else { return }
        resumeAfterStudy = await model.pauseForStudy()
        await study.begin(frame: frame, ocr: model.ocrService, translator: model.translation,
                          lookup: model.dictionary.lookup)
    }

    /// `--seed-words`, `--open=settings|words|review|recent` (CI screenshots of the sheets).
    private func applyLaunchSheets() {
        let options = LaunchOptions.current
        if options.seedWords { model.wordBank.seedDemo() }
        switch options.openSheet {
        case "settings": showingSettings = true
        case "words": showingWordBank = true
        case "review": showingReview = true
        case "recent": showingRecentLines = true
        default: break
        }
    }

    /// `--orientation=portrait|landscape` (iPhone CI screenshots).
    private func applyLaunchOrientation() {
        guard let name = LaunchOptions.current.orientation else { return }
        let mask: UIInterfaceOrientationMask = name == "landscape" ? .landscapeRight : .portrait
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask))
        }
    }

    /// `--study-after=` / `--study-select=` (CI screenshots of study mode).
    private func applyLaunchStudy() async {
        let options = LaunchOptions.current
        guard let delay = options.studyAfter else { return }
        try? await Task.sleep(for: .seconds(delay))
        await toggleStudy()
        if let rect = options.studySelect { study.select(rect: rect) }
        if let point = options.studyTap {
            study.autoOpenCard = options.openCard
            study.tap(at: point)
        }
    }

    func stageTapped() {
        guard isFullScreen, !study.isActive else { return }
        chromeRevealed.toggle()
        scheduleChromeHide()
    }

    func toggleFullScreen() {
        isFullScreen.toggle()
        chromeRevealed = false
        hideChromeTask?.cancel()
    }

    func scheduleChromeHide() {
        hideChromeTask?.cancel()
        guard isFullScreen, chromeRevealed else { return }
        hideChromeTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            chromeRevealed = false
        }
    }

    var videoStage: some View {
        let translationController = model.translation
        return VideoDisplayView(renderer: model.renderer)
            .background(Color.black)
            .overlay {
                VideoOverlayView(sourceSize: model.format?.size ?? model.latestOCR?.frameSize,
                                 ocr: model.latestOCR,
                                 displayed: translationController.displayed,
                                 showBoxes: model.settings.showOCRBoxes,
                                 showTranslations: model.settings.displayMode != .panel
                                     && model.settings.showTranslation && !peeking,
                                 textScale: model.settings.overlayTextScale,
                                 style: model.settings.overlayStyle,
                                 annotations: { line in
                                     readingAids.annotations(for: line, lookup: model.dictionary.lookup)
                                 })
            }
            .overlay(alignment: .center) { sourceMessage }
            .overlay {
                if study.isActive {
                    StudyView(session: study)
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .top) {
                if peeking && !study.isActive {
                    Text("▶ ORIGINAL")
                        .font(K.osd(18))
                        .foregroundStyle(K.paper)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(K.ink.opacity(0.75))
                        .padding(.top, 8)
                }
            }
    }

    /// Bars and panels, bottom-anchored over the space below the stage. Panels have fixed heights (regular layout).
    var chrome: some View {
        VStack(spacing: 0) {
            if study.isActive {
                studyPanel
            } else {
                transportBar
                panels(translationHeight: 150, recognizedHeight: 140)
                controlBar
            }
        }
        .simultaneousGesture(TapGesture().onEnded { scheduleChromeHide() })
    }

    // MARK: Chrome pieces, composed differently by each layout

    var studyPanel: some View {
        StudyPanel(session: study, store: model.dictionary.store, bank: model.wordBank,
                   source: model.selection?.label) { Task { await toggleStudy() } }
    }

    var transportBar: some View {
        VideoTransportBar(model: model, showingImporter: $showingImporter)
    }

    var controlBar: some View {
        ControlBar(model: model, isFullScreen: isFullScreen, showingImporter: $showingImporter,
                   showingSettings: $showingSettings, showingRecentLines: $showingRecentLines,
                   showingWordBank: $showingWordBank, cycleOverlay: cycleOverlay,
                   toggleFullScreen: toggleFullScreen,
                   toggleStudy: { Task { await toggleStudy() } })
    }

    /// Translation panel (panel display modes, or the status message in overlay mode), the Japanese text list and
    /// the debug panel, as enabled in settings. A nil height lets the scrolling panels share the space offered.
    @ViewBuilder func panels(translationHeight: CGFloat?, recognizedHeight: CGFloat?) -> some View {
        let translationController = model.translation
        if model.settings.displayMode != .overlay {
            ScrollView {
                TranslationPanel(controller: translationController,
                                 showOriginal: model.settings.showOriginalText,
                                 showTranslation: model.settings.showTranslation)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            .frame(height: translationHeight)
            .frame(maxHeight: translationHeight == nil ? .infinity : nil)
            .kSurface(.ink)
            .overlay(alignment: .top) { Rectangle().fill(K.paper.opacity(0.18)).frame(height: 1) }
        } else if translationController.statusMessage != nil {
            TranslationPanel(controller: translationController, showOriginal: false, showTranslation: false)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .kSurface(.ink)
        }
        if model.settings.showRecognizedText {
            ScrollView {
                RecognizedTextPanel(result: model.latestOCR, status: model.ocrStatus)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
            }
            .frame(height: recognizedHeight)
            .frame(maxHeight: recognizedHeight == nil ? .infinity : nil)
            .kSurface(.ink)
            .overlay(alignment: .top) { Rectangle().fill(K.paper.opacity(0.18)).frame(height: 1) }
        }
        if model.settings.showDebugStatistics {
            DebugPanel(model: model)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .kSurface(.ink)
                .overlay(alignment: .top) { Rectangle().fill(K.paper.opacity(0.18)).frame(height: 1) }
        }
    }

    @ViewBuilder private var sourceMessage: some View {
        if let message = model.errorMessage {
            Text(message.uppercased())
                .font(K.osd(16))
                .foregroundStyle(K.paper)
                .padding()
                .background(K.red)
                .kFrame(K.paper, tick: 10)
                .transition(.scale(scale: 1.2).combined(with: .opacity))
        }
    }
}

/// Bottom control bar. Regular (iPad): every control inline. Compact (iPhone and narrow windows, 10.2.0): the primary
/// controls inline and everything else in one "More" menu, fitting 375 pt with 44 pt targets.
private struct ControlBar: View {
    let model: AppModel
    let isFullScreen: Bool
    @Binding var showingImporter: Bool
    @Binding var showingSettings: Bool
    @Binding var showingRecentLines: Bool
    @Binding var showingWordBank: Bool
    let cycleOverlay: () -> Void
    let toggleFullScreen: () -> Void
    let toggleStudy: () -> Void
    @Environment(\.layoutClass) private var layoutClass

    var body: some View {
        HStack(spacing: 4) {
            if layoutClass.isCompact {
                compactControls
            } else {
                regularControls
            }
            Spacer(minLength: layoutClass.isCompact ? 4 : 8)
            OSDStatus(model: model, compact: layoutClass.isCompact)
        }
        .padding(.horizontal, layoutClass.isCompact ? 8 : 12)
        // 44 pt targets + 2 pt padding keep the bar as tall as before (36 pt buttons + 6 pt padding).
        .padding(.vertical, 2)
        .kSurface(.ink)
        .overlay(alignment: .top) { Rectangle().fill(K.red).frame(height: 2) }
    }

    /// The iPad bar: the same controls in the same order as before 10.2.0.
    @ViewBuilder private var regularControls: some View {
        Image("LogoMark")
            .resizable()
            .interpolation(.none)
            .frame(width: 32, height: 32)
            .padding(.trailing, 6)
            .accessibilityHidden(true)
        sourceMenu(showsTitle: true, maxTitleWidth: 240)
        playStopButton
        divider
        overlayButton(showsTitle: true)
        KMenu(items: viewItems) { KIconLabel(icon: "eye") }
            .accessibilityLabel("View options")
        divider
        studyButton(showsTitle: true)
        Button {
            showingWordBank = true
        } label: {
            HStack(spacing: 6) {
                PixelIcon("words").accessibilityHidden(true)
                Text("Words")
                if dueCount > 0 { KTag(text: "\(dueCount)", filled: true).kPulse(on: dueCount) }
            }
        }
        .buttonStyle(KIconButtonStyle())
        .help("Word bank and review (W, R)")
        .accessibilityLabel(wordsTitle)
        Button { showingRecentLines = true } label: { KIconLabel(icon: "recent") }
            .buttonStyle(KIconButtonStyle())
            .help("Recent lines (H)")
            .accessibilityLabel("Recent lines")
        fullScreenButton
        Button { showingSettings = true } label: { KIconLabel(icon: "settings") }
            .buttonStyle(KIconButtonStyle())
            .accessibilityLabel("Settings")
    }

    /// iPhone / narrow window: source, play/stop, overlay cycle, study, full screen, more. Icons only in portrait;
    /// landscape has the width for the source and overlay titles. No logo.
    @ViewBuilder private var compactControls: some View {
        let showsTitles = layoutClass == .compactLandscape
        sourceMenu(showsTitle: showsTitles, maxTitleWidth: 160)
        playStopButton
        overlayButton(showsTitle: showsTitles)
        studyButton(showsTitle: false)
        fullScreenButton
        moreMenu
    }

    // MARK: Controls shared by both arrangements

    private func sourceMenu(showsTitle: Bool, maxTitleWidth: CGFloat) -> some View {
        KMenu(items: sourceItems) {
            if showsTitle {
                KIconLabel(icon: "source", title: model.selection?.label ?? "SOURCE")
                    .frame(maxWidth: maxTitleWidth, alignment: .leading)
            } else {
                KIconLabel(icon: "source")
            }
        }
        .accessibilityLabel("Source")
        .accessibilityValue(sourceValue)
    }

    private var playStopButton: some View {
        Button {
            Task { model.isRunning ? await model.stop() : await model.start() }
        } label: {
            KIconLabel(icon: model.isRunning ? "stop" : "play")
        }
        .buttonStyle(KIconButtonStyle())
        .accessibilityLabel(playStopTitle)
    }

    private func overlayButton(showsTitle: Bool) -> some View {
        Button(action: cycleOverlay) {
            KIconLabel(icon: overlayLabel.icon, title: showsTitle ? overlayLabel.title : nil)
        }
        .buttonStyle(KIconButtonStyle(active: model.settings.showTranslation))
        .help("English → furigana → original Japanese (T)")
        .accessibilityLabel("Overlay")
        .accessibilityValue(overlayLabel.spoken)
        .accessibilityHint("Cycles English, furigana and original Japanese")
    }

    private func studyButton(showsTitle: Bool) -> some View {
        Button(action: toggleStudy) { KIconLabel(icon: "study", title: showsTitle ? "Study" : nil) }
            .buttonStyle(KIconButtonStyle())
            .help("Freeze the frame and look up words (S)")
            .accessibilityLabel("Study")
    }

    private var fullScreenButton: some View {
        Button(action: toggleFullScreen) { KIconLabel(icon: isFullScreen ? "windowed" : "fullscreen") }
            .buttonStyle(KIconButtonStyle(active: isFullScreen))
            .help("Full screen (F)")
            .accessibilityLabel(fullScreenTitle)
    }

    /// Compact overflow: words, recent lines, view toggles, loop (file sources) and settings. No "more" pixel glyph
    /// exists, so it is the chevron turned to point down; a red block marks words due for review.
    private var moreMenu: some View {
        KMenu(items: moreItems) {
            PixelIcon("chevron")
                .rotationEffect(.degrees(90))
                .accessibilityHidden(true)
                .overlay(alignment: .topTrailing) {
                    if dueCount > 0 {
                        Rectangle().fill(K.red).frame(width: 6, height: 6)
                    }
                }
        }
        .help("Words, recent lines, view options and settings")
        .accessibilityLabel("More")
        .accessibilityValue(moreValue)
    }

    private var divider: some View {
        Rectangle().fill(K.paper.opacity(0.18)).frame(width: 1, height: 22).padding(.horizontal, 4)
    }

    // MARK: Menus

    private func sourceItems() -> [KMenuItem] {
        var items = model.mediaItems.map { item in
            KMenuItem(title: item.origin == .bundled ? "\(item.name) (bundled)" : item.name, icon: "play",
                      isChecked: model.selection?.label == item.name) {
                Task { await model.select(.media(item)) }
            }
        }
        items.append(.divider)
        if model.captureDevices.devices.isEmpty {
            items.append(KMenuItem(title: "USB capture (none connected)", icon: "source") {
                Task { await model.select(.uvc(nil)) }
            })
        } else {
            for device in model.captureDevices.devices {
                items.append(KMenuItem(title: "\(device.name) (USB)", icon: "source",
                                       isChecked: model.selection?.label == device.name) {
                    Task { await model.select(.uvc(device)) }
                })
            }
        }
        items.append(.divider)
        items.append(KMenuItem(title: "Import video…", icon: "import") { showingImporter = true })
        return items
    }

    private func viewItems() -> [KMenuItem] {
        [
            toggleItem("English over Japanese", \.showTranslation),
            toggleItem("Japanese text list", \.showRecognizedText),
            toggleItem("Japanese in panel", \.showOriginalText),
            toggleItem("OCR boxes", \.showOCRBoxes),
            toggleItem("Debug statistics", \.showDebugStatistics),
        ]
    }

    private func moreItems() -> [KMenuItem] {
        var items: [KMenuItem] = [
            KMenuItem(title: wordsTitle, icon: "words") { presentAfterMenu($showingWordBank) },
            KMenuItem(title: "Recent lines", icon: "recent") { presentAfterMenu($showingRecentLines) },
            .divider,
        ]
        items += viewItems()
        if let status = model.playback {
            items.append(.divider)
            items.append(KMenuItem(title: "Loop video", icon: "loop", isChecked: status.loops) {
                Task { await model.setLooping(!status.loops) }
            })
        }
        items.append(.divider)
        items.append(KMenuItem(title: "Settings", icon: "settings") { presentAfterMenu($showingSettings) })
        return items
    }

    /// Opens a sheet once the menu popover has finished closing, so the two presentations do not collide.
    private func presentAfterMenu(_ flag: Binding<Bool>) {
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            flag.wrappedValue = true
        }
    }

    private func toggleItem(_ title: String, _ keyPath: WritableKeyPath<AppSettings, Bool>) -> KMenuItem {
        KMenuItem(title: title, isChecked: model.settings[keyPath: keyPath]) {
            model.settings[keyPath: keyPath].toggle()
        }
    }

    // MARK: Titles

    private var dueCount: Int { model.wordBank.bank.due(at: Date()).count }

    private var wordsTitle: String { dueCount > 0 ? "Words (\(dueCount) due)" : "Words" }

    private var moreValue: String { dueCount > 0 ? "\(dueCount) words due" : "" }

    private var sourceValue: String { model.selection?.label ?? "None" }

    private var playStopTitle: String { model.isRunning ? "Stop" : "Play" }

    private var fullScreenTitle: String { isFullScreen ? "Exit full screen" : "Full screen" }

    private var overlayLabel: (title: String, icon: String, spoken: String) {
        if !model.settings.showTranslation { return ("JP", "japanese", "Original Japanese") }
        return model.settings.overlayStyle == .english
            ? ("EN", "english", "English") : ("Furigana", "furigana", "Furigana")
    }
}

/// VCR-style status readout: a blinking record dot, state, format and frame rates. Compact: dot and state only.
private struct OSDStatus: View {
    let model: AppModel
    var compact = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.6)) { context in
            let blink = Int(context.date.timeIntervalSinceReferenceDate / 0.6) % 2 == 0
            HStack(spacing: 8) {
                Rectangle()
                    .fill(model.isRunning ? K.red : K.grey)
                    .frame(width: 8, height: 8)
                    .opacity(model.isRunning && !blink ? 0.25 : 1)
                Text(compact ? stateLabel : text)
            }
            .font(K.osd(13))
            .foregroundStyle(K.paper.opacity(0.7))
            .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status")
        .accessibilityValue(spokenState)
    }

    private var text: String {
        let m = model.metrics
        let size = model.format.map { "\($0.size)" } ?? "—"
        return String(format: "%@  %@  %.0f/%.0fFPS", stateLabel, size, m.framesReceivedPerSecond,
                      m.framesDisplayedPerSecond).uppercased()
    }

    private var stateLabel: String {
        switch model.sourceState {
        case .idle: "IDLE"
        case .starting: "LOAD"
        case .running: "REC"
        case .stopped: "STOP"
        case .failed: "ERR"
        }
    }

    private var spokenState: String {
        switch model.sourceState {
        case .idle: "Idle"
        case .starting: "Loading"
        case .running: "Running"
        case .stopped: "Stopped"
        case .failed: "Error"
        }
    }
}
