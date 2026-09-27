import KoubutsuCore
import SwiftUI

/// Spaced-repetition review of due words (FSRS). Space shows the answer; 1–4 rate.
struct ReviewView: View {
    let bank: WordBankStore
    @State private var queue: [UUID] = []
    @State private var showingAnswer = false
    @State private var reviewed = 0
    @State private var narrow = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var current: SavedWord? {
        queue.first.flatMap { id in bank.bank.words.first { $0.id == id } }
    }

    /// Tighter margins on a narrow (iPhone portrait) or short (iPhone landscape) sheet.
    private var margin: CGFloat { narrow || verticalSizeClass == .compact ? 16 : 24 }

    var body: some View {
        VStack(spacing: 0) {
            KSheetHeader(title: "Review", subtitle: queue.isEmpty ? "SESSION COMPLETE" : "\(queue.count) LEFT · \(reviewed) DONE") {
                Button { dismiss() } label: { Text("Done").kButtonTarget() }.buttonStyle(.k(.secondary))
            }
            if let word = current {
                // The card scrolls; the answer and grade buttons stay pinned below it, so they are always reachable.
                ScrollView {
                    card(word)
                        .id(word.id.uuidString + (showingAnswer ? "a" : "q"))
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                        .frame(maxWidth: .infinity)
                        .padding(margin)
                }
                .scrollBounceBehavior(.basedOnSize)
                Group {
                    if showingAnswer {
                        ratingButtons(word)
                    } else {
                        Button { withAnimation(K.snap) { showingAnswer = true } } label: {
                            Text(narrow ? "Show answer" : "Show answer  [SPACE]").kButtonTarget(compact: false)
                        }
                        .buttonStyle(.kPrimary)
                        .keyboardShortcut(.space, modifiers: [])
                        .accessibilityLabel("Show answer")
                    }
                }
                .padding(.horizontal, margin)
                .padding(.bottom, margin)
            } else {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 24) {
                            PixelIcon("check", size: 64).foregroundStyle(K.red).accessibilityHidden(true)
                            Text(reviewed == 0 ? "NOTHING IS DUE." : "DONE — \(reviewed) REVIEWED.").font(K.osd(28))
                                .multilineTextAlignment(.center)
                            if let next = bank.bank.words.filter({ !$0.isKnown }).map(\.card.due).min() {
                                Text("NEXT REVIEW " + IntervalFormat.dueLabel(next).uppercased()).font(K.osd(16))
                                    .foregroundStyle(K.ink.opacity(0.55))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(margin)
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
        }
        .animation(K.snap, value: queue.first)
        .animation(K.snap, value: showingAnswer)
        .trackingNarrowWidth($narrow)
        .kSheet()
        .kTexture(grain: 0.8, scanlines: 0)
        .onAppear { queue = bank.bank.due(at: Date()).map(\.id) }
    }

    private func card(_ word: SavedWord) -> some View {
        VStack(spacing: 14) {
            if showingAnswer {
                FittingFuriganaText(segments: Furigana.align(written: word.headword, reading: word.reading), size: 64)
                Text("\(word.reading)  \(Romaji.hepburn(word.reading).uppercased())").font(K.osd(22)).foregroundStyle(K.ink.opacity(0.6))
                    .multilineTextAlignment(.center)
            } else {
                Text(word.headword).font(.system(size: 64, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
            if let image = bank.image(for: word) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 90)
                    .grayscale(1).contrast(1.3)
                    .kFrame(K.red, tick: 10)
                    .accessibilityHidden(true)
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
                        .accessibilityElement(children: .combine)
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
        .padding(narrow ? 16 : 28)
        .frame(maxWidth: 760)
        .background(K.paperShade.opacity(0.6))
        .kFrame(K.red, tick: 16, hairline: K.ink.opacity(0.2))
    }

    /// One row of four on a wide sheet, 2×2 when narrow, one column at the accessibility text sizes.
    @ViewBuilder private func ratingButtons(_ word: SavedWord) -> some View {
        let preview = bank.preview(word)
        let ratings = Array(ReviewRating.allCases)
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    ForEach(ratings, id: \.self) { ratingButton($0, word: word, preview: preview) }
                }
            } else if narrow {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ForEach(Array(ratings.prefix(2)), id: \.self) { ratingButton($0, word: word, preview: preview) }
                    }
                    HStack(spacing: 12) {
                        ForEach(Array(ratings.dropFirst(2)), id: \.self) { ratingButton($0, word: word, preview: preview) }
                    }
                }
            } else {
                HStack(spacing: 12) {
                    ForEach(ratings, id: \.self) { ratingButton($0, word: word, preview: preview) }
                }
            }
        }
        .frame(maxWidth: 700)
    }

    private func ratingButton(_ rating: ReviewRating, word: SavedWord, preview: [ReviewRating: TimeInterval]) -> some View {
        let interval = IntervalFormat.short(preview[rating] ?? 0)
        return Button {
            bank.record(rating, for: word)
            reviewed += 1
            showingAnswer = false
            queue.removeFirst()
            // Failed words come back in this session once their short delay has passed.
            if rating == .again { queue.append(word.id) }
        } label: {
            VStack(spacing: 4) {
                Text("\(rating.rawValue) · \(rating.label)")
                Text(interval).font(K.osd(12))
            }
            .frame(maxWidth: .infinity, minHeight: 26)
        }
        .buttonStyle(KButtonStyle(kind: rating == .again ? .primary : .secondary))
        .keyboardShortcut(KeyEquivalent(Character(String(rating.rawValue))), modifiers: [])
        .accessibilityLabel("Grade \(rating.rawValue), \(rating.label)")
        .accessibilityValue("Next review in \(interval)")
    }
}
