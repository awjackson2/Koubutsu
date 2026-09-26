import AVFoundation
import KoubutsuCore
import Observation
import SwiftUI

/// Composition root and lifecycle owner. Holds the pipeline, the active source, and UI-facing state.
/// All source lifecycle transitions (select, start, stop, background/foreground) go through here.
@MainActor
@Observable
final class AppModel {
    enum SourceSelection: Hashable {
        case media(MediaItem)
        case uvc

        var label: String {
            switch self {
            case .media(let item): item.name
            case .uvc: "USB capture"
            }
        }
    }

    var settings = AppSettings() {
        didSet {
            processingTap.setRate(settings.ocrRate.rawValue)
            ocrWorker.setConfiguration(settings.ocrConfiguration)
        }
    }
    private(set) var mediaItems: [MediaItem] = []
    private(set) var selection: SourceSelection?
    private(set) var sourceState: VideoSourceState = .idle
    private(set) var sourceKind: VideoSourceKind?
    private(set) var format: VideoFormat?
    private(set) var metrics = PipelineMetricsSnapshot()
    private(set) var latestOCR: OCRResult?
    private(set) var ocrStatus: String?
    var errorMessage: String?

    let clock: any HostClock = AppleHostClock()
    let renderer: SampleBufferRenderer
    let pipelineMetrics: PipelineMetrics
    let pipeline: FramePipeline
    /// Sampled, backpressured frames for OCR. Consumed from Phase 1.5.0.
    let processingTap: SampledFrameTap
    let ocrService = VisionOCRService()
    private let ocrWorker: OCRWorker<VisionOCRService>

    private var source: (any VideoSource<VideoFrame>)?
    private var metricsTask: Task<Void, Never>?
    private var wasRunningBeforeBackground = false

    init() {
        renderer = SampleBufferRenderer()
        pipelineMetrics = PipelineMetrics(clock: clock)
        pipeline = FramePipeline(renderer: renderer, metrics: pipelineMetrics, clock: clock)
        let initialSettings = AppSettings()
        processingTap = SampledFrameTap(rate: initialSettings.ocrRate.rawValue, metrics: pipelineMetrics)
        pipeline.setProcessingTap(processingTap)
        ocrWorker = OCRWorker(service: ocrService, tap: processingTap, metrics: pipelineMetrics, clock: clock,
                              configuration: initialSettings.ocrConfiguration)
        refreshMedia()
        selection = MediaLibrary.defaultItem.map { .media($0) }
        ocrWorker.start(
            onResult: { [weak self] result in self?.latestOCR = result },
            onError: { [weak self] error in self?.ocrStatus = error.description })
        Task { await checkOCRSupport() }
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
        let newSource: any VideoSource<VideoFrame>
        switch selection {
        case .media(let item): newSource = TestVideoSource(url: item.url, loops: settings.loopTestVideo)
        case .uvc: newSource = UVCVideoSource()
        }
        configureAudioSession()
        newSource.setEventHandler { [weak self] event in
            Task { @MainActor in self?.apply(event) }
        }
        pipeline.attach(to: newSource)
        source = newSource
        sourceKind = newSource.kind
        pipelineMetrics.reset()
        startMetricsPolling()
        do {
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
        latestOCR = nil
        metricsTask?.cancel()
        metricsTask = nil
        sourceState = .stopped
        format = nil
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

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)
    }

    // MARK: - Metrics

    /// Samples metrics at 4 Hz; the UI never receives per-frame updates.
    private func startMetricsPolling() {
        metricsTask?.cancel()
        metricsTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.metrics = self.pipelineMetrics.snapshot()
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }
}
