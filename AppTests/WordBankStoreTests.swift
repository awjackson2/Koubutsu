import Foundation
import KoubutsuCore
import Testing
@testable import Koubutsu

@MainActor
struct WordBankStoreTests {
    @Test func savesPersistsReviewsAndDeletes() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let entry = DictionaryEntry(id: 1358280, isCommon: true, rank: 25, kanji: [.init(text: "食べる", isCommon: true)],
                                    readings: [.init(text: "たべる", isCommon: true)],
                                    senses: [.init(partsOfSpeech: ["v1"], glosses: ["to eat"])])
        let result = LookupResult(entry: entry, matched: "食べた", dictionaryForm: "食べる", reasons: ["past"])
        let store = WordBankStore(directory: directory)
        store.save(result, sentence: "パンを食べた", translation: "I ate bread", source: "Test", mediaTime: 3, image: nil)
        #expect(store.isSaved(result))
        let reloaded = WordBankStore(directory: directory)
        let word = try #require(reloaded.bank.words.first)
        #expect(word.headword == "食べる" && word.reading == "たべる" && word.meanings == ["to eat"])
        #expect(word.sentence == "パンを食べた" && word.source == "Test")
        reloaded.record(.good, for: word)
        #expect(WordBankStore(directory: directory).bank.words.first?.card.reviews == 1)
        reloaded.delete(word)
        #expect(WordBankStore(directory: directory).bank.words.isEmpty)
    }
}
