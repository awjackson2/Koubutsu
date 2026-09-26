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
        String(display(text).filter { !$0.isWhitespace && !isDecoration($0) })
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
