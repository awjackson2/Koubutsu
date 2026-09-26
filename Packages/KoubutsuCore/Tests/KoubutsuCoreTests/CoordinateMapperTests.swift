import Testing
@testable import KoubutsuCore

struct CoordinateMapperTests {
    let hd = PixelSize(width: 1920, height: 1080)

    @Test func aspectFitLetterboxes() {
        let m = CoordinateMapper(sourceSize: hd, viewWidth: 1000, viewHeight: 1000)
        #expect(m.displayedVideoRect.isApproximatelyEqual(to: PlaneRect(x: 0, y: 218.75, width: 1000, height: 562.5)))
        let r = m.viewRect(for: NormalizedRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1))
        #expect(r.isApproximatelyEqual(to: PlaneRect(x: 500, y: 500, width: 100, height: 56.25)))
    }

    @Test func aspectFitPillarboxes() {
        // iPad 11" landscape-ish area narrower in aspect than 16:9 would pillarbox if taller; test a wide view.
        let m = CoordinateMapper(sourceSize: hd, viewWidth: 2000, viewHeight: 900)
        #expect(m.displayedVideoRect.isApproximatelyEqual(to: PlaneRect(x: 200, y: 0, width: 1600, height: 900)))
        #expect(abs(m.scale - 1600.0 / 1920.0) < 1e-12)
    }

    @Test func aspectFillCropsAndVisibleRectClips() {
        let m = CoordinateMapper(sourceSize: hd, viewWidth: 1000, viewHeight: 1000, contentMode: .aspectFill)
        let d = m.displayedVideoRect
        #expect(abs(d.height - 1000) < 1e-9 && abs(d.width - 1777.777777) < 1e-3 && d.x < 0)
        #expect(m.visibleVideoRect.isApproximatelyEqual(to: PlaneRect(x: 0, y: 0, width: 1000, height: 1000)))
    }

    @Test func pixelRoundTrip() {
        let m = CoordinateMapper(sourceSize: hd, viewWidth: 1194, viewHeight: 834)
        let n = NormalizedRect(x: 0.12, y: 0.73, width: 0.4, height: 0.06)
        let px = m.sourcePixelRect(for: n)
        #expect(px.isApproximatelyEqual(to: PlaneRect(x: 230.4, y: 788.4, width: 768, height: 64.8)))
        #expect(m.normalized(fromSourcePixels: px).isApproximatelyEqual(to: n))
    }

    @Test func viewRoundTripAndHitTesting() {
        let m = CoordinateMapper(sourceSize: hd, viewWidth: 1194, viewHeight: 834)
        let n = NormalizedRect(x: 0.2, y: 0.3, width: 0.25, height: 0.1)
        #expect(m.normalizedRect(fromView: m.viewRect(for: n)).isApproximatelyEqual(to: n))
        #expect(m.normalizedPoint(fromView: PlanePoint(x: 5, y: 2)) == nil) // in the letterbox bar
        let center = m.normalizedPoint(fromView: PlanePoint(x: 597, y: 417))
        #expect(abs((center?.x ?? 0) - 0.5) < 1e-9 && abs((center?.y ?? 0) - 0.5) < 1e-9)
    }

    @Test func invalidSizesAreSafe() {
        let m = CoordinateMapper(sourceSize: .zero, viewWidth: 100, viewHeight: 100)
        #expect(!m.isValid)
        #expect(m.displayedVideoRect == .zero)
        #expect(m.normalizedPoint(fromView: PlanePoint(x: 1, y: 1)) == nil)
    }
}
