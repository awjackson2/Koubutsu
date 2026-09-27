import Foundation
import Testing
@testable import KoubutsuCore

/// Arrow-control navigation over a frozen frame's lines (10.8.0).
struct StudyNavigatorTests {
    // 「この先には強い敵」: 「0 こ1 の2 先3 に4 は5 強6 い7 敵8 」9
    let top = line("「この先には強い敵」", x: 0.1, y: 0.1)
    let punctuationOnly = line("。。", x: 0.1, y: 0.2)
    let empty = line("", x: 0.1, y: 0.25)
    let bottom = line("敵がいる", x: 0.1, y: 0.3)

    var navigator: StudyNavigator {
        // Deliberately out of reading order.
        StudyNavigator(observations: [bottom, punctuationOnly, top, empty], wordRanges: [
            top.id: [0..<1, 1..<3, 3..<4, 4..<5, 5..<6, 6..<8, 8..<9, 9..<10],
            bottom.id: [0..<1, 1..<2, 2..<4],
        ])
    }

    private func texts(_ spans: [SelectedSpan]?) -> [String]? { spans?.map(\.text) }

    private func span(_ observation: RecognizedTextObservation, _ range: Range<Int>) -> SelectedSpan {
        let characters = Array(observation.text)
        return SelectedSpan(observationID: observation.id, range: range, text: String(characters[range]),
                            lineText: observation.text)
    }

    // MARK: Lines and units

    @Test func linesInReadingOrderSkippingEmptyAndPunctuationOnly() {
        let n = navigator
        #expect(n.lines.map(\.id) == [top.id, bottom.id])
        // Edge brackets are dropped as units.
        #expect(n.lines[0].units == [1..<3, 3..<4, 4..<5, 5..<6, 6..<8, 8..<9])
        #expect(n.lines[0].phrase == 1..<9)
        #expect(n.lines[1].length == 4)
    }

    @Test func unitsTrimEdgePunctuationAndDropInvalidRanges() {
        let characters = Array("「ＨＰ」が")
        #expect(StudyNavigator.units(in: characters, ranges: [0..<4, 4..<5]) == [1..<3, 4..<5])
        // Overlapping ranges: the first wins; out-of-bounds and empty ranges are ignored.
        #expect(StudyNavigator.units(in: Array("あいう"), ranges: [0..<2, 1..<3, 2..<3, 3..<9, 1..<1])
                == [0..<2, 2..<3])
        // Nothing usable: one unit per character.
        #expect(StudyNavigator.units(in: Array("あい"), ranges: [5..<9]) == [0..<1, 1..<2])
        #expect(StudyNavigator.units(in: [], ranges: nil).isEmpty)
    }

    @Test func wordRangesFromTokensAreClipped() {
        let tokens = [LookupToken(text: "敵", offset: 0, results: []), LookupToken(text: "がいる", offset: 1, results: []),
                      LookupToken(text: "よ", offset: 9, results: [])]
        #expect(StudyNavigator.wordRanges(tokens: tokens, length: 3) == [0..<1, 1..<3])
    }

    // MARK: Words

    @Test func initialSelectionIsTheFirstWord() {
        #expect(navigator.initialSelection?.text == "この")
        #expect(texts(navigator.move(.nextWord, from: [])) == ["この"])
        #expect(texts(navigator.move(.previousWord, from: [])) == ["この"])
        #expect(texts(navigator.move(.extendCharacter, from: [])) == ["この"])
    }

    @Test func nextWordWalksEveryWordAcrossLinesAndStopsAtTheEnd() {
        let n = navigator
        var selection: [SelectedSpan] = []
        var visited: [String] = []
        while let next = n.move(.nextWord, from: selection) {
            selection = next
            visited.append(StudySelection.joinedText(next))
        }
        #expect(visited == ["この", "先", "に", "は", "強い", "敵", "敵", "が", "いる"])
        #expect(selection.first?.observationID == bottom.id)
        // No wraparound.
        #expect(n.move(.nextWord, from: selection) == nil)
    }

    @Test func previousWordWalksBackAndStopsAtTheStart() {
        let n = navigator
        #expect(n.move(.previousWord, from: [span(bottom, 0..<1)]) == [span(top, 8..<9)])
        #expect(texts(n.move(.previousWord, from: [span(bottom, 2..<4)])) == ["が"])
        #expect(n.move(.previousWord, from: [span(top, 1..<3)]) == nil)
    }

    @Test func tappedCharacterStepsToNeighbouringWords() {
        let n = navigator
        // 強 of 強い: next skips the rest of the word; previous goes to the word before.
        #expect(texts(n.move(.nextWord, from: [span(top, 6..<7)])) == ["敵"])
        #expect(texts(n.move(.previousWord, from: [span(top, 6..<7)])) == ["は"])
        // い of 強い: previous goes to the start of its own word.
        #expect(texts(n.move(.previousWord, from: [span(top, 7..<8)])) == ["強い"])
        // A tap widened by the lookup to 先には (three units) never gets stuck.
        #expect(texts(n.move(.nextWord, from: [span(top, 3..<6)])) == ["強い"])
    }

    // MARK: Lines

    @Test func lineStepsSelectWholeLines() {
        let n = navigator
        let first = n.move(.nextLine, from: [])
        #expect(texts(first) == ["この先には強い敵"])
        #expect(texts(n.move(.previousLine, from: [])) == ["この先には強い敵"])
        let second = n.move(.nextLine, from: first ?? [])
        #expect(texts(second) == ["敵がいる"])
        #expect(n.move(.nextLine, from: second ?? []) == nil)
        #expect(texts(n.move(.previousLine, from: second ?? [])) == ["この先には強い敵"])
        #expect(n.move(.previousLine, from: first ?? []) == nil)
        // From a word, a line step moves to the adjacent whole line.
        #expect(texts(n.move(.nextLine, from: [span(top, 3..<4)])) == ["敵がいる"])
    }

    // MARK: Granular

    @Test func extendAndShrinkByCharacterAcrossALineEnd() throws {
        let n = navigator
        let one = try #require(n.move(.extendCharacter, from: [span(top, 8..<9)]))
        #expect(texts(one) == ["敵」"])
        let two = try #require(n.move(.extendCharacter, from: one))
        #expect(two == [span(top, 8..<10), span(bottom, 0..<1)])
        #expect(StudySelection.joinedText(two) == "敵」敵")
        let back = try #require(n.move(.shrinkCharacter, from: two))
        #expect(back == [span(top, 8..<10)])
        let single = try #require(n.move(.shrinkCharacter, from: back))
        #expect(single == [span(top, 8..<9)])
        // Never below one character.
        #expect(n.move(.shrinkCharacter, from: single) == nil)
        // The last line's end cannot grow.
        #expect(n.move(.extendCharacter, from: [span(bottom, 0..<4)]) == nil)
    }

    @Test func extendByWordThenStepFromTheSpanningSelection() throws {
        let n = navigator
        #expect(texts(n.move(.extendWord, from: [span(top, 1..<3)])) == ["この先"])
        // From a tapped character, extend to the end of its own word.
        #expect(texts(n.move(.extendWord, from: [span(top, 6..<7)])) == ["強い"])
        let spanning = try #require(n.move(.extendWord, from: [span(top, 8..<9)]))
        #expect(spanning == [span(top, 8..<9), span(bottom, 0..<1)])
        let longer = try #require(n.move(.extendWord, from: spanning))
        #expect(texts(longer) == ["敵", "敵が"])
        // Forward steps start from the selection's end, backward ones from its start.
        #expect(texts(n.move(.nextWord, from: longer)) == ["いる"])
        #expect(texts(n.move(.previousWord, from: longer)) == ["強い"])
        #expect(texts(n.move(.nextLine, from: longer)) == nil)
        #expect(texts(n.move(.previousLine, from: longer)) == nil)
        #expect(texts(n.move(.shrinkCharacter, from: longer)) == ["敵", "敵"])
        #expect(n.move(.extendWord, from: [span(bottom, 2..<4)]) == nil)
    }

    // MARK: Fallbacks

    @Test func withoutSegmentationEveryCharacterIsAWord() {
        let status = line("HPが10。", x: 0.1, y: 0.1)
        let n = StudyNavigator(observations: [status])
        var selection: [SelectedSpan] = []
        var visited: [String] = []
        while let next = n.move(.nextWord, from: selection) {
            selection = next
            visited.append(StudySelection.joinedText(next))
        }
        #expect(visited == ["H", "P", "が", "1", "0"])
        #expect(n.lines[0].phrase == 0..<5)
    }

    @Test func staleOrInvalidSelectionRestartsAtTheTop() {
        let n = navigator
        let stale = SelectedSpan(observationID: UUID(), range: 0..<1, text: "x", lineText: "x")
        #expect(texts(n.move(.nextWord, from: [stale])) == ["この"])
        let outOfBounds = SelectedSpan(observationID: bottom.id, range: 3..<9, text: "", lineText: bottom.text)
        #expect(texts(n.move(.nextWord, from: [outOfBounds])) == ["この"])
    }

    @Test func noLinesNoMoves() {
        let n = StudyNavigator(observations: [line("。", x: 0, y: 0), line("", x: 0, y: 0.2)])
        #expect(n.lines.isEmpty && n.initialSelection == nil)
        for step in StudyNavigator.Step.allCases {
            #expect(n.move(step, from: []) == nil)
        }
    }

    @Test func wordsFromDictionarySegmentation() {
        let lookup = DictionaryLookup(store: fixtureStore)
        let text = "この先には強い敵がいる。"
        let observation = line(text, x: 0.1, y: 0.1)
        let ranges = StudyNavigator.wordRanges(tokens: lookup.segment(text), length: text.count)
        let n = StudyNavigator(observations: [observation], wordRanges: [observation.id: ranges])
        let characters = Array(text)
        #expect(n.lines[0].units.map { String(characters[$0]) }
                == ["この", "先", "に", "は", "強い", "敵", "が", "いる"])
    }
}
