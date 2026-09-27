import Foundation

/// Review state of one saved word (FSRS).
public struct ReviewCard: Sendable, Hashable, Codable {
    public enum State: String, Sendable, Codable { case new, learning, review, relearning }

    public var state: State = .new
    /// Days until recall probability falls to 90 %.
    public var stability: Double = 0
    /// 1 (easy) … 10 (hard).
    public var difficulty: Double = 0
    public var due: Date
    public var lastReview: Date?
    public var reviews: Int = 0
    public var lapses: Int = 0

    public init(due: Date) {
        self.due = due
    }
}

public enum ReviewRating: Int, Sendable, Codable, CaseIterable {
    case again = 1, hard, good, easy

    public var label: String {
        switch self {
        case .again: "Again"
        case .hard: "Hard"
        case .good: "Good"
        case .easy: "Easy"
        }
    }
}

/// FSRS-4.5 scheduler with the published default parameters and a 90 % retention target.
public struct FSRS: Sendable {
    public var weights: [Double] = [0.4872, 1.4003, 3.7145, 13.8206, 5.1618, 1.2298, 0.8975, 0.031, 1.6474,
                                    0.1367, 1.0461, 2.1072, 0.0793, 0.3246, 1.587, 0.2272, 2.8755]
    public var retention = 0.9
    /// Delay before a failed card comes back in the same session.
    public var relearnDelay: TimeInterval = 5 * 60
    public var maximumIntervalDays = 36500.0

    static let decay = -0.5
    static let factor = 19.0 / 81.0

    public init() {}

    public func retrievability(elapsedDays t: Double, stability s: Double) -> Double {
        guard s > 0 else { return 0 }
        return pow(1 + Self.factor * t / s, Self.decay)
    }

    public func intervalDays(stability s: Double) -> Double {
        min(maximumIntervalDays, s / Self.factor * (pow(retention, 1 / Self.decay) - 1))
    }

    func initialDifficulty(_ rating: ReviewRating) -> Double {
        clampDifficulty(weights[4] - Double(rating.rawValue - 3) * weights[5])
    }

    func clampDifficulty(_ d: Double) -> Double { min(10, max(1, d)) }

    /// The card after answering with `rating` at `now`.
    public func review(_ card: ReviewCard, rating: ReviewRating, now: Date) -> ReviewCard {
        var next = card
        let w = weights
        if card.state == .new {
            next.stability = w[rating.rawValue - 1]
            next.difficulty = initialDifficulty(rating)
        } else {
            let elapsed = max(0, now.timeIntervalSince(card.lastReview ?? now) / 86400)
            let r = retrievability(elapsedDays: elapsed, stability: card.stability)
            let d = card.difficulty
            let g = Double(rating.rawValue)
            next.difficulty = clampDifficulty(w[7] * initialDifficulty(.easy) + (1 - w[7]) * (d - w[6] * (g - 3)))
            if rating == .again {
                let lapse = w[11] * pow(d, -w[12]) * (pow(card.stability + 1, w[13]) - 1) * exp(w[14] * (1 - r))
                next.stability = min(card.stability, lapse)
                next.lapses += 1
            } else {
                let hard = rating == .hard ? w[15] : 1
                let easy = rating == .easy ? w[16] : 1
                next.stability = card.stability
                    * (exp(w[8]) * (11 - d) * pow(card.stability, -w[9]) * (exp(w[10] * (1 - r)) - 1) * hard * easy + 1)
            }
        }
        next.reviews += 1
        next.lastReview = now
        if rating == .again {
            next.state = card.state == .new || card.state == .learning ? .learning : .relearning
            next.due = now.addingTimeInterval(relearnDelay)
        } else {
            next.state = .review
            let days = max(1, intervalDays(stability: next.stability).rounded())
            next.due = now.addingTimeInterval(days * 86400)
        }
        return next
    }

    /// When each rating would schedule the card next.
    public func preview(_ card: ReviewCard, now: Date) -> [ReviewRating: TimeInterval] {
        Dictionary(uniqueKeysWithValues: ReviewRating.allCases.map { rating in
            (rating, review(card, rating: rating, now: now).due.timeIntervalSince(now))
        })
    }
}

/// A word the learner saved, with where they met it.
public struct SavedWord: Sendable, Hashable, Codable, Identifiable {
    public var id: UUID
    public var entryID: Int
    public var headword: String
    public var reading: String
    /// First senses' glosses, e.g. ["to eat", "to live on (e.g. a salary)"].
    public var meanings: [String]
    public var sentence: String?
    public var sentenceTranslation: String?
    /// Game or video name.
    public var source: String?
    public var mediaTime: Double?
    /// JPEG file name of the line cropped from the frozen frame.
    public var imageFile: String?
    public var created: Date
    /// Marked as known: no longer reviewed, no reading aid.
    public var isKnown: Bool = false
    public var card: ReviewCard

    public init(id: UUID = UUID(), entryID: Int, headword: String, reading: String, meanings: [String],
                sentence: String? = nil, sentenceTranslation: String? = nil, source: String? = nil,
                mediaTime: Double? = nil, imageFile: String? = nil, created: Date) {
        self.id = id
        self.entryID = entryID
        self.headword = headword
        self.reading = reading
        self.meanings = meanings
        self.sentence = sentence
        self.sentenceTranslation = sentenceTranslation
        self.source = source
        self.mediaTime = mediaTime
        self.imageFile = imageFile
        self.created = created
        self.card = ReviewCard(due: created)
    }
}

/// The learner's saved words.
public struct WordBank: Sendable, Hashable, Codable {
    public static let formatVersion = 1
    public var version = WordBank.formatVersion
    public private(set) var words: [SavedWord] = []

    public init(words: [SavedWord] = []) {
        self.words = words
    }

    public func contains(entryID: Int, headword: String) -> Bool {
        words.contains { $0.entryID == entryID && $0.headword == headword }
    }

    public func word(entryID: Int, headword: String) -> SavedWord? {
        words.first { $0.entryID == entryID && $0.headword == headword }
    }

    /// Adds `word` unless the same entry/headword is already saved. Returns whether it was added.
    @discardableResult
    public mutating func add(_ word: SavedWord) -> Bool {
        guard !contains(entryID: word.entryID, headword: word.headword) else { return false }
        words.append(word)
        return true
    }

    public mutating func remove(id: UUID) {
        words.removeAll { $0.id == id }
    }

    public mutating func setKnown(_ known: Bool, id: UUID) {
        guard let index = words.firstIndex(where: { $0.id == id }) else { return }
        words[index].isKnown = known
    }

    public mutating func record(_ rating: ReviewRating, id: UUID, now: Date, scheduler: FSRS = FSRS()) {
        guard let index = words.firstIndex(where: { $0.id == id }) else { return }
        words[index].card = scheduler.review(words[index].card, rating: rating, now: now)
    }

    /// Words to review now, most overdue first (known words excluded).
    public func due(at now: Date) -> [SavedWord] {
        words.filter { !$0.isKnown && $0.card.due <= now }.sorted { $0.card.due < $1.card.due }
    }

    /// Headwords the reading aids treat as known / as being learned.
    public var knownHeadwords: Set<String> { Set(words.filter(\.isKnown).map(\.headword)) }
    public var learningHeadwords: Set<String> { Set(words.filter { !$0.isKnown }.map(\.headword)) }
}

/// Anki import file (File → Import, Anki 2.1.55+): Basic note type, HTML fields, one note per word.
public enum AnkiExport {
    public static func tsv(_ words: [SavedWord], deck: String = "Koubutsu") -> String {
        var lines = ["#separator:tab", "#html:true", "#notetype:Basic", "#deck:\(deck)", "#tags column:3"]
        for word in words {
            let ruby = Furigana.align(written: word.headword, reading: word.reading).map { segment in
                segment.reading.map { "<ruby>\(html(segment.text))<rt>\(html($0))</rt></ruby>" } ?? html(segment.text)
            }.joined()
            var front = ruby
            if let sentence = word.sentence { front += "<br><small>\(html(sentence))</small>" }
            var back = "\(html(word.reading)) · \(html(Romaji.hepburn(word.reading)))<br>"
                + word.meanings.map(html).joined(separator: "<br>")
            if let translation = word.sentenceTranslation { back += "<br><small>\(html(translation))</small>" }
            var tags = ["koubutsu"]
            if let source = word.source { tags.append(source.replacingOccurrences(of: " ", with: "_")) }
            lines.append([front, back, tags.joined(separator: " ")].map(field).joined(separator: "\t"))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func html(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// Fields may not contain tabs or newlines.
    static func field(_ text: String) -> String {
        text.replacingOccurrences(of: "\t", with: " ").replacingOccurrences(of: "\n", with: "<br>")
    }
}
