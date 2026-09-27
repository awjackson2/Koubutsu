/// A dictionary word currently on screen, as the portrait info deck lists it (10.7.0).
public struct DeckWord: Sendable, Hashable, Identifiable {
    /// Entry and headword: the same key the word bank uses.
    public var id: String { "\(entryID)|\(headword)" }
    public var entryID: Int { results.first?.entry.id ?? 0 }
    /// The text as it appears on screen (possibly conjugated).
    public var surface: String
    public var headword: String
    public var reading: String
    /// First gloss of the best match's first sense.
    public var gloss: String
    /// Matches for the token, best first (what the word card shows).
    public var results: [LookupResult]
    /// Index of the on-screen text block the word came from.
    public var sourceIndex: Int

    /// Nil when there are no matches.
    public init?(surface: String, results: [LookupResult], sourceIndex: Int) {
        guard let best = results.first else { return nil }
        self.surface = surface
        headword = best.headword
        reading = best.reading
        gloss = best.entry.senses.first?.glosses.first ?? ""
        self.results = results
        self.sourceIndex = sourceIndex
    }
}

/// Where a deck word stands in the learner's word bank.
public enum DeckWordState: String, Sendable, Hashable, CaseIterable {
    case known, learning, new

    public var label: String { rawValue.uppercased() }
}

/// Turns segmented on-screen Japanese into the deck's word list: content words only, each once, in reading order.
public enum DeckWords {
    /// Parts of speech that are grammar rather than vocabulary: particles, copula, auxiliaries, affixes.
    static let functionPartsOfSpeech: Set<String> = [
        "prt", "cop", "cop-da", "aux", "aux-v", "aux-adj", "suf", "pref", "ctr",
    ]

    /// Whether a token is worth listing: it has a dictionary match with a gloss, it is not a lone kana (particles,
    /// okurigana split off by the segmenter), and its best match is not purely a function word.
    public static func isUseful(_ token: LookupToken) -> Bool {
        guard let best = token.results.first,
              best.entry.senses.contains(where: { !$0.glosses.isEmpty }) else { return false }
        let characters = Array(token.text)
        if characters.count == 1, !Kana.isKanji(characters[0]) { return false }
        guard characters.contains(where: { Kana.isKanji($0) || Kana.isKana($0) }) else { return false }
        let partsOfSpeech = best.entry.allPartsOfSpeech
        return partsOfSpeech.isEmpty || !partsOfSpeech.isSubset(of: functionPartsOfSpeech)
    }

    /// The useful words of one segmented text block, in order.
    public static func words(from tokens: [LookupToken], sourceIndex: Int) -> [DeckWord] {
        tokens.filter(isUseful).compactMap { DeckWord(surface: $0.text, results: $0.results, sourceIndex: sourceIndex) }
    }

    /// Segments each text block (line by line) and returns its useful words, de-duplicated by entry and headword
    /// (first occurrence kept), at most `limit`. Runs the dictionary: call it off the main actor.
    public static func words(texts: [String], lookup: DictionaryLookup, limit: Int = 60) -> [DeckWord] {
        var seen = Set<String>()
        var result: [DeckWord] = []
        for (index, text) in texts.enumerated() {
            for line in text.split(whereSeparator: \.isNewline) {
                for word in words(from: lookup.segment(String(line)), sourceIndex: index)
                where seen.insert(word.id).inserted {
                    result.append(word)
                    if result.count >= limit { return result }
                }
            }
        }
        return result
    }

    /// The word's state in `bank`: known (saved and marked known), learning (saved), or new.
    public static func state(of word: DeckWord, in bank: WordBank) -> DeckWordState {
        guard let saved = bank.word(entryID: word.entryID, headword: word.headword) else { return .new }
        return saved.isKnown ? .known : .learning
    }
}
