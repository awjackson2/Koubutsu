import KoubutsuCore
import SwiftUI

/// Bottom panel while studying: what is selected, where it came from, and its translation.
///
/// Adapts to the layout class (10.5.0): regular (iPad) is the fixed 210 pt panel as before; compact portrait fills
/// the height its layout offers (the chrome region below the video); compact landscape is a bottom strip over the
/// frozen frame capped at `VideoStageLayout.overlayStudyFraction` of the stage height, which collapses to its
/// one-line header. Heights come from `VideoStageLayout`.
///
/// The navigator pad (10.8.0) steps the selection by word, line and character: inline in the header on regular and
/// compact landscape (no extra height), its own row under the header in compact portrait.
struct StudyPanel: View {
    let session: StudySession
    let store: (any DictionaryStore)?
    let bank: WordBankStore
    /// Game or video name saved with words.
    let source: String?
    /// Compact landscape: the stage height the strip is budgeted against. Nil elsewhere.
    var overlayStageHeight: Double?
    let done: () -> Void
    @State private var card: WordCardContent?
    /// Compact landscape: the strip shows only its header, so the whole frozen frame is visible.
    @State private var collapsed = false
    @Environment(\.layoutClass) private var layoutClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isCompact: Bool { layoutClass.isCompact }
    private var isLandscapeStrip: Bool { layoutClass == .compactLandscape }
    /// Portrait has height to spare but not width: the pad gets its own row there.
    private var padInHeader: Bool { layoutClass != .compactPortrait }
    private var selectedCount: Int { session.spans.reduce(0) { $0 + $1.range.count } }
    private var selectionDescription: String {
        selectedCount == 1 ? "1 character selected" : "\(selectedCount) characters selected"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 8) {
            header
            if !padInHeader {
                StudyNavigatorPad(session: session)
                    .frame(maxWidth: .infinity)
            }
            if !(isLandscapeStrip && collapsed) {
                content
            }
        }
        // Regular keeps the system default padding (nil length), as before.
        .padding(.horizontal, isCompact ? 12 : nil)
        .padding(.vertical, isCompact ? (isLandscapeStrip ? 6 : 8) : nil)
        .frame(height: fixedHeight, alignment: .top)
        .frame(maxHeight: layoutClass == .compactPortrait ? CGFloat.infinity : nil, alignment: .top)
        .clipped()
        .kSurface(.ink)
        .overlay(alignment: .top) { Rectangle().fill(K.red).frame(height: 2) }
        .onChange(of: session.words.first?.id) { _, id in
            if id != nil, session.autoOpenCard {
                session.autoOpenCard = false
                openCard(session.words)
            }
        }
        .onChange(of: session.spans) { _, spans in
            // A new selection always shows its result.
            if !spans.isEmpty { collapsed = false }
        }
        .sheet(item: $card) { content in
            WordCardView(content: content, store: store, onSave: { result in
                bank.save(result, sentence: content.sentence, translation: content.sentenceTranslation, source: source,
                          mediaTime: session.frameTiming?.presentationTime.seconds, image: session.lineCrop())
            }, isSaved: { bank.isSaved($0) })
                .presentationDetents(cardDetents)
        }
        .background(Color(white: 0.07))
        .foregroundStyle(.white)
        .animation(K.snap, value: collapsed)
    }

    /// Regular: 210 pt. Compact landscape: the strip, or its header when collapsed. Compact portrait: nil, so the
    /// panel fills the height the layout offers.
    private var fixedHeight: CGFloat? {
        switch layoutClass {
        case .regular:
            return CGFloat(VideoStageLayout.regularStudyPanelHeight)
        case .compactPortrait:
            return nil
        case .compactLandscape:
            guard let overlayStageHeight else { return nil }
            return CGFloat(VideoStageLayout.overlayStudyPanelHeight(stageHeight: overlayStageHeight,
                                                                    collapsed: collapsed))
        }
    }

    /// A half-height card is a sliver when the screen is short (iPhone landscape): open it full height there.
    private var cardDetents: Set<PresentationDetent> {
        verticalSizeClass == .compact || layoutClass == .compactLandscape ? [.large] : [.medium, .large]
    }

    /// Selected text: 34 pt on the iPad, smaller where the panel is short.
    private var selectedTextSize: CGFloat {
        switch layoutClass {
        case .regular: 34
        case .compactPortrait: 26
        case .compactLandscape: 22
        }
    }

    /// One line on every width: icon, STUDY, selection count, the navigator pad (regular and landscape), then Clear,
    /// collapse (landscape) and Done, each a 44 pt target. In the landscape strip the STUDY title gives way to the
    /// pad on narrow phones.
    private var header: some View {
        HStack(spacing: isCompact ? 6 : 10) {
            Group {
                if isLandscapeStrip {
                    ViewThatFits(in: .horizontal) {
                        titleGroup(showsTitle: true)
                        titleGroup(showsTitle: false)
                    }
                } else {
                    titleGroup(showsTitle: true)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Study")
            .accessibilityValue(selectionDescription)
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
            if padInHeader {
                StudyNavigatorPad(session: session)
            }
            if !session.spans.isEmpty {
                Button { session.clearSelection() } label: { Text("Clear").kButtonTarget() }
                    .buttonStyle(.k(.ghost))
                    .accessibilityLabel("Clear selection")
            }
            if isLandscapeStrip {
                Button { collapsed.toggle() } label: {
                    PixelIcon("chevron", size: 16)
                        .rotationEffect(.degrees(collapsed ? -90 : 90))
                }
                .buttonStyle(KIconButtonStyle())
                .accessibilityLabel(collapsed ? "Expand study panel" : "Collapse study panel")
            }
            Button(action: done) { Text("Done").kButtonTarget() }
                .buttonStyle(.k(.primary))
                .keyboardShortcut(.escape, modifiers: [])
                .accessibilityLabel("Done studying")
                .accessibilityHint("Returns to the live video")
        }
    }

    private func titleGroup(showsTitle: Bool) -> some View {
        HStack(spacing: isCompact ? 6 : 10) {
            PixelIcon("study", size: isCompact ? 18 : 24).foregroundStyle(K.red)
            if showsTitle { Text("STUDY").font(K.osd(isCompact ? 16 : 20)) }
            if !isCompact { BlockMarks() }
            Text(String(format: "SEL %02d", selectedCount))
                .font(K.osd(isCompact ? 12 : 13)).foregroundStyle(K.paper.opacity(0.55))
        }
        .lineLimit(1)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                if session.spans.isEmpty {
                    HStack(spacing: 6) {
                        Text(hint.uppercased()).font(K.osd(isCompact ? 14 : 16)).foregroundStyle(K.paper.opacity(0.6))
                        BlinkingCursor().accessibilityHidden(true)
                    }
                } else {
                    Text(session.selectedText)
                        .font(.system(size: selectedTextSize, weight: .semibold))
                        .textSelection(.enabled)
                    if let line = session.spans.first?.lineText, session.spans.count == 1,
                       line != session.selectedText {
                        Text(context(line)).font(isCompact ? .body : .title3)
                    }
                    if let best = session.words.first {
                        Button { openCard(session.words) } label: {
                            HStack(alignment: .firstTextBaseline) {
                                WordSummary(result: best, compact: isLandscapeStrip)
                                Spacer(minLength: 4)
                                KTag(text: "Card ▶")
                            }
                            .frame(minHeight: KIconButtonStyle.minimumTarget)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .wordCardButtonAccessibility(best)
                        if session.words.count > 1 {
                            Text("Also: " + session.words.dropFirst().prefix(4)
                                .map { "\($0.headword)【\($0.reading)】" }.joined(separator: "  "))
                                .font(.callout).foregroundStyle(K.paper.opacity(0.6))
                        }
                    }
                    if !session.tokens.isEmpty {
                        ForEach(Array(session.tokens.enumerated()), id: \.offset) { _, token in
                            if let best = token.results.first {
                                Button { openCard(token.results) } label: {
                                    WordSummary(result: best, compact: true)
                                        .frame(maxWidth: .infinity, minHeight: KIconButtonStyle.minimumTarget,
                                               alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .wordCardButtonAccessibility(best)
                            }
                        }
                    }
                    if session.isTranslating {
                        HStack(spacing: 4) {
                            Text("TRANSLATING").font(K.osd(14)).foregroundStyle(K.red)
                            BlinkingCursor(width: 8, height: 14).accessibilityHidden(true)
                        }
                    } else if let translation = session.translation {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("EN").font(K.osd(12)).foregroundStyle(K.red)
                                .accessibilityLabel("English")
                            Text(translation).font(K.osd(isCompact ? 16 : 18)).foregroundStyle(K.paper.opacity(0.85))
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
                : "Tap a word, drag over a phrase, or use the arrows."
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

/// Arrow controls for the study selection (10.8.0): ◀ ▶ word, ▲ ▼ line, − ＋ character and ＋▶ word. Each is a 44 pt
/// `KIconButtonStyle` target, disabled (dimmed) where the step cannot move. Arrows are the pixel chevron rotated;
/// the minus is drawn to match the pixel plus (a 14×4 bar on a 16 grid).
///
/// VoiceOver: the ◀ ▶ pair is one adjustable element ("Word", valued with the selection; swipe up or down to step);
/// the other controls are labelled buttons.
private struct StudyNavigatorPad: View {
    let session: StudySession
    private let iconSize: CGFloat = 18

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 0) {
                stepButton(.previousWord, label: "Previous word") { arrow(degrees: 180) }
                stepButton(.nextWord, label: "Next word") { arrow(degrees: 0) }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Word")
            .accessibilityValue(session.spans.isEmpty ? "None selected" : session.selectedText)
            .accessibilityHint("Swipe up or down to select the next or previous word")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: session.move(.nextWord)
                case .decrement: session.move(.previousWord)
                @unknown default: break
                }
            }
            separator
            HStack(spacing: 0) {
                stepButton(.previousLine, label: "Previous line") { arrow(degrees: -90) }
                stepButton(.nextLine, label: "Next line") { arrow(degrees: 90) }
            }
            separator
            HStack(spacing: 0) {
                stepButton(.shrinkCharacter, label: "Shrink selection") { minus }
                stepButton(.extendCharacter, label: "Extend selection") { PixelIcon("plus", size: iconSize) }
                stepButton(.extendWord, label: "Extend selection by a word") {
                    HStack(spacing: 1) {
                        PixelIcon("plus", size: 10)
                        PixelIcon("chevron", size: 14)
                    }
                }
            }
        }
        .fixedSize()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Selection navigator")
    }

    private func stepButton<Icon: View>(_ step: StudyNavigator.Step, label: String,
                                        @ViewBuilder icon: () -> Icon) -> some View {
        let enabled = session.canMove(step)
        return Button { session.move(step) } label: {
            icon().opacity(enabled ? 1 : 0.35)
        }
        .buttonStyle(KIconButtonStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func arrow(degrees: Double) -> some View {
        PixelIcon("chevron", size: iconSize).rotationEffect(.degrees(degrees))
    }

    private var minus: some View {
        Rectangle()
            .frame(width: iconSize * 14 / 16, height: iconSize * 4 / 16)
            .frame(width: iconSize, height: iconSize)
    }

    private var separator: some View {
        Rectangle()
            .fill(K.paper.opacity(0.25))
            .frame(width: 1, height: 24)
            .accessibilityHidden(true)
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

private extension View {
    /// A dictionary match row that opens the word card (10.5.0): read as the headword and reading, with the first
    /// meanings as its value; the "Card ▶" tag is folded into the hint. Applied to the `Button`, which is already
    /// one VoiceOver element, so its label replaces the visual content.
    func wordCardButtonAccessibility(_ result: LookupResult) -> some View {
        accessibilityLabel(result.reading == result.headword ? result.headword
                                                             : "\(result.headword), \(result.reading)")
            .accessibilityValue(result.entry.senses.prefix(2).map { $0.glosses.prefix(2).joined(separator: ", ") }
                .joined(separator: "; "))
            .accessibilityHint("Opens the word card")
    }
}
