import Foundation
import Testing
@testable import KoubutsuCore

/// Rows copied from the generated database (Tools/build_dictionary.py, schema 1).
struct DictionaryModelTests {
    static let taberu = #"{"k":[{"t":"食べる","c":1},{"t":"喰べる","i":["sK"]}],"r":[{"t":"たべる","c":1}],"s":[{"p":["v1","vt"],"g":["to eat"]},{"p":["v1","vt"],"g":["to live on (e.g. a salary)"]}]}"#
    static let botan = #"{"k":[{"t":"釦","i":["ateji","rK"]},{"t":"鈕","i":["ateji","rK"]}],"r":[{"t":"ボタン","c":1}],"s":[{"p":["n"],"g":["button (clothing)"],"m":["uk"]}]}"#
    static let kagi = #"{"k":[{"t":"鍵","c":1},{"t":"鑰","i":["rK"]}],"r":[{"t":"かぎ","c":1},{"t":"カギ","nk":1}],"s":[{"p":["n"],"g":["key"]},{"p":["n"],"g":["lock"]}]}"#
    static let tekiKanji = #"{"m":["enemy","foe","opponent"],"on":["テキ"],"kun":["かたき","あだ","かな.う"],"s":15,"g":6,"f":1205,"j":1}"#

    @Test func decodesEntryRow() throws {
        let entry = try DictionaryEntry(id: 1358280, isCommon: true, rank: 25, json: Data(Self.taberu.utf8))
        #expect(entry.kanji.map(\.text) == ["食べる", "喰べる"])
        #expect(entry.kanji[0].isCommon && entry.kanji[1].isHidden)
        #expect(entry.readings.first?.text == "たべる")
        #expect(entry.senses.first?.glosses == ["to eat"])
        #expect(entry.allPartsOfSpeech == ["v1", "vt"])
    }

    @Test func readingRestrictionsAndUsuallyKana() throws {
        let kagi = try DictionaryEntry(id: 1260490, isCommon: true, rank: 18, json: Data(Self.kagi.utf8))
        #expect(kagi.readings(for: "鍵").map(\.text) == ["かぎ"])
        let botan = try DictionaryEntry(id: 1123880, isCommon: true, rank: 50, json: Data(Self.botan.utf8))
        #expect(botan.senses[0].usuallyKana)
    }

    @Test func decodesKanjiRow() throws {
        let kanji = try KanjiInfo(literal: "敵", json: Data(Self.tekiKanji.utf8))
        #expect(kanji.literal == "敵" && kanji.strokes == 15 && kanji.onReadings == ["テキ"])
        #expect(kanji.meanings.first == "enemy")
    }

    @Test func kanaFolding() {
        #expect(Kana.foldToHiragana("ボタンを押す") == "ぼたんを押す")
        #expect(Kana.toKatakana("かぎ") == "カギ")
        #expect(Kana.foldToHiragana("ー") == "ー")
        #expect(Kana.isKanji("々") && Kana.isKana("ー") && !Kana.isKanji("あ"))
    }

    @Test func inMemoryStoreFindsByFoldedKey() throws {
        let botan = try DictionaryEntry(id: 1123880, isCommon: true, rank: 50, json: Data(Self.botan.utf8))
        let kagi = try DictionaryEntry(id: 1260490, isCommon: true, rank: 18, json: Data(Self.kagi.utf8))
        let store = InMemoryDictionaryStore(entries: [botan, kagi])
        #expect(store.entries(forKey: "ぼたん").map(\.id) == [1123880])
        #expect(store.entries(forKey: "鍵").map(\.id) == [1260490])
        #expect(store.entries(forKey: "かぎ").map(\.id) == [1260490])
    }
}
