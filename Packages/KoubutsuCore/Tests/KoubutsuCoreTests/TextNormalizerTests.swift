import Testing
@testable import KoubutsuCore

struct TextNormalizerTests {
    @Test func foldsWidthAndWhitespace() {
        #expect(TextNormalizer.display("ｾｰﾌﾞ  しています") == "セーブしています")
        #expect(TextNormalizer.display("ＨＰ　１００") == "HP 100")
        #expect(TextNormalizer.display("鍵が\n必要です") == "鍵が必要です")
        #expect(TextNormalizer.display("Press  A") == "Press A")
    }

    @Test func keyDropsDecorations() {
        #expect(TextNormalizer.key("▶ はい") == "はい")
        #expect(TextNormalizer.key("鍵が必要です ▼") == "鍵が必要です")
        #expect(TextNormalizer.key("セーブしています…") == TextNormalizer.key("セーブしています..."))
        #expect(TextNormalizer.key("ています・・") == "ています...")
        #expect(TextNormalizer.key("ています・・・") == "ています...")
        #expect(TextNormalizer.key("ハート・マーク") == "ハート・マーク")
    }

    @Test func editDistanceAndSimilarity() {
        #expect(TextNormalizer.editDistance("鍵が必要です", "鍵が必要です") == 0)
        #expect(TextNormalizer.editDistance("鍵が必要です", "鍵か必要です") == 1)
        #expect(TextNormalizer.editDistance("", "abc") == 3)
        #expect(TextNormalizer.similarity("この先には強い敵がいる。", "この先には強い敵がいる") > 0.9)
        #expect(TextNormalizer.similarity("はい", "いいえ") < 0.5)
    }

    @Test func typewriterGrowth() {
        #expect(TextNormalizer.isGrowth(from: "ここ", to: "ここから"))
        #expect(TextNormalizer.isGrowth(from: "ここから先", to: "ここから先は"))
        #expect(!TextNormalizer.isGrowth(from: "ここから", to: "ここから"))
        #expect(!TextNormalizer.isGrowth(from: "はい", to: "いいえです"))
        // One OCR error in the shared head is tolerated for longer strings.
        #expect(TextNormalizer.isGrowth(from: "この先には強い", to: "この先にわ強い敵が"))
    }

    @Test func characterAccuracy() {
        #expect(TextNormalizer.characterAccuracy(expected: "鍵が必要です", recognized: "鍵が必要です") == 1)
        #expect(abs(TextNormalizer.characterAccuracy(expected: "鍵が必要です", recognized: "鍵か必要です") - 5.0 / 6.0) < 1e-9)
        #expect(TextNormalizer.characterAccuracy(expected: "abc", recognized: "") == 0)
    }
}
