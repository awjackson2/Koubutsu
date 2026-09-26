import AVFoundation

/// On-device Japanese pronunciation (system voice).
@MainActor
final class Speaker {
    static let shared = Speaker()
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
}
