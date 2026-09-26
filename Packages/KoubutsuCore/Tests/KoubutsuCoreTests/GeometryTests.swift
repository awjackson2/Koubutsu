import Testing
@testable import KoubutsuCore

struct GeometryTests {
    @Test func visionFlipRoundTrip() {
        // Vision: box at bottom 10% of the frame.
        let r = NormalizedRect(bottomLeftOriginX: 0.1, y: 0.0, width: 0.8, height: 0.1)
        #expect(r.y == 0.9)
        #expect(abs(r.maxY - 1.0) < 1e-12)
        let back = r.bottomLeftOrigin
        #expect(abs(back.y) < 1e-12 && back.height == 0.1)
    }

    @Test func clampAndIntersect() {
        let r = NormalizedRect(x: -0.2, y: 0.5, width: 0.5, height: 0.8).clamped
        #expect(r == NormalizedRect(x: 0, y: 0.5, width: 0.3, height: 0.5))
        let a = NormalizedRect(x: 0, y: 0, width: 0.5, height: 0.5)
        let b = NormalizedRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        #expect(a.intersection(b) == NormalizedRect(x: 0.25, y: 0.25, width: 0.25, height: 0.25))
        #expect(abs(a.iou(b) - (0.0625 / (0.25 + 0.25 - 0.0625))) < 1e-12)
        #expect(a.intersection(NormalizedRect(x: 0.6, y: 0.6, width: 0.1, height: 0.1)) == nil)
    }

    @Test func regionOfInterestDenormalization() {
        let roi = NormalizedRect(x: 0, y: 0.6, width: 1, height: 0.4)
        let inner = NormalizedRect(x: 0.5, y: 0.5, width: 0.25, height: 0.25)
        let full = roi.denormalizing(inner)
        #expect(abs(full.y - 0.8) < 1e-12 && abs(full.height - 0.1) < 1e-12 && full.x == 0.5)
    }

    @Test func quadBounds() {
        let q = NormalizedQuad(topLeft: .init(x: 0.1, y: 0.2), topRight: .init(x: 0.5, y: 0.1),
                               bottomRight: .init(x: 0.6, y: 0.4), bottomLeft: .init(x: 0.2, y: 0.5))
        #expect(q.boundingRect == NormalizedRect(x: 0.1, y: 0.1, width: 0.5, height: 0.4))
    }
}
