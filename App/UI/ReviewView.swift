import KoubutsuCore
import SwiftUI

/// Spaced-repetition review of due words (FSRS). Space shows the answer; 1–4 rate.
struct ReviewView: View {
    let bank: WordBankStore
    @State private var queue: [UUID] = []
    @State private var showingAnswer = false
    @State private var reviewed = 0
    @Environment(\.dismiss) private var dismiss

    private var current: SavedWord? {
        queue.first.flatMap { id in bank.bank.words.first { $0.id == id } }
    }

    var body: some View {
        VStack(spacing: 0) {
            KSheetHeader(title: "Review", subtitle: queue.isEmpty ? "SESSION COMPLETE" : "\(queue.count) LEFT · \(reviewed) DONE") {
                Button("Done") { dismiss() }.buttonStyle(.k(.secondary))
            }
            VStack(spacing: 24) {
                if let word = current {
                    card(word)
                        .id(word.id.uuidString + (showingAnswer ? "a" : "q"))
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                    Spacer(minLength: 0)
                    if showingAnswer {
                        ratingButtons(word)
                    } else {
                        Button("Show answer  [SPACE]") { withAnimation(K.snap) { showingAnswer = true } }
                            .buttonStyle(.kPrimary)
                            .keyboardShortcut(.space, modifiers: [])
                    }
                } else {
                    Spacer()
                    PixelIcon("check", size: 64).foregroundStyle(K.red)
                    Text(reviewed == 0 ? "NOTHING IS DUE." : "DONE — \(reviewed) REVIEWED.").font(K.osd(28))
                    if let next = bank.bank.words.filter({ !$0.isKnown }).map(\.card.due).min() {
                        Text("NEXT REVIEW " + IntervalFormat.dueLabel(next).uppercased()).font(K.osd(16)).foregroundStyle(K.ink.opacity(0.55))
                    }
                    Spacer()
                }
            }
            .padding(24)
            .animation(K.snap, value: queue.first)
            .animation(K.snap, value: showingAnswer)
        }
        .kSheet()
        .kTexture(grain: 0.8, scanlines: 0)
        .onAppear { queue = bank.bank.due(at: Date()).map(\.id) }
    }

    private func card(_ word: SavedWord) -> some View {
        VStack(spacing: 14) {
            if showingAnswer {
                FuriganaText(segments: Furigana.align(written: word.headword, reading: word.reading), size: 64)
                Text("\(word.reading)  \(Romaji.hepburn(word.reading).uppercased())").font(K.osd(22)).foregroundStyle(K.ink.opacity(0.6))
            } else {
                Text(word.headword).font(.system(size: 64, weight: .semibold))
            }
            if let image = bank.image(for: word) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 90)
                    .grayscale(1).contrast(1.3)
                    .kFrame(K.red, tick: 10)
            }
            if let sentence = word.sentence { Text(sentence).font(.title3) }
            if showingAnswer {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(word.meanings.enumerated()), id: \.offset) { i, meaning in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(String(format: "%02d", i + 1)).foregroundStyle(K.red)
                            Text(meaning.uppercased())
                        }
                        .font(K.osd(18))
                    }
                    if let translation = word.sentenceTranslation {
                        Text(translation).font(K.osd(15)).foregroundStyle(K.ink.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button { Speaker.shared.speak(word.reading) } label: { KIconLabel(icon: "speaker", title: "Listen", size: 16) }
                    .buttonStyle(.k(.secondary))
            }
        }
        .padding(28)
        .frame(maxWidth: 760)
        .background(K.paperShade.opacity(0.6))
        .kFrame(K.red, tick: 16, hairline: K.ink.opacity(0.2))
    }

    private func ratingButtons(_ word: SavedWord) -> some View {
        let preview = bank.preview(word)
        return HStack(spacing: 12) {
            ForEach(ReviewRating.allCases, id: \.self) { rating in
                Button {
                    bank.record(rating, for: word)
                    reviewed += 1
                    showingAnswer = false
                    queue.removeFirst()
                    // Failed words come back in this session once their short delay has passed.
                    if rating == .again { queue.append(word.id) }
                } label: {
                    VStack(spacing: 4) {
                        Text("\(rating.rawValue) · \(rating.label)")
                        Text(IntervalFormat.short(preview[rating] ?? 0)).font(K.osd(12))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(KButtonStyle(kind: rating == .again ? .primary : .secondary))
                .keyboardShortcut(KeyEquivalent(Character(String(rating.rawValue))), modifiers: [])
            }
        }
        .frame(maxWidth: 700)
    }

}
