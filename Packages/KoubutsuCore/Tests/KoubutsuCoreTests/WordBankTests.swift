import Foundation
import Testing
@testable import KoubutsuCore

struct WordBankTests {
    let fsrs = FSRS()
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func newCardSchedulesByFirstRating() {
        let card = ReviewCard(due: t0)
        let again = fsrs.review(card, rating: .again, now: t0)
        #expect(again.state == .learning && again.due.timeIntervalSince(t0) == 300)
        let good = fsrs.review(card, rating: .good, now: t0)
        #expect(good.state == .review && abs(good.stability - 3.7145) < 1e-9)
        #expect(good.due.timeIntervalSince(t0) == 4 * 86400) // S = 3.71 days → 4 days at 90 % retention
        let intervals = ReviewRating.allCases.map { fsrs.review(card, rating: $0, now: t0).due.timeIntervalSince(t0) }
        #expect(intervals == intervals.sorted())
    }

    @Test func intervalEqualsStabilityAtNinetyPercent() {
        #expect(abs(fsrs.intervalDays(stability: 10) - 10) < 1e-9)
        #expect(abs(fsrs.retrievability(elapsedDays: 10, stability: 10) - 0.9) < 1e-9)
    }

    @Test func successGrowsStabilityAndLapseShrinksIt() {
        let first = fsrs.review(ReviewCard(due: t0), rating: .good, now: t0)
        let later = first.due
        let good = fsrs.review(first, rating: .good, now: later)
        #expect(good.stability > first.stability * 2)
        let easy = fsrs.review(first, rating: .easy, now: later)
        let hard = fsrs.review(first, rating: .hard, now: later)
        #expect(hard.stability < good.stability && good.stability < easy.stability)
        let lapse = fsrs.review(first, rating: .again, now: later)
        #expect(lapse.stability < first.stability && lapse.lapses == 1 && lapse.state == .relearning)
        #expect((1...10).contains(lapse.difficulty) && lapse.difficulty > first.difficulty)
    }

    @Test func bankDedupesAndReportsDue() {
        var bank = WordBank()
        let word = SavedWord(entryID: 1358280, headword: "食べる", reading: "たべる", meanings: ["to eat"], created: t0)
        let added = bank.add(word)
        let duplicate = bank.add(SavedWord(entryID: 1358280, headword: "食べる", reading: "たべる", meanings: [], created: t0))
        #expect(added && !duplicate)
        #expect(bank.due(at: t0).count == 1)
        bank.record(.good, id: word.id, now: t0)
        #expect(bank.due(at: t0).isEmpty)
        #expect(bank.due(at: t0.addingTimeInterval(5 * 86400)).count == 1)
        bank.setKnown(true, id: word.id)
        #expect(bank.due(at: t0.addingTimeInterval(5 * 86400)).isEmpty)
        #expect(bank.knownHeadwords == ["食べる"] && bank.learningHeadwords.isEmpty)
    }

    @Test func bankRoundTripsThroughJSON() throws {
        var bank = WordBank()
        bank.add(SavedWord(entryID: 1, headword: "鍵", reading: "かぎ", meanings: ["key"], sentence: "鍵が必要です",
                           source: "Test", mediaTime: 12.5, created: t0))
        let decoded = try JSONDecoder().decode(WordBank.self, from: JSONEncoder().encode(bank))
        #expect(decoded == bank)
    }

    @Test func ankiExportHasHeadersRubyAndEscaping() {
        var word = SavedWord(entryID: 1, headword: "食べる", reading: "たべる", meanings: ["to eat", "a<b"],
                             sentence: "パンを食べる\tよ", source: "Persona 3", created: t0)
        word.sentenceTranslation = "I eat bread"
        let tsv = AnkiExport.tsv([word])
        let lines = tsv.split(separator: "\n").map(String.init)
        #expect(lines.prefix(5) == ["#separator:tab", "#html:true", "#notetype:Basic", "#deck:Koubutsu", "#tags column:3"])
        let fields = lines[5].split(separator: "\t", omittingEmptySubsequences: false)
        #expect(fields.count == 3)
        #expect(fields[0].hasPrefix("<ruby>食<rt>た</rt></ruby>べる<br><small>パンを食べる よ</small>"))
        #expect(fields[1].contains("tabemasu") == false && fields[1].contains("taberu") && fields[1].contains("a&lt;b"))
        #expect(fields[2] == "koubutsu Persona_3")
    }
}
