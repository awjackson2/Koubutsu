import Foundation

/// One JMdict entry (schema v1 of `Tools/build_dictionary.py`; JSON keys are abbreviated to keep the file small).
public struct DictionaryEntry: Sendable, Hashable, Identifiable, Codable {
    public struct KanjiForm: Sendable, Hashable, Codable {
        public var text: String
        public var isCommon: Bool
        /// JMdict `ke_inf` codes (e.g. `rK` rare kanji form, `sK` search-only).
        public var info: [String]

        enum CodingKeys: String, CodingKey { case text = "t", isCommon = "c", info = "i" }

        public init(text: String, isCommon: Bool = false, info: [String] = []) {
            self.text = text
            self.isCommon = isCommon
            self.info = info
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            text = try c.decode(String.self, forKey: .text)
            isCommon = (try c.decodeIfPresent(Int.self, forKey: .isCommon) ?? 0) != 0
            info = try c.decodeIfPresent([String].self, forKey: .info) ?? []
        }

        public func encode(to encoder: any Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(text, forKey: .text)
            if isCommon { try c.encode(1, forKey: .isCommon) }
            if !info.isEmpty { try c.encode(info, forKey: .info) }
        }

        /// Search-only or irregular forms that should not be shown as the headword.
        public var isHidden: Bool { info.contains("sK") }
    }

    public struct Reading: Sendable, Hashable, Codable {
        public var text: String
        public var isCommon: Bool
        /// True reading of the word but not of its kanji forms (`re_nokanji`).
        public var noKanji: Bool
        public var info: [String]
        /// Kanji forms this reading applies to; empty = all.
        public var restrictedTo: [String]

        enum CodingKeys: String, CodingKey { case text = "t", isCommon = "c", noKanji = "nk", info = "i", restrictedTo = "to" }

        public init(text: String, isCommon: Bool = false, noKanji: Bool = false, info: [String] = [],
                    restrictedTo: [String] = []) {
            self.text = text
            self.isCommon = isCommon
            self.noKanji = noKanji
            self.info = info
            self.restrictedTo = restrictedTo
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            text = try c.decode(String.self, forKey: .text)
            isCommon = (try c.decodeIfPresent(Int.self, forKey: .isCommon) ?? 0) != 0
            noKanji = (try c.decodeIfPresent(Int.self, forKey: .noKanji) ?? 0) != 0
            info = try c.decodeIfPresent([String].self, forKey: .info) ?? []
            restrictedTo = try c.decodeIfPresent([String].self, forKey: .restrictedTo) ?? []
        }

        public func encode(to encoder: any Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(text, forKey: .text)
            if isCommon { try c.encode(1, forKey: .isCommon) }
            if noKanji { try c.encode(1, forKey: .noKanji) }
            if !info.isEmpty { try c.encode(info, forKey: .info) }
            if !restrictedTo.isEmpty { try c.encode(restrictedTo, forKey: .restrictedTo) }
        }

        public func applies(to kanji: String) -> Bool {
            !noKanji && (restrictedTo.isEmpty || restrictedTo.contains(kanji))
        }
    }

    public struct Sense: Sendable, Hashable, Codable {
        /// JMdict part-of-speech codes (`v1`, `v5k`, `adj-i`, `n`, …).
        public var partsOfSpeech: [String]
        public var glosses: [String]
        public var misc: [String]
        public var fields: [String]
        public var dialects: [String]
        public var note: String?
        /// Restricted to these kanji forms / readings; empty = all.
        public var onlyKanji: [String]
        public var onlyReadings: [String]

        enum CodingKeys: String, CodingKey {
            case partsOfSpeech = "p", glosses = "g", misc = "m", fields = "f", dialects = "d", note = "n"
            case onlyKanji = "sk", onlyReadings = "sr"
        }

        public init(partsOfSpeech: [String], glosses: [String], misc: [String] = [], fields: [String] = [],
                    dialects: [String] = [], note: String? = nil, onlyKanji: [String] = [], onlyReadings: [String] = []) {
            self.partsOfSpeech = partsOfSpeech
            self.glosses = glosses
            self.misc = misc
            self.fields = fields
            self.dialects = dialects
            self.note = note
            self.onlyKanji = onlyKanji
            self.onlyReadings = onlyReadings
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            partsOfSpeech = try c.decodeIfPresent([String].self, forKey: .partsOfSpeech) ?? []
            glosses = try c.decodeIfPresent([String].self, forKey: .glosses) ?? []
            misc = try c.decodeIfPresent([String].self, forKey: .misc) ?? []
            fields = try c.decodeIfPresent([String].self, forKey: .fields) ?? []
            dialects = try c.decodeIfPresent([String].self, forKey: .dialects) ?? []
            note = try c.decodeIfPresent(String.self, forKey: .note)
            onlyKanji = try c.decodeIfPresent([String].self, forKey: .onlyKanji) ?? []
            onlyReadings = try c.decodeIfPresent([String].self, forKey: .onlyReadings) ?? []
        }

        public func encode(to encoder: any Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(partsOfSpeech, forKey: .partsOfSpeech)
            try c.encode(glosses, forKey: .glosses)
            if !misc.isEmpty { try c.encode(misc, forKey: .misc) }
            if !fields.isEmpty { try c.encode(fields, forKey: .fields) }
            if !dialects.isEmpty { try c.encode(dialects, forKey: .dialects) }
            try c.encodeIfPresent(note, forKey: .note)
            if !onlyKanji.isEmpty { try c.encode(onlyKanji, forKey: .onlyKanji) }
            if !onlyReadings.isEmpty { try c.encode(onlyReadings, forKey: .onlyReadings) }
        }

        /// "usually written using kana alone".
        public var usuallyKana: Bool { misc.contains("uk") }
    }

    public var id: Int
    public var isCommon: Bool
    /// Lower is more frequent (JMdict `nfXX` bucket; 50 for other common words, 99 otherwise).
    public var rank: Int
    public var kanji: [KanjiForm]
    public var readings: [Reading]
    public var senses: [Sense]

    enum CodingKeys: String, CodingKey { case kanji = "k", readings = "r", senses = "s" }

    public init(id: Int, isCommon: Bool = false, rank: Int = 99, kanji: [KanjiForm], readings: [Reading],
                senses: [Sense]) {
        self.id = id
        self.isCommon = isCommon
        self.rank = rank
        self.kanji = kanji
        self.readings = readings
        self.senses = senses
    }

    /// Decodes the `entry.json` column; `id`, `common` and `rank` come from their own columns.
    public init(id: Int, isCommon: Bool, rank: Int, json: Data) throws {
        let body = try JSONDecoder().decode(Body.self, from: json)
        self.init(id: id, isCommon: isCommon, rank: rank, kanji: body.k ?? [], readings: body.r, senses: body.s)
    }

    private struct Body: Decodable {
        var k: [KanjiForm]?
        var r: [Reading]
        var s: [Sense]
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(id: 0, kanji: try c.decodeIfPresent([KanjiForm].self, forKey: .kanji) ?? [],
                  readings: try c.decode([Reading].self, forKey: .readings),
                  senses: try c.decode([Sense].self, forKey: .senses))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(kanji, forKey: .kanji)
        try c.encode(readings, forKey: .readings)
        try c.encode(senses, forKey: .senses)
    }

    /// Readings that apply to `form` (a kanji form), most common first.
    public func readings(for form: String) -> [Reading] {
        readings.filter { $0.applies(to: form) }.sorted { $0.isCommon && !$1.isCommon }
    }

    /// Every part-of-speech code in the entry.
    public var allPartsOfSpeech: Set<String> { Set(senses.flatMap(\.partsOfSpeech)) }
}

/// One KANJIDIC2 character.
public struct KanjiInfo: Sendable, Hashable, Codable {
    public var literal: String
    public var meanings: [String]
    public var onReadings: [String]
    public var kunReadings: [String]
    public var strokes: Int?
    public var grade: Int?
    /// Newspaper frequency rank (1 = most frequent).
    public var frequency: Int?
    /// Old (pre-2010) JLPT level 1–4.
    public var jlpt: Int?

    enum CodingKeys: String, CodingKey {
        case meanings = "m", onReadings = "on", kunReadings = "kun", strokes = "s", grade = "g", frequency = "f", jlpt = "j"
    }

    public init(literal: String, meanings: [String], onReadings: [String] = [], kunReadings: [String] = [],
                strokes: Int? = nil, grade: Int? = nil, frequency: Int? = nil, jlpt: Int? = nil) {
        self.literal = literal
        self.meanings = meanings
        self.onReadings = onReadings
        self.kunReadings = kunReadings
        self.strokes = strokes
        self.grade = grade
        self.frequency = frequency
        self.jlpt = jlpt
    }

    public init(literal: String, json: Data) throws {
        var decoded = try JSONDecoder().decode(KanjiInfo.self, from: json)
        decoded.literal = literal
        self = decoded
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        literal = ""
        meanings = try c.decodeIfPresent([String].self, forKey: .meanings) ?? []
        onReadings = try c.decodeIfPresent([String].self, forKey: .onReadings) ?? []
        kunReadings = try c.decodeIfPresent([String].self, forKey: .kunReadings) ?? []
        strokes = try c.decodeIfPresent(Int.self, forKey: .strokes)
        grade = try c.decodeIfPresent(Int.self, forKey: .grade)
        frequency = try c.decodeIfPresent(Int.self, forKey: .frequency)
        jlpt = try c.decodeIfPresent(Int.self, forKey: .jlpt)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(meanings, forKey: .meanings)
        try c.encode(onReadings, forKey: .onReadings)
        try c.encode(kunReadings, forKey: .kunReadings)
        try c.encodeIfPresent(strokes, forKey: .strokes)
        try c.encodeIfPresent(grade, forKey: .grade)
        try c.encodeIfPresent(frequency, forKey: .frequency)
        try c.encodeIfPresent(jlpt, forKey: .jlpt)
    }
}

/// Read access to the dictionary. Keys are forms with katakana folded to hiragana (`Kana.foldToHiragana`).
public protocol DictionaryStore: Sendable {
    /// Entries having a kanji form or reading equal to `key`, most common first.
    func entries(forKey key: String) -> [DictionaryEntry]
    func kanji(_ literal: Character) -> KanjiInfo?
}

/// Test and preview store.
public struct InMemoryDictionaryStore: DictionaryStore {
    private var byKey: [String: [DictionaryEntry]] = [:]
    private var kanjiByLiteral: [String: KanjiInfo] = [:]

    public init(entries: [DictionaryEntry], kanji: [KanjiInfo] = []) {
        for entry in entries {
            let keys = Set(entry.kanji.map(\.text) + entry.readings.map(\.text)).map(Kana.foldToHiragana)
            for key in Set(keys) { byKey[key, default: []].append(entry) }
        }
        for key in byKey.keys {
            byKey[key]?.sort { ($0.isCommon ? 0 : 1, $0.rank) < ($1.isCommon ? 0 : 1, $1.rank) }
        }
        kanjiByLiteral = Dictionary(kanji.map { ($0.literal, $0) }, uniquingKeysWith: { a, _ in a })
    }

    public func entries(forKey key: String) -> [DictionaryEntry] { byKey[key] ?? [] }
    public func kanji(_ literal: Character) -> KanjiInfo? { kanjiByLiteral[String(literal)] }
}
