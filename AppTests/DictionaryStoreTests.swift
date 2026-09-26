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
}
