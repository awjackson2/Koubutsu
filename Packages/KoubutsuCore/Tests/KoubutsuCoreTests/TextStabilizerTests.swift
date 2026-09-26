import Foundation
import Testing
@testable import KoubutsuCore

private func result(at t: Double, _ lines: [(String, NormalizedRect)], confidence: Float = 0.9,
                    sequence: UInt64 = 0) -> OCRResult {
    let frame = FrameTiming(sequence: sequence, presentationTime: MediaTime(seconds: t),
                            hostTime: HostTime(seconds: t), sourceSessionID: 1)
    let observations = lines.map {
        RecognizedTextObservation(text: $0.0, confidence: confidence, boundingBox: $0.1, frame: frame)
    }
    return OCRResult(frame: frame, frameSize: .init(width: 1920, height: 1080), observations: observations,
                     started: frame.hostTime, finished: frame.hostTime.adding(0.05), configuration: .japanese)
}

private let dialogueBox = NormalizedRect(x: 0.12, y: 0.73, width: 0.4, height: 0.06)
private let otherBox = NormalizedRect(x: 0.6, y: 0.1, width: 0.2, height: 0.04)

private func stabilized(_ events: [TextEvent]) -> [StableText] {
    events.compactMap { if case .stabilized(let s) = $0 { s } else { nil } }
}

struct TextStabilizerTests {
    @Test func stableTextEmittedOnceAfterWindow() {
        var s = TextStabilizer()
        #expect(stabilized(s.process(result(at: 0.0, [("鍵が必要です", dialogueBox)]))).isEmpty)
        let second = stabilized(s.process(result(at: 0.2, [("鍵が必要です", dialogueBox)])))
        #expect(second.map(\.text) == ["鍵が必要です"])
        #expect(second.first?.firstSeenFrame.hostTime == HostTime(seconds: 0))
        for t in stride(from: 0.4, through: 3.0, by: 0.2) {
            #expect(stabilized(s.process(result(at: t, [("鍵が必要です", dialogueBox)]))).isEmpty)
        }
        #expect(s.duplicateDetections == 14)
    }

    @Test func typewriterRevealEmitsOnlyFinalText() {
        var s = TextStabilizer()
        let full = "ここから先は危険だ"
        var emitted: [String] = []
        // Reveal one character per OCR sample (5 FPS), then hold.
        var t = 0.0
        for n in 1...full.count {
            emitted += stabilized(s.process(result(at: t, [(String(full.prefix(n)), dialogueBox)]))).map(\.text)
            t += 0.2
        }
        for _ in 0..<3 {
            emitted += stabilized(s.process(result(at: t, [(full, dialogueBox)]))).map(\.text)
            t += 0.2
        }
        #expect(emitted == [full])
    }

    @Test func ocrFlickerDoesNotRetrigger() {
        var s = TextStabilizer()
        _ = s.process(result(at: 0.0, [("この先には強い敵がいる", dialogueBox)]))
        #expect(stabilized(s.process(result(at: 0.2, [("この先には強い敵がいる", dialogueBox)]))).count == 1)
        // One misread character.
        #expect(stabilized(s.process(result(at: 0.4, [("この先にわ強い敵がいる", dialogueBox)]))).isEmpty)
        #expect(stabilized(s.process(result(at: 0.6, [("この先には強い敵がいる", dialogueBox)]))).isEmpty)
    }

    @Test func newDialoguePageInSameBoxEmitsAgain() {
        var s = TextStabilizer()
        _ = s.process(result(at: 0.0, [("鍵が必要です", dialogueBox)]))
        let first = stabilized(s.process(result(at: 0.2, [("鍵が必要です", dialogueBox)])))
        _ = s.process(result(at: 0.4, [("扉が開いた", dialogueBox)]))
        let second = stabilized(s.process(result(at: 0.6, [("扉が開いた", dialogueBox)])))
        #expect(second.map(\.text) == ["扉が開いた"])
        #expect(first.first?.trackID == second.first?.trackID)
    }

    @Test func independentBlocksTrackedSeparately() {
        var s = TextStabilizer()
        _ = s.process(result(at: 0.0, [("鍵が必要です", dialogueBox), ("セーブ中", otherBox)]))
        let events = stabilized(s.process(result(at: 0.2, [("鍵が必要です", dialogueBox), ("セーブ中", otherBox)])))
        #expect(Set(events.map(\.text)) == ["鍵が必要です", "セーブ中"])
        #expect(s.tracks.count == 2)
    }

    @Test func removedAfterDisappearing() {
        var s = TextStabilizer()
        _ = s.process(result(at: 0.0, [("鍵が必要です", dialogueBox)]))
        _ = s.process(result(at: 0.2, [("鍵が必要です", dialogueBox)]))
        #expect(s.process(result(at: 0.6, [])).isEmpty)
        let events = s.process(result(at: 1.0, []))
        #expect(events.count == 1)
        if case .removed = events.first {} else { Issue.record("expected removal") }
        #expect(s.tracks.isEmpty)
    }

    @Test func lowConfidenceAndDecorationsIgnored() {
        var s = TextStabilizer()
        _ = s.process(result(at: 0.0, [("鍵", dialogueBox)], confidence: 0.1))
        #expect(s.tracks.isEmpty)
        _ = s.process(result(at: 0.2, [("▼", dialogueBox)]))
        #expect(s.tracks.isEmpty)
    }

    @Test func multiLineDialogueBecomesOneStableText() {
        var s = TextStabilizer()
        let l1 = NormalizedRect(x: 0.12, y: 0.731, width: 0.4, height: 0.059)
        let l2 = NormalizedRect(x: 0.12, y: 0.824, width: 0.2, height: 0.059)
        _ = s.process(result(at: 0.0, [("この先には強い敵がいる。", l1), ("鍵が必要です", l2)]))
        let events = stabilized(s.process(result(at: 0.2, [("この先には強い敵がいる。", l1), ("鍵が必要です", l2)])))
        #expect(events.map(\.text) == ["この先には強い敵がいる。鍵が必要です"])
    }
}
