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
    /// Full screen hides every bar and panel; the video stage itself never changes (7.6.4).
    @State private var isFullScreen = LaunchOptions.current.fullScreen
    /// In full screen, controls revealed by a tap (auto-hidden).
    @State private var chromeRevealed = false
    @State private var hideChromeTask: Task<Void, Never>?
    /// Press-and-hold on the video: show the original Japanese.
    @State private var peeking = false
    @State private var study = StudySession()
    /// A file source was playing when study mode froze it.
    @State private var resumeAfterStudy = false
    @Environment(\.scenePhase) private var scenePhase

    private var showsChrome: Bool { !isFullScreen || chromeRevealed || study.isActive }

    var body: some View {
        GeometryReader { geometry in
            // The stage depends only on the window: chrome below overlays it and never resizes the video.
            let stage = VideoStageLayout.stage(containerWidth: geometry.size.width,
                                               containerHeight: geometry.size.height)
            ZStack(alignment: .topLeading) {
                Color.black
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
        }
        .background(Color.black)
        .ignoresSafeArea(edges: .top)
        .preferredColorScheme(.dark)
        .persistentSystemOverlays(.hidden)
        .statusBarHidden(isFullScreen)
        .animation(.easeInOut(duration: 0.2), value: showsChrome)
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
        .task {
            await model.start()
            await model.applyLaunchPlayback()
        }
        .task { await applyLaunchStudy() }
        .onChange(of: scenePhase) { _, phase in
            Task { await model.scenePhaseChanged(phase) }
        }
        .onChange(of: model.settings.keepScreenAwake && model.isRunning, initial: true) { _, awake in
            UIApplication.shared.isIdleTimerDisabled = awake
        }
    }

    private var shortcutActions: KeyboardShortcuts.Actions {
        KeyboardShortcuts.Actions(
            toggleFullScreen: { toggleFullScreen() },
            toggleEnglish: { model.settings.showTranslation.toggle() },
            toggleStudy: { Task { await toggleStudy() } },
            showRecentLines: { showingRecentLines = true },
            showSettings: { showingSettings = true })
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
                          dictionary: model.dictionary.store)
    }

    /// `--study-after=` / `--study-select=` (CI screenshots of study mode).
    private func applyLaunchStudy() async {
        let options = LaunchOptions.current
        guard let delay = options.studyAfter else { return }
        try? await Task.sleep(for: .seconds(delay))
        await toggleStudy()
        if let rect = options.studySelect { study.select(rect: rect) }
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
                                 textScale: model.settings.overlayTextScale)
            }
            .overlay(alignment: .center) { sourceMessage }
            .overlay {
                if study.isActive { StudyView(session: study) }
            }
            .overlay(alignment: .top) {
                if peeking && !study.isActive {
                    Text("Original")
                        .font(.caption.bold())
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(.black.opacity(0.6), in: Capsule())
                        .padding(.top, 8)
                }
            }
    }

    /// Bars and panels, bottom-anchored over the space below the stage. Panels have fixed heights.
    private var chrome: some View {
        let translationController = model.translation
        return VStack(spacing: 0) {
            if study.isActive {
                StudyPanel(session: study) { Task { await toggleStudy() } }
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
                    .background(Color(white: 0.05))
                } else if translationController.statusMessage != nil {
                    TranslationPanel(controller: translationController, showOriginal: false, showTranslation: false)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(white: 0.05))
                }
                if model.settings.showRecognizedText {
                    ScrollView {
                        RecognizedTextPanel(result: model.latestOCR, status: model.ocrStatus)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                    }
                    .frame(height: 140)
                    .background(Color(white: 0.08))
                }
                if model.settings.showDebugStatistics {
                    DebugPanel(model: model)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.08))
                }
                ControlBar(model: model, isFullScreen: isFullScreen, showingImporter: $showingImporter,
                           showingSettings: $showingSettings, showingRecentLines: $showingRecentLines,
                           toggleFullScreen: toggleFullScreen, toggleStudy: { Task { await toggleStudy() } })
            }
        }
        .simultaneousGesture(TapGesture().onEnded { scheduleChromeHide() })
    }

    @ViewBuilder private var sourceMessage: some View {
        if let message = model.errorMessage {
            Text(message)
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .background(.red.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct ControlBar: View {
    let model: AppModel
    let isFullScreen: Bool
    @Binding var showingImporter: Bool
    @Binding var showingSettings: Bool
    @Binding var showingRecentLines: Bool
    let toggleFullScreen: () -> Void
    let toggleStudy: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Menu {
                ForEach(model.mediaItems) { item in
                    Button(item.origin == .bundled ? "\(item.name) (bundled)" : item.name) {
                        Task { await model.select(.media(item)) }
                    }
                }
                Divider()
                if model.captureDevices.devices.isEmpty {
                    Button("USB capture (none connected)") { Task { await model.select(.uvc(nil)) } }
                } else {
                    ForEach(model.captureDevices.devices) { device in
                        Button("\(device.name) (USB capture)") { Task { await model.select(.uvc(device)) } }
                    }
                }
                Divider()
                Button("Import video…") { showingImporter = true }
            } label: {
                Label(model.selection?.label ?? "Select source", systemImage: "play.rectangle")
            }
            Button {
                Task { model.isRunning ? await model.stop() : await model.start() }
            } label: {
                Image(systemName: model.isRunning ? "stop.fill" : "play.fill")
            }
            Button {
                model.settings.showTranslation.toggle()
            } label: {
                Label(model.settings.showTranslation ? "English" : "Japanese",
                      systemImage: model.settings.showTranslation ? "character.bubble.fill" : "character.bubble")
            }
            .help("Show English or the original Japanese (T)")
            Menu {
                Toggle("English over Japanese", isOn: settingBinding(\.showTranslation))
                Toggle("Japanese text list", isOn: settingBinding(\.showRecognizedText))
                Toggle("Japanese in translation panel", isOn: settingBinding(\.showOriginalText))
                Toggle("OCR boxes", isOn: settingBinding(\.showOCRBoxes))
                Toggle("Debug statistics", isOn: settingBinding(\.showDebugStatistics))
            } label: {
                Image(systemName: "eye")
            }
            Button(action: toggleStudy) {
                Label("Study", systemImage: "book")
            }
            .help("Freeze the frame and look up words (S)")
            Button {
                showingRecentLines = true
            } label: {
                Image(systemName: "text.bubble")
            }
            .help("Recent lines (H)")
            Button {
                toggleFullScreen()
            } label: {
                Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
            }
            .help("Full screen (F)")
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            Spacer()
            Text(statusText)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func settingBinding(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(get: { model.settings[keyPath: keyPath] }, set: { model.settings[keyPath: keyPath] = $0 })
    }

    private var statusText: String {
        let m = model.metrics
        let size = model.format.map { "\($0.size)" } ?? "—"
        return String(format: "%@ · %@ · in %.1f fps · shown %.1f fps", stateLabel, size,
                      m.framesReceivedPerSecond, m.framesDisplayedPerSecond)
    }

    private var stateLabel: String {
        switch model.sourceState {
        case .idle: "idle"
        case .starting: "starting"
        case .running: "running"
        case .stopped: "stopped"
        case .failed: "failed"
        }
    }
}
