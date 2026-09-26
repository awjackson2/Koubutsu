import Testing
@testable import KoubutsuCore

func entry(_ id: Int, _ kanji: [String], _ readings: [String], _ pos: [String], _ glosses: [String],
           common: Bool = true, rank: Int = 20, usuallyKana: Bool = false) -> DictionaryEntry {
    DictionaryEntry(id: id, isCommon: common, rank: rank,
                    kanji: kanji.map { .init(text: $0, isCommon: common) },
                    readings: readings.map { .init(text: $0, isCommon: common) },
                    senses: [.init(partsOfSpeech: pos, glosses: glosses, misc: usuallyKana ? ["uk"] : [])])
}

let fixtureStore = InMemoryDictionaryStore(entries: [
    entry(1, ["鍵"], ["かぎ"], ["n"], ["key"]),
    entry(2, ["必要"], ["ひつよう"], ["adj-na", "n"], ["necessary", "needed"]),
    entry(3, ["必"], ["ひつ"], ["n"], ["certainly"], common: false, rank: 99),
    entry(4, [], ["です"], ["cop"], ["be; is"]),
    entry(5, [], ["が"], ["prt"], ["subject marker"]),
    entry(6, ["食べる"], ["たべる"], ["v1", "vt"], ["to eat"]),
    entry(7, ["日本"], ["にほん", "にっぽん"], ["n"], ["Japan"]),
    entry(8, ["日本語"], ["にほんご"], ["n"], ["Japanese (language)"]),
    entry(9, ["此の"], ["この"], ["adj-pn"], ["this"], usuallyKana: true),
    entry(10, ["先"], ["さき"], ["n"], ["ahead", "previous"]),
    entry(11, [], ["に"], ["prt"], ["at", "in"]),
    entry(12, [], ["は"], ["prt"], ["topic marker"]),
    entry(13, ["強い"], ["つよい"], ["adj-i"], ["strong", "powerful"]),
    entry(14, ["敵"], ["てき"], ["n"], ["enemy"]),
    entry(15, ["居る"], ["いる"], ["v1", "vi"], ["to be (animate)", "to exist"], usuallyKana: true),
    entry(16, ["釦"], ["ボタン"], ["n"], ["button"], usuallyKana: true),
    entry(17, ["行く"], ["いく", "ゆく"], ["v5k-s", "vi"], ["to go"]),
    entry(18, ["勉強"], ["べんきょう"], ["n", "vs"], ["study"]),
    entry(19, ["高い"], ["たかい"], ["adj-i"], ["high", "expensive"]),
    entry(20, ["高"], ["たか"], ["n"], ["quantity"], common: false, rank: 99),
    entry(21, ["害"], ["がい"], ["n"], ["harm"], rank: 10),
    entry(22, [], ["る"], ["suf"], ["verb-forming suffix"]),
    entry(23, [], ["ガイル"], ["n"], ["Guile"]),
])

struct DictionaryLookupTests {
    let lookup = DictionaryLookup(store: fixtureStore)

    @Test func longestMatchFromStart() {
        #expect(lookup.lookup("鍵が必要です").first?.entry.id == 1)
        #expect(lookup.lookup("必要です").first?.entry.id == 2)
        #expect(lookup.lookup("日本語を話す").first?.entry.id == 8)
    }

    @Test func conjugatedVerbReducedToDictionaryForm() throws {
        let best = try #require(lookup.lookup("食べさせられた。").first)
        #expect(best.entry.id == 6)
        #expect(best.matched == "食べさせられた")
        #expect(best.dictionaryForm == "食べる")
        #expect(best.reasons == ["causative", "passive or potential", "past"])
        #expect(best.headword == "食べる" && best.reading == "たべる")
    }

    @Test func adjectiveAndSuruNoun() {
        let takakatta = lookup.lookup("高かったです").first
        #expect(takakatta?.entry.id == 19 && takakatta?.reasons == ["past"])
        let benkyou = lookup.lookup("勉強しました").first
        #expect(benkyou?.entry.id == 18 && benkyou?.matched == "勉強しました")
        #expect(lookup.lookup("行った").first?.entry.id == 17)
    }

    @Test func kanaWordsUseTheirKanaHeadword() {
        let button = lookup.lookup("ボタンを押す").first
        #expect(button?.entry.id == 16)
        #expect(button?.headword == "ボタン" && button?.reading == "ボタン")
        let iru = lookup.lookup("いる").first
        #expect(iru?.entry.id == 15 && iru?.headword == "いる")
    }

    @Test func segmentsAPhrase() {
        let tokens = lookup.segment("この先には強い敵がいる。")
        #expect(tokens.map(\.text) == ["この", "先", "に", "は", "強い", "敵", "が", "いる", "。"])
        #expect(tokens.last?.results.isEmpty == true)
        #expect(tokens[4].offset == 5)
    }

    @Test func particlesStayApartFromTheNextWord() {
        #expect(lookup.segment("敵がいる").map(\.text) == ["敵", "が", "いる"])
        #expect(lookup.word(at: "がいる").first?.entry.id == 5)
        // Hiragana never matches a katakana-only word.
        #expect(!lookup.lookup("がいる").contains { $0.entry.id == 23 })
    }

    @Test func nothingForUnknownText() {
        #expect(lookup.lookup("ABC").isEmpty)
        #expect(lookup.lookup("").isEmpty)
    }
}
