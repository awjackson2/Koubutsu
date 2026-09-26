import Foundation
import KoubutsuCore
import Testing
@testable import Koubutsu

/// The bundled JMdict/KANJIDIC2 database: unpacks, opens and answers lookups.
@Suite(.serialized, .timeLimit(.minutes(5)))
struct DictionaryStoreTests {
    @Test func bundledDictionaryAnswersLookups() throws {
        let store = try SQLiteDictionaryStore.open()
        let taberu = store.entries(forKey: "食べる")
        #expect(taberu.first?.readings.first?.text == "たべる")
        #expect(taberu.first?.senses.first?.glosses.contains("to eat") == true)
        // Katakana words are keyed in hiragana.
        #expect(store.entries(forKey: Kana.foldToHiragana("ボタン")).contains { $0.readings.contains { $0.text == "ボタン" } })
        #expect(store.entries(forKey: "かぎ").first?.kanji.first?.text == "鍵")
        let teki = try #require(store.kanji("敵"))
        #expect(teki.strokes == 15 && teki.meanings.contains("enemy"))
        #expect(store.entries(forKey: "zzzz").isEmpty)
    }

    @Test func lookupOnTheBundledDictionary() throws {
        let lookup = DictionaryLookup(store: try SQLiteDictionaryStore.open())
        let eaten = try #require(lookup.word(at: "食べさせられた。").first)
        #expect(eaten.dictionaryForm == "食べる" && eaten.matched == "食べさせられた")
        #expect(lookup.word(at: "行ったことがある").first?.dictionaryForm == "行く")
        let words = lookup.segment("この先には強い敵がいる。").map(\.text)
        #expect(words.contains("敵") && words.contains("強い") && words.contains("が"))
    }
}
