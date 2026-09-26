import Foundation

/// Japanese-aware text normalization and similarity for OCR output.
///
/// Two forms:
/// - `display(_:)` — canonical text for showing and translating: compatibility-normalized (full/half width
///   folded, e.g. half-width katakana → full-width, full-width ASCII → ASCII), whitespace collapsed.
/// - `key(_:)` — comparison/cache key: `display` plus removal of all whitespace and of decorative glyphs
///   games draw next to text (advance arrows, cursors, bullets) that OCR sometimes picks up.
public enum TextNormalizer {
    public static func display(_ text: String) -> String {
        let compat = text.precomposedStringWithCompatibilityMapping
        var out = ""
        out.reserveCapacity(compat.count)
        var pendingSpace = false
        for ch in compat {
            if ch.isWhitespace || ch.isNewline {
                pendingSpace = !out.isEmpty
                continue
            }
            if pendingSpace {
                // Keep a space only between two non-Japanese characters (e.g. Latin words).
                if let last = out.last, !isJapanese(last), !isJapanese(ch) { out.append(" ") }
                pendingSpace = false
            }
            out.append(ch)
        }
        return out
    }

    public static func key(_ text: String) -> String {
        var key = String(display(text).filter { !$0.isWhitespace && !isDecoration($0) })
        // OCR often reads a Japanese ellipsis 「…」 as a run of middle dots 「・・」.
        while let range = key.range(of: "・・") {
            var end = range.upperBound
            while end < key.endIndex, key[end] == "・" { end = key.index(after: end) }
            key.replaceSubrange(range.lowerBound..<end, with: "...")
        }
        return key
    }

    /// Characters games draw as UI decoration rather than text.
    public static func isDecoration(_ ch: Character) -> Bool {
        guard let scalar = ch.unicodeScalars.first else { return false }
        switch scalar.value {
        case 0x25A0...0x25FF: return true // Geometric shapes: ▶ ▼ ◆ ● ■ □ ○ ◇ △ ▽
        case 0x2190...0x21FF: return true // Arrows
        case 0x2605, 0x2606: return true // ★ ☆
        default: return false
        }
    }

    public static func isJapanese(_ ch: Character) -> Bool {
        guard let v = ch.unicodeScalars.first?.value else { return false }
        return (0x3040...0x30FF).contains(v)      // hiragana, katakana
            || (0x3400...0x4DBF).contains(v)      // CJK ext A
            || (0x4E00...0x9FFF).contains(v)      // CJK unified
            || (0x3000...0x303F).contains(v)      // CJK punctuation 。、「」
            || (0xFF00...0xFFEF).contains(v)      // full-width forms (after NFKC mostly folded)
            || (0x31F0...0x31FF).contains(v)      // katakana phonetic extensions
    }

    /// True when the text has at least one kana or kanji (punctuation and full-width forms alone do not count).
    /// Latin/digit OCR junk (e.g. another script misread) has nothing to translate or replace.
    public static func containsJapaneseText(_ text: String) -> Bool {
        text.unicodeScalars.contains {
            (0x3040...0x30FF).contains($0.value) && $0.value != 0x30FB && $0.value != 0x30FC // kana, not ・ ー
                || (0x3400...0x4DBF).contains($0.value) || (0x4E00...0x9FFF).contains($0.value)
                || (0x31F0...0x31FF).contains($0.value) || (0xFF66...0xFF9D).contains($0.value)
        }
    }

    /// A list-item marker at the start of a line.
    public enum ListMarker: Sendable, Hashable {
        /// `1.` `2)` `(3)` `④`. `strict` is false when the number runs into a digit (`8.3.5mm`), which could
        /// also be a decimal; callers accept it only when it continues a sequence.
        case numbered(Int, strict: Bool)
        case bullet
    }

    public static func listMarker(_ text: String) -> ListMarker? {
        // Circled numbers fold to plain digits under compatibility mapping, so check them on the raw text.
        let raw = text.drop { $0.isWhitespace }
        if let scalar = raw.first?.unicodeScalars.first, (0x2460...0x2473).contains(scalar.value), raw.count > 1 {
            return .numbered(Int(scalar.value - 0x2460) + 1, strict: true) // ① … ⑳
        }
        let chars = Array(display(text))
        guard let first = chars.first else { return nil }
        if "・●■◆※-".contains(first) {
            // 「・・・」 is an ellipsis, not a bullet.
            guard chars.count > 1, !"・.…".contains(chars[1]) else { return nil }
            return .bullet
        }
        var index = 0
        let parenthesized = first == "(" || first == "（"
        if parenthesized { index = 1 }
        var digits = ""
        while index < chars.count, digits.count < 3, let d = chars[index].wholeNumberValue, chars[index].isASCII {
            digits.append(String(d))
            index += 1
        }
        guard !digits.isEmpty, digits.count <= 2, let number = Int(digits), index < chars.count else { return nil }
        let terminator = chars[index]
        if parenthesized {
            guard terminator == ")" || terminator == "）", index + 1 < chars.count else { return nil }
            return .numbered(number, strict: true)
        }
        guard ".)．、".contains(terminator), index + 1 < chars.count else { return nil }
        let next = chars[index + 1]
        return .numbered(number, strict: next.wholeNumberValue == nil)
    }

    /// Levenshtein edit distance over grapheme clusters.
    public static func editDistance(_ a: String, _ b: String) -> Int {
        let x = Array(a), y = Array(b)
        if x.isEmpty { return y.count }
        if y.isEmpty { return x.count }
        var previous = Array(0...y.count)
        var current = [Int](repeating: 0, count: y.count + 1)
        for i in 1...x.count {
            current[0] = i
            for j in 1...y.count {
                let cost = x[i - 1] == y[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            }
            swap(&previous, &current)
        }
        return previous[y.count]
    }

    /// 1 - normalized edit distance of the comparison keys, in 0...1 (1 = identical).
    public static func similarity(_ a: String, _ b: String) -> Double {
        let ka = key(a), kb = key(b)
        let longest = max(ka.count, kb.count)
        guard longest > 0 else { return 1 }
        return 1 - Double(editDistance(ka, kb)) / Double(longest)
    }

    /// True when `newer` extends `older` (typewriter reveal): `older`'s key is a proper prefix of `newer`'s,
    /// allowing a small number of OCR errors in the shared part.
    public static func isGrowth(from older: String, to newer: String, tolerance: Int = 1) -> Bool {
        let ko = key(older), kn = key(newer)
        guard !ko.isEmpty, kn.count > ko.count else { return false }
        let head = String(kn.prefix(ko.count))
        return editDistance(head, ko) <= min(tolerance, ko.count / 4)
    }

    /// Character accuracy of `recognized` against `expected` (1 - CER, floored at 0), on comparison keys.
    public static func characterAccuracy(expected: String, recognized: String) -> Double {
        let ke = key(expected)
        guard !ke.isEmpty else { return key(recognized).isEmpty ? 1 : 0 }
        return max(0, 1 - Double(editDistance(ke, key(recognized))) / Double(ke.count))
    }
}
