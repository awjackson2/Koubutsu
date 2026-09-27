import KoubutsuCore
import SwiftUI

/// Pages of the portrait info deck.
enum DeckTab: String, CaseIterable, Identifiable {
    case log, words, session

    var id: String { rawValue }

    var title: String {
        switch self {
        case .log: "LOG"
        case .words: "WORDS"
        case .session: "SESSION"
        }
    }

    var spokenTitle: String {
        switch self {
        case .log: "Dialogue log"
        case .words: "Words on screen"
        case .session: "Session"
        }
    }
}

/// Compact portrait info deck (10.7.0): fills the housing gap between the transport and control bars when no
/// scrolling panel is enabled. A one-line tab strip over three swipeable pages — the live dialogue transcript, the
/// dictionary words on screen, and a session / pipeline readout. Reads only observable state the app already keeps;
/// nothing here is on the display path (rule 1).
struct PortraitDeck: View {
    let model: AppModel
    let deck: PortraitDeckModel
    /// Opens the review sheet (owned by `RootView`).
    let openReview: () -> Void
    @SceneStorage("portraitDeck.tab") private var tab: DeckTab = .log
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            tabStrip
            TabView(selection: $tab) {
                DeckLogPage(controller: model.translation)
                    .tag(DeckTab.log)
                DeckWordsPage(model: model, deck: deck)
                    .tag(DeckTab.words)
                DeckSessionPage(model: model, deck: deck, openReview: openReview)
                    .tag(DeckTab.session)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .kSurface(.ink, paint: false)
        .background(K.ink.opacity(0.88))
        .clipped()
        .kFrame(K.red, tick: 8, hairline: K.paper.opacity(0.18))
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        // Feeds the words page when the on-screen text changes; a separate view so geometry-only updates of the
        // displayed boxes do not re-evaluate the deck.
        .background { DeckWordFeed(controller: model.translation, dictionary: model.dictionary, deck: deck) }
    }

    /// `LOG | WORDS | SESSION`: 44 pt targets, the selected tab a red block.
    private var tabStrip: some View {
        HStack(spacing: 0) {
            BlockMarks(count: 2, size: 4)
                .padding(.horizontal, 8)
                .accessibilityHidden(true)
            ForEach(DeckTab.allCases) { item in
                if item != DeckTab.allCases.first {
                    Rectangle().fill(K.paper.opacity(0.18)).frame(width: 1, height: 20)
                        .accessibilityHidden(true)
                }
                tabButton(item)
            }
        }
        .frame(minHeight: CGFloat(VideoStageLayout.portraitDeckTabHeight))
        .overlay(alignment: .bottom) { Rectangle().fill(K.paper.opacity(0.18)).frame(height: 1) }
    }

    private func tabButton(_ item: DeckTab) -> some View {
        let selected = tab == item
        return Button {
            if reduceMotion {
                tab = item
            } else {
                withAnimation(K.snap) { tab = item }
            }
        } label: {
            HStack(spacing: 5) {
                Text(item.title)
                if item == .words, !deck.words.isEmpty, !deck.wordsAreStale {
                    Text(String(format: "%02d", deck.words.count))
                        .foregroundStyle(selected ? K.paper.opacity(0.8) : K.red)
                }
            }
            .font(K.osd(14, relativeTo: .subheadline))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(selected ? K.paper : K.paper.opacity(0.6))
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: KIconButtonStyle.minimumTarget)
            .background(selected ? K.red : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.spokenTitle)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint("Shows the \(item.spokenTitle.lowercased()) page")
    }
}

/// Invisible: forwards the Japanese on screen to the deck model when it (or the dictionary state) changes.
private struct DeckWordFeed: View {
    let controller: TranslationController
    let dictionary: DictionaryProvider
    let deck: PortraitDeckModel

    var body: some View {
        let texts = controller.displayed.map(\.stable.text)
        Color.clear
            .accessibilityHidden(true)
            .onChange(of: texts, initial: true) { _, texts in
                deck.update(texts: texts, lookup: dictionary.lookup)
            }
            .onChange(of: dictionary.state) { _, _ in
                deck.update(texts: controller.displayed.map(\.stable.text), lookup: dictionary.lookup)
            }
    }
}

// MARK: - Shared pieces

/// Centred OSD message with a blinking cursor (empty states).
private struct DeckEmptyState: View {
    let message: String
    var detail: String?

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text(message)
                    .font(K.osd(15, relativeTo: .subheadline))
                    .foregroundStyle(K.paper.opacity(0.6))
                BlinkingCursor(width: 8, height: 14).accessibilityHidden(true)
            }
            if let detail {
                Text(detail)
                    .font(K.osd(12, relativeTo: .caption))
                    .foregroundStyle(K.paper.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// "HH:MM:SS" in the device clock, matching the housing clock.
private func deckTime(_ date: Date) -> String {
    let c = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
    return String(format: "%02d:%02d:%02d", c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
}

// MARK: - LOG

/// The live dialogue transcript: Japanese over English, oldest at the top, newest at the bottom (auto-scrolled).
/// Lines still on screen carry a red marker; a line being translated shows a blinking cursor.
private struct DeckLogPage: View {
    let controller: TranslationController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Rows kept in the transcript (the history holds up to 500).
    private static let visibleRows = 80

    var body: some View {
        let entries = controller.history.entries.suffix(Self.visibleRows)
        let onScreen = Set(controller.displayed.map(\.stable.id))
        let translating = Set(controller.displayed.filter { $0.status == .translating }.map(\.stable.id))
        if entries.isEmpty {
            DeckEmptyState(message: "WAITING FOR DIALOGUE",
                           detail: "Lines appear here as they are read")
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(entries) { entry in
                            DeckLogRow(entry: entry, isOnScreen: onScreen.contains(entry.id),
                                       isTranslating: translating.contains(entry.id),
                                       isNewest: entry.id == entries.last?.id)
                                .id(entry.id)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .defaultScrollAnchor(.bottom)
                .onChange(of: scrollKey(entries.last)) { _, _ in
                    guard let id = entries.last?.id else { return }
                    if reduceMotion {
                        proxy.scrollTo(id, anchor: .bottom)
                    } else {
                        withAnimation(K.snap) { proxy.scrollTo(id, anchor: .bottom) }
                    }
                }
            }
        }
    }

    /// Changes when a line is added or the newest line gets its translation (its row grows).
    private func scrollKey(_ entry: DialogueEntry?) -> String {
        guard let entry else { return "" }
        return entry.id + (entry.translation == nil ? "" : "#en")
    }
}

private struct DeckLogRow: View {
    let entry: DialogueEntry
    let isOnScreen: Bool
    let isTranslating: Bool
    let isNewest: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Rectangle()
                .fill(isOnScreen ? K.red : K.paper.opacity(0.18))
                .frame(width: isOnScreen ? 3 : 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.source)
                    .font(.footnote)
                    .foregroundStyle(K.paper.opacity(isNewest ? 0.85 : 0.55))
                if let translation = entry.translation {
                    Text(translation)
                        .font(K.osd(15, relativeTo: .subheadline))
                        .foregroundStyle(isNewest ? K.paper : K.paper.opacity(0.75))
                } else if isTranslating {
                    HStack(spacing: 4) {
                        Text("TRANSLATING").font(K.osd(12, relativeTo: .caption)).foregroundStyle(K.red)
                        BlinkingCursor(width: 7, height: 12).accessibilityHidden(true)
                    }
                } else {
                    Text("— NO TRANSLATION").font(K.osd(12, relativeTo: .caption))
                        .foregroundStyle(K.paper.opacity(0.35))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(deckTime(entry.date))
                .font(K.osd(10, relativeTo: .caption2))
                .foregroundStyle(isNewest ? K.red : K.paper.opacity(0.35))
                .accessibilityHidden(true)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.source)
        .accessibilityValue(spokenValue)
    }

    private var spokenValue: String {
        var parts: [String] = []
        if let translation = entry.translation {
            parts.append(translation)
        } else if isTranslating {
            parts.append("Translating")
        }
        if isOnScreen { parts.append("on screen") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - WORDS

/// Dictionary words of the Japanese on screen: headword, reading, first gloss and word-bank state, with a save
/// button; tapping a row opens the word card.
private struct DeckWordsPage: View {
    let model: AppModel
    let deck: PortraitDeckModel
    @State private var card: WordCardContent?

    var body: some View {
        Group {
            switch model.dictionary.state {
            case .loading:
                DeckEmptyState(message: "LOADING DICTIONARY")
            case .failed:
                DeckEmptyState(message: "NO DICTIONARY", detail: "Word lookup is unavailable")
            case .ready:
                if deck.words.isEmpty {
                    DeckEmptyState(message: "NO WORDS ON SCREEN",
                                   detail: "Words from the Japanese on screen appear here")
                } else {
                    list
                }
            }
        }
        .sheet(item: $card) { content in
            WordCardView(content: content, store: model.dictionary.store, onSave: { result in
                save(result, sentence: content.sentence)
            }, isSaved: { model.wordBank.isSaved($0) })
                .presentationDetents([.medium, .large])
        }
    }

    private var list: some View {
        let bank = model.wordBank.bank
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text(deck.wordsAreStale ? "LAST SEEN" : "ON SCREEN")
                        .font(K.osd(12, relativeTo: .caption))
                        .foregroundStyle(deck.wordsAreStale ? K.paper.opacity(0.5) : K.red)
                    Rectangle().fill(K.paper.opacity(0.18)).frame(height: 1)
                    Text(String(format: "%02d", deck.words.count))
                        .font(K.osd(12, relativeTo: .caption))
                        .foregroundStyle(K.paper.opacity(0.5))
                }
                .padding(.vertical, 6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(deck.wordsAreStale ? "Last seen words" : "Words on screen")
                .accessibilityValue("\(deck.words.count)")
                .accessibilityAddTraits(.isHeader)
                ForEach(deck.words) { word in
                    row(word, state: DeckWords.state(of: word, in: bank))
                    Rectangle().fill(K.paper.opacity(0.08)).frame(height: 1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
        .opacity(deck.wordsAreStale ? 0.75 : 1)
    }

    private func row(_ word: DeckWord, state: DeckWordState) -> some View {
        HStack(spacing: 4) {
            Button { open(word) } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(word.headword)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                    if word.reading != word.headword {
                        Text(word.reading)
                            .font(.footnote)
                            .foregroundStyle(K.paper.opacity(0.6))
                            .lineLimit(1)
                    }
                    Text(word.gloss)
                        .font(K.osd(13, relativeTo: .footnote))
                        .foregroundStyle(K.paper.opacity(0.8))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(-1)
                    Spacer(minLength: 4)
                    KTag(text: state.label, color: color(state), filled: state == .learning)
                }
                .frame(maxWidth: .infinity, minHeight: KIconButtonStyle.minimumTarget, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(word.reading == word.headword ? word.headword : "\(word.headword), \(word.reading)")
            .accessibilityValue("\(word.gloss), \(state.rawValue)")
            .accessibilityHint("Opens the word card")
            let saved = state != .new
            Button { save(word) } label: {
                PixelIcon(saved ? "bookmark.fill" : "bookmark", size: 16)
                    .accessibilityHidden(true)
            }
            .buttonStyle(KIconButtonStyle(active: saved))
            .disabled(saved)
            .accessibilityLabel(saved ? "Saved to word bank" : "Save \(word.headword) to word bank")
        }
    }

    private func color(_ state: DeckWordState) -> Color {
        switch state {
        case .known: K.paper.opacity(0.5)
        case .learning: K.red
        case .new: K.paper.opacity(0.8)
        }
    }

    private func open(_ word: DeckWord) {
        let sentence = deck.sentence(for: word)
        card = WordCardContent(results: word.results, sentence: sentence,
                               sentenceTranslation: sentence.flatMap { historyEntry(for: $0)?.translation })
    }

    private func save(_ word: DeckWord) {
        guard let best = word.results.first else { return }
        save(best, sentence: deck.sentence(for: word))
    }

    /// Saves with the line it came from, its translation and its presentation time (from the dialogue history,
    /// rule 4); no line crop outside study mode.
    private func save(_ result: LookupResult, sentence: String?) {
        let line = sentence.flatMap { historyEntry(for: $0) }
        model.wordBank.save(result, sentence: sentence, translation: line?.translation,
                            source: model.selection?.label,
                            mediaTime: line?.firstSeenFrame.presentationTime.seconds, image: nil)
    }

    private func historyEntry(for sentence: String) -> DialogueEntry? {
        model.translation.history.entries.last { $0.source == sentence }
    }
}

// MARK: - SESSION

/// Reading statistics since launch and pipeline health as pixel meters. The clock ticks once a second; metrics come
/// from the model's existing 4 Hz snapshot.
private struct DeckSessionPage: View {
    let model: AppModel
    let deck: PortraitDeckModel
    let openReview: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(now: context.date)
        }
    }

    private func content(now: Date) -> some View {
        let stats = deck.stats
        let entries = model.translation.history.entries
        let bank = model.wordBank.bank
        let due = bank.due(at: now).count
        let lines = stats.linesRead(in: entries)
        let metrics = model.metrics
        return ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                    GridRow {
                        DeckStatTile(title: "SESSION", value: ReadingSessionStats.clock(stats.elapsed(at: now)),
                                     spoken: spokenDuration(stats.elapsed(at: now)))
                        DeckStatTile(title: "LINES", value: "\(lines)",
                                     detail: "\(stats.translatedLines(in: entries)) EN")
                    }
                    GridRow {
                        DeckStatTile(title: "WORDS SEEN", value: "\(deck.wordsSeen)")
                        DeckStatTile(title: "SAVED", value: "\(stats.wordsSaved(in: bank))")
                    }
                }
                reviewRow(due: due)
                KSectionHeader(title: "Pipeline")
                    .kHeading()
                DeckMeter(title: "OCR", value: metrics.ocrProcessedPerSecond, full: model.settings.ocrRate.rawValue,
                          text: String(format: "%.1f/%.0f FPS", metrics.ocrProcessedPerSecond,
                                       model.settings.ocrRate.rawValue),
                          spoken: String(format: "%.1f of %.0f frames per second", metrics.ocrProcessedPerSecond,
                                         model.settings.ocrRate.rawValue),
                          warnsHigh: false)
                latencyMeter("OCR LAT", spokenTitle: "OCR latency", metrics.ocrLatency, full: 0.5)
                latencyMeter("EN LAT", spokenTitle: "Translation latency", metrics.translationLatency, full: 1.5)
            }
            .padding(10)
        }
    }

    private func reviewRow(due: Int) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("REVIEWS DUE").font(K.osd(11, relativeTo: .caption)).foregroundStyle(K.red)
                Text("\(due)").font(K.osd(22, relativeTo: .title3))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Reviews due")
            .accessibilityValue("\(due)")
            Spacer(minLength: 8)
            Button(action: openReview) { Text("Review ▶").kButtonTarget() }
                .buttonStyle(.k(due > 0 ? .primary : .secondary))
                .disabled(due == 0)
                .accessibilityLabel("Review")
                .accessibilityHint(due > 0 ? "Opens the review of due words" : "No words are due")
        }
        .padding(8)
        .background(K.inkRaised)
        .kFrame(K.red, tick: 6, hairline: K.paper.opacity(0.12))
    }

    private func latencyMeter(_ title: String, spokenTitle: String, _ summary: LatencySummary,
                              full: Double) -> some View {
        let ms = summary.last.map { $0 * 1000 }
        return DeckMeter(title: title, value: summary.last, full: full,
                         text: ms.map { String(format: "%.0f MS", $0) } ?? "— MS",
                         spoken: ms.map { String(format: "%.0f milliseconds", $0) } ?? "No data",
                         spokenTitle: spokenTitle, warnsHigh: true)
    }

    private func spokenDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return "\(total / 3600) hours \(total / 60 % 60) minutes"
    }
}

/// A boxed statistic: red OSD title over a large value.
private struct DeckStatTile: View {
    let title: String
    let value: String
    var detail: String?
    var spoken: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(K.osd(11, relativeTo: .caption)).foregroundStyle(K.red)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value).font(K.osd(22, relativeTo: .title3)).lineLimit(1).minimumScaleFactor(0.6)
                if let detail {
                    Text(detail).font(K.osd(11, relativeTo: .caption)).foregroundStyle(K.paper.opacity(0.5))
                        .lineLimit(1)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(K.inkRaised)
        .kFrame(K.red, tick: 6, hairline: K.paper.opacity(0.12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title.capitalized)
        .accessibilityValue(spoken ?? [value, detail].compactMap { $0 }.joined(separator: ", "))
    }
}

/// A row of pixel blocks lit in proportion to `value / full` (`ReadingSessionStats.meterSegments`). Latency meters
/// (`warnsHigh`) turn red past three quarters.
private struct DeckMeter: View {
    let title: String
    let value: Double?
    let full: Double
    let text: String
    let spoken: String
    var spokenTitle: String?
    let warnsHigh: Bool

    private static let segments = 12

    var body: some View {
        let lit = ReadingSessionStats.meterSegments(value: value, full: full, segments: Self.segments)
        let hot = warnsHigh && lit > Self.segments * 3 / 4
        HStack(spacing: 8) {
            Text(title)
                .font(K.osd(11, relativeTo: .caption))
                .foregroundStyle(K.paper.opacity(0.6))
                .frame(width: 64, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 2) {
                ForEach(0..<Self.segments, id: \.self) { index in
                    Rectangle()
                        .fill(index < lit ? (hot ? K.red : K.paper) : K.paper.opacity(0.12))
                        .frame(height: 10)
                }
            }
            Text(text)
                .font(K.osd(11, relativeTo: .caption))
                .foregroundStyle(hot ? K.red : K.paper.opacity(0.8))
                .lineLimit(1)
                .frame(minWidth: 80, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenTitle ?? title)
        .accessibilityValue(spoken)
    }
}
