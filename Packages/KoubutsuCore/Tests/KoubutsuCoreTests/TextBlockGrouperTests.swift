import Foundation
import Testing
@testable import KoubutsuCore

func line(_ text: String, x: Double, y: Double, w: Double = 0.4, h: Double = 0.06, confidence: Float = 0.9,
          frame: FrameTiming = FakeFrame(sequence: 0, host: 0).timing) -> RecognizedTextObservation {
    RecognizedTextObservation(text: text, confidence: confidence,
                              boundingBox: NormalizedRect(x: x, y: y, width: w, height: h), frame: frame)
}

struct TextBlockGrouperTests {
    let grouper = TextBlockGrouper()

    @Test func dialogueLinesMerge() {
        // Synthetic clip geometry: 64px lines 100px apart at 1080p.
        let blocks = grouper.group([
            line("鍵が必要です", x: 0.12, y: 0.824, w: 0.2, h: 0.059),
            line("この先には強い敵がいる。", x: 0.12, y: 0.731, w: 0.4, h: 0.059),
        ])
        #expect(blocks.count == 1)
        #expect(blocks[0].text == "この先には強い敵がいる。鍵が必要です")
        #expect(blocks[0].lines.count == 2)
    }

    @Test func menuItemsStaySeparate() {
        // 56px items 120px apart: gap ≈ 1.14 × height.
        let items = ["アイテム", "そうび", "ステータス", "セーブ"].enumerated().map { i, t in
            line(t, x: 0.135, y: 0.305 + Double(i) * 0.111, w: 0.12, h: 0.052)
        }
        #expect(grouper.group(items).count == 4)
    }

    @Test func distantAndMisalignedTextSeparate() {
        let blocks = grouper.group([
            line("冒険を始めますか？", x: 0.275, y: 0.29, w: 0.45, h: 0.08),
            line("セーブしています…", x: 0.8, y: 0.05, w: 0.15, h: 0.03),
            line("右側", x: 0.8, y: 0.38, w: 0.1, h: 0.08),
        ])
        #expect(blocks.count == 3)
        #expect(blocks[0].text == "セーブしています...")
    }

    @Test func fragmentsOfOneLineAreJoined() {
        // CI run 15: small top-right status text split by Vision into four pieces.
        let blocks = grouper.group([
            line("います…", x: 0.905, y: 0.055, w: 0.045, h: 0.025),
            line("セ", x: 0.80, y: 0.056, w: 0.012, h: 0.025),
            line("て", x: 0.89, y: 0.055, w: 0.011, h: 0.025),
            line("ーブし", x: 0.815, y: 0.055, w: 0.07, h: 0.025),
        ])
        #expect(blocks.map(\.text) == ["セーブしています..."])
    }

    @Test func separateColumnsOnOneRowStayApart() {
        // Title menu: 「はい」 and a distant label on the same row are different texts.
        let blocks = grouper.group([
            line("はい", x: 0.47, y: 0.5, w: 0.06, h: 0.04),
            line("HP 100", x: 0.85, y: 0.5, w: 0.1, h: 0.04),
        ])
        #expect(blocks.count == 2)
    }

    @Test func blockGeometryAndConfidence() {
        let block = TextBlock(lines: [
            line("A", x: 0.1, y: 0.1, w: 0.2, h: 0.05, confidence: 0.9),
            line("B", x: 0.12, y: 0.16, w: 0.3, h: 0.05, confidence: 0.4),
        ])
        #expect(block.boundingBox.isApproximatelyEqual(to: NormalizedRect(x: 0.1, y: 0.1, width: 0.32, height: 0.11)))
        #expect(block.confidence == 0.4)
        #expect(block.text == "A B")
    }

    @Test func listItemsStaySeparateAndWrappedTailJoins() {
        let blocks = grouper.group([
            line("1.電源ボタン：画面ロッ", x: 0.049, y: 0.234, w: 0.631, h: 0.058),
            line("ク", x: 0.068, y: 0.287, w: 0.022, h: 0.041),
            line("2.ボリュームノブ：音量調整", x: 0.045, y: 0.325, w: 0.307, h: 0.053),
            line("7.ディスプレイ", x: 0.035, y: 0.564, w: 0.163, h: 0.053),
            line("8.3.5mmシングルエンド", x: 0.032, y: 0.612, w: 0.509, h: 0.056),
        ])
        #expect(blocks.map(\.text) == ["1.電源ボタン:画面ロック", "2.ボリュームノブ:音量調整", "7.ディスプレイ",
                                        "8.3.5mmシングルエンド"])
    }

    @Test func decimalLineContinuesProse() {
        let blocks = grouper.group([
            line("この装置の重さは", x: 0.1, y: 0.5),
            line("1.5キロです", x: 0.1, y: 0.56),
        ])
        #expect(blocks.count == 1)
    }

    @Test func fragmentsOfDifferentHeightAreNotJoined() {
        let blocks = grouper.group([
            line("231570820447", x: 0.0, y: 0.331, w: 0.166, h: 0.114),
            line("3.再生／一時停止ボタン", x: 0.23, y: 0.370, w: 0.579, h: 0.063),
        ])
        #expect(blocks.count == 2)
    }
}
