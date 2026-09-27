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

/// Everything about one looked-up word, as a printed index card: furigana, reading, romaji, conjugation, senses,
/// kanji, the sentence.
struct WordCardView: View {
    let content: WordCardContent
    let store: (any DictionaryStore)?
    var onSave: ((LookupResult) -> Void)?
    var isSaved: (LookupResult) -> Bool = { _ in false }

    @State private var index = 0
    @State private var showingSystemDictionary = false
    @State private var narrow = false
    @Environment(\.dismiss) private var dismiss

    private var result: LookupResult { content.results[min(index, content.results.count - 1)] }

    var body: some View {
        VStack(spacing: 0) {
            KSheetHeader(title: "Word", subtitle: String(format: "ENTRY %07d", result.entry.id)) {
                HStack(spacing: 10) {
                    if let onSave {
                        Button {
                            onSave(result)
                        } label: {
                            KIconLabel(icon: isSaved(result) ? "bookmark.fill" : "bookmark",
                                       title: isSaved(result) ? "Saved" : "Save", size: 16)
                        }
                        .buttonStyle(.k(isSaved(result) ? .secondary : .primary))
                        .disabled(isSaved(result))
                        .accessibilityLabel(isSaved(result) ? "Saved to word bank" : "Save to word bank")
                    }
                    Button { dismiss() } label: { Text("Done").kButtonTarget() }.buttonStyle(.k(.secondary))
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if !result.reasons.isEmpty { conjugation }
                    senses
                    otherForms
                    kanjiSection
                    if let sentence = content.sentence { sentenceSection(sentence) }
                    if content.results.count > 1 { otherMatches }
                    Text("JMDICT / KANJIDIC2 — EDRDG, CC BY-SA 4.0").font(K.osd(11)).foregroundStyle(K.ink.opacity(0.4))
                }
                .padding(narrow ? 16 : 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .trackingNarrowWidth($narrow)
        .kSheet()
        .kTexture(grain: 0.8, scanlines: 0)
        .sheet(isPresented: $showingSystemDictionary) {
            SystemDictionaryView(term: result.headword)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            FittingFuriganaText(segments: Furigana.align(written: result.headword, reading: result.reading), size: 52)
                .padding(12)
                .kFrame(K.red, tick: 12)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { readingLine }
                VStack(alignment: .leading, spacing: 6) { readingLine }
            }
            .accessibilityElement(children: .combine)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { headerActions }
                VStack(alignment: .leading, spacing: 10) { headerActions }
            }
            .buttonStyle(.k(.secondary))
        }
    }

    @ViewBuilder private var readingLine: some View {
        Text(result.reading).font(.title2)
        Text(Romaji.hepburn(result.reading).uppercased()).font(K.osd(20)).foregroundStyle(K.ink.opacity(0.55))
        if result.entry.isCommon { KTag(text: "Common", filled: true) }
    }

    @ViewBuilder private var headerActions: some View {
        Button { Speaker.shared.speak(result.reading) } label: { KIconLabel(icon: "speaker", title: "Listen", size: 16) }
        Button { showingSystemDictionary = true } label: { KIconLabel(icon: "dictionary", title: "Dictionary", size: 16) }
            .accessibilityHint("Opens the system dictionary")
        Button { UIPasteboard.general.string = result.headword } label: { KIconLabel(icon: "copy", title: "Copy", size: 16) }
            .accessibilityHint("Copies the word")
    }

    private var conjugation: some View {
        VStack(alignment: .leading, spacing: 6) {
            KSectionHeader(title: "Conjugation", index: 1).kHeading()
            // One line when it fits; otherwise the forms above the reasons, then one reason per line.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    conjugationForms
                    conjugationReasons
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) { conjugationForms }
                    HStack(alignment: .firstTextBaseline, spacing: 8) { conjugationReasons }
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) { conjugationForms }
                    ForEach(Array(result.reasons.enumerated()), id: \.offset) { _, reason in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("›").font(K.osd(16)).foregroundStyle(K.red)
                            KTag(text: reason, color: K.ink)
                        }
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder private var conjugationForms: some View {
        Text(result.matched).font(.title3)
        Text("=").font(K.osd(16))
        Text(result.dictionaryForm).font(.title3)
    }

    private var conjugationReasons: some View {
        ForEach(Array(result.reasons.enumerated()), id: \.offset) { _, reason in
            Text("›").font(K.osd(16)).foregroundStyle(K.red)
            KTag(text: reason, color: K.ink)
        }
    }

    private var senses: some View {
        VStack(alignment: .leading, spacing: 12) {
            KSectionHeader(title: "Meanings", index: 2).kHeading()
            ForEach(Array(result.entry.senses.enumerated()), id: \.offset) { number, sense in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(String(format: "%02d", number + 1)).font(K.osd(16)).foregroundStyle(K.red)
                    VStack(alignment: .leading, spacing: 4) {
                        let labels = sense.partsOfSpeech.map(DictionaryLabels.partOfSpeech)
                            + (sense.misc + sense.fields + sense.dialects).map(DictionaryLabels.label)
                        if !labels.isEmpty {
                            Text(labels.joined(separator: " · ").uppercased()).font(K.osd(12)).foregroundStyle(K.ink.opacity(0.55))
                        }
                        Text(sense.glosses.joined(separator: "; ")).font(K.osd(18))
                        if let note = sense.note { Text(note).font(K.osd(13)).foregroundStyle(K.ink.opacity(0.55)) }
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    @ViewBuilder private var otherForms: some View {
        let kanji = result.entry.kanji.filter { !$0.isHidden && $0.text != result.headword }.map(\.text)
        let readings = result.entry.readings.map(\.text).filter { $0 != result.reading }
        if !kanji.isEmpty || !readings.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                KSectionHeader(title: "Other forms", index: 3).kHeading()
                Text((kanji + readings).joined(separator: "、")).font(.title3)
            }
        }
    }

    @ViewBuilder private var kanjiSection: some View {
        let infos = result.headword.filter(Kana.isKanji).compactMap { store?.kanji($0) }
        if !infos.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                KSectionHeader(title: "Kanji", index: 4).kHeading()
                ForEach(infos, id: \.literal) { info in
                    HStack(alignment: .top, spacing: narrow ? 10 : 14) {
                        // Smaller tile on a narrow sheet so the readings keep a usable width.
                        Text(info.literal).font(.system(size: narrow ? 38 : 48))
                            .frame(width: narrow ? 56 : 72, height: narrow ? 56 : 72)
                            .background(K.ink)
                            .foregroundStyle(K.paper)
                            .kFrame(K.red, tick: 10)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(info.meanings.prefix(5).joined(separator: ", ").uppercased()).font(K.osd(17))
                            if !info.onReadings.isEmpty { labeled("ON", info.onReadings.joined(separator: "、")) }
                            if !info.kunReadings.isEmpty { labeled("KUN", info.kunReadings.joined(separator: "、")) }
                            Text(kanjiFacts(info)).font(K.osd(12)).foregroundStyle(K.ink.opacity(0.55))
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func sentenceSection(_ sentence: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            KSectionHeader(title: "Sentence", index: 5).kHeading()
            Text(highlighted(sentence)).font(.title3).textSelection(.enabled)
            if let translation = content.sentenceTranslation {
                Text(translation).font(K.osd(16)).foregroundStyle(K.ink.opacity(0.6)).textSelection(.enabled)
            }
            Button { Speaker.shared.speak(sentence) } label: { KIconLabel(icon: "speaker", title: "Listen", size: 16) }
                .buttonStyle(.k(.ghost))
                .accessibilityLabel("Listen to the sentence")
        }
    }

    private var otherMatches: some View {
        VStack(alignment: .leading, spacing: 6) {
            KSectionHeader(title: "Other matches", index: 6).kHeading()
            ForEach(Array(content.results.enumerated()), id: \.offset) { i, other in
                Button {
                    withAnimation(K.snap) { index = i }
                } label: {
                    HStack(alignment: narrow ? .firstTextBaseline : .center, spacing: 10) {
                        Text(i == index ? "■" : "□").font(K.osd(16)).foregroundStyle(K.red)
                            .accessibilityHidden(true)
                        if narrow {
                            // Headword above the gloss, so the gloss is not squeezed to nothing.
                            VStack(alignment: .leading, spacing: 2) {
                                matchTitle(other, selected: i == index)
                                matchGloss(other).lineLimit(2)
                            }
                        } else {
                            matchTitle(other, selected: i == index)
                            matchGloss(other).lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(i == index ? .isSelected : [])
            }
        }
    }

    private func matchTitle(_ other: LookupResult, selected: Bool) -> some View {
        Text("\(other.headword)【\(other.reading)】").font(.body.weight(selected ? .bold : .regular))
    }

    private func matchGloss(_ other: LookupResult) -> some View {
        Text(other.entry.senses.first?.glosses.prefix(2).joined(separator: "; ") ?? "")
            .font(K.osd(14))
            .foregroundStyle(K.ink.opacity(0.55))
    }

    private func labeled(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label).font(K.osd(12)).foregroundStyle(K.red).frame(width: 32, alignment: .leading)
            Text(value).font(.callout)
        }
    }

    private func kanjiFacts(_ info: KanjiInfo) -> String {
        var facts: [String] = []
        if let strokes = info.strokes { facts.append("\(strokes) STROKES") }
        if let grade = info.grade { facts.append(grade <= 6 ? "GRADE \(grade)" : grade == 8 ? "SECONDARY" : "JINMEIYO") }
        if let jlpt = info.jlpt { facts.append("OLD JLPT \(jlpt)") }
        if let frequency = info.frequency { facts.append("FREQ #\(frequency)") }
        return facts.joined(separator: " · ")
    }

    private func highlighted(_ sentence: String) -> AttributedString {
        var attributed = AttributedString(sentence)
        if let range = attributed.range(of: result.matched) {
            attributed[range].foregroundColor = K.red
            attributed[range].underlineStyle = .single
        }
        return attributed
    }
}

/// Text with readings above kanji runs (readings in pixel Japanese).
struct FuriganaText: View {
    let segments: [FuriganaSegment]
    let size: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                VStack(spacing: 2) {
                    Text(segment.reading ?? " ")
                        .font(K.dotFixed(size * 0.36))
                        .foregroundStyle(K.red)
                        .opacity(segment.reading == nil ? 0 : 1)
                        .fixedSize()
                    Text(segment.text).font(.system(size: size, weight: .semibold)).fixedSize()
                }
            }
        }
        // One element: the word, then its reading (not each ruby run on its own).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(written)
        .accessibilityValue(reading == written ? "" : reading)
    }

    private var written: String { segments.map(\.text).joined() }
    private var reading: String { segments.map { $0.reading ?? $0.text }.joined() }
}

/// `FuriganaText` at the largest size that fits the width, down to 40 % of `size`: furigana cannot wrap, and a
/// long headword at 52–64 pt is wider than an iPhone.
struct FittingFuriganaText: View {
    let segments: [FuriganaSegment]
    let size: CGFloat

    var body: some View {
        ViewThatFits(in: .horizontal) {
            FuriganaText(segments: segments, size: size)
            FuriganaText(segments: segments, size: size * 0.75)
            FuriganaText(segments: segments, size: size * 0.55)
            FuriganaText(segments: segments, size: size * 0.4)
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
