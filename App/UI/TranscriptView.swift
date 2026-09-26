import KoubutsuCore
import SwiftUI
import UniformTypeIdentifiers

/// Timestamped JP/EN transcript of the current video. Tap a line to jump there; export SRT or CSV.
struct TranscriptView: View {
    let model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let transcript = model.translation.transcript
        let entries = transcript.resolved
        NavigationStack {
            List(entries) { entry in
                Button {
                    Task {
                        await model.seek(to: entry.start)
                        dismiss()
                    }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(MediaTimeFormat.clock(entry.start))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.japanese)
                            if let english = entry.english {
                                Text(english).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView("No dialogue yet", systemImage: "text.bubble",
                                           description: Text("Stable Japanese text appears here as the video plays."))
                }
            }
            .safeAreaInset(edge: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    if let progress = model.analysisProgress {
                        ProgressView(value: progress) { Text("Analyzing whole video…") }
                    } else {
                        Button {
                            Task { await model.analyzeCurrentVideo() }
                        } label: {
                            Label("Analyze whole video", systemImage: "text.viewfinder")
                        }
                    }
                    if let summary = model.analysisSummary {
                        Text(summary).font(.caption2.monospaced()).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.bar)
            }
            .navigationTitle("Transcript (\(entries.count))")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ShareLink("Subtitles JP + EN (.srt)", item: TranscriptFile(
                            name: "transcript_bilingual.srt", contents: transcript.srt(.bilingual)),
                                  preview: SharePreview("transcript_bilingual.srt"))
                        ShareLink("Subtitles EN (.srt)", item: TranscriptFile(
                            name: "transcript_en.srt", contents: transcript.srt(.english)),
                                  preview: SharePreview("transcript_en.srt"))
                        ShareLink("Subtitles JP (.srt)", item: TranscriptFile(
                            name: "transcript_ja.srt", contents: transcript.srt(.japanese)),
                                  preview: SharePreview("transcript_ja.srt"))
                        ShareLink("Table (.csv)", item: TranscriptFile(
                            name: "transcript.csv", contents: transcript.csv()),
                                  preview: SharePreview("transcript.csv"))
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(entries.isEmpty)
                }
            }
        }
    }
}

/// A text file handed to the share sheet (saved to Files, AirDrop, …). Created on device only.
struct TranscriptFile: Transferable {
    let name: String
    let contents: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .plainText) { file in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(file.name)
            try file.contents.write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}
