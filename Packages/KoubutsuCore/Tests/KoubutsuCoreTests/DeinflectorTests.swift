import Testing
@testable import KoubutsuCore

struct DeinflectorTests {
    let deinflector = Deinflector()

    /// The chain producing `base` with the given type, if any.
    func reasons(_ form: String, _ base: String, _ type: WordType) -> [String]? {
        deinflector.deinflect(form).filter { $0.term == base && $0.accepts(type) }
            .min { $0.reasons.count < $1.reasons.count }?.reasons
    }

    @Test(arguments: [
        ("食べました", "食べる", WordType.ichidan, ["polite", "polite past"]),
        ("食べさせられた", "食べる", .ichidan, ["causative", "passive or potential", "past"]),
        ("食べなかった", "食べる", .ichidan, ["negative", "past"]),
        ("食べている", "食べる", .ichidan, ["te-form", "progressive"]),
        ("食べてる", "食べる", .ichidan, ["te-form", "progressive (-teru)"]),
        ("食べちゃった", "食べる", .ichidan, ["te-form", "completely (-chau)", "past"]),
        ("食べたい", "食べる", .ichidan, ["want to"]),
        ("食べよう", "食べる", .ichidan, ["volitional"]),
        ("食べれば", "食べる", .ichidan, ["conditional"]),
        ("食べたら", "食べる", .ichidan, ["conditional (-tara)"]),
        ("行った", "行く", .godan, ["past"]),
        ("読んで", "読む", .godan, ["te-form"]),
        ("書かなかった", "書く", .godan, ["negative", "past"]),
        ("泳いだ", "泳ぐ", .godan, ["past"]),
        ("待って", "待つ", .godan, ["te-form"]),
        ("死んだ", "死ぬ", .godan, ["past"]),
        ("話します", "話す", .godan, ["polite"]),
        ("言われた", "言う", .godan, ["passive", "past"]),
        ("読める", "読む", .godan, ["potential"]),
        ("行こう", "行く", .godan, ["volitional"]),
        ("書かされた", "書く", .godan, ["causative passive", "past"]),
        ("来なかった", "来る", .kuru, ["negative", "past"]),
        ("きます", "くる", .kuru, ["polite"]),
        ("しない", "する", .suru, ["negative"]),
        ("勉強した", "勉強", .suruNoun, ["suru verb", "past"]),
        ("強くない", "強い", .adjectiveI, ["negative"]),
        ("高かった", "高い", .adjectiveI, ["past"]),
        ("強く", "強い", .adjectiveI, ["adverbial"]),
        ("待ってください", "待つ", .godan, ["te-form", "request"]),
    ])
    func deinflects(_ form: String, _ base: String, _ type: WordType, _ expected: [String]) {
        #expect(reasons(form, base, type) == expected, "\(form) → \(deinflector.deinflect(form).map { "\($0.term) \($0.reasons)" }.prefix(40))")
    }

    @Test func unmodifiedInputAcceptsAnyEntry() {
        let first = deinflector.deinflect("敵").first
        #expect(first?.term == "敵" && first?.types == nil && first?.accepts([]) == true)
    }

    @Test func wrongTypeRejected() {
        // 高かった is not an ichidan verb 高かる / 高かっる.
        #expect(reasons("高かった", "高かる", .ichidan) == nil)
    }

    @Test func partsOfSpeechMapping() {
        #expect(WordType.of(partsOfSpeech: ["v5k-s", "vi"]) == .godan)
        #expect(WordType.of(partsOfSpeech: ["n", "vs"]) == .suruNoun)
        #expect(WordType.of(partsOfSpeech: ["adj-ix"]) == .adjectiveI)
        #expect(WordType.of(partsOfSpeech: ["n"]).isEmpty)
    }
}
