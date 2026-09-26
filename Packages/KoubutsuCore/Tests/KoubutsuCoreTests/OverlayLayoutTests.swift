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
        #expect(p[0].lineLimit == lines)
    }

    @Test func narrowBoxWidensIntoFreeSpaceBeforeShrinking() {
        let box = NormalizedRect(x: 0.1, y: 0.5, width: 0.1, height: 0.05) // 192×54 pt
        let p = layout.place([OverlayItem(id: 1, sourceBox: box, lineCount: 1)], mapper: mapper,
                             textLength: { _ in 60 })
        let nominal = layout.nominalFontSize(sourceHeight: 54, lineCount: 1)
        #expect(p[0].frame.width > 192 + 8)
        #expect(p[0].fontSize >= nominal * layout.readableFontFraction)
        #expect(abs(p[0].frame.height - (54 + 8)) < 1e-9)
    }

    @Test func wideningStopsAtTheNextTextOnTheRow() {
        let a = OverlayItem(id: "a", sourceBox: NormalizedRect(x: 0.1, y: 0.5, width: 0.05, height: 0.03), lineCount: 1)
        let b = OverlayItem(id: "b", sourceBox: NormalizedRect(x: 0.3, y: 0.5, width: 0.1, height: 0.03), lineCount: 1)
        let p = layout.place([a, b], mapper: mapper, textLength: { $0 == "a" ? 400 : 5 })
        #expect(p[0].frame.maxX <= mapper.viewRect(for: b.sourceBox).minX + 1e-9)
        #expect(p[0].frame.height > mapper.viewRect(for: a.sourceBox).height + 8)
    }

    @Test func grownBoxNeverCoversTheTextBelow() {
        let a = OverlayItem(id: "a", sourceBox: NormalizedRect(x: 0.9, y: 0.10, width: 0.03, height: 0.02), lineCount: 1)
        let b = OverlayItem(id: "b", sourceBox: NormalizedRect(x: 0.9, y: 0.16, width: 0.03, height: 0.02), lineCount: 1)
        let p = layout.place([b, a], mapper: mapper, textLength: { _ in 300 })
        #expect(p.map(\.id) == ["a", "b"])
        let bText = mapper.viewRect(for: b.sourceBox)
        #expect(p[0].frame.maxY <= bText.minY + 1e-9)
        #expect(p[0].frame.height > mapper.viewRect(for: a.sourceBox).height + 8)
        #expect(p[0].fontSize == layout.fontSizeRange.lowerBound)
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

    @Test func textScaleEnlargesNominalFont() {
        let larger = OverlayLayout(textScale: 1.5)
        #expect(abs(larger.nominalFontSize(sourceHeight: 40, lineCount: 1) - 40 * 0.7 * 1.5) < 1e-9)
        #expect(larger.fontSizeRange.upperBound == 66)
        #expect(OverlayLayout(textScale: 1).nominalFontSize(sourceHeight: 40, lineCount: 1)
                == layout.nominalFontSize(sourceHeight: 40, lineCount: 1))
    }
}
