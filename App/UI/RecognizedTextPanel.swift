import KoubutsuCore
import SwiftUI

/// Lists the most recent OCR result: Japanese text, confidence and normalized bounding box.
struct RecognizedTextPanel: View {
    let result: OCRResult?
    let status: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let status {
                Text(status.uppercased()).font(K.osd(14)).foregroundStyle(K.red)
            }
            if let result, !result.observations.isEmpty {
                ForEach(result.observations) { observation in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("JP").font(K.osd(12)).foregroundStyle(K.red)
                        Text(observation.text).font(.title3)
                        Spacer(minLength: 8)
                        Text(String(format: "%.2f", observation.confidence))
                            .font(K.osd(12))
                            .foregroundStyle(observation.confidence >= 0.5 ? K.paper : K.red)
                        Text(observation.boundingBox.description)
                            .font(K.osd(11))
                            .foregroundStyle(K.paper.opacity(0.5))
                    }
                }
            } else {
                Text(result == nil ? "WAITING FOR OCR_" : "NO TEXT RECOGNIZED")
                    .font(K.osd(14))
                    .foregroundStyle(K.paper.opacity(0.55))
            }
        }
        .foregroundStyle(K.paper)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
