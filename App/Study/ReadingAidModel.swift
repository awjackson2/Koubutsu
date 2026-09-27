import KoubutsuCore
import Observation

/// Furigana and learning highlights for recognized lines, computed off the main actor and cached per line
/// text (lines repeat every OCR result while they stay on screen).
@MainActor
@Observable
final class ReadingAidModel {
    private(set) var annotations: [String: [ReadingAnnotation]] = [:]
    @ObservationIgnored private var pending: Set<String> = []
    @ObservationIgnored private var vocabulary: (known: Set<String>, learning: Set<String>) = ([], [])
    @ObservationIgnored private let cacheLimit = 400

    /// Saving or marking a word changes every line's annotations. Call outside view updates.
    func setVocabulary(known: Set<String>, learning: Set<String>) {
        guard known != vocabulary.known || learning != vocabulary.learning else { return }
        vocabulary = (known, learning)
        annotations.removeAll()
    }

    /// Cached annotations for `line`, scheduling the computation if needed. Safe to call from a view body:
    /// it only reads observed state; the result is published later.
    func annotations(for line: String, lookup: DictionaryLookup?) -> [ReadingAnnotation]? {
        if let cached = annotations[line] { return cached }
        guard let lookup, !pending.contains(line), TextNormalizer.containsJapaneseText(line) else { return nil }
        pending.insert(line)
        let (known, learning) = vocabulary
        Task {
            let computed = await Task.detached(priority: .utility) {
                ReadingAid.annotations(tokens: lookup.segment(line), known: known, learning: learning)
            }.value
            pending.remove(line)
            guard known == vocabulary.known, learning == vocabulary.learning else { return }
            if annotations.count >= cacheLimit { annotations.removeAll() }
            annotations[line] = computed
        }
        return nil
    }
}
