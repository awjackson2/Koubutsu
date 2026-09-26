import AVFoundation
import KoubutsuCore
import Observation
import Synchronization

/// Plays the capture device's USB audio (UAC) through the iPad with minimal latency.
///
/// On iPadOS a UAC device appears as an audio route input (`.usbAudio`), not as an `AVCaptureDevice`. This
/// service selects it as the preferred input and routes input → output with `AVAudioEngine`. A tap exposes
/// timestamped buffers for future consumers (recording, speech recognition) on the same host clock as video.
@MainActor
@Observable
final class CaptureAudioService {
    enum State: Equatable {
        case stopped
        case running(inputName: String)
        case unavailable(String)
    }

    private(set) var state: State = .stopped
    /// RMS level of the last buffer, 0...1 (debug meter).
    private(set) var level: Float = 0
    var volume: Float = 1 {
        didSet { engine?.mainMixerNode.outputVolume = volume }
    }

    @ObservationIgnored private var engine: AVAudioEngine?
    @ObservationIgnored private var routeObserver: NSObjectProtocol?
    @ObservationIgnored private let levelBox = LevelBox()

    /// The USB audio input, if one is connected.
    static func usbInput() -> AVAudioSessionPortDescription? {
        AVAudioSession.sharedInstance().availableInputs?.first { $0.portType == .usbAudio }
    }

    func start() {
        stop()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default,
                                    options: [.defaultToSpeaker, .allowBluetoothA2DP, .mixWithOthers])
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
        } catch {
            state = .unavailable("audio session: \(error.localizedDescription)")
            return
        }
        guard let usb = Self.usbInput() else {
            state = .unavailable("no USB audio input")
            return
        }
        do {
            try session.setPreferredInput(usb)
        } catch {
            state = .unavailable("cannot select \(usb.portName): \(error.localizedDescription)")
            return
        }
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            state = .unavailable("USB input has no audio format")
            return
        }
        engine.connect(input, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = volume
        input.installTap(onBus: 0, bufferSize: 1024, format: format, block: Self.makeTap(levelBox))
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            state = .unavailable("audio engine: \(error.localizedDescription)")
            return
        }
        self.engine = engine
        state = .running(inputName: usb.portName)
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, case .running = self.state, Self.usbInput() == nil else { return }
                self.stop()
                self.state = .unavailable("USB audio disconnected")
            }
        }
    }

    func stop() {
        if let routeObserver { NotificationCenter.default.removeObserver(routeObserver) }
        routeObserver = nil
        if let engine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        engine = nil
        if case .running = state { state = .stopped }
    }

    /// Built outside the main actor: the tap runs on the audio render thread.
    private nonisolated static func makeTap(_ box: LevelBox) -> AVAudioNodeTapBlock {
        { buffer, _ in box.update(buffer) }
    }

    func refreshLevel() {
        level = levelBox.value
    }
}

/// Thread-safe RMS holder written from the audio tap.
final class LevelBox: Sendable {
    private let storage = Synchronization.Mutex<Float>(0)

    var value: Float { storage.withLock { $0 } }

    func update(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return }
        var sum: Float = 0
        for i in 0..<Int(buffer.frameLength) { sum += data[i] * data[i] }
        let rms = (sum / Float(buffer.frameLength)).squareRoot()
        storage.withLock { $0 = rms }
    }
}
