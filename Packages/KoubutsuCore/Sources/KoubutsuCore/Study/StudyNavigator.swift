import Foundation

/// Walks the recognized lines of a frozen frame by word, line and character (10.8.0), for arrow controls where
/// tapping small glyphs is hard.
///
/// Lines are the observations in reading order (`StudySelection.readingOrder`). Each line has word units: character
/// ranges from `DictionaryLookup.segment(_:)` with leading and trailing whitespace/punctuation trimmed (tokens made
/// only of those are dropped), or one unit per character when the line has no segmentation. Lines without units are
/// skipped. Steps never wrap around: at either end they return nil.
public struct StudyNavigator: Sendable, Equatable {
    public enum Step: Sendable, CaseIterable, Hashable {
        case nextWord, previousWord
        case nextLine, previousLine
        /// Moves the selection's end one character later (appending the next line's first character at a line end).
        case extendCharacter
        /// Moves the selection's end one character earlier; never below one character.
        case shrinkCharacter
        /// Moves the selection's end to the end of the next word (appending the next line's first word at a line end).
        case extendWord

        var isForward: Bool {
            switch self {
            case .previousWord, .previousLine: false
            default: true
            }
        }
    }

    public struct Line: Sendable, Equatable {
        public var id: UUID
        public var text: String
        public var length: Int
        /// Word units in order, non-empty and non-overlapping.
        public var units: [Range<Int>]

        /// First unit start to last unit end (edge punctuation left out).
        public var phrase: Range<Int> { units[0].lowerBound..<units[units.count - 1].upperBound }
    }

    public private(set) var lines: [Line]

    /// - Parameter wordRanges: per observation, word ranges (character offsets), e.g. from `wordRanges(tokens:length:)`.
    ///   Observations without an entry (or whose ranges are unusable) fall back to one unit per character.
    public init(observations: [RecognizedTextObservation], wordRanges: [UUID: [Range<Int>]] = [:]) {
        lines = StudySelection.readingOrder(observations).compactMap { observation in
            let characters = Array(observation.text)
            let units = Self.units(in: characters, ranges: wordRanges[observation.id])
            guard !units.isEmpty else { return nil }
            return Line(id: observation.id, text: observation.text, length: characters.count, units: units)
        }
    }

    /// Character ranges of segmentation tokens, clipped to a line `length` characters long.
    public static func wordRanges(tokens: [LookupToken], length: Int) -> [Range<Int>] {
        tokens.compactMap { token in
            let lower = max(0, token.offset), upper = min(length, token.offset + token.text.count)
            return lower < upper ? lower..<upper : nil
        }
    }

    /// Word units of a line: `ranges` sorted, overlaps and out-of-bounds dropped, each trimmed of edge
    /// whitespace/punctuation. With no usable ranges, one unit per character that is not whitespace/punctuation.
    public static func units(in characters: [Character], ranges: [Range<Int>]?) -> [Range<Int>] {
        var valid: [Range<Int>] = []
        for range in (ranges ?? []).sorted(by: { $0.lowerBound < $1.lowerBound })
        where range.lowerBound >= 0 && range.upperBound <= characters.count && !range.isEmpty {
            if let last = valid.last, range.lowerBound < last.upperBound { continue }
            valid.append(range)
        }
        if valid.isEmpty {
            valid = characters.indices.map { $0..<($0 + 1) }
        }
        return valid.compactMap { range in
            var lower = range.lowerBound, upper = range.upperBound
            while lower < upper, isSeparator(characters[lower]) { lower += 1 }
            while upper > lower, isSeparator(characters[upper - 1]) { upper -= 1 }
            return lower < upper ? lower..<upper : nil
        }
    }

    /// Whitespace, punctuation (「」、。！…) and symbols never start or end a unit.
    public static func isSeparator(_ ch: Character) -> Bool {
        ch.isWhitespace || ch.isPunctuation || ch.isSymbol
    }

    /// The first word of the first line.
    public var initialSelection: SelectedSpan? {
        lines.first.map { span(in: $0, $0.units[0]) }
    }

    /// The selection after `step` from `current` (spans in reading order, as `StudySelection` produces them), or
    /// nil when the step cannot move (an end, a one-character shrink floor, or no lines).
    public func move(_ step: Step, from current: [SelectedSpan]) -> [SelectedSpan]? {
        guard !lines.isEmpty else { return nil }
        let located = current.compactMap { span -> (line: Int, span: SelectedSpan)? in
            guard let index = lines.firstIndex(where: { $0.id == span.observationID }),
                  span.range.lowerBound >= 0, span.range.upperBound <= lines[index].length,
                  !span.range.isEmpty else { return nil }
            return (index, span)
        }.sorted { ($0.line, $0.span.range.lowerBound) < ($1.line, $1.span.range.lowerBound) }
        guard let first = located.first, let last = located.last else {
            // Nothing (or nothing current) selected: start at the top.
            switch step {
            case .nextLine, .previousLine: return [span(in: lines[0], lines[0].phrase)]
            default: return initialSelection.map { [$0] }
            }
        }
        let anchor = step.isForward ? last : first
        let line = lines[anchor.line]
        let range = anchor.span.range
        switch step {
        case .nextWord:
            if let unit = line.units.first(where: { $0.lowerBound > range.lowerBound && $0.upperBound > range.upperBound }) {
                return [span(in: line, unit)]
            }
            return lines.indices.contains(anchor.line + 1) ? [span(in: lines[anchor.line + 1],
                                                                   lines[anchor.line + 1].units[0])] : nil
        case .previousWord:
            if let unit = line.units.last(where: { $0.lowerBound < range.lowerBound }) {
                return [span(in: line, unit)]
            }
            guard anchor.line > 0 else { return nil }
            let previous = lines[anchor.line - 1]
            return [span(in: previous, previous.units[previous.units.count - 1])]
        case .nextLine:
            return lines.indices.contains(anchor.line + 1) ? [span(in: lines[anchor.line + 1],
                                                                   lines[anchor.line + 1].phrase)] : nil
        case .previousLine:
            return anchor.line > 0 ? [span(in: lines[anchor.line - 1], lines[anchor.line - 1].phrase)] : nil
        case .extendCharacter:
            if range.upperBound < line.length {
                return replacingLast(located, with: span(in: line, range.lowerBound..<(range.upperBound + 1)))
            }
            guard let next = nextLine(after: last.line, in: located) else { return nil }
            let start = next.units[0].lowerBound
            return located.map { $0.span } + [span(in: next, start..<(start + 1))]
        case .shrinkCharacter:
            if range.count > 1 {
                return replacingLast(located, with: span(in: line, range.lowerBound..<(range.upperBound - 1)))
            }
            return located.count > 1 ? located.dropLast().map { $0.span } : nil
        case .extendWord:
            if let unit = line.units.first(where: { $0.upperBound > range.upperBound }) {
                return replacingLast(located, with: span(in: line, range.lowerBound..<unit.upperBound))
            }
            guard let next = nextLine(after: last.line, in: located) else { return nil }
            return located.map { $0.span } + [span(in: next, next.units[0])]
        }
    }

    /// The line after `index`, unless it is already part of the selection.
    private func nextLine(after index: Int, in located: [(line: Int, span: SelectedSpan)]) -> Line? {
        guard lines.indices.contains(index + 1), !located.contains(where: { $0.line == index + 1 }) else { return nil }
        return lines[index + 1]
    }

    private func replacingLast(_ located: [(line: Int, span: SelectedSpan)], with span: SelectedSpan) -> [SelectedSpan] {
        located.dropLast().map { $0.span } + [span]
    }

    private func span(in line: Line, _ range: Range<Int>) -> SelectedSpan {
        let characters = Array(line.text)
        return SelectedSpan(observationID: line.id, range: range, text: String(characters[range]),
                            lineText: line.text)
    }
}
