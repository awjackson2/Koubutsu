import Foundation
import Testing
@testable import KoubutsuCore

/// Portrait info deck (10.7.0): the layout threshold, on-screen word filtering and session statistics.
struct PortraitDeckTests {
    let lookup = DictionaryLookup(store: fixtureStore)

    // MARK: Layout

    @Test func deckNeedsTheMinimumFillerHeight() {
        #expect(VideoStageLayout.showsPortraitDeck(fillerHeight: 120))
        #expect(VideoStageLayout.showsPortraitDeck(fillerHeight: 380))
        #expect(!VideoStageLayout.showsPortraitDeck(fillerHeight: 119.5))
        #expect(!VideoStageLayout.showsPortraitDeck(fillerHeight: 0))
        #expect(!VideoStageLayout.showsPortraitDeck(fillerHeight: .infinity))
        #expect(VideoStageLayout.portraitDeckMinHeight > VideoStageLayout.portraitDeckTabHeight)
    }

    /// On every iPhone portrait size the filler left by the chrome region minus the bars fits the deck.
    @Test(arguments: [(375.0, 667.0, 20.0, 0.0), (393, 852, 59, 34), (440, 956, 62, 34)])
    func iPhonePortraitFillerFitsTheDeck(width: Double, height: Double, safeTop: Double, safeBottom: Double) {
        let safe = VideoStageLayout.StageInsets(top: safeTop, left: 0, bottom: safeBottom, right: 0)
        let stage = VideoStageLayout.framed(containerWidth: width, containerHeight: height - safeBottom,
                                            insets: VideoStageLayout.windowedInsets(for: .compactPortrait, safe: safe))
        let region = VideoStageLayout.chromeRegion(below: stage, containerWidth: width,
                                                   containerHeight: height - safeBottom)
        let filler = region.height - VideoStageLayout.compactBarsAllowance
        #expect(VideoStageLayout.showsPortraitDeck(fillerHeight: filler))
    }

    // MARK: Words

    @Test func listsContentWordsInReadingOrder() {
        let words = DeckWords.words(texts: ["この先には強い敵がいる。"], lookup: lookup)
        #expect(words.map(\.surface) == ["この", "先", "強い", "敵", "いる"])
        #expect(words.map(\.headword) == ["この", "先", "強い", "敵", "いる"])
        #expect(words[1].reading == "さき")
        #expect(words[1].gloss == "ahead")
        #expect(words.allSatisfy { $0.sourceIndex == 0 })
    }

    @Test func skipsParticlesCopulaAndPunctuation() {
        let words = DeckWords.words(texts: ["鍵が必要です"], lookup: lookup)
        #expect(words.map(\.headword) == ["鍵", "必要"])
        let tokens = lookup.segment("敵がいる。")
        #expect(tokens.filter(DeckWords.isUseful).map(\.text) == ["敵", "いる"])
    }

    @Test func deDuplicatesAcrossBlocksAndLinesKeepingTheFirst() {
        let words = DeckWords.words(texts: ["敵がいる", "強い敵\n鍵が必要です"], lookup: lookup)
        #expect(words.map(\.headword) == ["敵", "いる", "強い", "鍵", "必要"])
        #expect(words.map(\.sourceIndex) == [0, 0, 1, 1, 1])
        #expect(Set(words.map(\.id)).count == words.count)
    }

    @Test func respectsTheLimitAndEmptyInput() {
        #expect(DeckWords.words(texts: ["この先には強い敵がいる。"], lookup: lookup, limit: 2).count == 2)
        #expect(DeckWords.words(texts: [], lookup: lookup).isEmpty)
        #expect(DeckWords.words(texts: ["", "ABC 123"], lookup: lookup).isEmpty)
        #expect(DeckWord(surface: "x", results: [], sourceIndex: 0) == nil)
    }

    @Test func wordBankState() throws {
        let words = DeckWords.words(texts: ["強い敵がいる"], lookup: lookup)
        let strong = try #require(words.first { $0.headword == "強い" })
        let enemy = try #require(words.first { $0.headword == "敵" })
        let exist = try #require(words.first { $0.headword == "いる" })
        let now = Date(timeIntervalSince1970: 1_000_000)
        var bank = WordBank()
        bank.add(SavedWord(entryID: strong.entryID, headword: "強い", reading: "つよい", meanings: ["strong"],
                           created: now))
        let known = SavedWord(entryID: enemy.entryID, headword: "敵", reading: "てき", meanings: ["enemy"],
                              created: now)
        bank.add(known)
        bank.setKnown(true, id: known.id)
        #expect(DeckWords.state(of: strong, in: bank) == .learning)
        #expect(DeckWords.state(of: enemy, in: bank) == .known)
        #expect(DeckWords.state(of: exist, in: bank) == .new)
        #expect(DeckWordState.learning.label == "LEARNING")
    }

    // MARK: Session

    @Test func sessionCountsOnlyWhatHappenedSinceItStarted() {
        let start = Date(timeIntervalSince1970: 2_000_000)
        let stats = ReadingSessionStats(started: start)
        var history = DialogueHistory()
        history.record(stable("前の行"), date: start.addingTimeInterval(-10))
        history.record(stable("鍵が必要です"), date: start.addingTimeInterval(5))
        history.record(stable("この先には強い敵がいる。"), date: start.addingTimeInterval(9))
        if let id = history.entries.last?.id { history.setTranslation("There is a powerful enemy ahead.", provider: "t", for: id) }
        #expect(stats.linesRead(in: history.entries) == 2)
        #expect(stats.translatedLines(in: history.entries) == 1)

        var bank = WordBank()
        bank.add(SavedWord(entryID: 1, headword: "鍵", reading: "かぎ", meanings: ["key"],
                           created: start.addingTimeInterval(-60)))
        bank.add(SavedWord(entryID: 14, headword: "敵", reading: "てき", meanings: ["enemy"],
                           created: start.addingTimeInterval(30)))
        #expect(stats.wordsSaved(in: bank) == 1)
        #expect(stats.elapsed(at: start.addingTimeInterval(-5)) == 0)
        #expect(stats.elapsed(at: start.addingTimeInterval(75)) == 75)
    }

    @Test func clockText() {
        #expect(ReadingSessionStats.clock(0) == "00:00:00")
        #expect(ReadingSessionStats.clock(59.9) == "00:00:59")
        #expect(ReadingSessionStats.clock(3_725) == "01:02:05")
        #expect(ReadingSessionStats.clock(360_000) == "100:00:00")
        #expect(ReadingSessionStats.clock(-4) == "00:00:00")
        #expect(ReadingSessionStats.clock(.nan) == "00:00:00")
    }

    @Test func meterSegmentsAreClamped() {
        #expect(ReadingSessionStats.meterSegments(value: 5, full: 10, segments: 10) == 5)
        #expect(ReadingSessionStats.meterSegments(value: 25, full: 10, segments: 10) == 10)
        #expect(ReadingSessionStats.meterSegments(value: 0.01, full: 10, segments: 10) == 1)
        #expect(ReadingSessionStats.meterSegments(value: 0, full: 10, segments: 10) == 0)
        #expect(ReadingSessionStats.meterSegments(value: nil, full: 10, segments: 10) == 0)
        #expect(ReadingSessionStats.meterSegments(value: .infinity, full: 10, segments: 10) == 0)
        #expect(ReadingSessionStats.meterSegments(value: 3, full: 0, segments: 10) == 0)
    }
}
