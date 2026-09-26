import KoubutsuCore
import SwiftUI

/// Version-0 translation display: stable Japanese blocks with their English translation, under the video.
struct TranslationPanel: View {
    let controller: TranslationController
    let showOriginal: Bool
    let showTranslation: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let message = controller.statusMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
                    Text(message).font(.callout)
                    if controller.availability == .needsDownload {
                        Button("Download") { controller.requestDownload() }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            if controller.displayed.isEmpty {
                Text("Waiting for Japanese text…").foregroundStyle(.secondary)
            }
            ForEach(controller.displayed) { item in
                VStack(alignment: .leading, spacing: 2) {
                    if let speaker = item.stable.speaker {
                        Text(speaker).font(.caption.bold()).foregroundStyle(.tint).padding(.leading, 34)
                    }
                    if showOriginal {
                        line("JP", Text(item.stable.text).font(.title3))
                    }
                    if showTranslation {
                        line("EN", english(item))
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func line(_ label: String, _ content: some View) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label).font(.caption.bold()).foregroundStyle(.secondary).frame(width: 24, alignment: .leading)
            content
        }
    }

    private func english(_ item: DisplayedText) -> some View {
        Group {
            switch item.status {
            case .translating:
                Text("…").foregroundStyle(.secondary)
            case .translated(let text, let fromCache, let latency):
                HStack(alignment: .firstTextBaseline) {
                    Text(text).font(.title3)
                    Text(fromCache ? "cache" : String(format: "%.0f ms", latency * 1000))
                        .font(.caption2.monospaced()).foregroundStyle(.secondary)
                }
            case .failed(let reason):
                Text(reason).foregroundStyle(.orange).font(.callout)
            case .unavailable:
                Text("translation unavailable").foregroundStyle(.secondary).font(.callout)
            }
        }
    }
}
