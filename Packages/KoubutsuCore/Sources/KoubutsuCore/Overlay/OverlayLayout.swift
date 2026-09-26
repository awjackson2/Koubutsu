/// Input to overlay layout: one translated block and where its Japanese text is.
public struct OverlayItem<ID: Hashable & Sendable>: Sendable {
    public var id: ID
    /// Japanese block bounds, normalized top-left.
    public var sourceBox: NormalizedRect
    /// Number of Japanese lines in the block (used to estimate the source font size).
    public var lineCount: Int

    public init(id: ID, sourceBox: NormalizedRect, lineCount: Int) {
        self.id = id
        self.sourceBox = sourceBox
        self.lineCount = max(1, lineCount)
    }
}

/// Where and how large to draw a translation.
public struct OverlayPlacement<ID: Hashable & Sendable>: Sendable, Hashable {
    public var id: ID
    /// Box in view points covering the Japanese text (grown downward only if the English cannot fit).
    public var frame: PlaneRect
    /// Font size in points that fits the English inside `frame`.
    public var fontSize: Double
    /// Wrapped line count the font was fitted for (renderers should cap lines here and scale down instead
    /// of adding lines, so an estimate error never spills out of the box).
    public var lineLimit: Int
    /// The Japanese text's own box in view points.
    public var sourceFrame: PlaneRect
}

/// Replaces Japanese text in place: each translation box covers the Japanese block it translates (plus
/// padding), and the English font is the largest size, up to one proportional to the Japanese line height,
/// whose wrapped text fits the box. Only when even the minimum font does not fit does a box grow downward;
/// grown boxes that would overlap an earlier box are pushed below it. Everything stays inside the visible video.
public struct OverlayLayout: Sendable {
    public var padding: Double = 4
    public var minimumWidth: Double = 60
    /// English glyphs look right at ~70% of the Japanese line height.
    public var fontScale: Double = 0.7
    public var fontSizeRange: ClosedRange<Double> = 9...44
    /// Rendered line height as a multiple of font size.
    public var lineHeightFactor: Double = 1.2
    /// Average Latin glyph advance as a multiple of font size (semibold, conservative).
    public var glyphWidthFactor: Double = 0.6

    public init() {}

    /// Nominal font for a Japanese box: proportional to its line height.
    public func nominalFontSize(sourceHeight: Double, lineCount: Int) -> Double {
        let jpLineHeight = sourceHeight / Double(max(1, lineCount))
        return min(max(jpLineHeight * fontScale, fontSizeRange.lowerBound), fontSizeRange.upperBound)
    }

    /// Estimated wrapped line count of `textLength` characters in `width` points at `fontSize`.
    public func wrappedLines(textLength: Int, width: Double, fontSize: Double) -> Int {
        let perLine = max(1, (width / (fontSize * glyphWidthFactor)).rounded(.down))
        return max(1, Int((Double(max(1, textLength)) / perLine).rounded(.up)))
    }

    /// Largest font ≤ `nominal` whose wrapped text fits `width`×`height`, and the height it needs.
    public func fit(textLength: Int, width: Double, height: Double,
                    nominal: Double) -> (fontSize: Double, height: Double, lines: Int) {
        let minimum = fontSizeRange.lowerBound
        var font = max(nominal, minimum)
        while true {
            let lines = wrappedLines(textLength: textLength, width: width, fontSize: font)
            let needed = Double(lines) * font * lineHeightFactor
            if needed <= height || font <= minimum { return (font, max(height, needed), lines) }
            font = max(minimum, font - 0.5)
        }
    }

    public func place<ID>(_ items: [OverlayItem<ID>], mapper: CoordinateMapper,
                          textLength: (ID) -> Int = { _ in 1 }) -> [OverlayPlacement<ID>] {
        guard mapper.isValid else { return [] }
        let bounds = mapper.visibleVideoRect
        var placed: [OverlayPlacement<ID>] = []
        let ordered = items.sorted { ($0.sourceBox.minY, $0.sourceBox.minX) < ($1.sourceBox.minY, $1.sourceBox.minX) }
        for item in ordered {
            let source = mapper.viewRect(for: item.sourceBox)
            let width = min(max(source.width + 2 * padding, minimumWidth), bounds.width)
            let baseHeight = source.height + 2 * padding
            let fitted = fit(textLength: textLength(item.id), width: width - 2 * padding,
                             height: source.height,
                             nominal: nominalFontSize(sourceHeight: source.height, lineCount: item.lineCount))
            let height = max(baseHeight, fitted.height + 2 * padding)
            var frame = PlaneRect(x: source.x - padding, y: source.y - padding, width: width, height: height)
            frame.x = min(max(frame.x, bounds.minX), bounds.maxX - frame.width)
            if height > baseHeight {
                // Grown boxes may spill onto later text; push them below earlier boxes they would cover.
                var moved = true
                while moved {
                    moved = false
                    for other in placed where other.frame.intersects(frame) {
                        frame.y = other.frame.maxY + 1
                        moved = true
                    }
                }
            }
            frame.y = min(max(frame.y, bounds.minY), max(bounds.minY, bounds.maxY - frame.height))
            placed.append(OverlayPlacement(id: item.id, frame: frame, fontSize: fitted.fontSize, lineLimit: fitted.lines,
                                           sourceFrame: source))
        }
        return placed
    }
}
