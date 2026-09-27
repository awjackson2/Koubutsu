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
    /// User text-size setting for the English in replacement boxes.
    var textScale: Double = 1
    var style: AppSettings.OverlayStyle = .english
    /// Furigana/highlights per line text (furigana style).
    var annotations: (String) -> [ReadingAnnotation]? = { _ in nil }

    private var layout: OverlayLayout { OverlayLayout(textScale: textScale) }

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
                        switch style {
                        case .english: translations(mapper: mapper)
                        case .furigana: readingAids(mapper: mapper)
                        }
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
            .stroke(K.red, lineWidth: 2)
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
                    .font(K.osdFixed(placement.fontSize))
                    .foregroundStyle(K.paper)
                    .lineSpacing(0)
                    .lineLimit(placement.lineLimit)
                    .minimumScaleFactor(0.4)
                    .padding(layout.padding)
                    .frame(width: placement.frame.width, height: placement.frame.height, alignment: .leading)
                    .background(K.ink)
                    .overlay(alignment: .topLeading) { Rectangle().fill(K.red).frame(width: 6, height: 2) }
                    .offset(x: placement.frame.x, y: placement.frame.y)
            }
        }
    }
}

extension VideoOverlayView {
    /// Furigana above kanji runs and underlines under words being learned, on the original Japanese.
    private func readingAids(mapper: CoordinateMapper) -> some View {
        var marks: [ReadingMark] = []
        // The latest OCR lines, not the stabilized tracks: readings need no translation, and tracks are kept
        // on screen for a while after text disappears (which would leave readings floating over nothing).
        let lines = (ocr?.observations ?? []).filter { TextNormalizer.containsJapaneseText($0.text) }
        for line in lines {
            let boxes = CharacterLayout.boxes(for: line)
            for annotation in annotations(line.text) ?? [] {
                guard annotation.range.upperBound <= boxes.count, !annotation.range.isEmpty else { continue }
                let box = boxes[annotation.range].dropFirst().reduce(boxes[annotation.range.lowerBound]) { $0.union($1) }
                marks.append(ReadingMark(id: "\(line.id)-\(annotation.range)-\(annotation.reading ?? "_")",
                                         rect: mapper.viewRect(for: box), reading: annotation.reading,
                                         learning: annotation.isLearning))
            }
        }
        return ForEach(marks) { mark in
            if let reading = mark.reading {
                let size = max(9, min(28, mark.rect.height * 0.42 * textScale))
                Text(reading)
                    .font(K.dotFixed(size))
                    .foregroundStyle(mark.learning ? K.red : K.paper)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 3)
                    .background(K.ink.opacity(0.78))
                    .frame(width: max(mark.rect.width, 1), height: size * 1.3)
                    .offset(x: mark.rect.x, y: mark.rect.y - size * 1.35)
            } else {
                Rectangle()
                    .fill(K.red)
                    .frame(width: mark.rect.width, height: max(2, mark.rect.height * 0.08))
                    .offset(x: mark.rect.x, y: mark.rect.maxY + 1)
            }
        }
    }
}

/// One furigana label or learning underline, in view coordinates.
private struct ReadingMark: Identifiable {
    let id: String
    let rect: PlaneRect
    let reading: String?
    let learning: Bool
}

extension PlaneRect {
    var cgRect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
}
