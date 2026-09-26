import Testing
@testable import KoubutsuCore

struct FuriganaTests {
    func pairs(_ w: String, _ r: String) -> [String] {
        Furigana.align(written: w, reading: r).map { $0.reading.map { "\($0)" } ?? "-" }
    }

    @Test func alignsKanjiRuns() {
        #expect(Furigana.align(written: "食べる", reading: "たべる")
                == [.init(text: "食", reading: "た"), .init(text: "べる", reading: nil)])
        #expect(Furigana.align(written: "取り扱い", reading: "とりあつかい")
                == [.init(text: "取", reading: "と"), .init(text: "り", reading: nil),
                    .init(text: "扱", reading: "あつか"), .init(text: "い", reading: nil)])
        #expect(Furigana.align(written: "お前", reading: "おまえ")
                == [.init(text: "お", reading: nil), .init(text: "前", reading: "まえ")])
        #expect(Furigana.align(written: "今日", reading: "きょう") == [.init(text: "今日", reading: "きょう")])
        #expect(Furigana.align(written: "ボタン", reading: "ボタン") == [.init(text: "ボタン", reading: nil)])
    }

    @Test func mismatchFallsBackToWholeWord() {
        #expect(Furigana.align(written: "食べる", reading: "くう") == [.init(text: "食べる", reading: "くう")])
    }

    @Test(arguments: [
        ("たべました", "tabemashita"), ("きょう", "kyou"), ("がっこう", "gakkou"), ("まっちゃ", "matcha"),
        ("しんぶん", "shinbun"), ("こんや", "kon'ya"), ("ほんを", "hon'o"), ("セーブ", "seebu"), ("ちょっと", "chotto"),
        ("じてんしゃ", "jitensha"), ("ふぁいと", "faito"),
    ])
    func romaji(_ kana: String, _ expected: String) {
        #expect(Romaji.hepburn(kana) == expected)
    }

    @Test func labels() {
        #expect(DictionaryLabels.partOfSpeech("v5k") == "godan verb (く)")
        #expect(DictionaryLabels.label("uk") == "usually kana")
        #expect(DictionaryLabels.partOfSpeech("zzz") == "zzz")
    }
}
