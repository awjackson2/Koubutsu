/// A rectangle in normalized image coordinates: origin at the TOP-LEFT of the frame, x right, y down,
/// all values in 0...1 of the frame's width/height.
///
/// This is Koubutsu's canonical coordinate space for anything recognized in a frame. Vision reports
/// bottom-left-origin rectangles; convert once at the adapter boundary with `init(bottomLeftOrigin:...)`.
/// Mapping to view coordinates is the coordinate-mapping layer's job (Major 3), never ad hoc UI math.
public struct NormalizedRect: Sendable, Hashable, Codable, CustomStringConvertible {
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

    /// Converts from a bottom-left-origin normalized rect (Vision's convention).
    public init(bottomLeftOriginX x: Double, y: Double, width: Double, height: Double) {
        self.init(x: x, y: 1 - y - height, width: width, height: height)
    }

    public static let full = NormalizedRect(x: 0, y: 0, width: 1, height: 1)

    public var minX: Double { x }
    public var minY: Double { y }
    public var maxX: Double { x + width }
    public var maxY: Double { y + height }
    public var midX: Double { x + width / 2 }
    public var midY: Double { y + height / 2 }
    public var area: Double { Swift.max(0, width) * Swift.max(0, height) }

    /// The same rect expressed with a bottom-left origin (for handing back to Vision, e.g. regionOfInterest).
    public var bottomLeftOrigin: (x: Double, y: Double, width: Double, height: Double) {
        (x, 1 - y - height, width, height)
    }

    /// Clamped to the unit square.
    public var clamped: NormalizedRect {
        let x0 = Swift.min(Swift.max(x, 0), 1), y0 = Swift.min(Swift.max(y, 0), 1)
        let x1 = Swift.min(Swift.max(maxX, 0), 1), y1 = Swift.min(Swift.max(maxY, 0), 1)
        return NormalizedRect(x: x0, y: y0, width: Swift.max(0, x1 - x0), height: Swift.max(0, y1 - y0))
    }

    public func intersection(_ other: NormalizedRect) -> NormalizedRect? {
        let x0 = Swift.max(minX, other.minX), y0 = Swift.max(minY, other.minY)
        let x1 = Swift.min(maxX, other.maxX), y1 = Swift.min(maxY, other.maxY)
        guard x1 > x0, y1 > y0 else { return nil }
        return NormalizedRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    public func union(_ other: NormalizedRect) -> NormalizedRect {
        let x0 = Swift.min(minX, other.minX), y0 = Swift.min(minY, other.minY)
        let x1 = Swift.max(maxX, other.maxX), y1 = Swift.max(maxY, other.maxY)
        return NormalizedRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    public func isApproximatelyEqual(to other: NormalizedRect, tolerance: Double = 1e-9) -> Bool {
        abs(x - other.x) <= tolerance && abs(y - other.y) <= tolerance
            && abs(width - other.width) <= tolerance && abs(height - other.height) <= tolerance
    }

    /// Intersection-over-union, 0...1.
    public func iou(_ other: NormalizedRect) -> Double {
        guard let i = intersection(other) else { return 0 }
        let u = area + other.area - i.area
        return u > 0 ? i.area / u : 0
    }

    /// Maps a rect expressed relative to `self` (e.g. a Vision result inside a region of interest) into
    /// the full-frame space `self` lives in.
    public func denormalizing(_ inner: NormalizedRect) -> NormalizedRect {
        NormalizedRect(x: x + inner.x * width, y: y + inner.y * height,
                       width: inner.width * width, height: inner.height * height)
    }

    public func denormalizing(_ point: NormalizedPoint) -> NormalizedPoint {
        NormalizedPoint(x: x + point.x * width, y: y + point.y * height)
    }

    public func denormalizing(_ quad: NormalizedQuad) -> NormalizedQuad {
        NormalizedQuad(topLeft: denormalizing(quad.topLeft), topRight: denormalizing(quad.topRight),
                       bottomRight: denormalizing(quad.bottomRight), bottomLeft: denormalizing(quad.bottomLeft))
    }

    public var description: String {
        String(format: "(x %.3f, y %.3f, w %.3f, h %.3f)", x, y, width, height)
    }
}

/// A normalized point, top-left origin.
public struct NormalizedPoint: Sendable, Hashable, Codable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public init(bottomLeftOriginX x: Double, y: Double) { self.init(x: x, y: 1 - y) }
}

/// A possibly-rotated quadrilateral in normalized top-left-origin space (Vision reports text corners).
public struct NormalizedQuad: Sendable, Hashable, Codable {
    public var topLeft: NormalizedPoint
    public var topRight: NormalizedPoint
    public var bottomRight: NormalizedPoint
    public var bottomLeft: NormalizedPoint

    public init(topLeft: NormalizedPoint, topRight: NormalizedPoint,
                bottomRight: NormalizedPoint, bottomLeft: NormalizedPoint) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }

    public var boundingRect: NormalizedRect {
        let xs = [topLeft.x, topRight.x, bottomRight.x, bottomLeft.x]
        let ys = [topLeft.y, topRight.y, bottomRight.y, bottomLeft.y]
        let x0 = xs.min()!, y0 = ys.min()!
        return NormalizedRect(x: x0, y: y0, width: xs.max()! - x0, height: ys.max()! - y0)
    }
}
