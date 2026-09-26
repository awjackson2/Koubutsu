import AVFoundation
import KoubutsuCore
import QuartzCore

/// Plays a prerecorded video file as a live-like frame source.
///
/// `AVPlayer` drives decoding, timing and audio; an `AVPlayerItemVideoOutput` is polled on a dedicated
/// high-priority queue and every new pixel buffer is wrapped (no copy) and delivered to the frame handler.
/// Frames therefore go through exactly the same downstream path as live capture frames.
///
/// Threading: player objects are created and controlled on the main actor; pulling happens on `pullQueue`.
final class TestVideoSource: VideoSource, @unchecked Sendable {
    typealias Frame = VideoFrame

    let kind = VideoSourceKind.testVideo
    let url: URL
    let displayName: String
    let loops: Bool

    private let handlers = SourceHandlers<VideoFrame>()
    private let pullQueue = DispatchQueue(label: "koubutsu.video.test.pull", qos: .userInteractive)

    // Main-actor state.
    @MainActor private var player: AVPlayer?
    @MainActor private var endObserver: NSObjectProtocol?
    @MainActor private var statusObservation: NSKeyValueObservation?

    // pullQueue state.
    private var output: AVPlayerItemVideoOutput?
    private var timer: DispatchSourceTimer?
    private var factory = VideoFrameFactory()
    private var sequence: UInt64 = 0
    private var sessionID: UInt64 = 0

    init(url: URL, loops: Bool = true, displayName: String? = nil) {
        self.url = url
        self.loops = loops
        self.displayName = displayName ?? url.deletingPathExtension().lastPathComponent
    }

    func setFrameHandler(_ handler: (@Sendable (VideoFrame) -> Void)?) { handlers.setFrameHandler(handler) }
    func setEventHandler(_ handler: (@Sendable (VideoSourceEvent) -> Void)?) { handlers.setEventHandler(handler) }

    func start() async throws(VideoSourceError) {
        await stop()
        handlers.emit(.stateChanged(.starting))
        do throws(VideoSourceError) {
            let (output, format) = try await prepareAndPlay()
            pullQueue.sync {
                self.output = output.value
                self.factory = VideoFrameFactory()
                self.sequence = 0
                self.sessionID = SourceSession.next()
                self.startTimer(frameRate: format.nominalFrameRate)
            }
            handlers.emit(.formatChanged(format))
            handlers.emit(.stateChanged(.running))
        } catch {
            handlers.emit(.stateChanged(.failed(error)))
            throw error
        }
    }

    func stop() async {
        pullQueue.sync {
            timer?.cancel()
            timer = nil
            output = nil
        }
        let wasRunning = await teardownPlayer()
        if wasRunning { handlers.emit(.stateChanged(.stopped)) }
    }

    // MARK: - Setup

    @MainActor
    private func prepareAndPlay() async throws(VideoSourceError) -> (UncheckedSendableBox<AVPlayerItemVideoOutput>, VideoFormat) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw .mediaMissing(url.lastPathComponent)
        }
        let asset = AVURLAsset(url: url)
        let track: AVAssetTrack
        let naturalSize: CGSize
        let nominalFrameRate: Float
        let transform: CGAffineTransform
        do {
            guard let first = try await asset.loadTracks(withMediaType: .video).first else {
                throw VideoSourceError.unsupportedFormat("no video track in \(url.lastPathComponent)")
            }
            track = first
            (naturalSize, nominalFrameRate, transform) = try await track.load(.naturalSize, .nominalFrameRate,
                                                                              .preferredTransform)
        } catch let error as VideoSourceError {
            throw error
        } catch {
            throw .mediaUnreadable(error.localizedDescription)
        }
        let oriented = naturalSize.applying(transform)
        let format = VideoFormat(size: PixelSize(width: Int(abs(oriented.width)), height: Int(abs(oriented.height))),
                                 nominalFrameRate: Double(nominalFrameRate > 0 ? nominalFrameRate : 60),
                                 pixelFormat: VideoPixelFormat.fourCC)
        let item = AVPlayerItem(asset: asset)
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: VideoPixelFormat.bufferAttributes)
        output.suppressesPlayerRendering = true
        item.add(output)
        play(item)
        return (UncheckedSendableBox(output), format)
    }

    @MainActor
    private func play(_ item: AVPlayerItem) {
        let player = AVPlayer(playerItem: item)
        player.actionAtItemEnd = loops ? .none : .pause
        player.automaticallyWaitsToMinimizeStalling = false
        self.player = player
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleEnd() }
        }
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            let reason = item.error?.localizedDescription ?? "playback failed"
            self?.handlers.emit(.stateChanged(.failed(.mediaUnreadable(reason))))
        }
        player.play()
    }

    @MainActor
    private func handleEnd() {
        guard let player else { return }
        if loops {
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            player.play()
        } else {
            Task { await self.stop() }
        }
    }

    @MainActor
    private func teardownPlayer() -> Bool {
        guard let player else { return false }
        player.pause()
        player.replaceCurrentItem(with: nil)
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
        statusObservation = nil
        self.player = nil
        return true
    }

    // MARK: - Pulling (pullQueue)

    private func startTimer(frameRate: Double) {
        // Poll at twice the source rate (max 240 Hz) so a new frame waits at most half a frame interval.
        let interval = 1.0 / min(max(frameRate * 2, 60), 240)
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: pullQueue)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .microseconds(500))
        timer.setEventHandler { [weak self] in self?.pull() }
        self.timer = timer
        timer.resume()
    }

    private func pull() {
        guard let output else { return }
        let host = CACurrentMediaTime()
        let itemTime = output.itemTime(forHostTime: host)
        guard output.hasNewPixelBuffer(forItemTime: itemTime) else { return }
        var displayTime = CMTime.invalid
        guard let pixelBuffer = output.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: &displayTime) else {
            return
        }
        let pts = displayTime.isValid ? displayTime : itemTime
        let timing = FrameTiming(sequence: sequence, presentationTime: MediaTime(pts),
                                 hostTime: HostTime(seconds: host), sourceSessionID: sessionID)
        sequence += 1
        guard let frame = factory.makeFrame(pixelBuffer: pixelBuffer, presentationTime: pts, timing: timing) else {
            return
        }
        handlers.deliver(frame)
    }
}
