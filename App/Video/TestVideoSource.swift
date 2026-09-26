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
final class TestVideoSource: VideoSource, PlaybackControlling, @unchecked Sendable {
    typealias Frame = VideoFrame

    let kind = VideoSourceKind.testVideo
    let url: URL
    let displayName: String
    /// Initial looping preference; changed at runtime through `setLooping`.
    let loops: Bool

    private let handlers = SourceHandlers<VideoFrame>()
    private let pullQueue = DispatchQueue(label: "koubutsu.video.test.pull", qos: .userInteractive)

    // Main-actor state.
    @MainActor private var player: AVPlayer?
    @MainActor private var endObserver: NSObjectProtocol?
    @MainActor private var statusObservation: NSKeyValueObservation?
    @MainActor private var isLooping = true
    /// Duration of the current item in seconds, loaded in `prepareAndPlay`.
    @MainActor private var duration: Double = 0

    // pullQueue state.
    private var output: AVPlayerItemVideoOutput?
    private var timer: PullThread?
    private var factory = VideoFrameFactory()
    private var sequence: UInt64 = 0
    private var sessionID: UInt64 = 0
    /// Last delivered image, re-delivered while paused so OCR keeps reading the frozen frame.
    private var lastPixelBuffer: CVPixelBuffer?
    private var lastPTS = CMTime.invalid
    private var lastDelivery: CFTimeInterval = 0
    /// Re-delivery interval while no new frames arrive (paused or stalled).
    private let stillFrameInterval: CFTimeInterval = 0.25

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
            lastPixelBuffer = nil
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
        if let assetDuration = try? await asset.load(.duration), assetDuration.isNumeric {
            duration = assetDuration.seconds
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
        isLooping = loops
        player.actionAtItemEnd = loops ? .none : .pause
        player.automaticallyWaitsToMinimizeStalling = false
        self.player = player
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleEnd() }
        }
        statusObservation = Self.observeFailure(of: item, handlers: handlers)
        player.play()
    }

    /// Built outside the main actor: KVO may call back on any thread.
    private nonisolated static func observeFailure(of item: AVPlayerItem,
                                                   handlers: SourceHandlers<VideoFrame>) -> NSKeyValueObservation {
        item.observe(\.status, options: [.new]) { item, _ in
            guard item.status == .failed else { return }
            let reason = item.error?.localizedDescription ?? "playback failed"
            handlers.emit(.stateChanged(.failed(.mediaUnreadable(reason))))
        }
    }

    @MainActor
    private func handleEnd() {
        guard let player else { return }
        if isLooping {
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            player.play()
        }
        // Not looping: the player pauses on the last frame (actionAtItemEnd = .pause); the source stays
        // running so the user can seek back.
    }

    // MARK: - PlaybackControlling (Video mode)

    @MainActor
    func play() {
        guard let player else { return }
        if duration > 0, player.currentTime().seconds >= duration - 0.05 {
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        player.play()
    }

    @MainActor
    func pause() { player?.pause() }

    @MainActor
    func seek(to seconds: Double) async {
        guard let player else { return }
        let status = PlaybackStatus(isPlaying: false, currentTime: 0, duration: duration, loops: isLooping)
        let target = CMTime(seconds: status.clamped(seconds), preferredTimescale: 600)
        await player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    @MainActor
    func setLooping(_ loops: Bool) {
        isLooping = loops
        player?.actionAtItemEnd = loops ? .none : .pause
    }

    @MainActor
    func playbackStatus() -> PlaybackStatus {
        guard let player else { return PlaybackStatus(isPlaying: false, currentTime: 0, duration: 0, loops: isLooping) }
        let time = player.currentTime()
        return PlaybackStatus(isPlaying: player.rate != 0, currentTime: time.isValid ? time.seconds : 0,
                              duration: duration, loops: isLooping)
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
        // The thread serializes with start/stop through pullQueue (sync runs on the calling thread).
        let interval = 1.0 / min(max(frameRate * 2, 60), 240)
        timer = PullThread(interval: interval, name: "koubutsu.video.test.pull") { [weak self] in
            guard let self else { return }
            self.pullQueue.sync { self.pull() }
        }
    }

    private func pull() {
        guard let output else { return }
        let host = CACurrentMediaTime()
        let itemTime = output.itemTime(forHostTime: host)
        let pixelBuffer: CVPixelBuffer
        let pts: CMTime
        if output.hasNewPixelBuffer(forItemTime: itemTime) {
            var displayTime = CMTime.invalid
            guard let buffer = output.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: &displayTime) else {
                return
            }
            pixelBuffer = buffer
            pts = displayTime.isValid ? displayTime : itemTime
        } else if let last = lastPixelBuffer, host - lastDelivery >= stillFrameInterval {
            // Paused (or stalled): hand the same image to the pipeline again so OCR/stabilization keep
            // working on what the user is looking at. Display re-enqueue of an identical image is invisible.
            pixelBuffer = last
            pts = lastPTS
        } else {
            return
        }
        lastPixelBuffer = pixelBuffer
        lastPTS = pts
        lastDelivery = host
        let timing = FrameTiming(sequence: sequence, presentationTime: MediaTime(pts),
                                 hostTime: HostTime(seconds: host), sourceSessionID: sessionID)
        sequence += 1
        guard let frame = factory.makeFrame(pixelBuffer: pixelBuffer, presentationTime: pts, timing: timing) else {
            return
        }
        handlers.deliver(frame)
    }
}
