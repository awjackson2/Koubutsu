import KoubutsuCore
import SwiftUI

/// Hardware-keyboard shortcuts. Invisible buttons that stay in the hierarchy even when the bars are hidden
/// (full screen), so the shortcuts always work.
///
/// While study mode is active the arrow keys drive the study navigator (10.8.0): ← → word, ↑ ↓ line, ⇧← ⇧→ shrink
/// or extend by a character, ⌥⇧→ extend by a word. Otherwise ← → skip the file source by 10 s as before and the
/// other arrow shortcuts are disabled (the key goes to the system).
struct KeyboardShortcuts: View {
    struct Actions {
        var toggleFullScreen: () -> Void
        var toggleEnglish: () -> Void
        var toggleStudy: () -> Void
        var showWordBank: () -> Void
        var showReview: () -> Void
        var showRecentLines: () -> Void
        var showSettings: () -> Void
    }

    let model: AppModel
    let study: StudySession
    let actions: Actions

    var body: some View {
        ZStack {
            shortcut("f", modifiers: [], action: actions.toggleFullScreen)
            shortcut("t", modifiers: [], action: actions.toggleEnglish)
            shortcut("s", modifiers: [], action: actions.toggleStudy)
            shortcut("w", modifiers: [], action: actions.showWordBank)
            shortcut("r", modifiers: [], action: actions.showReview)
            shortcut("h", modifiers: [], action: actions.showRecentLines)
            shortcut(",", modifiers: .command, action: actions.showSettings)
            shortcut(.space, modifiers: []) { Task { await model.togglePlayPause() } }
            shortcut(.leftArrow, modifiers: []) {
                if study.isActive { study.move(.previousWord) } else { Task { await model.skip(by: -10) } }
            }
            shortcut(.rightArrow, modifiers: []) {
                if study.isActive { study.move(.nextWord) } else { Task { await model.skip(by: 10) } }
            }
            studyShortcut(.upArrow, modifiers: [], step: .previousLine)
            studyShortcut(.downArrow, modifiers: [], step: .nextLine)
            studyShortcut(.leftArrow, modifiers: .shift, step: .shrinkCharacter)
            studyShortcut(.rightArrow, modifiers: .shift, step: .extendCharacter)
            studyShortcut(.rightArrow, modifiers: [.shift, .option], step: .extendWord)
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    private func studyShortcut(_ key: KeyEquivalent, modifiers: EventModifiers,
                               step: StudyNavigator.Step) -> some View {
        shortcut(key, modifiers: modifiers) { study.move(step) }
            .disabled(!study.isActive)
    }

    private func shortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        Button("", action: action).keyboardShortcut(key, modifiers: modifiers)
    }
}
