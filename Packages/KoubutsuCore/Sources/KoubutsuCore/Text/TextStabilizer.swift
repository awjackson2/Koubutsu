import Foundation

/// A text block that has been stable long enough to act on (translate, log, overlay).
public struct StableText: Sendable, Hashable, Identifiable {
    /// Track identity: stays the same while the block stays on screen, even if its text changes.
    public var trackID: UUID
    /// Unique per emitted text version (track + key).
    public var id: String { "\(trackID.uuidString)#\(key)" }
    public var text: String
    public var key: String
    public var boundingBox: NormalizedRect
    public var confidence: Float
    public var lines: [RecognizedTextObservation]
    /// Frame where this exact text was first seen (start of the capture→translation latency).
    public var firstSeenFrame: FrameTiming
    /// Frame at which it was judged stable.
    public var stabilizedFrame: FrameTiming

    public init(trackID: UUID, text: String, key: String, boundingBox: NormalizedRect, confidence: Float,
                lines: [RecognizedTextObservation], firstSeenFrame: FrameTiming, stabilizedFrame: FrameTiming) {
        self.trackID = trackID
        self.text = text
        self.key = key
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.lines = lines
        self.firstSeenFrame = firstSeenFrame
        self.stabilizedFrame = stabilizedFrame
    }
}

public enum TextEvent: Sendable, Hashable {
    /// A block's text became stable (first time, or after it changed).
    case stabilized(StableText)
    /// A block's previously stable text changed (new page, scene change); its old translation is stale.
    case invalidated(trackID: UUID)
    /// A block left the screen.
    case removed(trackID: UUID)
}

/// A block currently being tracked (stable or not). Useful for overlays that follow text as it reveals.
public struct TrackedBlock: Sendable, Hashable, Identifiable {
    public var id: UUID
    public var block: TextBlock
    public var firstSeenCurrentText: FrameTiming
    public var lastSeen: HostTime
    public var observationsOfCurrentText: Int
    public var stableKey: String?
    /// Last text emitted for this track (still shown downstream while a replacement is being confirmed).
    public var shownKey: String?
    /// Consecutive OCR results this track was not found in.
    public var missedResults: Int = 0

    public var isStable: Bool { stableKey == block.key }
}

public struct StabilizerConfiguration: Sendable, Hashable {
    /// Text must stay unchanged for at least this long…
    public var minimumStableDuration: Double = 0
    /// …and be seen in at least this many OCR results.
    public var minimumObservations: Int = 1
    /// Boxes overlapping at least this much (IoU) are the same block.
    public var matchIoU: Double = 0.2
    /// Or: boxes whose centers are this close (normalized) with similar text.
    public var matchCenterDistance: Double = 0.05
    public var matchSimilarity: Double = 0.5
    /// Texts at least this similar (and not growth) are treated as OCR noise of the same text.
    public var noiseSimilarity: Double = 0.85
    /// Readings needed before text replaces something already shown: different (non-growth) text on a shown
    /// track, or a new block over a shown block. One misread or regrouped OCR result then cannot redraw the screen.
    public var replacementObservations: Int = 2
    /// A new block counts as over a shown block when this fraction of its area is covered by it.
    public var coverFraction: Double = 0.5
    /// A track unseen for this long is removed…
    public var removeAfter: Double = 0.6
    /// …and only once it has been missing from this many consecutive OCR results (at a low OCR rate a single
    /// missed reading must not blink the box).
    public var minimumMissedResults: Int = 2
    /// Blocks below this confidence are ignored.
    public var minimumConfidence: Float = 0.3
    /// Blocks with fewer comparison-key characters are ignored (stray glyphs).
    public var minimumKeyLength: Int = 1
    /// One-character blocks need at least this confidence (stray glyphs are read at low confidence).
    public var shortTextMinimumConfidence: Float = 0.5
    /// Blocks with no kana or kanji are ignored: nothing to translate, and another script misread as
    /// Latin/digits would otherwise be drawn as a box.
    public var requiresJapanese: Bool = true

    public init() {}
}

/// Turns a stream of per-frame OCR results into stable text events.
///
/// Typewriter reveals are handled implicitly: while characters are appearing the text keeps changing, which
/// keeps resetting the stability window, so only the completed text is emitted. OCR flicker (a character
/// misread in one frame) is absorbed by the noise-similarity rule.
public struct TextStabilizer: Sendable {
    public var configuration: StabilizerConfiguration
    public var grouper: TextBlockGrouper
    public private(set) var tracks: [TrackedBlock] = []
    /// OCR results that repeated already-stable text (no work needed downstream).
    public private(set) var duplicateDetections = 0

    public init(configuration: StabilizerConfiguration = .init(), grouper: TextBlockGrouper = .init()) {
        self.configuration = configuration
        self.grouper = grouper
    }

    public mutating func reset() {
        tracks.removeAll()
    }

    /// Processes one OCR result. Returns the events it caused, in order.
    public mutating func process(_ result: OCRResult) -> [TextEvent] {
        let now = result.frame.hostTime
        let blocks = grouper.group(result.observations).filter {
            $0.confidence >= configuration.minimumConfidence && $0.key.count >= configuration.minimumKeyLength
                && ($0.key.count > 1 || $0.confidence >= configuration.shortTextMinimumConfidence)
                && (!configuration.requiresJapanese || TextNormalizer.containsJapaneseText($0.key))
        }
        var events: [TextEvent] = []
        var unmatchedTracks = Set(tracks.indices)

        for block in matchOrder(blocks) {
            if let index = bestTrack(for: block, among: unmatchedTracks) {
                unmatchedTracks.remove(index)
                var track = tracks[index]
                track.missedResults = 0
                let wasStable = track.isStable
                if Self.update(&track, with: block, frame: result.frame, configuration: configuration) {
                    duplicateDetections += 1
                }
                if wasStable && !track.isStable { events.append(.invalidated(trackID: track.id)) }
                tracks[index] = track
            } else {
                tracks.append(TrackedBlock(id: UUID(), block: block, firstSeenCurrentText: result.frame,
                                           lastSeen: now, observationsOfCurrentText: 1, stableKey: nil))
            }
        }

        for index in unmatchedTracks where tracks[index].lastSeen != now { tracks[index].missedResults += 1 }

        // Remove tracks that have been gone long enough.
        var kept: [TrackedBlock] = []
        for track in tracks {
            if now - track.lastSeen > configuration.removeAfter && track.missedResults >= configuration.minimumMissedResults {
                events.append(.removed(trackID: track.id))
            } else {
                kept.append(track)
            }
        }
        tracks = kept

        // Emit newly stable text.
        let shownBefore = Set(tracks.filter { $0.shownKey != nil }.map(\.id))
        for index in tracks.indices where tracks[index].lastSeen == now && !tracks[index].isStable {
            let track = tracks[index]
            let age = now - track.firstSeenCurrentText.hostTime
            guard age >= configuration.minimumStableDuration,
                  track.observationsOfCurrentText >= requiredObservations(for: track, shownBefore: shownBefore)
            else { continue }
            tracks[index].stableKey = track.block.key
            tracks[index].shownKey = track.block.key
            events.append(.stabilized(StableText(
                trackID: track.id, text: track.block.text, key: track.block.key,
                boundingBox: track.block.boundingBox, confidence: track.block.confidence,
                lines: track.block.lines, firstSeenFrame: track.firstSeenCurrentText, stabilizedFrame: result.frame)))
        }
        return events
    }

    /// Instant for text in free space and for growth of the shown text (typewriter); confirmed otherwise.
    /// "Over" means covering at least `coverFraction` of the new block; neighbouring lines touch but do not count.
    private func requiredObservations(for track: TrackedBlock, shownBefore: Set<UUID>) -> Int {
        let confirmed = max(configuration.minimumObservations, configuration.replacementObservations)
        if let shown = track.shownKey {
            return TextNormalizer.isGrowth(from: shown, to: track.block.key) ? configuration.minimumObservations : confirmed
        }
        let box = track.block.boundingBox
        let coversShownText = tracks.contains {
            $0.id != track.id && shownBefore.contains($0.id)
                && ($0.block.boundingBox.intersection(box)?.area ?? 0) >= configuration.coverFraction * box.area
        }
        return coversShownText ? confirmed : configuration.minimumObservations
    }

    /// Larger blocks claim tracks first so a big dialogue box is not stolen by a fragment.
    private func matchOrder(_ blocks: [TextBlock]) -> [TextBlock] {
        blocks.sorted { $0.boundingBox.area > $1.boundingBox.area }
    }

    private func bestTrack(for block: TextBlock, among candidates: Set<Int>) -> Int? {
        var best: (index: Int, score: Double)?
        for index in candidates {
            let track = tracks[index]
            let iou = track.block.boundingBox.iou(block.boundingBox)
            var score = iou
            if iou < configuration.matchIoU {
                let dx = track.block.boundingBox.minX - block.boundingBox.minX
                let dy = track.block.boundingBox.minY - block.boundingBox.minY
                let near = (dx * dx + dy * dy).squareRoot() <= configuration.matchCenterDistance
                let related = TextNormalizer.isGrowth(from: track.block.key, to: block.key)
                    || TextNormalizer.similarity(track.block.key, block.key) >= configuration.matchSimilarity
                guard near && related else { continue }
                score = configuration.matchIoU * 0.5
            }
            if best == nil || score > best!.score { best = (index, score) }
        }
        return best?.index
    }

    /// Returns true when the observation repeated already-stable text.
    private static func update(_ track: inout TrackedBlock, with block: TextBlock, frame: FrameTiming,
                               configuration: StabilizerConfiguration) -> Bool {
        track.lastSeen = frame.hostTime
        if block.key == track.block.key {
            track.observationsOfCurrentText += 1
            track.block = block
            return track.isStable
        }
        let growth = TextNormalizer.isGrowth(from: track.block.key, to: block.key)
        let noise = !growth && TextNormalizer.similarity(track.block.key, block.key) >= configuration.noiseSimilarity
        if noise {
            // Same text misread: count it, keep the more confident reading.
            track.observationsOfCurrentText += 1
            if block.confidence > track.block.confidence, !track.isStable { track.block = block }
            return track.isStable
        }
        track.block = block
        track.firstSeenCurrentText = frame
        track.observationsOfCurrentText = 1
        track.stableKey = nil
        return false
    }
}
