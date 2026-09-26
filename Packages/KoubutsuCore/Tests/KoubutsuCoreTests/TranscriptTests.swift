import Foundation
import Testing
@testable import KoubutsuCore

private func stableAt(_ text: String, media: Double, track: UUID = UUID()) -> StableText {
    let frame = FrameTiming(sequence: 0, presentationTime: MediaTime(seconds: media),
                            hostTime: HostTime(seconds: media), sourceSessionID: 1)
    return StableText(trackID: track, text: text, key: TextNormalizer.key(text), boundingBox: .full,
                      confidence: 0.9, lines: [], firstSeenFrame: frame, stabilizedFrame: frame)
}

struct TranscriptTests {
    @Test func entriesTranslationsAndEnds() {
        var t = TranscriptBuilder()
        let box = UUID()
        let a = stableAt("ここは危険だ。", media: 12.0, track: box)
        t.stabilized(a)
        t.translated(id: a.id, english: "It's dangerous here.")
        let b = stableAt("気をつけて。", media: 15.5, track: box)   // next page in the same box closes a
        t.stabilized(b)
        t.ended(trackID: box, at: 18.0)
        let r = t.resolved
        #expect(r.map(\.japanese) == ["ここは危険だ。", "気をつけて。"])
        #expect(r[0].end == 15.5 && r[1].end == 18.0)
        #expect(r[0].english == "It's dangerous here.")
    }

    @Test func srtAndCSV() {
        var t = TranscriptBuilder()
        let a = stableAt("鍵が必要です", media: 61.2)
        t.stabilized(a)
        t.translated(id: a.id, english: "You need a key.")
        t.stabilized(stableAt("扉が開いた", media: 70))
        #expect(t.srt(.bilingual) == """
            1
            00:01:01,200 --> 00:01:04,200
            鍵が必要です
            You need a key.

            2
            00:01:10,000 --> 00:01:13,000
            扉が開いた

            """)
        #expect(t.srt(.english).hasPrefix("1\n00:01:01,200 --> 00:01:04,200\nYou need a key.\n"))
        #expect(!t.srt(.english).contains("扉"))
        #expect(t.csv().split(separator: "\n")[1] == "61.200,64.200,\"\",\"鍵が必要です\",\"You need a key.\",0.90")
    }

    @Test func seekBackwardsKeepsMediaOrder() {
        var t = TranscriptBuilder()
        t.stabilized(stableAt("後", media: 300))
        t.discontinuity()
        t.stabilized(stableAt("前", media: 30))
        #expect(t.resolved.map(\.japanese) == ["前", "後"])
        #expect(t.resolved.last?.end == 303)
    }
}
