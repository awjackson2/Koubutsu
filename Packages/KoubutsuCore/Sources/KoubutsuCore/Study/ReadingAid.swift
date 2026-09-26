/// A span of a recognized line that gets a reading aid.
public struct ReadingAnnotation: Sendable, Hashable {
    /// Character offsets in the line.
    public var range: Range<Int>
    /// Reading shown above the span (kanji runs only); nil for highlight-only spans.
    public var reading: String?
    /// The word containing this span is saved and still being learned.
    public var isLearning: Bool

    public init(range: Range<Int>, reading: String?, isLearning: Bool) {
        self.range = range
        self.reading = reading
        self.isLearning = isLearning
    }
}

public enum ReadingAid {
    /// Readings for the kanji runs of `surface` (the text as it appears, possibly conjugated), as character
    /// ranges within `surface`. Uses the dictionary form's alignment; conjugation only changes trailing kana,
    /// so kanji runs correspond in order.
    public static func surfaceFurigana(surface: String, result: LookupResult) -> [(range: Range<Int>, reading: String)] {
        let form = result.dictionaryForm
        guard surface.contains(where: Kana.isKanji) else { return [] }
        let reading = result.entry.readings(for: form).first?.text ?? result.reading
        let formRuns = Furigana.align(written: form, reading: reading).compactMap(\.reading)
        let surfaceRuns = kanjiRuns(in: surface)
        guard !formRuns.isEmpty, formRuns.count == surfaceRuns.count,
              Furigana.align(written: form, reading: reading).count > 1 || surfaceRuns.count == 1 else { return [] }
        return zip(surfaceRuns, formRuns).map { (range: $0, reading: $1) }
    }

    /// Kanji runs as character ranges.
    static func kanjiRuns(in text: String) -> [Range<Int>] {
        var runs: [Range<Int>] = []
        var start: Int?
        for (index, ch) in text.enumerated() {
            if Kana.isKanji(ch) {
                if start == nil { start = index }
            } else if let s = start {
                runs.append(s..<index)
                start = nil
            }
        }
        if let s = start { runs.append(s..<text.count) }
        return runs
    }

    /// Annotations for one line split into `tokens`: readings over kanji of words not marked known, and a
    /// highlight on words being learned.
    public static func annotations(tokens: [LookupToken], known: Set<String>, learning: Set<String>) -> [ReadingAnnotation] {
        var result: [ReadingAnnotation] = []
        for token in tokens {
            guard let best = token.results.first else { continue }
            let forms = [best.headword, best.dictionaryForm]
            let isKnown = forms.contains(where: known.contains)
            let isLearning = forms.contains(where: learning.contains)
            if isLearning {
                result.append(ReadingAnnotation(range: token.offset..<(token.offset + token.text.count), reading: nil,
                                                isLearning: true))
            }
            guard !isKnown else { continue }
            for run in surfaceFurigana(surface: token.text, result: best) {
                result.append(ReadingAnnotation(range: (token.offset + run.range.lowerBound)..<(token.offset + run.range.upperBound),
                                                reading: run.reading, isLearning: isLearning))
            }
        }
        return result
    }
}
