import AVFoundation
import KoubutsuCore
import QuartzCore

/// Description of an external (UVC) capture device.
struct CaptureDeviceInfo: Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let manufacturer: String
}

/// External USB Video Class capture source (Switch 2 USB-C capture adapter, HDMI capture card, …).
///
/// Discovers devices of type `.external` (UVC on iPad), selects the format closest to 1080p60 with
/// `CaptureFormatSelector`, and delivers `AVCaptureVideoDataOutput` sample buffers — already stamped on the
/// host clock — to the same frame handler `TestVideoSource` uses. Nothing downstream knows the difference.
final class UVCVideoSource: NSObject, VideoSource, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    typealias Frame = VideoFrame

    let kind = VideoSourceKind.uvcCapture
    private(set) var displayName = "USB capture device"
    /// Unique ID of the device to use; nil = first available external device.
    let deviceID: String?
    var targetSize = PixelSize(width: 1920, height: 1080)
    var targetFrameRate: Double = 60

    private let handlers = SourceHandlers<VideoFrame>()
    private let sessionQueue = DispatchQueue(label: "koubutsu.capture.session")
    private let outputQueue = DispatchQueue(label: "koubutsu.capture.video", qos: .userInteractive)

    // sessionQueue state
    private var session: AVCaptureSession?
    private var observers: [NSObjectProtocol] = []
    // outputQueue state
    private var sequence: UInt64 = 0
    private var sessionID: UInt64 = 0
    private(set) var droppedCaptureFrames = 0

    init(deviceID: String? = nil) {
        self.deviceID = deviceID
    }

    static func discoverDevices() -> [CaptureDeviceInfo] {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
            .devices
            .map { CaptureDeviceInfo(id: $0.uniqueID, name: $0.localizedName, manufacturer: $0.manufacturer) }
    }

    func setFrameHandler(_ handler: (@Sendable (VideoFrame) -> Void)?) { handlers.setFrameHandler(handler) }
    func setEventHandler(_ handler: (@Sendable (VideoSourceEvent) -> Void)?) { handlers.setEventHandler(handler) }

    func start() async throws(VideoSourceError) {
        await stop()
        handlers.emit(.stateChanged(.starting))
        do throws(VideoSourceError) {
            // Look for a device before asking for camera permission, so no prompt appears without hardware.
            let device = try findDevice()
            try await Self.ensureAuthorized()
            displayName = device.localizedName
            let format = try await configureAndRun(device: device)
            handlers.emit(.formatChanged(format))
            handlers.emit(.stateChanged(.running))
        } catch {
            handlers.emit(.stateChanged(.failed(error)))
            throw error
        }
    }

    func stop() async {
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                let wasRunning = self.session != nil
                for observer in self.observers { NotificationCenter.default.removeObserver(observer) }
                self.observers.removeAll()
                if let session = self.session {
                    session.stopRunning()
                    session.beginConfiguration()
                    session.inputs.forEach(session.removeInput)
                    session.outputs.forEach(session.removeOutput)
                    session.commitConfiguration()
                }
                self.session = nil
                if wasRunning { self.handlers.emit(.stateChanged(.stopped)) }
                done.resume()
            }
        }
    }

    // MARK: - Setup

    private static func ensureAuthorized() async throws(VideoSourceError) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return
        case .notDetermined:
            if await AVCaptureDevice.requestAccess(for: .video) { return }
            throw .permissionDenied
        default:
            throw .permissionDenied
        }
    }

    private func findDevice() throws(VideoSourceError) -> AVCaptureDevice {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video,
                                                       position: .unspecified).devices
        if let deviceID {
            guard let device = devices.first(where: { $0.uniqueID == deviceID }) else { throw .noDeviceAvailable }
            return device
        }
        guard let device = devices.first else { throw .noDeviceAvailable }
        return device
    }

    private func configureAndRun(device: AVCaptureDevice) async throws(VideoSourceError) -> VideoFormat {
        let box = UncheckedSendableBox(device)
        let result: Result<VideoFormat, VideoSourceError> = await withCheckedContinuation { continuation in
            sessionQueue.async {
                continuation.resume(returning: self.configure(box.value))
            }
        }
        return try result.get()
    }

    /// sessionQueue only.
    private func configure(_ device: AVCaptureDevice) -> Result<VideoFormat, VideoSourceError> {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .inputPriority

        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            session.commitConfiguration()
            return .failure(.configurationFailed(error.localizedDescription))
        }
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            return .failure(.configurationFailed("cannot add capture input"))
        }
        session.addInput(input)

        // Choose the format closest to 1080p60.
        let formats = device.formats
        let candidates = formats.enumerated().map { index, format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let ranges = format.videoSupportedFrameRateRanges
            return CaptureFormatCandidate(
                index: index,
                size: PixelSize(width: Int(dimensions.width), height: Int(dimensions.height)),
                minFrameRate: ranges.map(\.minFrameRate).min() ?? 0,
                maxFrameRate: ranges.map(\.maxFrameRate).max() ?? 0,
                pixelFormat: CMFormatDescriptionGetMediaSubType(format.formatDescription))
        }
        let selector = CaptureFormatSelector(targetSize: targetSize, targetFrameRate: targetFrameRate)
        var selectedRate = targetFrameRate
        if let selection = selector.select(from: candidates) {
            let format = formats[selection.candidate.index]
            do {
                try device.lockForConfiguration()
                device.activeFormat = format
                if let range = format.videoSupportedFrameRateRanges
                    .first(where: { $0.minFrameRate <= selection.frameRate && selection.frameRate <= $0.maxFrameRate }) {
                    // Use the range's own duration when requesting its maximum rate (e.g. exactly 1001/60000).
                    let duration = abs(range.maxFrameRate - selection.frameRate) < 0.01
                        ? range.minFrameDuration
                        : CMTime(value: 1000, timescale: CMTimeScale(selection.frameRate * 1000))
                    device.activeVideoMinFrameDuration = duration
                    device.activeVideoMaxFrameDuration = duration
                }
                device.unlockForConfiguration()
                selectedRate = selection.frameRate
            } catch {
                // Keep the device's default format; capture still works.
            }
        }

        let output = AVCaptureVideoDataOutput()
        if output.availableVideoPixelFormatTypes.contains(VideoPixelFormat.fourCC) {
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: VideoPixelFormat.fourCC]
        }
        // Never queue late frames: the display wants the newest frame, and OCR has its own sampling.
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: outputQueue)
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return .failure(.configurationFailed("cannot add video output"))
        }
        session.addOutput(output)
        session.commitConfiguration()

        observe(session: session, device: device)
        outputQueue.sync {
            sequence = 0
            sessionID = SourceSession.next()
            droppedCaptureFrames = 0
        }
        session.startRunning()
        self.session = session

        let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
        let subtype = output.videoSettings[kCVPixelBufferPixelFormatTypeKey as String] as? UInt32
            ?? CMFormatDescriptionGetMediaSubType(device.activeFormat.formatDescription)
        return .success(VideoFormat(size: PixelSize(width: Int(dimensions.width), height: Int(dimensions.height)),
                                    nominalFrameRate: selectedRate, pixelFormat: subtype))
    }

    private func observe(session: AVCaptureSession, device: AVCaptureDevice) {
        let center = NotificationCenter.default
        let name = device.localizedName
        let handlers = self.handlers
        observers.append(center.addObserver(forName: AVCaptureDevice.wasDisconnectedNotification, object: device,
                                            queue: nil) { _ in
            handlers.emit(.stateChanged(.failed(.deviceDisconnected(name))))
        })
        observers.append(center.addObserver(forName: AVCaptureSession.runtimeErrorNotification, object: session,
                                            queue: nil) { note in
            let error = note.userInfo?[AVCaptureSessionErrorKey] as? NSError
            handlers.emit(.stateChanged(.failed(.configurationFailed(error?.localizedDescription ?? "capture error"))))
        })
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate (outputQueue)

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        // Capture PTS is on the host clock; guard against devices that stamp otherwise.
        let now = CACurrentMediaTime()
        var host = pts.isValid ? pts.seconds : now
        if abs(host - now) > 1 { host = now }
        let timing = FrameTiming(sequence: sequence, presentationTime: MediaTime(pts),
                                 hostTime: HostTime(seconds: host), sourceSessionID: sessionID)
        sequence += 1
        guard let frame = VideoFrame(sampleBuffer: sampleBuffer, timing: timing) else { return }
        handlers.deliver(frame)
    }

    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        droppedCaptureFrames += 1
    }
}
