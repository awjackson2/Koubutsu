import KoubutsuCore
import SwiftUI
import Translation
import UIKit
import UniformTypeIdentifiers

struct RootView: View {
    @State private var model = AppModel()
    @State private var showingImporter = false
    @State private var showingSettings = false
    @State private var showingRecentLines = false
    @State private var showingWordBank = false
    @State private var showingReview = false
    /// Full screen hides every bar and panel; the video stage itself never changes (7.6.4).
    @State private var isFullScreen = LaunchOptions.current.fullScreen
    /// In full screen, controls revealed by a tap (auto-hidden).
    @State private var chromeRevealed = false
    @State private var hideChromeTask: Task<Void, Never>?
    /// Press-and-hold on the video: show the original Japanese.
    @State private var peeking = false
    @State private var study = StudySession()
    @State private var readingAids = ReadingAidModel()
    @State private var booting = !LaunchOptions.current.skipBoot
    /// A file source was playing when study mode froze it.
    @State private var resumeAfterStudy = false
    @Environment(\.scenePhase) private var scenePhase

    private var showsChrome: Bool { !isFullScreen || chromeRevealed || study.isActive }

    var body: some View {
        GeometryReader { geometry in
            // The stage depends only on the window (and full screen): chrome below overlays it and never resizes
            // the video. Outside full screen it sits inside the monitor housing (9.4.0).
            let insets = isFullScreen ? VideoStageLayout.StageInsets.zero
                : VideoStageLayout.windowedInsets(safeTop: geometry.safeAreaInsets.top)
            let stage = VideoStageLayout.framed(containerWidth: geometry.size.width,
                                                containerHeight: geometry.size.height, insets: insets)
            ZStack(alignment: .topLeading) {
                Color.black
                if !isFullScreen {
                    MonitorFrame(stage: CGRect(x: stage.x, y: stage.y, width: stage.width, height: stage.height),
                                 sourceLabel: model.selection?.label, isRunning: model.isRunning,
                                 bottomInset: insets.bottom)
                        .transition(.opacity)
                }
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
                if showsChrome {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        chrome
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .transition(.opacity)
                }
            }
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
    private func cycleOverlay() {
        if !model.settings.showTranslation {
            model.settings.showTranslation = true
            model.settings.overlayStyle = .english
        } else if model.settings.overlayStyle == .english {
            model.settings.overlayStyle = .furigana
        } else {
            model.settings.showTranslation = false
        }
    }

    private func toggleStudy() async {
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

    private func stageTapped() {
        guard isFullScreen, !study.isActive else { return }
        chromeRevealed.toggle()
        scheduleChromeHide()
    }

    private func toggleFullScreen() {
        isFullScreen.toggle()
        chromeRevealed = false
        hideChromeTask?.cancel()
    }

    private func scheduleChromeHide() {
        hideChromeTask?.cancel()
        guard isFullScreen, chromeRevealed else { return }
        hideChromeTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            chromeRevealed = false
        }
    }

    private var videoStage: some View {
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

    /// Bars and panels, bottom-anchored over the space below the stage. Panels have fixed heights.
    private var chrome: some View {
        let translationController = model.translation
        return VStack(spacing: 0) {
            if study.isActive {
                StudyPanel(session: study, store: model.dictionary.store, bank: model.wordBank,
                           source: model.selection?.label) { Task { await toggleStudy() } }
            } else {
                VideoTransportBar(model: model, showingImporter: $showingImporter)
                if model.settings.displayMode != .overlay {
                    ScrollView {
                        TranslationPanel(controller: translationController,
                                         showOriginal: model.settings.showOriginalText,
                                         showTranslation: model.settings.showTranslation)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                    }
                    .frame(height: 150)
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
                    .frame(height: 140)
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
                ControlBar(model: model, isFullScreen: isFullScreen, showingImporter: $showingImporter,
                           showingSettings: $showingSettings, showingRecentLines: $showingRecentLines,
                           showingWordBank: $showingWordBank, cycleOverlay: cycleOverlay,
                           toggleFullScreen: toggleFullScreen,
                           toggleStudy: { Task { await toggleStudy() } })
            }
        }
        .simultaneousGesture(TapGesture().onEnded { scheduleChromeHide() })
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

    var body: some View {
        HStack(spacing: 4) {
            Image("LogoMark")
                .resizable()
                .interpolation(.none)
                .frame(width: 32, height: 32)
                .padding(.trailing, 6)
            KMenu(items: sourceItems) {
                KIconLabel(icon: "source", title: model.selection?.label ?? "SOURCE")
                    .frame(maxWidth: 240, alignment: .leading)
            }
            Button {
                Task { model.isRunning ? await model.stop() : await model.start() }
            } label: {
                KIconLabel(icon: model.isRunning ? "stop" : "play")
            }
            .buttonStyle(KIconButtonStyle())
            divider
            Button(action: cycleOverlay) {
                KIconLabel(icon: overlayLabel.icon, title: overlayLabel.title)
            }
            .buttonStyle(KIconButtonStyle(active: model.settings.showTranslation))
            .help("English → furigana → original Japanese (T)")
            KMenu(items: viewItems) { KIconLabel(icon: "eye") }
            divider
            Button(action: toggleStudy) { KIconLabel(icon: "study", title: "Study") }
                .buttonStyle(KIconButtonStyle())
                .help("Freeze the frame and look up words (S)")
            Button {
                showingWordBank = true
            } label: {
                let due = model.wordBank.bank.due(at: Date()).count
                HStack(spacing: 6) {
                    PixelIcon("words")
                    Text("Words")
                    if due > 0 { KTag(text: "\(due)", filled: true).kPulse(on: due) }
                }
            }
            .buttonStyle(KIconButtonStyle())
            .help("Word bank and review (W, R)")
            Button { showingRecentLines = true } label: { KIconLabel(icon: "recent") }
                .buttonStyle(KIconButtonStyle())
                .help("Recent lines (H)")
            Button(action: toggleFullScreen) { KIconLabel(icon: isFullScreen ? "windowed" : "fullscreen") }
                .buttonStyle(KIconButtonStyle(active: isFullScreen))
                .help("Full screen (F)")
            Button { showingSettings = true } label: { KIconLabel(icon: "settings") }
                .buttonStyle(KIconButtonStyle())
            Spacer(minLength: 8)
            OSDStatus(model: model)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .kSurface(.ink)
        .overlay(alignment: .top) { Rectangle().fill(K.red).frame(height: 2) }
    }

    private var divider: some View {
        Rectangle().fill(K.paper.opacity(0.18)).frame(width: 1, height: 22).padding(.horizontal, 4)
    }

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

    private func toggleItem(_ title: String, _ keyPath: WritableKeyPath<AppSettings, Bool>) -> KMenuItem {
        KMenuItem(title: title, isChecked: model.settings[keyPath: keyPath]) {
            model.settings[keyPath: keyPath].toggle()
        }
    }

    private var overlayLabel: (title: String, icon: String) {
        if !model.settings.showTranslation { return ("JP", "japanese") }
        return model.settings.overlayStyle == .english ? ("EN", "english") : ("Furigana", "furigana")
    }
}

/// VCR-style status readout: a blinking record dot, state, format and frame rates.
private struct OSDStatus: View {
    let model: AppModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.6)) { context in
            let blink = Int(context.date.timeIntervalSinceReferenceDate / 0.6) % 2 == 0
            HStack(spacing: 8) {
                Rectangle()
                    .fill(model.isRunning ? K.red : K.grey)
                    .frame(width: 8, height: 8)
                    .opacity(model.isRunning && !blink ? 0.25 : 1)
                Text(text)
            }
            .font(K.osd(13))
            .foregroundStyle(K.paper.opacity(0.7))
            .lineLimit(1)
        }
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
}
