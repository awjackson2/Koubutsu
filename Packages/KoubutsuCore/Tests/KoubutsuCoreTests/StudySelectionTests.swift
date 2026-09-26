import Foundation
import Testing
@testable import KoubutsuCore

struct StudySelectionTests {
    let line1 = line("この先には強い敵", x: 0.1, y: 0.7, w: 0.4, h: 0.05)
    let line2 = line("HPが10回復", x: 0.1, y: 0.78, w: 0.3, h: 0.05)

    @Test func proportionalLayoutWeightsHalfWidth() {
        let boxes = CharacterLayout.boxes(for: line2)
        #expect(boxes.count == 7)
        #expect(abs(boxes[0].width / boxes[2].width - CharacterLayout.halfWidthWeight) < 1e-9) // H vs が
        #expect(abs(boxes.last!.maxX - line2.boundingBox.maxX) < 1e-9)
    }

    @Test func recognizerBoxesUsedWhenCountsMatch() {
        var o = line("敵だ", x: 0.1, y: 0.1, w: 0.2, h: 0.05)
        o.characterBoxes = [NormalizedRect(x: 0.1, y: 0.1, width: 0.05, height: 0.05),
                            NormalizedRect(x: 0.2, y: 0.1, width: 0.05, height: 0.05)]
        #expect(CharacterLayout.boxes(for: o) == o.characterBoxes)
        o.characterBoxes = [NormalizedRect(x: 0.1, y: 0.1, width: 0.05, height: 0.05)]
        #expect(CharacterLayout.boxes(for: o).count == 2)
    }

    @Test func tapPicksNearestCharacterOfLine() {
        let selection = StudySelection(observations: [line1, line2])
        // 8 equal characters over 0.4: 強 is index 5, centred at 0.1 + 0.05 * 5.5.
        let hit = selection.character(at: NormalizedPoint(x: 0.1 + 0.05 * 5.5, y: 0.725))
        #expect(hit?.text == "強")
        #expect(hit?.range == 5..<6)
        #expect(hit?.lineText == "この先には強い敵")
        #expect(selection.character(at: NormalizedPoint(x: 0.9, y: 0.1)) == nil)
    }

    @Test func dragSelectsAcrossLines() {
        let selection = StudySelection(observations: [line2, line1])
        let rect = NormalizedRect(x: 0.29, y: 0.69, width: 0.5, height: 0.14)
        let spans = selection.spans(in: rect)
        #expect(spans.map(\.text) == ["は強い敵", "回復"])
        #expect(spans.first?.range == 4..<8)
        #expect(spans.first?.lineText == "この先には強い敵")
        #expect(StudySelection.joinedText(spans).hasSuffix("回復"))
    }
}
