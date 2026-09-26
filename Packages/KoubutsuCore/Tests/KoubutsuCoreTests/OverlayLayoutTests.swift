import Testing
@testable import KoubutsuCore

struct OverlayLayoutTests {
    let mapper = CoordinateMapper(sourceSize: .init(width: 1920, height: 1080), viewWidth: 1920, viewHeight: 1080)
    let layout = OverlayLayout()

    @Test func coversJapaneseBoxWithScaledFont() {
        let box = NormalizedRect(x: 0.12, y: 0.73, width: 0.4, height: 0.06)
        let p = layout.place([OverlayItem(id: 1, sourceBox: box, lineCount: 1)], mapper: mapper)
        #expect(p.count == 1)
        let source = mapper.viewRect(for: box)
        #expect(p[0].sourceFrame == source)
        #expect(abs(p[0].frame.x - (source.x - 6)) < 1e-9 && abs(p[0].frame.y - (source.y - 6)) < 1e-9)
        #expect(abs(p[0].fontSize - min(source.height * 0.7, 44)) < 1e-9)
    }

    @Test func shortTextGetsMinimumWidth() {
        let p = layout.place([OverlayItem(id: 1, sourceBox: NormalizedRect(x: 0.47, y: 0.5, width: 0.03, height: 0.04),
                                          lineCount: 1)], mapper: mapper)
        #expect(p[0].frame.width == 120)
    }

    @Test func overlappingBoxesAreStacked() {
        let a = OverlayItem(id: "a", sourceBox: NormalizedRect(x: 0.1, y: 0.10, width: 0.3, height: 0.05), lineCount: 1)
        let b = OverlayItem(id: "b", sourceBox: NormalizedRect(x: 0.1, y: 0.12, width: 0.3, height: 0.05), lineCount: 1)
        let p = layout.place([b, a], mapper: mapper, estimatedLines: { _ in 2 })
        #expect(p.map(\.id) == ["a", "b"])
        #expect(!p[0].frame.intersects(p[1].frame))
        #expect(p[1].frame.minY >= p[0].frame.maxY)
    }

    @Test func staysInsideVisibleVideo() {
        let letterboxed = CoordinateMapper(sourceSize: .init(width: 1920, height: 1080), viewWidth: 1000, viewHeight: 1000)
        let p = layout.place([OverlayItem(id: 1, sourceBox: NormalizedRect(x: 0.95, y: 0.97, width: 0.05, height: 0.03),
                                          lineCount: 1)], mapper: letterboxed, estimatedLines: { _ in 3 })
        let bounds = letterboxed.visibleVideoRect
        #expect(p[0].frame.maxX <= bounds.maxX + 1e-9)
        #expect(p[0].frame.maxY <= bounds.maxY + 1e-9)
        #expect(p[0].frame.minY >= bounds.minY)
    }
}
