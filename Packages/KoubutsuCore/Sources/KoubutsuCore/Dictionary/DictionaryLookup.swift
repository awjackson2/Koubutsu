/// A dictionary entry matched at the start of some text.
public struct LookupResult: Sendable, Hashable, Identifiable {
    public var id: Int { entry.id }
    public var entry: DictionaryEntry
    /// The text as it appears on screen (e.g. 食べさせられた).
    public var matched: String
    /// The dictionary form it was reduced to (e.g. 食べる).
    public var dictionaryForm: String
    /// Conjugation steps from the dictionary form, innermost first (e.g. causative, passive or potential, past).
    public var reasons: [String]
    /// See `Deinflection.specificity`.
    public var specificity: Int

    public init(entry: DictionaryEntry, matched: String, dictionaryForm: String, reasons: [String],
                specificity: Int = 0) {
        self.entry = entry
        self.matched = matched
        self.dictionaryForm = dictionaryForm
        self.reasons = reasons
        self.specificity = specificity
    }

    /// The kanji form matching the text, or the entry's first visible kanji form, or nil for kana words.
    public var headword: String {
        if entry.kanji.contains(where: { $0.text == dictionaryForm }) { return dictionaryForm }
        if let reading = entry.readings.first(where: { Kana.foldToHiragana($0.text) == Kana.foldToHiragana(dictionaryForm) }),
           entry.senses.first?.usuallyKana == true || entry.kanji.isEmpty || reading.noKanji {
            return reading.text
        }
        return entry.kanji.first(where: { !$0.isHidden })?.text ?? entry.readings.first?.text ?? dictionaryForm
    }

    /// The reading for `headword`.
    public var reading: String {
        let head = headword
        if entry.readings.contains(where: { $0.text == head }) { return head }
        if let match = entry.readings.first(where: { Kana.foldToHiragana($0.text) == Kana.foldToHiragana(dictionaryForm) }) {
            return match.text
        }
        return entry.readings(for: head).first?.text ?? entry.readings.first?.text ?? ""
    }
}

/// A piece of a phrase: a dictionary word, or unknown text.
public struct LookupToken: Sendable, Hashable {
    public var text: String
    /// Character offset in the phrase.
    public var offset: Int
    /// Matches for this token, best first; empty for text not in the dictionary.
    public var results: [LookupResult]

    public init(text: String, offset: Int, results: [LookupResult]) {
        self.text = text
        self.offset = offset
        self.results = results
    }
}

/// Finds the dictionary word at the start of a text (longest match, with de-inflection), and splits phrases.
public struct DictionaryLookup: Sendable {
    public let store: any DictionaryStore
    public let deinflector: Deinflector
    /// Longest prefix tried, in characters.
    public var maximumLength = 16

    public init(store: any DictionaryStore, deinflector: Deinflector = Deinflector()) {
        self.store = store
        self.deinflector = deinflector
    }

    /// Entries for the word starting at the beginning of `text`, best first: longest match, then fewest
    /// conjugation steps, then common words, then frequency.
    public func lookup(_ text: String) -> [LookupResult] {
        let characters = Array(text.prefix { !$0.isNewline })
        guard !characters.isEmpty else { return [] }
        var best: [Int: LookupResult] = [:]
        for length in stride(from: min(maximumLength, characters.count), through: 1, by: -1) {
            let prefix = String(characters[..<length])
            guard TextNormalizer.containsJapaneseText(prefix) || length == 1 else { continue }
            for candidate in deinflector.deinflect(prefix) {
                for entry in store.entries(forKey: Kana.foldToHiragana(candidate.term)) {
                    guard candidate.accepts(WordType.of(partsOfSpeech: entry.allPartsOfSpeech)),
                          !Self.isKatakanaOnlyMatch(entry, hiraganaTerm: candidate.term) else { continue }
                    let result = LookupResult(entry: entry, matched: prefix, dictionaryForm: candidate.term,
                                              reasons: candidate.reasons, specificity: candidate.specificity)
                    if let existing = best[entry.id], !Self.isBetter(result, than: existing) { continue }
                    best[entry.id] = result
                }
            }
        }
        return best.values.sorted { Self.isBetter($0, than: $1) }
    }

    /// Splits a phrase into dictionary words and unknown text, choosing the split with the lowest cost:
    /// each word costs 1 (1.5 when written in kana for a kanji word, e.g. がい for 害), each unknown character 2.
    /// This keeps particles apart where greedy longest match would not (敵が|いる, not 敵|がい|る).
    public func segment(_ text: String) -> [LookupToken] {
        let characters = Array(text)
        let n = characters.count
        guard n > 0 else { return [] }
        // Best result per match length at each position.
        var options: [[Int: [LookupResult]]] = Array(repeating: [:], count: n)
        for i in 0..<n where TextNormalizer.containsJapaneseText(String(characters[i])) || Kana.isKana(characters[i]) {
            for result in lookup(String(characters[i...])) {
                options[i][result.matched.count, default: []].append(result)
            }
        }
        var cost = Array(repeating: Double.infinity, count: n + 1)
        var step = Array(repeating: 0, count: n + 1)
        cost[n] = 0
        for i in stride(from: n - 1, through: 0, by: -1) {
            cost[i] = cost[i + 1] + 2
            step[i] = -1
            for (length, results) in options[i] where i + length <= n {
                let wordCost = results.contains(where: Self.isWrittenAsMatched) ? 1.0 : 1.5
                if wordCost + cost[i + length] < cost[i] {
                    cost[i] = wordCost + cost[i + length]
                    step[i] = length
                }
            }
        }
        var tokens: [LookupToken] = []
        var i = 0
        while i < n {
            if step[i] > 0 {
                let length = step[i]
                tokens.append(LookupToken(text: String(characters[i..<(i + length)]), offset: i,
                                          results: (options[i][length] ?? []).sorted { Self.isBetter($0, than: $1) }))
                i += length
            } else if let last = tokens.last, last.results.isEmpty, last.offset + last.text.count == i {
                tokens[tokens.count - 1].text.append(characters[i])
                i += 1
            } else {
                tokens.append(LookupToken(text: String(characters[i]), offset: i, results: []))
                i += 1
            }
        }
        return tokens
    }

    /// The word a learner tapped at the start of `text` (the rest of the line gives context): the first word of
    /// the best split, then every other match at that position.
    public func word(at text: String) -> [LookupResult] {
        let line = String(text.prefix { !$0.isNewline })
        let all = lookup(line)
        guard let first = segment(String(line.prefix(maximumLength * 2))).first, !first.results.isEmpty else { return all }
        let ids = Set(first.results.map(\.id))
        return first.results + all.filter { !ids.contains($0.id) }
    }

    /// Hiragana text never matches a word written only in katakana (がいる is not the name ガイル).
    static func isKatakanaOnlyMatch(_ entry: DictionaryEntry, hiraganaTerm term: String) -> Bool {
        guard term.contains(where: { ("ぁ"..."ゖ").contains($0) }) else { return false }
        if entry.kanji.contains(where: { $0.text == term }) { return false }
        return !entry.readings.contains { $0.text == term }
    }

    /// The text is written the way the entry is usually written: its kanji form, or kana for a kana word
    /// (particles, 〜uk words), rather than kana standing in for a kanji word (が for 画).
    static func isWrittenAsMatched(_ result: LookupResult) -> Bool {
        let form = result.dictionaryForm
        if result.entry.kanji.contains(where: { $0.text == form }) { return true }
        guard let reading = result.entry.readings.first(where: { Kana.foldToHiragana($0.text) == Kana.foldToHiragana(form) })
        else { return false }
        return result.entry.kanji.isEmpty || reading.noKanji || result.entry.senses.first?.usuallyKana == true
    }

    static func isBetter(_ a: LookupResult, than b: LookupResult) -> Bool {
        if a.matched.count != b.matched.count { return a.matched.count > b.matched.count }
        if a.reasons.count != b.reasons.count { return a.reasons.count < b.reasons.count }
        if a.specificity != b.specificity { return a.specificity > b.specificity }
        let aWritten = isWrittenAsMatched(a), bWritten = isWrittenAsMatched(b)
        if aWritten != bWritten { return aWritten }
        let aExact = a.entry.kanji.contains { $0.text == a.matched } || a.entry.readings.contains { $0.text == a.matched }
        let bExact = b.entry.kanji.contains { $0.text == b.matched } || b.entry.readings.contains { $0.text == b.matched }
        if aExact != bExact { return aExact }
        if a.entry.isCommon != b.entry.isCommon { return a.entry.isCommon }
        if a.entry.rank != b.entry.rank { return a.entry.rank < b.entry.rank }
        return a.entry.id < b.entry.id
    }
}
