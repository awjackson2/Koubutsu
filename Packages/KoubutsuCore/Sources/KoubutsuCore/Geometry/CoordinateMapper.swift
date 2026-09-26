/// A rectangle in view (points) or pixel space. Origin top-left, y down. Platform-neutral stand-in for CGRect.
public struct PlaneRect: Sendable, Hashable, CustomStringConvertible {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public static let zero = PlaneRect(x: 0, y: 0, width: 0, height: 0)

    public var minX: Double { x }
    public var minY: Double { y }
    public var maxX: Double { x + width }
    public var maxY: Double { y + height }

    public func intersects(_ other: PlaneRect) -> Bool {
        minX < other.maxX && other.minX < maxX && minY < other.maxY && other.minY < maxY
    }

    public func isApproximatelyEqual(to other: PlaneRect, tolerance: Double = 1e-6) -> Bool {
        abs(x - other.x) <= tolerance && abs(y - other.y) <= tolerance
            && abs(width - other.width) <= tolerance && abs(height - other.height) <= tolerance
    }

    public var description: String {
        "(\(Int(x.rounded())), \(Int(y.rounded())), \(Int(width.rounded()))×\(Int(height.rounded())))"
    }
}

public struct PlanePoint: Sendable, Hashable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// How video content is fitted into its view (mirrors `AVLayerVideoGravity`).
public enum VideoContentMode: Sendable, Hashable {
    /// Whole frame visible, letterboxed/pillarboxed (`.resizeAspect`).
    case aspectFit
    /// View filled, frame cropped (`.resizeAspectFill`).
    case aspectFill
    /// Frame stretched to the view (`.resize`).
    case stretch
}

/// The single source of truth for converting between coordinate spaces:
///
/// ```
/// Vision (normalized, bottom-left)  ── converted once in the Vision adapter ──▶
/// normalized frame (top-left)  ⇄  source pixels  ⇄  displayed video rect  ⇄  view/overlay points
/// ```
///
/// UI code must not do its own geometry: it asks the mapper.
public struct CoordinateMapper: Sendable, Hashable {
    public var sourceSize: PixelSize
    public var viewSize: (width: Double, height: Double) {
        get { (viewWidth, viewHeight) }
        set { (viewWidth, viewHeight) = newValue }
    }
    public var contentMode: VideoContentMode
    private var viewWidth: Double
    private var viewHeight: Double

    public init(sourceSize: PixelSize, viewWidth: Double, viewHeight: Double, contentMode: VideoContentMode = .aspectFit) {
        self.sourceSize = sourceSize
        self.viewWidth = viewWidth
        self.viewHeight = viewHeight
        self.contentMode = contentMode
    }

    public static func == (lhs: CoordinateMapper, rhs: CoordinateMapper) -> Bool {
        lhs.sourceSize == rhs.sourceSize && lhs.viewWidth == rhs.viewWidth && lhs.viewHeight == rhs.viewHeight
            && lhs.contentMode == rhs.contentMode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sourceSize)
        hasher.combine(viewWidth)
        hasher.combine(viewHeight)
        hasher.combine(contentMode)
    }

    public var isValid: Bool {
        sourceSize.width > 0 && sourceSize.height > 0 && viewWidth > 0 && viewHeight > 0
    }

    /// Where the video frame is drawn inside the view (may extend beyond the view for aspect fill).
    public var displayedVideoRect: PlaneRect {
        guard isValid else { return .zero }
        let sw = Double(sourceSize.width), sh = Double(sourceSize.height)
        switch contentMode {
        case .stretch:
            return PlaneRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        case .aspectFit, .aspectFill:
            let scaleX = viewWidth / sw, scaleY = viewHeight / sh
            let scale = contentMode == .aspectFit ? min(scaleX, scaleY) : max(scaleX, scaleY)
            let w = sw * scale, h = sh * scale
            return PlaneRect(x: (viewWidth - w) / 2, y: (viewHeight - h) / 2, width: w, height: h)
        }
    }

    /// The visible part of the video within the view.
    public var visibleVideoRect: PlaneRect {
        let d = displayedVideoRect
        let x0 = max(d.minX, 0), y0 = max(d.minY, 0)
        let x1 = min(d.maxX, viewWidth), y1 = min(d.maxY, viewHeight)
        return PlaneRect(x: x0, y: y0, width: max(0, x1 - x0), height: max(0, y1 - y0))
    }

    /// Points per source pixel.
    public var scale: Double {
        guard isValid else { return 0 }
        return displayedVideoRect.width / Double(sourceSize.width)
    }

    // MARK: normalized ⇄ source pixels

    public func sourcePixelRect(for rect: NormalizedRect) -> PlaneRect {
        let w = Double(sourceSize.width), h = Double(sourceSize.height)
        return PlaneRect(x: rect.x * w, y: rect.y * h, width: rect.width * w, height: rect.height * h)
    }

    public func normalized(fromSourcePixels rect: PlaneRect) -> NormalizedRect {
        let w = Double(sourceSize.width), h = Double(sourceSize.height)
        return NormalizedRect(x: rect.x / w, y: rect.y / h, width: rect.width / w, height: rect.height / h)
    }

    // MARK: normalized ⇄ view

    public func viewRect(for rect: NormalizedRect) -> PlaneRect {
        let d = displayedVideoRect
        return PlaneRect(x: d.x + rect.x * d.width, y: d.y + rect.y * d.height,
                         width: rect.width * d.width, height: rect.height * d.height)
    }

    public func viewPoint(for point: NormalizedPoint) -> PlanePoint {
        let d = displayedVideoRect
        return PlanePoint(x: d.x + point.x * d.width, y: d.y + point.y * d.height)
    }

    /// Inverse mapping for touches (e.g. selecting a custom region). Nil outside the video.
    public func normalizedPoint(fromView point: PlanePoint) -> NormalizedPoint? {
        let d = displayedVideoRect
        guard d.width > 0, d.height > 0 else { return nil }
        let p = NormalizedPoint(x: (point.x - d.x) / d.width, y: (point.y - d.y) / d.height)
        guard (0...1).contains(p.x), (0...1).contains(p.y) else { return nil }
        return p
    }

    public func normalizedRect(fromView rect: PlaneRect) -> NormalizedRect {
        let d = displayedVideoRect
        guard d.width > 0, d.height > 0 else { return .full }
        return NormalizedRect(x: (rect.x - d.x) / d.width, y: (rect.y - d.y) / d.height,
                              width: rect.width / d.width, height: rect.height / d.height).clamped
    }
}
