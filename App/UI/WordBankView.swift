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
    @State private var narrow = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var words: [SavedWord] {
        let all = bank.bank.words.sorted { $0.created > $1.created }
        guard !search.isEmpty else { return all }
        return all.filter { word in
            [word.headword, word.reading, Romaji.hepburn(word.reading)].contains { $0.localizedCaseInsensitiveContains(search) }
                || word.meanings.contains { $0.localizedCaseInsensitiveContains(search) }
        }
    }

    /// Narrow sheet (iPhone portrait) or accessibility text sizes: rows and controls stack.
    private var stacked: Bool { narrow || dynamicTypeSize.isAccessibilitySize }
    /// Short sheet (iPhone landscape) or accessibility text sizes: the search controls scroll with the list, so the
    /// list keeps room on screen.
    private var controlsScroll: Bool { verticalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        VStack(spacing: 0) {
            KSheetHeader(title: "Word bank", subtitle: "\(bank.bank.words.count) SAVED · \(dueCount) DUE") {
                HStack(spacing: 10) {
                    Button { exporting = true } label: { KIconLabel(icon: "export", title: stacked ? nil : "Anki", size: 16) }
                        .buttonStyle(.k(.secondary))
                        .disabled(bank.bank.words.isEmpty)
                        .accessibilityLabel("Export to Anki")
                    Button { dismiss() } label: { Text("Done").kButtonTarget() }.buttonStyle(.k(.secondary))
                }
            }
            if controlsScroll {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        controls
                        list
                    }
                    .padding(narrow ? 16 : 20)
                }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    controls
                    ScrollView { list }
                }
                .padding(narrow ? 16 : 20)
            }
        }
        .trackingNarrowWidth($narrow)
        .kSheet()
        .kTexture(grain: 0.8, scanlines: 0)
        .fileExporter(isPresented: $exporting, document: TextFile(text: AnkiExport.tsv(bank.bank.words)),
                      contentType: .plainText, defaultFilename: "Koubutsu words") { _ in }
        .sheet(item: $card) { content in
            WordCardView(content: content, store: store)
        }
    }

    private var dueCount: Int { bank.bank.due(at: Date()).count }

    @ViewBuilder private var controls: some View {
        if stacked {
            VStack(alignment: .leading, spacing: 12) {
                KSearchField(text: $search, prompt: "SEARCH WORDS")
                reviewButton
            }
        } else {
            HStack(spacing: 12) {
                KSearchField(text: $search, prompt: "SEARCH WORDS, READINGS, MEANINGS")
                reviewButton
            }
        }
        KSectionHeader(title: "Saved", index: words.count).kHeading()
    }

    private var reviewButton: some View {
        Button {
            dismiss()
            startReview()
        } label: {
            KIconLabel(icon: "review", title: dueCount == 0 ? "Nothing due" : "Review \(dueCount)", size: 16)
                .frame(maxWidth: stacked ? .infinity : nil)
        }
        .buttonStyle(.k(.primary))
        .disabled(dueCount == 0)
    }

    private var list: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            if words.isEmpty {
                Text("SAVE WORDS FROM A WORD CARD IN STUDY MODE (S)_")
                    .font(K.osd(15)).foregroundStyle(K.ink.opacity(0.5)).padding(.vertical, 20)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(words) { word in
                if stacked { stackedRow(word) } else { row(word) }
                Rectangle().fill(K.ink.opacity(0.15)).frame(height: 1)
            }
        }
    }

    /// iPad row: thumbnail, text and due date in one line, actions at the end.
    private func row(_ word: SavedWord) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button { open(word) } label: {
                HStack(alignment: .center, spacing: 14) {
                    thumbnail(word, width: 110, height: 44)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) { headwordLine(word) }
                        meaningLines(word, lines: 1)
                    }
                    Spacer(minLength: 8)
                    dueLabel(word)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the word card")
            knownButton(word)
            deleteButton(word)
        }
        .padding(.vertical, 10)
    }

    /// Narrow row: a smaller thumbnail above the text, the actions in a column at the side.
    private func stackedRow(_ word: SavedWord) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button { open(word) } label: {
                VStack(alignment: .leading, spacing: 6) {
                    thumbnail(word, width: 88, height: 35)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) { headwordLine(word) }
                        VStack(alignment: .leading, spacing: 2) { headwordLine(word) }
                    }
                    meaningLines(word, lines: 2)
                    dueLabel(word)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the word card")
            VStack(alignment: .trailing, spacing: 0) {
                knownButton(word)
                deleteButton(word)
            }
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder private func thumbnail(_ word: SavedWord, width: CGFloat, height: CGFloat) -> some View {
        if let image = bank.image(for: word) {
            Image(uiImage: image).resizable().scaledToFill()
                .frame(width: width, height: height).clipped()
                .grayscale(1).contrast(1.3)
                .kFrame(K.red, tick: 6)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder private func headwordLine(_ word: SavedWord) -> some View {
        Text(word.headword).font(.title3.weight(.semibold))
        if word.reading != word.headword { Text(word.reading).foregroundStyle(K.ink.opacity(0.55)) }
        if word.isKnown { KTag(text: "Known", color: K.ink) }
    }

    @ViewBuilder private func meaningLines(_ word: SavedWord, lines: Int) -> some View {
        Text((word.meanings.first ?? "").uppercased()).font(K.osd(14)).lineLimit(lines)
        if let sentence = word.sentence {
            Text(sentence).font(.caption).foregroundStyle(K.ink.opacity(0.55)).lineLimit(lines)
        }
    }

    @ViewBuilder private func dueLabel(_ word: SavedWord) -> some View {
        if !word.isKnown {
            Text(IntervalFormat.dueLabel(word.card.due).uppercased())
                .font(K.osd(13))
                .foregroundStyle(word.card.due <= Date() ? K.red : K.ink.opacity(0.55))
        }
    }

    private func knownButton(_ word: SavedWord) -> some View {
        Button { bank.setKnown(!word.isKnown, for: word) } label: {
            Text(word.isKnown ? "Learn" : "Known").kButtonTarget()
        }
        .buttonStyle(.k(.ghost))
        .accessibilityHint(word.isKnown ? "Puts \(word.headword) back into review" : "Marks \(word.headword) as known")
    }

    private func deleteButton(_ word: SavedWord) -> some View {
        Button { bank.delete(word) } label: { PixelIcon("trash", size: 16).kButtonTarget() }
            .buttonStyle(.k(.ghost))
            .accessibilityLabel("Delete \(word.headword)")
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
