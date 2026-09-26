import KoubutsuCore
import SwiftUI

/// Draws over the video: OCR boxes (debug) and translated text placed over the Japanese it translates.
/// All geometry comes from `CoordinateMapper` / `OverlayLayout`; this view only renders.
struct VideoOverlayView: View {
    let sourceSize: PixelSize?
    let ocr: OCRResult?
    let displayed: [DisplayedText]
    let showBoxes: Bool
    let showTranslations: Bool

    private let layout = OverlayLayout()

    var body: some View {
        GeometryReader { geometry in
            if let sourceSize {
                let mapper = CoordinateMapper(sourceSize: sourceSize, viewWidth: geometry.size.width,
                                              viewHeight: geometry.size.height, contentMode: .aspectFit)
                ZStack(alignment: .topLeading) {
                    if showBoxes, let ocr {
                        ocrBoxes(ocr, mapper: mapper)
                    }
                    if showTranslations {
                        translations(mapper: mapper)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            }
        }
        .allowsHitTesting(false)
    }

    private func ocrBoxes(_ result: OCRResult, mapper: CoordinateMapper) -> some View {
        ForEach(result.observations) { observation in
            let quad = observation.quad
            Path { path in
                if let quad {
                    let points = [quad.topLeft, quad.topRight, quad.bottomRight, quad.bottomLeft]
                        .map { mapper.viewPoint(for: $0) }
                        .map { CGPoint(x: $0.x, y: $0.y) }
                    path.addLines(points)
                    path.closeSubpath()
                } else {
                    path.addRect(mapper.viewRect(for: observation.boundingBox).cgRect)
                }
            }
            .stroke(Color.yellow.opacity(0.9), lineWidth: 2)
        }
    }

    private func translations(mapper: CoordinateMapper) -> some View {
        let translated = displayed.filter { $0.translation != nil }
        let byID = Dictionary(uniqueKeysWithValues: translated.map { ($0.id, $0) })
        let items = translated.map {
            OverlayItem(id: $0.id, sourceBox: $0.stable.boundingBox, lineCount: max(1, $0.stable.lines.count))
        }
        let placements = layout.place(items, mapper: mapper) { id in
            guard let item = byID[id], let text = item.translation else { return 1 }
            return Self.estimatedLines(text: text, box: mapper.viewRect(for: item.stable.boundingBox),
                                       lineCount: max(1, item.stable.lines.count), layout: layout)
        }
        return ForEach(placements, id: \.id) { placement in
            if let text = byID[placement.id]?.translation {
                Text(text)
                    .font(.system(size: placement.fontSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 1)
                    .padding(.horizontal, layout.padding)
                    .padding(.vertical, layout.padding / 2)
                    .frame(width: placement.frame.width, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: placement.frame.height, alignment: .topLeading)
                    .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 6))
                    .offset(x: placement.frame.x, y: placement.frame.y)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: placements.map(\.id))
    }

    /// Rough wrapped-line estimate for layout (average Latin glyph ≈ 0.52 em).
    static func estimatedLines(text: String, box: PlaneRect, lineCount: Int, layout: OverlayLayout) -> Int {
        let font = min(max(box.height / Double(lineCount) * layout.fontScale, layout.fontSizeRange.lowerBound),
                       layout.fontSizeRange.upperBound)
        let width = max(box.width, layout.minimumWidth - 2 * layout.padding)
        let perLine = max(1, width / (font * 0.52))
        return max(1, Int((Double(text.count) / perLine).rounded(.up)))
    }
}

extension PlaneRect {
    var cgRect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
}
