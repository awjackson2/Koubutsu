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
/// whose wrapped text fits the box. English that would need a font below `readableFontFraction` of that size
/// first widens its box rightward into free space; only then does the font go down to the minimum and the box
/// grow downward, again only into free space. A box never covers another block's Japanese or an earlier box,
/// and everything stays inside the visible video.
public struct OverlayLayout: Sendable {
    public var padding: Double = 4
    public var minimumWidth: Double = 60
    /// English glyphs look right at ~70% of the Japanese line height.
    public var fontScale: Double = 0.7
    public var fontSizeRange: ClosedRange<Double> = 9...44
    /// Below this fraction of the nominal font a box widens into free space before shrinking further.
    public var readableFontFraction: Double = 0.6
    /// Rendered line height as a multiple of font size.
    public var lineHeightFactor: Double = 1.2
    /// Average Latin glyph advance as a multiple of font size (semibold, conservative).
    public var glyphWidthFactor: Double = 0.6

    public init() {}

    /// Layout with English text scaled by `textScale` (user setting): nominal and maximum font both scale.
    public init(textScale: Double) {
        fontScale *= textScale
        fontSizeRange = fontSizeRange.lowerBound...(fontSizeRange.upperBound * max(textScale, 0.1))
    }

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

    /// Largest font ≤ `nominal` (and ≥ `floor`, default the minimum) whose wrapped text fits `width`×`height`,
    /// the height it needs, and whether it fits.
    public func fit(textLength: Int, width: Double, height: Double, nominal: Double,
                    floor: Double? = nil) -> (fontSize: Double, height: Double, lines: Int) {
        let minimum = max(floor ?? fontSizeRange.lowerBound, fontSizeRange.lowerBound)
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
        let ordered = items.sorted { ($0.sourceBox.minY, $0.sourceBox.minX) < ($1.sourceBox.minY, $1.sourceBox.minX) }
        let sources = ordered.map { mapper.viewRect(for: $0.sourceBox) }
        var placed: [OverlayPlacement<ID>] = []
        for (index, item) in ordered.enumerated() {
            let source = sources[index]
            // Other blocks' Japanese and earlier boxes; a box may cover their padding, never their text.
            let obstacles = sources.enumerated().filter { $0.offset != index }.map(\.element) + placed.map(\.frame)
            let length = textLength(item.id)
            let nominal = nominalFontSize(sourceHeight: source.height, lineCount: item.lineCount)
            let readable = nominal * readableFontFraction
            var frame = PlaneRect(x: source.x - padding, y: source.y - padding,
                                  width: min(max(source.width + 2 * padding, minimumWidth), bounds.width),
                                  height: source.height + 2 * padding)
            frame.x = min(max(frame.x, bounds.minX), bounds.maxX - frame.width)
            frame.y = min(max(frame.y, bounds.minY), max(bounds.minY, bounds.maxY - frame.height))
            let inner = source.height
            var fitted = fit(textLength: length, width: frame.width - 2 * padding, height: inner, nominal: nominal,
                             floor: readable)
            if fitted.height > inner {
                // Widen rightward into free space (never over other text).
                let right = obstacles.filter { $0.minX >= source.maxX - 1e-9 && overlapsRows($0, source) }
                    .map(\.minX).min() ?? bounds.maxX
                frame.width = max(frame.width, min(right, bounds.maxX) - frame.x)
                fitted = fit(textLength: length, width: frame.width - 2 * padding, height: inner, nominal: nominal,
                             floor: readable)
                if fitted.height > inner {
                    fitted = fit(textLength: length, width: frame.width - 2 * padding, height: inner, nominal: nominal)
                }
            }
            if fitted.height > inner {
                // Grow downward, only into free space.
                let below = obstacles.filter { $0.minY >= source.maxY - 1e-9 && overlapsColumns($0, frame) }
                    .map(\.minY).min() ?? bounds.maxY
                let available = max(inner, min(below, bounds.maxY) - frame.y - 2 * padding)
                frame.height = max(frame.height, min(fitted.height, available) + 2 * padding)
                let lines = max(1, Int(((frame.height - 2 * padding) / (fitted.fontSize * lineHeightFactor)).rounded(.down)))
                fitted.lines = min(fitted.lines, lines)
            }
            placed.append(OverlayPlacement(id: item.id, frame: frame, fontSize: fitted.fontSize,
                                           lineLimit: fitted.lines, sourceFrame: source))
        }
        return placed
    }

    /// Shares at least a quarter of the shorter height (lines whose boxes merely touch do not).
    private func overlapsRows(_ a: PlaneRect, _ b: PlaneRect) -> Bool {
        min(a.maxY, b.maxY) - max(a.minY, b.minY) > 0.25 * min(a.height, b.height)
    }

    private func overlapsColumns(_ a: PlaneRect, _ b: PlaneRect) -> Bool {
        min(a.maxX, b.maxX) - max(a.minX, b.minX) > 0
    }
}
