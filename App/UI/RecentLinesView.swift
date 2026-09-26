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
        VStack(spacing: 0) {
            KSheetHeader(title: "Recent lines", subtitle: "\(entries.count) LOGGED · THIS SESSION") {
                HStack(spacing: 10) {
                    Button("Copy all") {
                        UIPasteboard.general.string = entries.reversed().map(text(for:)).joined(separator: "\n\n")
                    }
                    .buttonStyle(.k(.secondary))
                    .disabled(entries.isEmpty)
                    Button("Clear") { controller.clearHistory() }
                        .buttonStyle(.k(.ghost))
                        .disabled(entries.isEmpty)
                    Button("Done") { dismiss() }.buttonStyle(.k(.secondary))
                }
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if entries.isEmpty {
                        Text("NO LINES YET_").font(K.osd(16)).foregroundStyle(K.ink.opacity(0.5)).padding(.vertical, 20)
                    }
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack(alignment: .firstTextBaseline, spacing: 14) {
                            Text(String(format: "%03d", entries.count - index)).font(K.osd(14)).foregroundStyle(K.red)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.translation?.uppercased() ?? "…").font(K.osd(17))
                                Text(entry.source).font(.callout).foregroundStyle(K.ink.opacity(0.6))
                            }
                            .textSelection(.enabled)
                            Spacer(minLength: 8)
                            Button { UIPasteboard.general.string = text(for: entry) } label: { PixelIcon("copy", size: 16) }
                                .buttonStyle(.k(.ghost))
                        }
                        .padding(.vertical, 10)
                        Rectangle().fill(K.ink.opacity(0.15)).frame(height: 1)
                    }
                }
                .padding(20)
            }
        }
        .kSheet()
        .kTexture(grain: 0.8, scanlines: 0)
    }

    private func text(for entry: DialogueEntry) -> String {
        [entry.source, entry.translation].compactMap { $0 }.joined(separator: "\n")
    }
}
