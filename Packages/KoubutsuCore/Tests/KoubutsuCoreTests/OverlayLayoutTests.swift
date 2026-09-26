import Testing
@testable import KoubutsuCore

struct OverlayLayoutTests {
    let mapper = CoordinateMapper(sourceSize: .init(width: 1920, height: 1080), viewWidth: 1920, viewHeight: 1080)
    let layout = OverlayLayout()

    @Test func shortEnglishCoversJapaneseBoxExactlyAtNominalFont() {
        let box = NormalizedRect(x: 0.12, y: 0.73, width: 0.4, height: 0.06)
        let p = layout.place([OverlayItem(id: 1, sourceBox: box, lineCount: 1)], mapper: mapper,
                             textLength: { _ in 20 })
        #expect(p.count == 1)
        let source = mapper.viewRect(for: box)
        #expect(p[0].sourceFrame == source)
        #expect(abs(p[0].frame.x - (source.x - 4)) < 1e-9 && abs(p[0].frame.y - (source.y - 4)) < 1e-9)
        #expect(abs(p[0].frame.width - (source.width + 8)) < 1e-9)
        #expect(abs(p[0].frame.height - (source.height + 8)) < 1e-9)
        #expect(abs(p[0].fontSize - min(source.height * 0.7, 44)) < 1e-9)
    }

    @Test func longEnglishShrinksToFitSameBox() {
        let box = NormalizedRect(x: 0.1, y: 0.8, width: 0.5, height: 0.1) // two Japanese lines, 108 pt tall
        let p = layout.place([OverlayItem(id: 1, sourceBox: box, lineCount: 2)], mapper: mapper,
                             textLength: { _ in 160 })
        let source = mapper.viewRect(for: box)
        #expect(p[0].fontSize < source.height / 2 * 0.7)
        #expect(abs(p[0].frame.height - (source.height + 8)) < 1e-9)
        let lines = layout.wrappedLines(textLength: 160, width: p[0].frame.width - 8, fontSize: p[0].fontSize)
        #expect(Double(lines) * p[0].fontSize * layout.lineHeightFactor <= source.height)
    }

    @Test func textThatCannotFitGrowsDownward() {
        let box = NormalizedRect(x: 0.47, y: 0.5, width: 0.02, height: 0.02)
        let p = layout.place([OverlayItem(id: 1, sourceBox: box, lineCount: 1)], mapper: mapper,
                             textLength: { _ in 60 })
        #expect(p[0].frame.width == 60)
        #expect(p[0].fontSize == layout.fontSizeRange.lowerBound)
        #expect(p[0].frame.height > mapper.viewRect(for: box).height + 8)
    }

    @Test func grownBoxesAreStacked() {
        let a = OverlayItem(id: "a", sourceBox: NormalizedRect(x: 0.1, y: 0.10, width: 0.03, height: 0.02), lineCount: 1)
        let b = OverlayItem(id: "b", sourceBox: NormalizedRect(x: 0.1, y: 0.12, width: 0.03, height: 0.02), lineCount: 1)
        let p = layout.place([b, a], mapper: mapper, textLength: { _ in 80 })
        #expect(p.map(\.id) == ["a", "b"])
        #expect(!p[0].frame.intersects(p[1].frame))
    }

    @Test func staysInsideVisibleVideo() {
        let letterboxed = CoordinateMapper(sourceSize: .init(width: 1920, height: 1080), viewWidth: 1000, viewHeight: 1000)
        let p = layout.place([OverlayItem(id: 1, sourceBox: NormalizedRect(x: 0.95, y: 0.97, width: 0.05, height: 0.03),
                                          lineCount: 1)], mapper: letterboxed, textLength: { _ in 40 })
        let bounds = letterboxed.visibleVideoRect
        #expect(p[0].frame.maxX <= bounds.maxX + 1e-9)
        #expect(p[0].frame.maxY <= bounds.maxY + 1e-9)
        #expect(p[0].frame.minY >= bounds.minY)
    }
}
