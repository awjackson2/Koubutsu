/// A piece of a written word with the reading shown above it (nil for kana, which needs none).
public struct FuriganaSegment: Sendable, Hashable {
    public var text: String
    public var reading: String?

    public init(text: String, reading: String?) {
        self.text = text
        self.reading = reading
    }
}

public enum Furigana {
    /// Splits `written` into kanji and kana runs and places the matching part of `reading` over each kanji
    /// run. Kana runs must appear literally in the reading (katakana/hiragana folded). When no consistent split
    /// exists (irregular readings such as 今日 = きょう are a single run anyway), the whole reading goes over
    /// the whole word.
    public static func align(written: String, reading: String) -> [FuriganaSegment] {
        guard written.contains(where: Kana.isKanji) else { return [FuriganaSegment(text: written, reading: nil)] }
        var runs: [(text: String, isKanji: Bool)] = []
        for ch in written {
            let isKanji = !Kana.isKana(ch)
            if let last = runs.last, last.isKanji == isKanji {
                runs[runs.count - 1].text.append(ch)
            } else {
                runs.append((String(ch), isKanji))
            }
        }
        if let segments = match(runs[...], Array(Kana.foldToHiragana(reading))[...], original: Array(reading)[...]) {
            return segments
        }
        return [FuriganaSegment(text: written, reading: reading)]
    }

    private static func match(_ runs: ArraySlice<(text: String, isKanji: Bool)>, _ folded: ArraySlice<Character>,
                              original: ArraySlice<Character>) -> [FuriganaSegment]? {
        guard let run = runs.first else { return folded.isEmpty ? [] : nil }
        let rest = runs.dropFirst()
        if !run.isKanji {
            let kana = Array(Kana.foldToHiragana(run.text))
            guard folded.starts(with: kana) else { return nil }
            guard let tail = match(rest, folded.dropFirst(kana.count), original: original.dropFirst(kana.count)) else {
                return nil
            }
            return [FuriganaSegment(text: run.text, reading: nil)] + tail
        }
        // A kanji run reads at least one kana; try every split, shortest first.
        let maxLength = rest.isEmpty ? folded.count : folded.count - 1
        guard maxLength >= 1 else { return nil }
        let lengths: [Int] = rest.isEmpty ? [folded.count] : Array(1...maxLength)
        for length in lengths {
            if let tail = match(rest, folded.dropFirst(length), original: original.dropFirst(length)) {
                return [FuriganaSegment(text: run.text, reading: String(original.prefix(length)))] + tail
            }
        }
        return nil
    }
}

/// Kana → romaji (modified Hepburn, long vowels spelled out: おう → ou, ー repeats the vowel).
public enum Romaji {
    static let digraphs: [String: String] = [
        "きゃ": "kya", "きゅ": "kyu", "きょ": "kyo", "しゃ": "sha", "しゅ": "shu", "しょ": "sho", "しぇ": "she",
        "ちゃ": "cha", "ちゅ": "chu", "ちょ": "cho", "ちぇ": "che", "にゃ": "nya", "にゅ": "nyu", "にょ": "nyo",
        "ひゃ": "hya", "ひゅ": "hyu", "ひょ": "hyo", "みゃ": "mya", "みゅ": "myu", "みょ": "myo",
        "りゃ": "rya", "りゅ": "ryu", "りょ": "ryo", "ぎゃ": "gya", "ぎゅ": "gyu", "ぎょ": "gyo",
        "じゃ": "ja", "じゅ": "ju", "じょ": "jo", "じぇ": "je", "ぢゃ": "ja", "ぢゅ": "ju", "ぢょ": "jo",
        "びゃ": "bya", "びゅ": "byu", "びょ": "byo", "ぴゃ": "pya", "ぴゅ": "pyu", "ぴょ": "pyo",
        "ふぁ": "fa", "ふぃ": "fi", "ふぇ": "fe", "ふぉ": "fo", "てぃ": "ti", "でぃ": "di", "とぅ": "tu", "どぅ": "du",
        "うぃ": "wi", "うぇ": "we", "うぉ": "wo", "ゔぁ": "va", "ゔぃ": "vi", "ゔぇ": "ve", "ゔぉ": "vo",
        "つぁ": "tsa", "つぃ": "tsi", "つぇ": "tse", "つぉ": "tso", "いぇ": "ye",
    ]
    static let monographs: [Character: String] = [
        "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o", "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
        "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so", "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
        "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no", "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
        "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo", "や": "ya", "ゆ": "yu", "よ": "yo",
        "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro", "わ": "wa", "ゐ": "i", "ゑ": "e", "を": "o", "ん": "n",
        "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go", "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
        "だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do", "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
        "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po", "ゔ": "vu",
        "ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o", "ゃ": "ya", "ゅ": "yu", "ょ": "yo", "ゎ": "wa",
    ]

    public static func hepburn(_ kana: String) -> String {
        let chars = Array(Kana.foldToHiragana(kana))
        var out = ""
        var geminate = false
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            if ch == "っ" {
                geminate = true
                i += 1
                continue
            }
            if ch == "ー" {
                if let vowel = out.last(where: { "aeiou".contains($0) }) { out.append(vowel) }
                i += 1
                continue
            }
            var syllable: String?
            if i + 1 < chars.count, let pair = digraphs[String([ch, chars[i + 1]])] {
                syllable = pair
                i += 2
            } else if let single = monographs[ch] {
                syllable = single
                i += 1
            } else {
                out.append(ch)
                i += 1
                geminate = false
                continue
            }
            guard var s = syllable else { continue }
            if s == "n", i < chars.count, let next = monographs[chars[i]] ?? nil, "aeiouy".contains(next.first!) {
                s = "n'"
            }
            if geminate {
                s = (s.hasPrefix("ch") ? "t" : String(s.first!)) + s
                geminate = false
            }
            out += s
        }
        if geminate { out += "'" }
        return out
    }
}

/// Plain-English names for JMdict codes.
public enum DictionaryLabels {
    static let partsOfSpeech: [String: String] = [
        "n": "noun", "n-adv": "adverbial noun", "n-t": "temporal noun", "n-suf": "noun suffix", "n-pref": "noun prefix",
        "pn": "pronoun", "adj-i": "i-adjective", "adj-ix": "i-adjective (いい/よい)", "adj-na": "na-adjective",
        "adj-no": "no-adjective", "adj-pn": "pre-noun adjectival", "adj-t": "taru adjective", "adj-f": "prenominal",
        "adv": "adverb", "adv-to": "adverb (と)", "aux": "auxiliary", "aux-v": "auxiliary verb", "aux-adj": "auxiliary adjective",
        "conj": "conjunction", "cop": "copula", "ctr": "counter", "exp": "expression", "int": "interjection",
        "num": "numeric", "pref": "prefix", "suf": "suffix", "prt": "particle",
        "v1": "ichidan verb", "v1-s": "ichidan verb (くれる)", "v5aru": "godan verb (-aru)", "v5b": "godan verb (ぶ)",
        "v5g": "godan verb (ぐ)", "v5k": "godan verb (く)", "v5k-s": "godan verb (行く)", "v5m": "godan verb (む)",
        "v5n": "godan verb (ぬ)", "v5r": "godan verb (る)", "v5r-i": "godan verb (irregular る)", "v5s": "godan verb (す)",
        "v5t": "godan verb (つ)", "v5u": "godan verb (う)", "v5u-s": "godan verb (special う)", "vk": "kuru verb",
        "vs": "suru verb", "vs-i": "suru verb (irregular)", "vs-s": "suru verb (special)", "vz": "zuru verb",
        "vi": "intransitive", "vt": "transitive",
    ]
    static let misc: [String: String] = [
        "uk": "usually kana", "abbr": "abbreviation", "col": "colloquial", "hon": "honorific", "hum": "humble",
        "pol": "polite", "sl": "slang", "arch": "archaic", "obs": "obsolete", "obsc": "obscure", "sens": "sensitive",
        "vulg": "vulgar", "derog": "derogatory", "fam": "familiar", "fem": "female", "male": "male", "joc": "jocular",
        "id": "idiom", "on-mim": "onomatopoeia", "poet": "poetic", "rare": "rare", "chn": "children's", "yoji": "four-character idiom",
        "proverb": "proverb", "form": "formal", "euph": "euphemism", "dated": "dated", "hist": "historical",
        "net-sl": "internet slang", "X": "rude", "rK": "rare kanji", "ateji": "ateji", "iK": "irregular kanji",
        "ik": "irregular kana", "oK": "old kanji", "ok": "old kana", "sK": "search-only", "gikun": "gikun",
    ]

    public static func partOfSpeech(_ code: String) -> String { partsOfSpeech[code] ?? code }
    public static func label(_ code: String) -> String { misc[code] ?? code }
}
