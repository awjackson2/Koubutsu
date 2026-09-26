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

/// The pre-7.6 stability window: two readings over at least 0.15 s.
private let windowed: StabilizerConfiguration = {
    var c = StabilizerConfiguration()
    c.minimumStableDuration = 0.15
    c.minimumObservations = 2
    return c
}()

struct TextStabilizerTests {
    @Test func defaultEmitsOnFirstReading() {
        var s = TextStabilizer()
        #expect(stabilized(s.process(result(at: 0.0, [("鍵が必要です", dialogueBox)]))).map(\.text) == ["鍵が必要です"])
        #expect(stabilized(s.process(result(at: 0.1, [("鍵が必要です", dialogueBox)]))).isEmpty)
    }

    @Test func defaultFollowsTypewriterRevealOnSameTrack() {
        var s = TextStabilizer()
        let first = stabilized(s.process(result(at: 0.0, [("ここから", dialogueBox)])))
        let events = s.process(result(at: 0.1, [("ここから先は危険だ", dialogueBox)]))
        #expect(events.first == .invalidated(trackID: first[0].trackID))
        let second = stabilized(events)
        #expect(second.map(\.text) == ["ここから先は危険だ"])
        #expect(second.first?.trackID == first.first?.trackID)
        // A one-character misread of the same text is noise, not a change.
        #expect(s.process(result(at: 0.2, [("ここから先わ危険だ", dialogueBox)])).isEmpty)
    }

    @Test func stableTextEmittedOnceAfterWindow() {
        var s = TextStabilizer(configuration: windowed)
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
        var s = TextStabilizer(configuration: windowed)
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
        var s = TextStabilizer(configuration: windowed)
        _ = s.process(result(at: 0.0, [("この先には強い敵がいる", dialogueBox)]))
        #expect(stabilized(s.process(result(at: 0.2, [("この先には強い敵がいる", dialogueBox)]))).count == 1)
        // One misread character.
        #expect(stabilized(s.process(result(at: 0.4, [("この先にわ強い敵がいる", dialogueBox)]))).isEmpty)
        #expect(stabilized(s.process(result(at: 0.6, [("この先には強い敵がいる", dialogueBox)]))).isEmpty)
    }

    @Test func newDialoguePageInSameBoxEmitsAgain() {
        var s = TextStabilizer(configuration: windowed)
        _ = s.process(result(at: 0.0, [("鍵が必要です", dialogueBox)]))
        let first = stabilized(s.process(result(at: 0.2, [("鍵が必要です", dialogueBox)])))
        let change = s.process(result(at: 0.4, [("扉が開いた", dialogueBox)]))
        #expect(change == [.invalidated(trackID: first.first!.trackID)])
        let second = stabilized(s.process(result(at: 0.6, [("扉が開いた", dialogueBox)])))
        #expect(second.map(\.text) == ["扉が開いた"])
        #expect(first.first?.trackID == second.first?.trackID)
    }

    @Test func independentBlocksTrackedSeparately() {
        var s = TextStabilizer(configuration: windowed)
        _ = s.process(result(at: 0.0, [("鍵が必要です", dialogueBox), ("セーブ中", otherBox)]))
        let events = stabilized(s.process(result(at: 0.2, [("鍵が必要です", dialogueBox), ("セーブ中", otherBox)])))
        #expect(Set(events.map(\.text)) == ["鍵が必要です", "セーブ中"])
        #expect(s.tracks.count == 2)
    }

    @Test func removedAfterDisappearing() {
        var s = TextStabilizer(configuration: windowed)
        _ = s.process(result(at: 0.0, [("鍵が必要です", dialogueBox)]))
        _ = s.process(result(at: 0.2, [("鍵が必要です", dialogueBox)]))
        #expect(s.process(result(at: 0.6, [])).isEmpty)
        let events = s.process(result(at: 1.0, []))
        #expect(events.count == 1)
        if case .removed = events.first {} else { Issue.record("expected removal") }
        #expect(s.tracks.isEmpty)
    }

    @Test func lowConfidenceAndDecorationsIgnored() {
        var s = TextStabilizer(configuration: windowed)
        _ = s.process(result(at: 0.0, [("鍵", dialogueBox)], confidence: 0.1))
        #expect(s.tracks.isEmpty)
        _ = s.process(result(at: 0.2, [("▼", dialogueBox)]))
        #expect(s.tracks.isEmpty)
    }

    @Test func multiLineDialogueBecomesOneStableText() {
        var s = TextStabilizer(configuration: windowed)
        let l1 = NormalizedRect(x: 0.12, y: 0.731, width: 0.4, height: 0.059)
        let l2 = NormalizedRect(x: 0.12, y: 0.824, width: 0.2, height: 0.059)
        _ = s.process(result(at: 0.0, [("この先には強い敵がいる。", l1), ("鍵が必要です", l2)]))
        let events = stabilized(s.process(result(at: 0.2, [("この先には強い敵がいる。", l1), ("鍵が必要です", l2)])))
        #expect(events.map(\.text) == ["この先には強い敵がいる。鍵が必要です"])
    }

    @Test func blocksWithoutJapaneseAreIgnored() {
        var s = TextStabilizer()
        _ = s.process(result(at: 0.0, [("231570820447", dialogueBox), ("TALK", otherBox)]))
        #expect(s.tracks.isEmpty)
    }

    @Test func lowConfidenceSingleGlyphIgnored() {
        var s = TextStabilizer()
        _ = s.process(result(at: 0.0, [("ク", dialogueBox)], confidence: 0.3))
        #expect(s.tracks.isEmpty)
        #expect(stabilized(s.process(result(at: 0.1, [("ク", dialogueBox)], confidence: 0.5))).count == 1)
    }

    @Test func shownTextIsReplacedOnlyAfterTwoReadings() {
        var s = TextStabilizer()
        let first = stabilized(s.process(result(at: 0.0, [("鍵が必要です", dialogueBox)])))
        #expect(first.count == 1)
        // One differing reading: nothing replaces the shown text yet.
        #expect(stabilized(s.process(result(at: 0.1, [("扉が開いた", dialogueBox)]))).isEmpty)
        let second = stabilized(s.process(result(at: 0.2, [("扉が開いた", dialogueBox)])))
        #expect(second.map(\.text) == ["扉が開いた"])
        #expect(second.first?.trackID == first.first?.trackID)
    }

    @Test func alternatingMisreadNeverReplacesShownText() {
        var s = TextStabilizer()
        _ = s.process(result(at: 0.0, [("鍵が必要です", dialogueBox)]))
        for i in 1...10 {
            let text = i.isMultiple(of: 2) ? "鍵が必要です" : "扉が開いた"
            #expect(stabilized(s.process(result(at: Double(i) * 0.1, [(text, dialogueBox)]))).isEmpty)
        }
    }

    @Test func newBlockOverShownBlockNeedsTwoReadings() {
        var s = TextStabilizer()
        let wide = NormalizedRect(x: 0.1, y: 0.2, width: 0.6, height: 0.3)
        let part = NormalizedRect(x: 0.1, y: 0.2, width: 0.6, height: 0.06)
        _ = s.process(result(at: 0.0, [("一行目二行目三行目", wide)]))
        // The shown block splits: its first line alone appears over it.
        let events = stabilized(s.process(result(at: 0.1, [("一行目", part), ("一行目二行目三行目", wide)])))
        #expect(events.isEmpty)
        #expect(stabilized(s.process(result(at: 0.2, [("一行目", part), ("一行目二行目三行目", wide)]))).map(\.text)
                == ["一行目"])
    }

    @Test func oneMissedReadingDoesNotRemove() {
        var s = TextStabilizer()
        _ = s.process(result(at: 0.0, [("鍵が必要です", dialogueBox)]))
        // Slow OCR (2 results/s): one miss is past the time window but is not enough on its own.
        #expect(s.process(result(at: 1.0, [])).isEmpty)
        #expect(s.process(result(at: 1.5, [("鍵が必要です", dialogueBox)])).isEmpty)
        _ = s.process(result(at: 2.5, []))
        let events = s.process(result(at: 3.5, []))
        if case .removed = events.first {} else { Issue.record("expected removal after two misses") }
    }
}
