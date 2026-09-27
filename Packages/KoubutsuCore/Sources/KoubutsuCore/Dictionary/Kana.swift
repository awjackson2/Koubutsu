/// Kana utilities for lookup and display.
public enum Kana {
    /// Katakana → hiragana (ァ…ヶ); everything else unchanged. Dictionary keys use this form.
    public static func foldToHiragana(_ text: String) -> String {
        String(String.UnicodeScalarView(text.unicodeScalars.map { scalar in
            (0x30A1...0x30F6).contains(scalar.value) ? Unicode.Scalar(scalar.value - 0x60)! : scalar
        }))
    }

    /// Hiragana → katakana.
    public static func toKatakana(_ text: String) -> String {
        String(String.UnicodeScalarView(text.unicodeScalars.map { scalar in
            (0x3041...0x3096).contains(scalar.value) ? Unicode.Scalar(scalar.value + 0x60)! : scalar
        }))
    }

    public static func isKana(_ ch: Character) -> Bool {
        guard let v = ch.unicodeScalars.first?.value else { return false }
        return (0x3041...0x309F).contains(v) || (0x30A0...0x30FF).contains(v) || v == 0x30FC
    }

    public static func isKanji(_ ch: Character) -> Bool {
        guard let v = ch.unicodeScalars.first?.value else { return false }
        return (0x4E00...0x9FFF).contains(v) || (0x3400...0x4DBF).contains(v) || v == 0x3005 // 々
    }
}
