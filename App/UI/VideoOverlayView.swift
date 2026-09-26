import KoubutsuCore
import SwiftUI

/// Draws over the video: OCR boxes (debug) and English replacing the Japanese it translates, in place.
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

    /// Replace in place: an opaque box over each Japanese block with the English fitted inside it.
    private func translations(mapper: CoordinateMapper) -> some View {
        let shown = displayed.filter { $0.visibleTranslation != nil }
        let byID = Dictionary(uniqueKeysWithValues: shown.map { ($0.id, $0) })
        let items = shown.map {
            OverlayItem(id: $0.id, sourceBox: $0.stable.boundingBox, lineCount: max(1, $0.stable.lines.count))
        }
        let placements = layout.place(items, mapper: mapper) { id in byID[id]?.visibleTranslation?.count ?? 1 }
        return ForEach(placements, id: \.id) { placement in
            if let text = byID[placement.id]?.visibleTranslation {
                Text(text)
                    .font(.system(size: placement.fontSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineSpacing(0)
                    .minimumScaleFactor(0.6)
                    .padding(layout.padding)
                    .frame(width: placement.frame.width, height: placement.frame.height, alignment: .leading)
                    .background(Color(white: 0.06).opacity(0.94), in: RoundedRectangle(cornerRadius: 4))
                    .offset(x: placement.frame.x, y: placement.frame.y)
            }
        }
    }
}

extension PlaneRect {
    var cgRect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
}
