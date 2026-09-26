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
        NavigationStack {
            VStack(spacing: 20) {
                if let word = current {
                    card(word)
                    Spacer(minLength: 0)
                    if showingAnswer {
                        ratingButtons(word)
                    } else {
                        Button("Show answer") { showingAnswer = true }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .keyboardShortcut(.space, modifiers: [])
                    }
                } else {
                    Spacer()
                    Image(systemName: "checkmark.circle").font(.system(size: 56)).foregroundStyle(.green)
                    Text(reviewed == 0 ? "Nothing is due." : "Done — \(reviewed) reviewed.").font(.title2)
                    if let next = bank.bank.words.filter({ !$0.isKnown }).map(\.card.due).min() {
                        Text("Next review " + IntervalFormat.dueLabel(next)).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            .padding()
            .navigationTitle(queue.isEmpty ? "Review" : "Review · \(queue.count) left")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .onAppear { queue = bank.bank.due(at: Date()).map(\.id) }
        }
    }

    private func card(_ word: SavedWord) -> some View {
        VStack(spacing: 14) {
            if showingAnswer {
                FuriganaText(segments: Furigana.align(written: word.headword, reading: word.reading), size: 56)
                Text("\(word.reading) · \(Romaji.hepburn(word.reading))").font(.title3).foregroundStyle(.secondary)
            } else {
                Text(word.headword).font(.system(size: 56, weight: .semibold))
            }
            if let image = bank.image(for: word) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            if let sentence = word.sentence { Text(sentence).font(.title3) }
            if showingAnswer {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(word.meanings.enumerated()), id: \.offset) { i, meaning in
                        Text("\(i + 1). \(meaning)")
                    }
                    if let translation = word.sentenceTranslation {
                        Text(translation).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button { Speaker.shared.speak(word.reading) } label: { Label("Listen", systemImage: "speaker.wave.2") }
            }
        }
        .frame(maxWidth: 700)
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
                    VStack {
                        Text(rating.label).font(.headline)
                        Text(IntervalFormat.short(preview[rating] ?? 0)).font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(color(rating))
                .keyboardShortcut(KeyEquivalent(Character(String(rating.rawValue))), modifiers: [])
            }
        }
        .frame(maxWidth: 700)
    }

    private func color(_ rating: ReviewRating) -> Color {
        switch rating {
        case .again: .red
        case .hard: .orange
        case .good: .green
        case .easy: .blue
        }
    }
}
