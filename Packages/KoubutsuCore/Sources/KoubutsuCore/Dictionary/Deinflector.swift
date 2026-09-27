/// Grammatical word classes used by de-inflection. Terminal classes correspond to JMdict parts of speech;
/// intermediate ones (polite, past, te) only chain rules and never match an entry directly.
public struct WordType: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }

    public static let ichidan = WordType(rawValue: 1 << 0)
    public static let godan = WordType(rawValue: 1 << 1)
    public static let kuru = WordType(rawValue: 1 << 2)
    public static let suru = WordType(rawValue: 1 << 3)
    /// A noun that takes する (JMdict `vs`).
    public static let suruNoun = WordType(rawValue: 1 << 4)
    public static let adjectiveI = WordType(rawValue: 1 << 5)
    static let polite = WordType(rawValue: 1 << 8)
    static let past = WordType(rawValue: 1 << 9)
    static let te = WordType(rawValue: 1 << 10)

    public static let verb: WordType = [.ichidan, .godan, .kuru, .suru]
    public static let terminal: WordType = [.verb, .suruNoun, .adjectiveI]
    static let any = WordType(rawValue: .max)

    /// Word types of a dictionary entry's JMdict part-of-speech codes.
    public static func of(partsOfSpeech: some Sequence<String>) -> WordType {
        var result: WordType = []
        for pos in partsOfSpeech {
            if pos == "v1" || pos == "v1-s" { result.insert(.ichidan) }
            else if pos.hasPrefix("v5") { result.insert(.godan) }
            else if pos == "vk" { result.insert(.kuru) }
            else if pos == "vs-i" || pos == "vs-s" { result.insert(.suru) }
            else if pos == "vs" { result.insert(.suruNoun) }
            else if pos == "adj-i" || pos == "adj-ix" { result.insert(.adjectiveI) }
        }
        return result
    }
}

/// One way a form could have been produced from a dictionary form.
public struct Deinflection: Sendable, Hashable {
    /// Candidate dictionary form.
    public var term: String
    /// Types the candidate must have; `nil` for the unmodified input (any entry matches).
    public var types: WordType?
    /// Transformations from the dictionary form to the input, outermost last (e.g. ["causative", "passive", "past"]).
    public var reasons: [String]
    /// Characters of inflected suffix the rules matched; more specific rules (行った → 行く) beat general
    /// ones (った → う) when both apply.
    public var specificity: Int

    public init(term: String, types: WordType?, reasons: [String], specificity: Int = 0) {
        self.term = term
        self.types = types
        self.reasons = reasons
        self.specificity = specificity
    }

    /// Whether an entry with `entryTypes` can be this candidate.
    public func accepts(_ entryTypes: WordType) -> Bool {
        guard let types else { return true }
        return !types.intersection(entryTypes).intersection(.terminal).isEmpty
    }
}

/// Undoes Japanese conjugation by suffix rules applied recursively (Yomitan-style). Rules are written as
/// inflected suffix → dictionary suffix, with the word type the inflected form must have (`from`) and the type
/// of the result (`to`).
public struct Deinflector: Sendable {
    struct Rule: Sendable {
        var inflected: String
        var base: String
        var from: WordType
        var to: WordType
        var reason: String
    }

    let rulesBySuffix: [String: [Rule]]
    let longestSuffix: Int
    public var maximumDepth = 6

    public init() {
        let rules = Self.makeRules()
        rulesBySuffix = Dictionary(grouping: rules, by: \.inflected)
        longestSuffix = rules.map(\.inflected.count).max() ?? 0
    }

    public func deinflect(_ source: String) -> [Deinflection] {
        var results = [Deinflection(term: source, types: nil, reasons: [])]
        var seen: Set<String> = []
        var index = 0
        while index < results.count {
            let current = results[index]
            index += 1
            guard current.reasons.count < maximumDepth else { continue }
            let mask = current.types ?? .any
            for length in stride(from: min(longestSuffix, current.term.count), through: 1, by: -1) {
                guard let rules = rulesBySuffix[String(current.term.suffix(length))] else { continue }
                for rule in rules where !rule.from.intersection(mask).isEmpty {
                    let term = String(current.term.dropLast(length)) + rule.base
                    guard !term.isEmpty else { continue }
                    let key = "\(term)|\(rule.to.rawValue)|\(current.reasons.count)"
                    guard seen.insert(key).inserted else { continue }
                    results.append(Deinflection(term: term, types: rule.to, reasons: [rule.reason] + current.reasons,
                                                specificity: current.specificity + length))
                }
            }
        }
        return results
    }

    // MARK: - Rules

    /// Godan dictionary endings and their a/i/e/o-row forms.
    static let godanRows: [(u: String, a: String, i: String, e: String, o: String)] = [
        ("う", "わ", "い", "え", "お"), ("く", "か", "き", "け", "こ"), ("ぐ", "が", "ぎ", "げ", "ご"),
        ("す", "さ", "し", "せ", "そ"), ("つ", "た", "ち", "て", "と"), ("ぬ", "な", "に", "ね", "の"),
        ("ぶ", "ば", "び", "べ", "ぼ"), ("む", "ま", "み", "め", "も"), ("る", "ら", "り", "れ", "ろ"),
    ]

    /// Godan past/te stems: う/つ/る → っ, く → い, ぐ → い(voiced), す → し, ぬ/ぶ/む → ん.
    static let godanOnbin: [(u: String, stem: String, voiced: Bool)] = [
        ("う", "っ", false), ("つ", "っ", false), ("る", "っ", false), ("く", "い", false), ("ぐ", "い", true),
        ("す", "し", false), ("ぬ", "ん", true), ("ぶ", "ん", true), ("む", "ん", true),
    ]

    static func makeRules() -> [Rule] {
        var rules: [Rule] = []
        func add(_ inflected: String, _ base: String, _ from: WordType, _ to: WordType, _ reason: String) {
            rules.append(Rule(inflected: inflected, base: base, from: from, to: to, reason: reason))
        }
        /// Adds a rule for every verb class given the ichidan/godan-row/kuru/suru forms of one suffix.
        func verbForms(ichidan: String?, godanRow: KeyPath<(u: String, a: String, i: String, e: String, o: String), String>?,
                       godanSuffix: String, kuru: [String], suru: [String], from: WordType, reason: String) {
            if let ichidan { add(ichidan, "る", from, .ichidan, reason) }
            if let godanRow {
                for row in godanRows { add(row[keyPath: godanRow] + godanSuffix, row.u, from, .godan, reason) }
            }
            for form in kuru {
                add(form, "くる", from, .kuru, reason)
                add("来" + form.dropFirst(), "来る", from, .kuru, reason)
            }
            for form in suru { add(form, "する", from, .suru, reason) }
        }

        // Polite ます family → ます (chains to the stem rules below).
        for (form, reason) in [("ました", "polite past"), ("ません", "polite negative"),
                               ("ませんでした", "polite past negative"), ("ましょう", "polite volitional"),
                               ("まして", "polite te-form"), ("ますれば", "polite conditional")] {
            add(form, "ます", .any, .polite, reason)
        }
        verbForms(ichidan: "ます", godanRow: \.i, godanSuffix: "ます", kuru: ["きます"], suru: ["します"],
                  from: [.polite], reason: "polite")
        // Past and te: ichidan, godan (onbin), kuru, suru, 行く, adjectives.
        add("た", "る", .any, .ichidan, "past")
        add("て", "る", .any, .ichidan, "te-form")
        for row in godanOnbin {
            add(row.stem + (row.voiced ? "だ" : "た"), row.u, .any, .godan, "past")
            add(row.stem + (row.voiced ? "で" : "て"), row.u, .any, .godan, "te-form")
        }
        for (form, base) in [("いった", "いく"), ("行った", "行く")] { add(form, base, .any, .godan, "past") }
        for (form, base) in [("いって", "いく"), ("行って", "行く")] { add(form, base, .any, .godan, "te-form") }
        for (form, base) in [("きた", "くる"), ("来た", "来る")] { add(form, base, .any, .kuru, "past") }
        for (form, base) in [("きて", "くる"), ("来て", "来る")] { add(form, base, .any, .kuru, "te-form") }
        add("した", "する", .any, .suru, "past")
        add("して", "する", .any, .suru, "te-form")
        add("かった", "い", .any, .adjectiveI, "past")
        add("くて", "い", .any, .adjectiveI, "te-form")
        // たら / ば.
        for rule in rules where rule.reason == "past" {
            add(String(rule.inflected.dropLast()) + (rule.inflected.hasSuffix("だ") ? "だら" : "たら"), rule.base,
                .any, rule.to, "conditional (-tara)")
        }
        verbForms(ichidan: "れば", godanRow: \.e, godanSuffix: "ば", kuru: ["くれば"], suru: ["すれば"],
                  from: .any, reason: "conditional")
        add("ければ", "い", .any, .adjectiveI, "conditional")
        // Negative: forms end in ない, which conjugates like an i-adjective.
        verbForms(ichidan: "ない", godanRow: \.a, godanSuffix: "ない", kuru: ["こない"], suru: ["しない"],
                  from: [.any], reason: "negative")
        add("くない", "い", .any, .adjectiveI, "negative")
        verbForms(ichidan: "ず", godanRow: \.a, godanSuffix: "ず", kuru: ["こず"], suru: ["せず"],
                  from: .any, reason: "negative (-zu)")
        verbForms(ichidan: "ずに", godanRow: \.a, godanSuffix: "ずに", kuru: ["こずに"], suru: ["せずに"],
                  from: .any, reason: "without doing")
        // -たい (adjective-like).
        verbForms(ichidan: "たい", godanRow: \.i, godanSuffix: "たい", kuru: ["きたい"], suru: ["したい"],
                  from: .any, reason: "want to")
        // Potential (godan → ichidan-like), passive, causative (results conjugate as ichidan).
        for row in godanRows { add(row.e + "る", row.u, .ichidan, .godan, "potential") }
        add("れる", "る", .ichidan, .ichidan, "potential")
        add("こられる", "くる", .ichidan, .kuru, "potential or passive")
        add("来られる", "来る", .ichidan, .kuru, "potential or passive")
        add("できる", "する", .ichidan, .suru, "potential")
        add("られる", "る", .ichidan, .ichidan, "passive or potential")
        for row in godanRows { add(row.a + "れる", row.u, .ichidan, .godan, "passive") }
        add("される", "する", .ichidan, .suru, "passive")
        add("させる", "る", .ichidan, .ichidan, "causative")
        for row in godanRows { add(row.a + "せる", row.u, .ichidan, .godan, "causative") }
        add("こさせる", "くる", .ichidan, .kuru, "causative")
        add("来させる", "来る", .ichidan, .kuru, "causative")
        add("させる", "する", .ichidan, .suru, "causative")
        for row in godanRows where row.u != "す" { add(row.a + "される", row.u, .ichidan, .godan, "causative passive") }
        // Volitional, imperative.
        verbForms(ichidan: "よう", godanRow: \.o, godanSuffix: "う", kuru: ["こよう"], suru: ["しよう"],
                  from: .any, reason: "volitional")
        verbForms(ichidan: "ろ", godanRow: \.e, godanSuffix: "", kuru: ["こい"], suru: ["しろ", "せよ"],
                  from: .any, reason: "imperative")
        add("よ", "る", .any, .ichidan, "imperative")
        verbForms(ichidan: "なさい", godanRow: \.i, godanSuffix: "なさい", kuru: ["きなさい"], suru: ["しなさい"],
                  from: .any, reason: "polite imperative")
        // Auxiliaries after て: いる/おく/しまう/くる/いく/ください, contractions.
        for te in ["て", "で"] {
            add(te + "いる", te, .ichidan, .te, "progressive")
            add(te + "る", te, .ichidan, .te, "progressive (-teru)")
            add(te + "おく", te, .godan, .te, "in advance (-teoku)")
            add(te + "しまう", te, .godan, .te, "completely (-teshimau)")
            add(te + "ください", te, .any, .te, "request")
        }
        // Contractions go straight back to the te-form.
        for (contracted, te, reason) in [("とく", "て", "in advance (-toku)"), ("どく", "で", "in advance (-toku)"),
                                         ("ちゃう", "て", "completely (-chau)"), ("じゃう", "で", "completely (-chau)")] {
            add(contracted, te, .godan, .te, reason)
        }
        // i-adjectives.
        add("く", "い", .any, .adjectiveI, "adverbial")
        add("さ", "い", .any, .adjectiveI, "noun (-sa)")
        add("そう", "い", .any, .adjectiveI, "looks like (-sou)")
        add("すぎる", "い", .ichidan, .adjectiveI, "too (-sugiru)")
        verbForms(ichidan: "すぎる", godanRow: \.i, godanSuffix: "すぎる", kuru: ["きすぎる"], suru: ["しすぎる"],
                  from: .ichidan, reason: "too much (-sugiru)")
        // Noun + する.
        add("する", "", .suru, .suruNoun, "suru verb")
        // Masu stem (compounds, ～方, ～に行く).
        verbForms(ichidan: nil, godanRow: \.i, godanSuffix: "", kuru: [], suru: [], from: .any, reason: "masu stem")
        return rules.filter { !$0.inflected.isEmpty }
    }
}
