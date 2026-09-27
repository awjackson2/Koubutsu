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
                    KTag(text: "Notice", filled: true)
                    Text(message).font(K.osd(14))
                    if controller.availability == .needsDownload {
                        Button("Download") { controller.requestDownload() }
                            .buttonStyle(.k(.primary))
                    }
                }
            }
            if controller.displayed.isEmpty {
                Text("WAITING FOR JAPANESE TEXT_").font(K.osd(14)).foregroundStyle(K.paper.opacity(0.55))
            }
            ForEach(controller.displayed) { item in
                VStack(alignment: .leading, spacing: 2) {
                    if showOriginal {
                        line("JP", Text(item.stable.text).font(.title3))
                    }
                    if showTranslation {
                        line("EN", english(item))
                    }
                }
            }
        }
        .foregroundStyle(K.paper)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func line(_ label: String, _ content: some View) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label).font(K.osd(12)).foregroundStyle(K.red).frame(width: 24, alignment: .leading)
            content
        }
    }

    private func english(_ item: DisplayedText) -> some View {
        Group {
            switch item.status {
            case .translating:
                if let previous = item.previousTranslation {
                    Text(previous).font(K.osd(18)).foregroundStyle(.secondary)
                } else {
                    Text("…").foregroundStyle(.secondary)
                }
            case .translated(let text, let fromCache, let latency):
                HStack(alignment: .firstTextBaseline) {
                    Text(text).font(K.osd(18))
                    Text(fromCache ? "CACHE" : String(format: "%.0fMS", latency * 1000))
                        .font(K.osd(11)).foregroundStyle(K.paper.opacity(0.5))
                }
            case .failed(let reason):
                Text(reason).foregroundStyle(K.red).font(K.osd(13))
            case .unavailable:
                Text("TRANSLATION UNAVAILABLE").foregroundStyle(K.paper.opacity(0.55)).font(K.osd(13))
            }
        }
    }
}
