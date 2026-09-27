import Foundation
import KoubutsuCore
import Observation

/// State behind the compact portrait info deck (10.7.0): the reading session (started at launch) and the dictionary
/// words of the Japanese on screen. Owned by `RootView`, so the session survives the deck leaving the hierarchy
/// (study mode, full screen, rotation).
///
/// Engineering rule 1: fed only when the on-screen Japanese text changes (not per frame or per OCR result);
/// segmentation runs on a detached task and never blocks the main actor.
@MainActor
@Observable
final class PortraitDeckModel {
    /// Session statistics are counted from here (app launch).
    let stats = ReadingSessionStats(started: Date())
    /// Words of the latest Japanese on screen, in reading order.
    private(set) var words: [DeckWord] = []
    /// The text blocks `words` came from (`DeckWord.sourceIndex` indexes this).
    private(set) var sources: [String] = []
    /// No Japanese is on screen now: `words` are from the last text that was.
    private(set) var wordsAreStale = false
    /// Distinct words listed this session.
    private(set) var wordsSeen = 0

    @ObservationIgnored private var seenIDs = Set<String>()
    @ObservationIgnored private var currentTexts: [String]?
    @ObservationIgnored private var segmentedWithLookup = false
    @ObservationIgnored private var task: Task<Void, Never>?

    /// Debounce: dialogue that types out character by character settles before it is segmented.
    private static let debounce = Duration.milliseconds(250)
    private static let wordLimit = 60

    /// The on-screen text blocks changed (or the dictionary became ready). Re-segments after a short debounce,
    /// cancelling a pending run. With no Japanese on screen the last words stay, marked stale.
    func update(texts: [String], lookup: DictionaryLookup?) {
        let japanese = texts.filter(TextNormalizer.containsJapaneseText)
        let lookupArrived = lookup != nil && !segmentedWithLookup
        guard japanese != currentTexts || lookupArrived else { return }
        currentTexts = japanese
        task?.cancel()
        guard !japanese.isEmpty else {
            wordsAreStale = !words.isEmpty
            return
        }
        guard let lookup else { return }
        segmentedWithLookup = true
        let limit = Self.wordLimit
        task = Task { [weak self] in
            try? await Task.sleep(for: Self.debounce)
            guard !Task.isCancelled else { return }
            let found = await Task.detached(priority: .utility) {
                DeckWords.words(texts: japanese, lookup: lookup, limit: limit)
            }.value
            guard !Task.isCancelled, let self else { return }
            self.words = found
            self.sources = japanese
            self.wordsAreStale = false
            var added = 0
            for word in found where self.seenIDs.insert(word.id).inserted { added += 1 }
            if added > 0 { self.wordsSeen += added }
        }
    }

    /// The text block a word came from (its sentence for the word card and the word bank).
    func sentence(for word: DeckWord) -> String? {
        sources.indices.contains(word.sourceIndex) ? sources[word.sourceIndex] : nil
    }
}
