import Foundation

/// A group of OCR lines that belong together (e.g. the lines of one dialogue box), in reading order.
public struct TextBlock: Sendable, Hashable {
    public var lines: [RecognizedTextObservation]
    /// Display-normalized text of all lines joined (Japanese lines join without separators).
    public var text: String
    /// Comparison key (see `TextNormalizer.key`).
    public var key: String
    public var boundingBox: NormalizedRect
    /// Lowest line confidence.
    public var confidence: Float
    public var frame: FrameTiming

    public init(lines: [RecognizedTextObservation]) {
        precondition(!lines.isEmpty)
        self.lines = lines
        let joined = lines.map { TextNormalizer.display($0.text) }.reduce("") { acc, next in
            guard let last = acc.last, let first = next.first else { return acc + next }
            let needsSpace = !TextNormalizer.isJapanese(last) && !TextNormalizer.isJapanese(first)
            return acc + (needsSpace ? " " : "") + next
        }
        text = joined
        key = TextNormalizer.key(joined)
        boundingBox = lines.dropFirst().reduce(lines[0].boundingBox) { $0.union($1.boundingBox) }
        confidence = lines.map(\.confidence).min() ?? 0
        frame = lines[0].frame
    }
}

/// Groups horizontal OCR lines into blocks: a line joins the block above it when it is vertically close,
/// of similar height, and horizontally aligned. Parameters are ratios of line height so they are
/// resolution-independent.
public struct TextBlockGrouper: Sendable {
    /// Maximum vertical gap between consecutive lines, as a multiple of line height.
    public var maximumGapRatio: Double = 0.8
    /// Allowed ratio between line heights.
    public var heightRatioRange: ClosedRange<Double> = 0.6...1.7
    /// Left edges within this many line heights count as aligned.
    public var leftAlignmentRatio: Double = 1.5
    /// Or: horizontal overlap of at least this fraction of the narrower line.
    public var minimumHorizontalOverlap: Double = 0.3

    public init() {}

    public func group(_ observations: [RecognizedTextObservation]) -> [TextBlock] {
        let sorted = observations.sorted {
            $0.boundingBox.minY == $1.boundingBox.minY ? $0.boundingBox.minX < $1.boundingBox.minX
                                                       : $0.boundingBox.minY < $1.boundingBox.minY
        }
        var groups: [[RecognizedTextObservation]] = []
        for line in sorted {
            if let index = groups.lastIndex(where: { belongs(line, below: $0.last!) }) {
                groups[index].append(line)
            } else {
                groups.append([line])
            }
        }
        return groups.map(TextBlock.init(lines:))
    }

    func belongs(_ line: RecognizedTextObservation, below previous: RecognizedTextObservation) -> Bool {
        let a = previous.boundingBox, b = line.boundingBox
        guard a.height > 0, b.height > 0 else { return false }
        let ratio = b.height / a.height
        guard heightRatioRange.contains(ratio) else { return false }
        let lineHeight = max(a.height, b.height)
        let gap = b.minY - a.maxY
        guard gap >= -0.5 * lineHeight, gap <= maximumGapRatio * lineHeight else { return false }
        // Same visual row (side-by-side) is not a continuation line.
        guard b.minY >= a.midY else { return false }
        if abs(b.minX - a.minX) <= leftAlignmentRatio * lineHeight { return true }
        let overlap = min(a.maxX, b.maxX) - max(a.minX, b.minX)
        return overlap > 0 && overlap >= minimumHorizontalOverlap * min(a.width, b.width)
    }
}
