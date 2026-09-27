import KoubutsuCore
import SwiftUI
import UIKit

/// The lines read this session with their English, newest first. In memory only (the history the translator
/// already keeps for context); nothing is saved or exported.
struct RecentLinesView: View {
    let controller: TranslationController
    @State private var narrow = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var entries: [DialogueEntry] { controller.history.entries.reversed() }
    /// Narrow sheet or accessibility text sizes: Copy all and Clear move out of the header into the list.
    private var stacked: Bool { narrow || dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        VStack(spacing: 0) {
            KSheetHeader(title: "Recent lines", subtitle: "\(entries.count) LOGGED · THIS SESSION") {
                HStack(spacing: 10) {
                    if !stacked { listActions }
                    Button { dismiss() } label: { Text("Done").kButtonTarget() }.buttonStyle(.k(.secondary))
                }
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if stacked {
                        HStack(spacing: 10) { listActions }
                            .padding(.bottom, 10)
                    }
                    if entries.isEmpty {
                        Text("NO LINES YET_").font(K.osd(16)).foregroundStyle(K.ink.opacity(0.5)).padding(.vertical, 20)
                    }
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack(alignment: .firstTextBaseline, spacing: 14) {
                            HStack(alignment: .firstTextBaseline, spacing: 14) {
                                Text(String(format: "%03d", entries.count - index)).font(K.osd(14)).foregroundStyle(K.red)
                                    .accessibilityLabel("Line \(entries.count - index)")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.translation?.uppercased() ?? "…").font(K.osd(17))
                                    Text(entry.source).font(.callout).foregroundStyle(K.ink.opacity(0.6))
                                }
                                .textSelection(.enabled)
                            }
                            .accessibilityElement(children: .combine)
                            Spacer(minLength: 8)
                            Button { UIPasteboard.general.string = text(for: entry) } label: {
                                PixelIcon("copy", size: 16).kButtonTarget()
                            }
                            .buttonStyle(.k(.ghost))
                            .accessibilityLabel("Copy line \(entries.count - index)")
                        }
                        .padding(.vertical, 10)
                        Rectangle().fill(K.ink.opacity(0.15)).frame(height: 1)
                    }
                }
                .padding(narrow ? 16 : 20)
            }
        }
        .trackingNarrowWidth($narrow)
        .kSheet()
        .kTexture(grain: 0.8, scanlines: 0)
    }

    @ViewBuilder private var listActions: some View {
        Button {
            UIPasteboard.general.string = entries.reversed().map(text(for:)).joined(separator: "\n\n")
        } label: {
            Text("Copy all").kButtonTarget()
        }
        .buttonStyle(.k(.secondary))
        .disabled(entries.isEmpty)
        Button { controller.clearHistory() } label: { Text("Clear").kButtonTarget() }
            .buttonStyle(.k(.ghost))
            .disabled(entries.isEmpty)
            .accessibilityLabel("Clear recent lines")
    }

    private func text(for entry: DialogueEntry) -> String {
        [entry.source, entry.translation].compactMap { $0 }.joined(separator: "\n")
    }
}
