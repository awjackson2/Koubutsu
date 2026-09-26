import KoubutsuCore
import SwiftUI

/// Lists the most recent OCR result: Japanese text, confidence and normalized bounding box.
struct RecognizedTextPanel: View {
    let result: OCRResult?
    let status: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let status {
                Text(status).foregroundStyle(.orange)
            }
            if let result, !result.observations.isEmpty {
                ForEach(result.observations) { observation in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("JP").font(.caption.bold()).foregroundStyle(.secondary)
                        Text(observation.text).font(.title3)
                        Spacer(minLength: 8)
                        Text(String(format: "%.2f", observation.confidence))
                            .font(.caption.monospaced())
                            .foregroundStyle(observation.confidence >= 0.5 ? Color.green : Color.orange)
                        Text(observation.boundingBox.description)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text(result == nil ? "Waiting for OCR…" : "No text recognized")
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
