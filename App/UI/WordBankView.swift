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
        NavigationStack {
            List {
                Section {
                    let due = bank.bank.due(at: Date()).count
                    Button {
                        dismiss()
                        startReview()
                    } label: {
                        Label(due == 0 ? "Nothing due — review later" : "Review \(due) due word\(due == 1 ? "" : "s")",
                              systemImage: "rectangle.stack")
                    }
                    .disabled(due == 0)
                }
                Section("\(bank.bank.words.count) saved") {
                    if words.isEmpty {
                        Text("Save words from a word card in study mode (S).").foregroundStyle(.secondary)
                    }
                    ForEach(words) { word in
                        row(word)
                            .contentShape(Rectangle())
                            .onTapGesture { open(word) }
                            .swipeActions {
                                Button("Delete", role: .destructive) { bank.delete(word) }
                                Button(word.isKnown ? "Learning" : "Known") { bank.setKnown(!word.isKnown, for: word) }
                                    .tint(.green)
                            }
                    }
                }
            }
            .searchable(text: $search)
            .navigationTitle("Word bank")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Export for Anki") { exporting = true }.disabled(bank.bank.words.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .fileExporter(isPresented: $exporting, document: TextFile(text: AnkiExport.tsv(bank.bank.words)),
                          contentType: .plainText, defaultFilename: "Koubutsu words") { _ in }
            .sheet(item: $card) { content in
                WordCardView(content: content, store: store)
            }
        }
    }

    private func row(_ word: SavedWord) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let image = bank.image(for: word) {
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(width: 96, height: 40).clipShape(RoundedRectangle(cornerRadius: 4))
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(word.headword).font(.title3.weight(.semibold))
                    if word.reading != word.headword { Text(word.reading).foregroundStyle(.secondary) }
                    if word.isKnown { Text("known").font(.caption).foregroundStyle(.green) }
                }
                Text(word.meanings.first ?? "").font(.callout).lineLimit(1)
                if let sentence = word.sentence { Text(sentence).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
            }
            Spacer()
            if !word.isKnown { Text(IntervalFormat.dueLabel(word.card.due)).font(.caption).foregroundStyle(.secondary) }
        }
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
