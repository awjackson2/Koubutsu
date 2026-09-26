import Testing
@testable import KoubutsuCore

/// Grouping on geometry measured from a real 1920×1080 Persona 3 Reload dialogue frame (0:12):
/// name tag ≈0.6× line height above-left of a two-line dialogue (lines at 858/907 px).
/// Every Japanese region is replaced in place, so the name tag must stay its own block and the two
/// dialogue lines must form one block (translated as one sentence).
struct RealFootageGroupingTests {
    let grouper = TextBlockGrouper()
    let name = line("伊織順平", x: 0.285, y: 0.698, w: 0.058, h: 0.022)
    let talk = line("TALK", x: 0.300, y: 0.724, w: 0.020, h: 0.009)
    let line1 = line("あっ、オマエ今、", x: 0.320, y: 0.794, w: 0.195, h: 0.037)
    let line2 = line("めんどくせーとか思ったろ!", x: 0.320, y: 0.840, w: 0.26, h: 0.037)

    @Test func nameTagAndDialogueAreSeparateBlocks() {
        let blocks = grouper.group([line2, name, line1, talk])
        #expect(blocks.map(\.text).contains("伊織順平"))
        #expect(blocks.map(\.text).contains("あっ、オマエ今、めんどくせーとか思ったろ!"))
        #expect(blocks.count == 3)
    }

    @Test func dialogueLinesOfEqualHeightMerge() {
        let blocks = grouper.group([line1, line2])
        #expect(blocks.count == 1)
    }
}
