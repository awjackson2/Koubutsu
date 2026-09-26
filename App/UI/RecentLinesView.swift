import KoubutsuCore
import SwiftUI
import UIKit

/// The lines read this session with their English, newest first. In memory only (the history the translator
/// already keeps for context); nothing is saved or exported.
struct RecentLinesView: View {
    let controller: TranslationController
    @Environment(\.dismiss) private var dismiss

    private var entries: [DialogueEntry] { controller.history.entries.reversed() }

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    Text("No lines yet.").foregroundStyle(.secondary)
                }
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.translation ?? "…")
                            .font(.body.weight(.semibold))
                        Text(entry.source)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .textSelection(.enabled)
                    .swipeActions {
                        Button("Copy") { UIPasteboard.general.string = text(for: entry) }
                            .tint(.blue)
                    }
                    .contextMenu {
                        Button("Copy English") { UIPasteboard.general.string = entry.translation ?? "" }
                        Button("Copy Japanese") { UIPasteboard.general.string = entry.source }
                    }
                }
            }
            .navigationTitle("Recent lines")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear", role: .destructive) { controller.clearHistory() }
                        .disabled(entries.isEmpty)
                }
                ToolbarItem {
                    Button("Copy all") {
                        UIPasteboard.general.string = entries.reversed().map(text(for:)).joined(separator: "\n\n")
                    }
                    .disabled(entries.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func text(for entry: DialogueEntry) -> String {
        [entry.source, entry.translation].compactMap { $0 }.joined(separator: "\n")
    }
}
