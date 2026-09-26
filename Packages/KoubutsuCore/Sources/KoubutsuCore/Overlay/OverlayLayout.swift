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
    /// Box in view points. Width is fixed; the renderer may grow the height to fit wrapped text.
    public var frame: PlaneRect
    /// Font size in points, derived from the Japanese line height.
    public var fontSize: Double
    /// The Japanese text's own box in view points (for covering the original).
    public var sourceFrame: PlaneRect
}

/// Places translated text over the Japanese it replaces.
///
/// Each translation box starts at the Japanese block's top-left, at least as wide as the block (with a minimum
/// width so short Japanese like 「はい」 still fits "Yes"), using a font size proportional to the Japanese line
/// height. Boxes that would overlap an already placed box are pushed below it; everything is kept inside the
/// visible video area.
public struct OverlayLayout: Sendable {
    public var padding: Double = 6
    public var minimumWidth: Double = 120
    /// English glyphs look right at ~70% of the Japanese line height.
    public var fontScale: Double = 0.7
    public var fontSizeRange: ClosedRange<Double> = 12...44
    /// Estimated rendered height per line as a multiple of font size.
    public var lineHeightFactor: Double = 1.25

    public init() {}

    public func place<ID>(_ items: [OverlayItem<ID>], mapper: CoordinateMapper,
                          estimatedLines: (ID) -> Int = { _ in 1 }) -> [OverlayPlacement<ID>] {
        guard mapper.isValid else { return [] }
        let bounds = mapper.visibleVideoRect
        var placed: [OverlayPlacement<ID>] = []
        let ordered = items.sorted { ($0.sourceBox.minY, $0.sourceBox.minX) < ($1.sourceBox.minY, $1.sourceBox.minX) }
        for item in ordered {
            let source = mapper.viewRect(for: item.sourceBox)
            let jpLineHeight = source.height / Double(item.lineCount)
            let font = min(max(jpLineHeight * fontScale, fontSizeRange.lowerBound), fontSizeRange.upperBound)
            let width = min(max(source.width + 2 * padding, minimumWidth), bounds.width)
            let lines = Double(max(1, estimatedLines(item.id)))
            let height = max(source.height + 2 * padding, lines * font * lineHeightFactor + 2 * padding)
            var frame = PlaneRect(x: source.x - padding, y: source.y - padding, width: width, height: height)
            // Keep horizontally inside the visible video.
            frame.x = min(max(frame.x, bounds.minX), bounds.maxX - frame.width)
            // Resolve overlaps by moving below earlier boxes.
            var moved = true
            while moved {
                moved = false
                for other in placed where other.frame.intersects(frame) {
                    frame.y = other.frame.maxY + 2
                    moved = true
                }
            }
            // Keep vertically inside; if pushed past the bottom, clamp (overlap is preferable to disappearing).
            frame.y = min(max(frame.y, bounds.minY), max(bounds.minY, bounds.maxY - frame.height))
            placed.append(OverlayPlacement(id: item.id, frame: frame, fontSize: font, sourceFrame: source))
        }
        return placed
    }
}
