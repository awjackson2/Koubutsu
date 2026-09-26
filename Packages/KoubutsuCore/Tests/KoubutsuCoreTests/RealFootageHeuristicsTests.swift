import Foundation
import Testing
@testable import KoubutsuCore

/// Patterns taken from the Persona 3 Reload footage report (footage workflow run 4).
/// Geometry measured on a 1920×1080 frame of the dialogue box at 0:12 (lines 858/907 px, label ≈0.6× height).
struct RealFootageHeuristicsTests {
    let grouper = TextBlockGrouper()
    // 「伊織順平」 label ≈ 0.6× the dialogue line height, above-left of the text.
    let name = line("伊織順平", x: 0.285, y: 0.698, w: 0.058, h: 0.022)
    let talk = line("TALK", x: 0.300, y: 0.724, w: 0.020, h: 0.009)
    let line1 = line("あっ、オマエ今、", x: 0.320, y: 0.794, w: 0.195, h: 0.037)
    let line2 = line("めんどくせーとか思ったろ!", x: 0.320, y: 0.840, w: 0.26, h: 0.037)

    @Test func speakerLabelIsSeparatedFromDialogue() {
        let blocks = grouper.group([line2, name, line1, talk])
        let dialogue = blocks.first { $0.text.contains("オマエ") }
        #expect(dialogue?.speaker == "伊織順平")
        #expect(dialogue?.text == "あっ、オマエ今、めんどくせーとか思ったろ!")
        #expect(!blocks.contains { $0.text == "伊織順平" })
    }

    @Test func equalHeightFirstLineIsNotASpeaker() {
        let blocks = grouper.group([
            line("ここは", x: 0.32, y: 0.794, w: 0.08, h: 0.037),
            line("危険だ。", x: 0.32, y: 0.840, w: 0.1, h: 0.037),
        ])
        #expect(blocks.count == 1)
        #expect(blocks[0].speaker == nil)
        #expect(blocks[0].text == "ここは危険だ。")
    }

    @Test func speakerCarriedToStableTextAndTranscript() {
        var stabilizer = TextStabilizer()
        var transcript = TranscriptBuilder()
        for t in [0.0, 0.2] {
            let frame = FrameTiming(sequence: 0, presentationTime: MediaTime(seconds: 12 + t),
                                    hostTime: HostTime(seconds: t), sourceSessionID: 1)
            let observations = [name, line1, line2].map {
                RecognizedTextObservation(text: $0.text, confidence: 0.9, boundingBox: $0.boundingBox, frame: frame)
            }
            let result = OCRResult(frame: frame, frameSize: .init(width: 1920, height: 1080),
                                   observations: observations, started: frame.hostTime, finished: frame.hostTime,
                                   configuration: .japanese)
            for case .stabilized(let s) in stabilizer.process(result) { transcript.stabilized(s) }
        }
        let entry = transcript.resolved.first
        #expect(entry?.speaker == "伊織順平")
        #expect(transcript.srt(.japanese).contains("【伊織順平】あっ、オマエ今、"))
    }

    private func stable(_ text: String, box: NormalizedRect, at t: Double) -> StableText {
        let frame = FrameTiming(sequence: 0, presentationTime: MediaTime(seconds: t), hostTime: HostTime(seconds: t),
                                sourceSessionID: 1)
        return StableText(trackID: UUID(), text: text, key: TextNormalizer.key(text), boundingBox: box,
                          confidence: 0.5, lines: [], firstSeenFrame: frame, stabilizedFrame: frame)
    }

    @Test func buttonHintVariantsBecomeHUD() {
        var hud = HUDFilter()
        let hint = NormalizedRect(x: 0.78, y: 0.94, width: 0.2, height: 0.03)
        let wider = NormalizedRect(x: 0.74, y: 0.94, width: 0.24, height: 0.03)
        let seen = ["◎オート日早送り", "キョログ◎オート日早送り", "1オート日早送り", "◎オート冒早送り", "ログ)オート早送り"]
            .enumerated().map { i, text in hud.isHUD(stable(text, box: i % 2 == 0 ? hint : wider, at: Double(i) * 5)) }
        #expect(seen == [false, false, true, true, true])
        #expect(hud.hudPlaceCount == 1)
    }

    @Test func dateVariantsBecomeHUD() {
        var hud = HUDFilter()
        let date = NormalizedRect(x: 0.9, y: 0.02, width: 0.07, height: 0.04)
        let seen = ["4/18土", "4/18キ", "4/18才", "4/18土"].enumerated()
            .map { i, t in hud.isHUD(stable(t, box: date, at: Double(i) * 20)) }
        #expect(seen == [false, false, true, true])
    }

    @Test func clockWordMatchesItsCombinedForm() {
        // Run 5: 「午後」 alone and 「4/18キ午後」 alternate in the date/time HUD.
        var hud = HUDFilter()
        let clock = NormalizedRect(x: 0.88, y: 0.02, width: 0.1, height: 0.05)
        let word = NormalizedRect(x: 0.93, y: 0.03, width: 0.04, height: 0.03)
        let seen = [("4/18キ午後", clock), ("午後", word), ("午後", word), ("4/18土午後", clock)]
            .enumerated().map { i, v in hud.isHUD(stable(v.0, box: v.1, at: Double(i) * 10)) }
        #expect(seen == [false, false, true, true])
    }

    @Test func movingLabelRepeatedEverywhereIsHUD() {
        var hud = HUDFilter()
        let places = [NormalizedRect(x: 0.30, y: 0.72, width: 0.02, height: 0.01),
                      NormalizedRect(x: 0.55, y: 0.60, width: 0.02, height: 0.01),
                      NormalizedRect(x: 0.20, y: 0.75, width: 0.02, height: 0.01)]
        let seen = places.enumerated().map { i, box in hud.isHUD(stable("TALK", box: box, at: Double(i) * 30)) }
        #expect(seen == [false, false, true])
    }

    @Test func latinTagIsNotASpeaker() {
        let tag = line("TALK", x: 0.285, y: 0.698, w: 0.03, h: 0.022)
        let blocks = grouper.group([tag, line1, line2])
        #expect(blocks.allSatisfy { $0.speaker == nil })
    }

    @Test func changingDialogueInTheSameBoxIsNeverSuppressed() {
        var hud = HUDFilter()
        let box = NormalizedRect(x: 0.32, y: 0.79, width: 0.4, height: 0.13)
        let lines = ["おーす、久々じゃん。", "つか、ちょっと聞いてくれよー!", "どうした?朝から元気だな",
                     "あっ、オマエ今、めんどくせーとか思ったろ!", "ごめんな、オレばっかり....",
                     "まあ、オマエも元気だせよ。"]
        let suppressed = lines.enumerated().map { i, t in hud.isHUD(stable(t, box: box, at: Double(i) * 4)) }
        #expect(!suppressed.contains(true))
    }
}
