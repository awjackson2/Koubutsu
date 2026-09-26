import KoubutsuCore
import SwiftUI

/// Bottom panel while studying: what is selected, where it came from, and its translation.
struct StudyPanel: View {
    let session: StudySession
    let store: (any DictionaryStore)?
    let bank: WordBankStore
    /// Game or video name saved with words.
    let source: String?
    let done: () -> Void
    @State private var card: WordCardContent?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                PixelIcon("study", size: 24).foregroundStyle(K.red)
                Text("STUDY").font(K.osd(20))
                BlockMarks()
                Text(String(format: "SEL %02d", session.spans.reduce(0) { $0 + $1.range.count }))
                    .font(K.osd(13)).foregroundStyle(K.paper.opacity(0.55))
                Spacer()
                if !session.spans.isEmpty {
                    Button("Clear") { session.clearSelection() }.buttonStyle(.k(.ghost))
                }
                Button("Done", action: done)
                    .buttonStyle(.k(.primary))
                    .keyboardShortcut(.escape, modifiers: [])
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if session.spans.isEmpty {
                        Text(hint.uppercased() + "_").font(K.osd(16)).foregroundStyle(K.paper.opacity(0.6))
                    } else {
                        Text(session.selectedText)
                            .font(.system(size: 34, weight: .semibold))
                            .textSelection(.enabled)
                        if let line = session.spans.first?.lineText, session.spans.count == 1,
                           line != session.selectedText {
                            Text(context(line)).font(.title3)
                        }
                        if let best = session.words.first {
                            Button { openCard(session.words) } label: {
                                HStack(alignment: .firstTextBaseline) {
                                    WordSummary(result: best)
                                    Spacer()
                                    KTag(text: "Card ▶")
                                }
                            }
                            .buttonStyle(.plain)
                            if session.words.count > 1 {
                                Text("Also: " + session.words.dropFirst().prefix(4)
                                    .map { "\($0.headword)【\($0.reading)】" }.joined(separator: "  "))
                                    .font(.callout).foregroundStyle(K.paper.opacity(0.6))
                            }
                        }
                        if !session.tokens.isEmpty {
                            ForEach(Array(session.tokens.enumerated()), id: \.offset) { _, token in
                                if let best = token.results.first {
                                    Button { openCard(token.results) } label: { WordSummary(result: best, compact: true) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }
                        if session.isTranslating {
                            Text("TRANSLATING_").font(K.osd(14)).foregroundStyle(K.red)
                        } else if let translation = session.translation {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("EN").font(K.osd(12)).foregroundStyle(K.red)
                                Text(translation).font(K.osd(18)).foregroundStyle(K.paper.opacity(0.85))
                                    .textSelection(.enabled)
                            }
                        } else {
                            Text("TRANSLATION UNAVAILABLE").font(K.osd(13)).foregroundStyle(K.paper.opacity(0.5))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(height: 210, alignment: .top)
        .kSurface(.ink)
        .overlay(alignment: .top) { Rectangle().fill(K.red).frame(height: 2) }
        .onChange(of: session.words.first?.id) { _, id in
            if id != nil, session.autoOpenCard {
                session.autoOpenCard = false
                openCard(session.words)
            }
        }
        .sheet(item: $card) { content in
            WordCardView(content: content, store: store, onSave: { result in
                bank.save(result, sentence: content.sentence, translation: content.sentenceTranslation, source: source,
                          mediaTime: session.frameTiming?.presentationTime.seconds, image: session.lineCrop())
            }, isSaved: { bank.isSaved($0) })
                .presentationDetents([.medium, .large])
        }
        .background(Color(white: 0.07))
        .foregroundStyle(.white)
    }

    private func openCard(_ results: [LookupResult]) {
        guard !results.isEmpty else { return }
        card = WordCardContent(results: results, sentence: session.spans.first?.lineText,
                               sentenceTranslation: session.translatedSource == session.spans.first?.lineText
                                   ? session.translation : nil)
    }

    private var hint: String {
        switch session.phase {
        case .recognizing: "Reading the frame…"
        case .failed: "Could not read this frame."
        case .ready:
            session.japaneseObservations.isEmpty
                ? "No Japanese found in this frame."
                : "Tap a word, or drag over a phrase."
        }
    }

    /// The line with the selected characters emphasized.
    private func context(_ line: String) -> AttributedString {
        var attributed = AttributedString(line)
        guard let span = session.spans.first else { return attributed }
        let characters = Array(line)
        guard span.range.upperBound <= characters.count else { return attributed }
        let prefix = String(characters[..<span.range.lowerBound])
        let selected = String(characters[span.range])
        if let start = attributed.characters.index(attributed.startIndex, offsetBy: prefix.count,
                                                   limitedBy: attributed.endIndex),
           let end = attributed.characters.index(start, offsetBy: selected.count, limitedBy: attributed.endIndex) {
            attributed[start..<end].foregroundColor = .yellow
            attributed[start..<end].font = .title3.bold()
        }
        return attributed
    }
}

/// Headword, reading, conjugation and the first meanings of a dictionary match.
struct WordSummary: View {
    let result: LookupResult
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(result.headword).font(compact ? .title3.weight(.semibold) : .title2.weight(.semibold))
                if result.reading != result.headword {
                    Text(result.reading).font(compact ? .callout : .title3).foregroundStyle(K.paper.opacity(0.6))
                }
                if !result.reasons.isEmpty {
                    KTag(text: result.reasons.joined(separator: " › "))
                }
            }
            Text(result.entry.senses.prefix(compact ? 1 : 3).enumerated()
                .map { "\($0.offset + 1). " + $0.element.glosses.prefix(3).joined(separator: "; ") }
                .joined(separator: "  "))
                .font(K.osd(compact ? 14 : 16))
        }
    }
}
