import KoubutsuCore
import SwiftUI
import UniformTypeIdentifiers

/// Saved words: search, status, review, Anki export.
struct WordBankView: View {
    let bank: WordBankStore
    let store: (any DictionaryStore)?
    let startReview: () -> Void

    @State private var search = ""
    @State private var card: WordCardContent?
    @State private var exporting = false
    @Environment(\.dismiss) private var dismiss

    private var words: [SavedWord] {
        let all = bank.bank.words.sorted { $0.created > $1.created }
        guard !search.isEmpty else { return all }
        return all.filter { word in
            [word.headword, word.reading, Romaji.hepburn(word.reading)].contains { $0.localizedCaseInsensitiveContains(search) }
                || word.meanings.contains { $0.localizedCaseInsensitiveContains(search) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            KSheetHeader(title: "Word bank", subtitle: "\(bank.bank.words.count) SAVED · \(dueCount) DUE") {
                HStack(spacing: 10) {
                    Button { exporting = true } label: { KIconLabel(icon: "export", title: "Anki", size: 16) }
                        .buttonStyle(.k(.secondary))
                        .disabled(bank.bank.words.isEmpty)
                    Button("Done") { dismiss() }.buttonStyle(.k(.secondary))
                }
            }
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    KSearchField(text: $search, prompt: "SEARCH WORDS, READINGS, MEANINGS")
                    Button {
                        dismiss()
                        startReview()
                    } label: {
                        KIconLabel(icon: "review", title: dueCount == 0 ? "Nothing due" : "Review \(dueCount)", size: 16)
                    }
                    .buttonStyle(.k(.primary))
                    .disabled(dueCount == 0)
                }
                KSectionHeader(title: "Saved", index: words.count)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if words.isEmpty {
                            Text("SAVE WORDS FROM A WORD CARD IN STUDY MODE (S)_")
                                .font(K.osd(15)).foregroundStyle(K.ink.opacity(0.5)).padding(.vertical, 20)
                        }
                        ForEach(words) { word in
                            row(word)
                            Rectangle().fill(K.ink.opacity(0.15)).frame(height: 1)
                        }
                    }
                }
            }
            .padding(20)
        }
        .kSheet()
        .kTexture(grain: 0.8, scanlines: 0)
        .fileExporter(isPresented: $exporting, document: TextFile(text: AnkiExport.tsv(bank.bank.words)),
                      contentType: .plainText, defaultFilename: "Koubutsu words") { _ in }
        .sheet(item: $card) { content in
            WordCardView(content: content, store: store)
        }
    }

    private var dueCount: Int { bank.bank.due(at: Date()).count }

    private func row(_ word: SavedWord) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button { open(word) } label: {
                HStack(alignment: .center, spacing: 14) {
                    if let image = bank.image(for: word) {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(width: 110, height: 44).clipped()
                            .grayscale(1).contrast(1.3)
                            .kFrame(K.red, tick: 6)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(word.headword).font(.title3.weight(.semibold))
                            if word.reading != word.headword { Text(word.reading).foregroundStyle(K.ink.opacity(0.55)) }
                            if word.isKnown { KTag(text: "Known", color: K.ink) }
                        }
                        Text((word.meanings.first ?? "").uppercased()).font(K.osd(14)).lineLimit(1)
                        if let sentence = word.sentence {
                            Text(sentence).font(.caption).foregroundStyle(K.ink.opacity(0.55)).lineLimit(1)
                        }
                    }
                    Spacer(minLength: 8)
                    if !word.isKnown {
                        Text(IntervalFormat.dueLabel(word.card.due).uppercased())
                            .font(K.osd(13))
                            .foregroundStyle(word.card.due <= Date() ? K.red : K.ink.opacity(0.55))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button(word.isKnown ? "Learn" : "Known") { bank.setKnown(!word.isKnown, for: word) }
                .buttonStyle(.k(.ghost))
            Button { bank.delete(word) } label: { PixelIcon("trash", size: 16) }
                .buttonStyle(.k(.ghost))
        }
        .padding(.vertical, 10)
    }

    private func open(_ word: SavedWord) {
        guard let entry = store?.entries(forKey: Kana.foldToHiragana(word.headword)).first(where: { $0.id == word.entryID })
                ?? store?.entries(forKey: Kana.foldToHiragana(word.reading)).first(where: { $0.id == word.entryID }) else { return }
        card = WordCardContent(results: [LookupResult(entry: entry, matched: word.headword, dictionaryForm: word.headword,
                                                      reasons: [])],
                               sentence: word.sentence, sentenceTranslation: word.sentenceTranslation)
    }
}

extension IntervalFormat {
    static func dueLabel(_ due: Date, now: Date = Date()) -> String {
        due <= now ? "due" : "in " + short(due.timeIntervalSince(now))
    }
}

/// Plain-text document for `fileExporter`.
struct TextFile: FileDocument {
    static let readableContentTypes: [UTType] = [.plainText]
    var text: String

    init(text: String) { self.text = text }

    init(configuration: ReadConfiguration) throws {
        text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
