import AVFoundation
import KoubutsuCore
import Observation
import os
import SwiftUI

/// Composition root and lifecycle owner. Holds the pipeline, the active source, and UI-facing state.
/// All source lifecycle transitions (select, start, stop, background/foreground) go through here.
@MainActor
@Observable
final class AppModel {
    enum SourceSelection: Hashable {
        case media(MediaItem)
        /// A specific capture device, or nil for the first available one.
        case uvc(CaptureDeviceInfo?)

        var label: String {
            switch self {
            case .media(let item): item.name
            case .uvc(let device): device?.name ?? "USB capture"
            }
        }

        var isCapture: Bool {
            if case .uvc = self { true } else { false }
        }
    }

    var settings = AppSettings() {
        didSet { applySettings() }
    }
    private(set) var mediaItems: [MediaItem] = []
    private(set) var selection: SourceSelection?
    private(set) var sourceState: VideoSourceState = .idle
    private(set) var sourceKind: VideoSourceKind?
    private(set) var format: VideoFormat?
    private(set) var metrics = PipelineMetricsSnapshot()
    private(set) var latestOCR: OCRResult?
    /// Transport state when the source is a video file (Video mode); nil for live capture.
    private(set) var playback: PlaybackStatus?
    private(set) var ocrStatus: String?
    var errorMessage: String?

    let clock: any HostClock = AppleHostClock()
    let renderer: SampleBufferRenderer
    let pipelineMetrics: PipelineMetrics
    let pipeline: FramePipeline
    /// Sampled, backpressured frames for OCR. Consumed from Phase 1.5.0.
    let processingTap: SampledFrameTap
    let ocrService = VisionOCRService()
    let translation: TranslationController
    let performance = PerformanceMonitor()
    private(set) var benchmarkReport: String?
    private(set) var isBenchmarking = false
    let captureDevices = CaptureDeviceMonitor()
    let captureAudio = CaptureAudioService()
    private let ocrWorker: OCRWorker<VisionOCRService>

    private var source: (any VideoSource<VideoFrame>)?
    private var currentMediaURL: URL?
    private var metricsTask: Task<Void, Never>?
    private var wasRunningBeforeBackground = false
    private let settingsStore = SettingsStore()

    init() {
        renderer = SampleBufferRenderer()
        pipelineMetrics = PipelineMetrics(clock: clock)
        pipeline = FramePipeline(renderer: renderer, metrics: pipelineMetrics, clock: clock)
        let options = LaunchOptions.current
        var initialSettings = settingsStore.load()
        options.apply(to: &initialSettings)
        processingTap = SampledFrameTap(rate: initialSettings.ocrRate.rawValue, metrics: pipelineMetrics)
        pipeline.setProcessingTap(processingTap)
        ocrWorker = OCRWorker(service: ocrService, tap: processingTap, metrics: pipelineMetrics, clock: clock,
                              configuration: initialSettings.ocrConfiguration)
        if options.demoTranslator {
            translation = TranslationController(service: DemoTranslationService(), metrics: pipelineMetrics,
                                                clock: clock)
        } else {
            let appleTranslation = AppleTranslationService()
            translation = TranslationController(service: appleTranslation, metrics: pipelineMetrics, clock: clock,
                                                resetService: { await appleTranslation.reset() })
        }
        settings = initialSettings
        applySettings()
        refreshMedia()
        if let name = options.selectVideo,
           let item = mediaItems.first(where: { $0.name.localizedCaseInsensitiveContains(name) }) {
            selection = .media(item)
        } else if settings.autoSwitchToCapture, let device = captureDevices.devices.first {
            selection = .uvc(device)
        } else {
            selection = MediaLibrary.defaultItem.map { .media($0) }
        }
        captureDevices.onChange = { [weak self] change in
            Task { await self?.captureDeviceChanged(change) }
        }
        ocrWorker.start(
            onResult: { [weak self] result in
                self?.latestOCR = result
                self?.translation.process(result)
            },
            onError: { [weak self] error in self?.ocrStatus = error.description })
        Task { await checkOCRSupport() }
        Task { await translation.refreshAvailability() }
    }

    private func checkOCRSupport() async {
        let configuration = settings.ocrConfiguration
        if await ocrService.supports(configuration) {
            ocrStatus = nil
        } else {
            ocrStatus = OCRError.languageUnsupported(configuration.languages.joined(separator: ",")).description
            ocrWorker.setEnabled(false)
        }
    }

    // MARK: - Settings

    private func applySettings() {
        processingTap.setRate(settings.ocrRate.rawValue)
        ocrWorker.setConfiguration(settings.ocrConfiguration)
        captureAudio.volume = Float(settings.captureAudioVolume)
        translation.hidesHUDText = settings.hideHUDText
        translation.quality = settings.translationMode == .higherQuality ? .highFidelity : .lowLatency
        translation.sourceLanguage = settings.sourceLanguage
        translation.targetLanguage = settings.targetLanguage
        settingsStore.save(settings)
    }

    // MARK: - Sources

    func refreshMedia() {
        mediaItems = MediaLibrary.allVideos()
    }

    func select(_ newSelection: SourceSelection) async {
        selection = newSelection
        await start()
    }

    func start() async {
        await stopSource()
        guard let selection else {
            errorMessage = VideoSourceError.mediaMissing("no test video available").description
            return
        }
        errorMessage = nil
        if case .media(let item) = selection, item.url != currentMediaURL {
            translation.clearTranscript()
        }
        if case .media(let item) = selection {
            currentMediaURL = item.url
        } else {
            currentMediaURL = nil
        }
        let newSource: any VideoSource<VideoFrame>
        switch selection {
        case .media(let item): newSource = TestVideoSource(url: item.url, loops: settings.loopTestVideo)
        case .uvc(let device): newSource = UVCVideoSource(deviceID: device?.id)
        }
        configureAudio(for: selection)
        newSource.setEventHandler { [weak self] event in
            Task { @MainActor in self?.apply(event) }
        }
        pipeline.attach(to: newSource)
        source = newSource
        sourceKind = newSource.kind
        pipelineMetrics.reset()
        startMetricsPolling()
        do throws(VideoSourceError) {
            try await newSource.start()
        } catch {
            sourceState = .failed(error)
            errorMessage = error.description
        }
    }

    func stop() async {
        await stopSource()
    }

    var isRunning: Bool { sourceState.isActive }

    private func stopSource() async {
        guard let source else { return }
        self.source = nil
        pipeline.detach(from: source)
        await source.stop()
        source.setEventHandler(nil)
        renderer.clear()
        captureAudio.stop()
        latestOCR = nil
        translation.reset()
        metricsTask?.cancel()
        metricsTask = nil
        sourceState = .stopped
        format = nil
        playback = nil
    }

    private func apply(_ event: VideoSourceEvent) {
        switch event {
        case .stateChanged(let state):
            sourceState = state
            if case .failed(let error) = state { errorMessage = error.description }
        case .formatChanged(let newFormat):
            format = newFormat
        }
    }

    func importVideo(from url: URL) async {
        do {
            let item = try MediaLibrary.importVideo(from: url)
            refreshMedia()
            await select(.media(item))
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Lifecycle

    func scenePhaseChanged(_ phase: ScenePhase) async {
        switch phase {
        case .background:
            wasRunningBeforeBackground = isRunning
            if wasRunningBeforeBackground { await stopSource() }
        case .active:
            if wasRunningBeforeBackground {
                wasRunningBeforeBackground = false
                await start()
            }
        default:
            break
        }
    }

    /// Test video: the player plays the file's audio. Capture: route the device's USB audio to the output.
    private func configureAudio(for selection: SourceSelection) {
        if selection.isCapture {
            guard settings.playCaptureAudio else { return }
            captureAudio.volume = Float(settings.captureAudioVolume)
            captureAudio.start()
        } else {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .moviePlayback)
            try? session.setActive(true)
        }
    }

    /// Hot-plug: switch to a newly connected capture device (if enabled); restart after reconnection.
    private func captureDeviceChanged(_ change: CaptureDeviceMonitor.Change) async {
        switch change {
        case .connected(let device):
            let usingCapture = selection?.isCapture ?? false
            if usingCapture || settings.autoSwitchToCapture {
                await select(.uvc(device))
            }
        case .disconnected(let device):
            guard case .uvc(let selected) = selection, selected == nil || selected?.id == device.id else { return }
            sourceState = .failed(.deviceDisconnected(device.name))
            errorMessage = VideoSourceError.deviceDisconnected(device.name).description
                + " Reconnect it to continue."
        }
    }

    /// Applies `--start-at` / `--pause-after` once, for automation of Video mode captures.
    func applyLaunchPlayback() async {
        let options = LaunchOptions.current
        guard playbackControl != nil, options.startAt != nil || options.pauseAfter != nil else { return }
        if let start = options.startAt { await seek(to: start) }
        if let pauseAfter = options.pauseAfter {
            try? await Task.sleep(for: .seconds(pauseAfter))
            await playbackControl?.pause()
        }
    }

    // MARK: - Video mode (transport)

    private var playbackControl: (any PlaybackControlling)? { source as? any PlaybackControlling }

    var isVideoMode: Bool { playback != nil }

    func togglePlayPause() async {
        guard let control = playbackControl else { return }
        if await control.playbackStatus().isPlaying { await control.pause() } else { await control.play() }
        playback = await control.playbackStatus()
    }

    /// Seeks and clears on-screen OCR/translation state (the content jumps).
    func seek(to seconds: Double) async {
        guard let control = playbackControl else { return }
        await control.seek(to: seconds)
        latestOCR = nil
        translation.reset()
        playback = await control.playbackStatus()
    }

    func skip(by seconds: Double) async {
        guard let current = playback else { return }
        await seek(to: current.currentTime + seconds)
    }

    func setLooping(_ loops: Bool) async {
        settings.loopTestVideo = loops
        await playbackControl?.setLooping(loops)
        playback = await playbackControl?.playbackStatus()
    }

    /// Progress 0...1 of "Analyze whole video", nil when idle.
    private(set) var analysisProgress: Double?
    private(set) var analysisSummary: String?

    /// Runs OCR over the whole current video offline (faster than playback) and fills the transcript.
    func analyzeCurrentVideo() async {
        guard analysisProgress == nil, let url = currentMediaURL else { return }
        analysisProgress = 0
        let progress = ProgressBox()
        let poll = Task { [weak self] in
            while !Task.isCancelled {
                self?.analysisProgress = progress.value
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
        var analyzer = VideoAnalyzer()
        analyzer.configuration = settings.ocrConfiguration
        analyzer.hidesHUDText = settings.hideHUDText
        do {
            let report = try await analyzer.analyze(url: url) { progress.value = $0 }
            translation.adoptTranscript(report.transcript)
            analysisSummary = report.summary
        } catch {
            analysisSummary = "Analysis failed: \(error.localizedDescription)"
        }
        poll.cancel()
        analysisProgress = nil
    }

    // MARK: - Benchmark

    /// Runs the OCR benchmark over the bundled clip (on device: real ANE/GPU numbers).
    func runBenchmark() async {
        guard !isBenchmarking, let clip = MediaLibrary.defaultItem?.url,
              let manifest = try? ClipManifest.load(named: MediaLibrary.defaultClipName) else { return }
        isBenchmarking = true
        benchmarkReport = "Running benchmark…"
        let configuration = settings.ocrConfiguration
        let report: String
        do {
            var runner = BenchmarkRunner()
            runner.configuration = configuration
            runner.configuration.regionOfInterest = nil
            report = try await runner.run(clip: clip, manifest: manifest).summary
        } catch {
            report = "Benchmark failed: \(error.localizedDescription)"
        }
        Logger(subsystem: "com.awjackson2.Koubutsu", category: "Benchmark").notice("\(report, privacy: .public)")
        benchmarkReport = report
        isBenchmarking = false
    }

    // MARK: - Metrics

    /// Samples metrics at 4 Hz; the UI never receives per-frame updates.
    private func startMetricsPolling() {
        metricsTask?.cancel()
        metricsTask = Task { [weak self] in
            var tick = 0
            while !Task.isCancelled {
                guard let self else { return }
                self.metrics = self.pipelineMetrics.snapshot()
                self.captureAudio.refreshLevel()
                if let control = self.playbackControl {
                    self.playback = await control.playbackStatus()
                }
                tick += 1
                if tick % 4 == 0 { await self.performance.refresh(renderer: self.renderer) }
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }
}
