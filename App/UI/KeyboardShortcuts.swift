import SwiftUI

/// Hardware-keyboard shortcuts. Invisible buttons that stay in the hierarchy even when the bars are hidden
/// (full screen), so the shortcuts always work.
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
            shortcut(.leftArrow, modifiers: []) { Task { await model.skip(by: -10) } }
            shortcut(.rightArrow, modifiers: []) { Task { await model.skip(by: 10) } }
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    private func shortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        Button("", action: action).keyboardShortcut(key, modifiers: modifiers)
    }
}
