import Testing
@testable import KoubutsuCore

struct ReadingAidTests {
    let lookup = DictionaryLookup(store: fixtureStore)

    @Test func conjugatedWordKeepsOkurigana() throws {
        let result = try #require(lookup.lookup("食べさせられた").first)
        let runs = ReadingAid.surfaceFurigana(surface: "食べさせられた", result: result)
        #expect(runs.map(\.range) == [0..<1] && runs.map(\.reading) == ["た"])
        let tsuyoku = try #require(lookup.lookup("強くない").first)
        #expect(ReadingAid.surfaceFurigana(surface: "強くない", result: tsuyoku).map(\.reading) == ["つよ"])
    }

    @Test func kanaWordsGetNothing() throws {
        let iru = try #require(lookup.lookup("いる").first)
        #expect(ReadingAid.surfaceFurigana(surface: "いる", result: iru).isEmpty)
    }

    @Test func lineAnnotationsSkipKnownAndMarkLearning() {
        let tokens = lookup.segment("この先には強い敵がいる。")
        let plain = ReadingAid.annotations(tokens: tokens, known: [], learning: [])
        #expect(plain.map(\.reading) == ["さき", "つよ", "てき"])
        #expect(plain.first?.range == 2..<3)
        let studied = ReadingAid.annotations(tokens: tokens, known: ["強い"], learning: ["敵"])
        #expect(studied.compactMap(\.reading) == ["さき", "てき"])
        #expect(studied.contains { $0.reading == nil && $0.isLearning && $0.range == 7..<8 })
    }

    @Test func kanjiRuns() {
        #expect(ReadingAid.kanjiRuns(in: "取り扱い説明書") == [0..<1, 2..<3, 4..<7])
    }
}
