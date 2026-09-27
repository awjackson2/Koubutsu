import Foundation

/// Where each character of a recognized line is. Uses the recognizer's per-character boxes when they match the
/// text; otherwise splits the line box by character width (full-width glyphs 1 em, half-width ~0.55 em), which
/// is close for horizontal Japanese.
public enum CharacterLayout {
    public static let halfWidthWeight = 0.55

    public static func boxes(for observation: RecognizedTextObservation) -> [NormalizedRect] {
        let characters = Array(observation.text)
        if let boxes = observation.characterBoxes, boxes.count == characters.count { return boxes }
        return proportionalBoxes(characters: characters, in: observation.boundingBox)
    }

    public static func proportionalBoxes(characters: [Character], in box: NormalizedRect) -> [NormalizedRect] {
        let weights = characters.map { isHalfWidth($0) ? halfWidthWeight : 1.0 }
        let total = weights.reduce(0, +)
        guard total > 0 else { return [] }
        var x = box.x
        return weights.map { weight in
            let width = box.width * weight / total
            defer { x += width }
            return NormalizedRect(x: x, y: box.y, width: width, height: box.height)
        }
    }

    /// ASCII and half-width forms render at about half the width of kana/kanji.
    public static func isHalfWidth(_ ch: Character) -> Bool {
        guard let v = ch.unicodeScalars.first?.value else { return false }
        return v < 0x2E80 && !(0x2000...0x206F).contains(v) || (0xFF61...0xFF9F).contains(v)
    }
}

/// A run of selected characters in one recognized line.
public struct SelectedSpan: Sendable, Hashable {
    public var observationID: UUID
    /// Character (grapheme) offsets into the line's text.
    public var range: Range<Int>
    public var text: String
    public var lineText: String

    public init(observationID: UUID, range: Range<Int>, text: String, lineText: String) {
        self.observationID = observationID
        self.range = range
        self.text = text
        self.lineText = lineText
    }
}

/// Resolves touches on a frozen frame to characters of recognized text.
public struct StudySelection: Sendable {
    public var observations: [RecognizedTextObservation]
    /// A tap this far outside a line (as a fraction of its height) still hits it.
    public var tapSlop: Double = 0.35

    public init(observations: [RecognizedTextObservation]) {
        self.observations = observations
    }

    /// The character under (or nearest to) `point` in the line containing it.
    public func character(at point: NormalizedPoint) -> SelectedSpan? {
        character(at: point, minimumSlopX: 0, minimumSlopY: 0)
    }

    /// As `character(at:)`, with the tolerance around each line at least `minimumSlopX` / `minimumSlopY`
    /// (normalized units, from `CoordinateMapper.normalizedLength(fromView:)`) for small glyphs on a small video
    /// (10.5.0). With zero minimums this is exactly `character(at:)`.
    public func character(at point: NormalizedPoint, minimumSlopX: Double, minimumSlopY: Double) -> SelectedSpan? {
        nearest(to: point, minimumSlopX: minimumSlopX, minimumSlopY: minimumSlopY)?.span
    }

    /// Centre of the character `character(at:minimumSlopX:minimumSlopY:)` picks, or nil when no line is in reach.
    /// The centre lies inside its line, so `character(at:)` resolves it to the same character.
    public func characterCentre(at point: NormalizedPoint, minimumSlopX: Double,
                                minimumSlopY: Double) -> NormalizedPoint? {
        guard let box = nearest(to: point, minimumSlopX: minimumSlopX, minimumSlopY: minimumSlopY)?.box else {
            return nil
        }
        return NormalizedPoint(x: box.midX, y: box.midY)
    }

    private func nearest(to point: NormalizedPoint, minimumSlopX: Double,
                         minimumSlopY: Double) -> (span: SelectedSpan, box: NormalizedRect)? {
        var best: (span: SelectedSpan, box: NormalizedRect, distance: Double)?
        for observation in observations {
            let box = observation.boundingBox
            let slop = box.height * tapSlop
            let slopX = max(slop, minimumSlopX), slopY = max(slop, minimumSlopY)
            guard point.x >= box.minX - slopX, point.x <= box.maxX + slopX,
                  point.y >= box.minY - slopY, point.y <= box.maxY + slopY else { continue }
            let characters = Array(observation.text)
            for (index, charBox) in CharacterLayout.boxes(for: observation).enumerated() {
                let dx = point.x - charBox.midX, dy = point.y - charBox.midY
                let distance = (dx * dx + dy * dy).squareRoot()
                if best == nil || distance < best!.distance {
                    best = (SelectedSpan(observationID: observation.id, range: index..<(index + 1),
                                         text: String(characters[index]), lineText: observation.text),
                            charBox, distance)
                }
            }
        }
        return best.map { ($0.span, $0.box) }
    }

    /// Every character whose box is mostly inside `rect`, grouped per line in reading order.
    public func spans(in rect: NormalizedRect) -> [SelectedSpan] {
        let ordered = observations.sorted { ($0.boundingBox.minY, $0.boundingBox.minX) < ($1.boundingBox.minY, $1.boundingBox.minX) }
        return ordered.compactMap { observation in
            let characters = Array(observation.text)
            let inside = CharacterLayout.boxes(for: observation).enumerated().filter { _, box in
                guard let overlap = box.intersection(rect), box.area > 0 else { return false }
                return overlap.area >= 0.5 * box.area
            }.map(\.offset)
            guard let first = inside.first, let last = inside.last else { return nil }
            return SelectedSpan(observationID: observation.id, range: first..<(last + 1),
                                text: String(characters[first...last]), lineText: observation.text)
        }
    }

    /// Selected text across spans: Japanese lines join without separators.
    public static func joinedText(_ spans: [SelectedSpan]) -> String {
        spans.map(\.text).joined()
    }
}
