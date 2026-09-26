import KoubutsuCore
import SwiftUI

/// Bottom panel while studying: what is selected, where it came from, and its translation.
struct StudyPanel: View {
    let session: StudySession
    let done: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Study", systemImage: "book")
                    .font(.headline)
                Spacer()
                if !session.spans.isEmpty {
                    Button("Clear") { session.clearSelection() }
                }
                Button("Done", action: done)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.escape, modifiers: [])
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if session.spans.isEmpty {
                        Text(hint).foregroundStyle(.secondary)
                    } else {
                        Text(session.selectedText)
                            .font(.system(size: 34, weight: .semibold))
                            .textSelection(.enabled)
                        if let line = session.spans.first?.lineText, session.spans.count == 1,
                           line != session.selectedText {
                            Text(context(line)).font(.title3)
                        }
                        if session.isTranslating {
                            ProgressView().controlSize(.small)
                        } else if let translation = session.translation {
                            Text(translation).font(.title3).foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        } else {
                            Text("Translation unavailable").font(.callout).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(height: 210, alignment: .top)
        .background(Color(white: 0.07))
        .foregroundStyle(.white)
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
