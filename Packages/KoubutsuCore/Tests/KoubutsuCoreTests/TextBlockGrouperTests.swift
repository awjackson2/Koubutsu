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

    @Test func sideBySideLinesDoNotMerge() {
        let blocks = grouper.group([
            line("左", x: 0.1, y: 0.5, w: 0.1, h: 0.06),
            line("右", x: 0.15, y: 0.505, w: 0.1, h: 0.06),
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
}
