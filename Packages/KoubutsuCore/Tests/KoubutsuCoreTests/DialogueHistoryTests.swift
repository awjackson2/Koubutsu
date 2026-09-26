import Foundation
import Testing
@testable import KoubutsuCore

struct DialogueHistoryTests {
    @Test func recordsInOrderAndMergesRepeats() {
        var history = DialogueHistory(capacity: 3)
        let recorded = ["ここは危険だ。", "ここは危険だ。", "気をつけて。", "先に進もう。", "扉が開いた"]
            .map { history.record(stable($0)) }
        #expect(recorded == [true, false, true, true, true])
        #expect(history.entries.map(\.source) == ["気をつけて。", "先に進もう。", "扉が開いた"])
    }

    @Test func typewriterGrowthReplacesItsOwnEntry() {
        var history = DialogueHistory()
        let track = UUID()
        func revealed(_ text: String) -> StableText {
            var s = stable(text)
            s.trackID = track
            return s
        }
        history.record(stable("前の台詞。"))
        for text in ["ここ", "ここから", "ここから先は危険だ"] { history.record(revealed(text)) }
        #expect(history.entries.map(\.source) == ["前の台詞。", "ここから先は危険だ"])
        history.record(revealed("扉が開いた"))
        #expect(history.entries.map(\.source) == ["前の台詞。", "ここから先は危険だ", "扉が開いた"])
    }

    @Test func translationsAndContext() {
        var history = DialogueHistory()
        let a = stable("敵が近くにいる。"), b = stable("気をつけて。")
        history.record(a)
        history.record(b)
        history.setTranslation("Enemies are near.", provider: "Fake", for: a.id)
        let context = history.context(before: b.id)
        #expect(context == [DialogueContextLine(source: "敵が近くにいる。", translation: "Enemies are near.")])
        #expect(history.context(limit: 1).map(\.source) == ["気をつけて。"])
    }

    @Test func displayLatencyMetric() {
        let metrics = PipelineMetrics(clock: ContinuousHostClock())
        metrics.translationDisplayed(frameHostTime: HostTime(seconds: 1), at: HostTime(seconds: 1.4))
        #expect(abs((metrics.snapshot().captureToDisplayLatency.last ?? 0) - 0.4) < 1e-9)
    }
}
