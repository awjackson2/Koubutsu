import KoubutsuCore
import SwiftUI
import UIKit

/// What a word card shows: the matches at the tapped position and the sentence they came from.
struct WordCardContent: Identifiable {
    let id = UUID()
    var results: [LookupResult]
    var sentence: String?
    var sentenceTranslation: String?
}

/// Everything about one looked-up word: furigana, reading, romaji, conjugation, senses, kanji, the sentence.
struct WordCardView: View {
    let content: WordCardContent
    let store: (any DictionaryStore)?
    var onSave: ((LookupResult) -> Void)?
    var isSaved: (LookupResult) -> Bool = { _ in false }

    @State private var index = 0
    @State private var showingSystemDictionary = false
    @Environment(\.dismiss) private var dismiss

    private var result: LookupResult { content.results[min(index, content.results.count - 1)] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if !result.reasons.isEmpty { conjugation }
                    senses
                    otherForms
                    kanjiSection
                    if let sentence = content.sentence { sentenceSection(sentence) }
                    if content.results.count > 1 { otherMatches }
                    Text("JMdict / KANJIDIC2 — EDRDG, CC BY-SA 4.0").font(.caption2).foregroundStyle(.tertiary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(result.headword)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                if let onSave {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            onSave(result)
                        } label: {
                            Label(isSaved(result) ? "Saved" : "Save", systemImage: isSaved(result) ? "bookmark.fill" : "bookmark")
                        }
                        .disabled(isSaved(result))
                    }
                }
            }
            .sheet(isPresented: $showingSystemDictionary) {
                SystemDictionaryView(term: result.headword)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            FuriganaText(segments: Furigana.align(written: result.headword, reading: result.reading), size: 44)
            HStack(spacing: 12) {
                Text(result.reading).font(.title3)
                Text(Romaji.hepburn(result.reading)).font(.title3).foregroundStyle(.secondary)
                if result.entry.isCommon { tag("common", .green) }
            }
            HStack(spacing: 12) {
                Button { Speaker.shared.speak(result.reading) } label: { Label("Listen", systemImage: "speaker.wave.2") }
                Button { showingSystemDictionary = true } label: { Label("iPad dictionary", systemImage: "character.book.closed") }
                Button { UIPasteboard.general.string = result.headword } label: { Label("Copy", systemImage: "doc.on.doc") }
            }
            .buttonStyle(.bordered)
        }
    }

    private var conjugation: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle("Conjugation")
            Text("\(result.matched) = \(result.dictionaryForm) · " + result.reasons.joined(separator: " → "))
        }
    }

    private var senses: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Meanings")
            ForEach(Array(result.entry.senses.enumerated()), id: \.offset) { number, sense in
                VStack(alignment: .leading, spacing: 3) {
                    let labels = sense.partsOfSpeech.map(DictionaryLabels.partOfSpeech)
                        + (sense.misc + sense.fields + sense.dialects).map(DictionaryLabels.label)
                    if !labels.isEmpty {
                        Text(labels.joined(separator: " · ")).font(.caption).foregroundStyle(.cyan)
                    }
                    Text("\(number + 1). " + sense.glosses.joined(separator: "; ")).font(.body)
                    if let note = sense.note { Text(note).font(.caption).foregroundStyle(.secondary) }
                }
            }
        }
    }

    @ViewBuilder private var otherForms: some View {
        let kanji = result.entry.kanji.filter { !$0.isHidden && $0.text != result.headword }.map(\.text)
        let readings = result.entry.readings.map(\.text).filter { $0 != result.reading }
        if !kanji.isEmpty || !readings.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                sectionTitle("Other forms")
                Text((kanji + readings).joined(separator: "、")).font(.body)
            }
        }
    }

    @ViewBuilder private var kanjiSection: some View {
        let infos = result.headword.filter(Kana.isKanji).compactMap { store?.kanji($0) }
        if !infos.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Kanji")
                ForEach(infos, id: \.literal) { info in
                    HStack(alignment: .top, spacing: 14) {
                        Text(info.literal).font(.system(size: 44))
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(info.meanings.prefix(5).joined(separator: ", ")).font(.body.weight(.semibold))
                            if !info.onReadings.isEmpty { Text("On: " + info.onReadings.joined(separator: "、")).font(.callout) }
                            if !info.kunReadings.isEmpty { Text("Kun: " + info.kunReadings.joined(separator: "、")).font(.callout) }
                            Text(kanjiFacts(info)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func sentenceSection(_ sentence: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle("Sentence")
            Text(highlighted(sentence)).font(.title3).textSelection(.enabled)
            if let translation = content.sentenceTranslation {
                Text(translation).foregroundStyle(.secondary).textSelection(.enabled)
            }
            Button { Speaker.shared.speak(sentence) } label: { Label("Listen", systemImage: "speaker.wave.2") }
                .buttonStyle(.borderless)
        }
    }

    private var otherMatches: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("Other matches")
            ForEach(Array(content.results.enumerated()), id: \.offset) { i, other in
                Button {
                    index = i
                } label: {
                    HStack {
                        Text("\(other.headword)【\(other.reading)】").fontWeight(i == index ? .bold : .regular)
                        Text(other.entry.senses.first?.glosses.prefix(2).joined(separator: "; ") ?? "")
                            .foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func kanjiFacts(_ info: KanjiInfo) -> String {
        var facts: [String] = []
        if let strokes = info.strokes { facts.append("\(strokes) strokes") }
        if let grade = info.grade { facts.append(grade <= 6 ? "grade \(grade)" : grade == 8 ? "secondary school" : "jinmeiyō") }
        if let jlpt = info.jlpt { facts.append("old JLPT \(jlpt)") }
        if let frequency = info.frequency { facts.append("frequency #\(frequency)") }
        return facts.joined(separator: " · ")
    }

    private func highlighted(_ sentence: String) -> AttributedString {
        var attributed = AttributedString(sentence)
        if let range = attributed.range(of: result.matched) {
            attributed[range].foregroundColor = .yellow
        }
        return attributed
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased()).font(.caption.weight(.bold)).foregroundStyle(.secondary)
    }

    private func tag(_ text: String, _ color: Color) -> some View {
        Text(text).font(.caption.weight(.semibold)).padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.25), in: Capsule())
    }
}

/// Text with readings above kanji runs.
struct FuriganaText: View {
    let segments: [FuriganaSegment]
    let size: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                VStack(spacing: 0) {
                    Text(segment.reading ?? " ")
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(.secondary)
                        .opacity(segment.reading == nil ? 0 : 1)
                        .fixedSize()
                    Text(segment.text).font(.system(size: size, weight: .semibold)).fixedSize()
                }
            }
        }
    }
}

/// The iPadOS dictionary (monolingual Japanese if the user has installed it in Settings → General → Dictionary).
struct SystemDictionaryView: UIViewControllerRepresentable {
    let term: String

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }

    func updateUIViewController(_ controller: UIReferenceLibraryViewController, context: Context) {}
}
