/// Recognizes persistent HUD text (button hints, date/clock, mode labels) so it is not treated as dialogue.
///
/// A place on screen becomes HUD when similar text stabilizes there repeatedly (OCR variants such as
/// 「◎オート日早送り」/「キョログ◎オート日早送り」 count as similar). Once HUD, similar text there is suppressed;
/// *different* text at the same place (the next line in a dialogue box) is never suppressed.
public struct HUDFilter: Sendable {
    /// Sightings of similar text at one place before it counts as HUD.
    public var repeatThreshold = 3
    /// Two boxes are the same place when their intersection covers this much of the smaller box.
    public var placeOverlap = 0.6
    public var textSimilarity = 0.5
    /// Sightings further apart than this (seconds) do not accumulate.
    public var window: Double = 180

    private struct Place {
        var box: NormalizedRect
        var keys: [String]
        var count: Int
        var lastSeen: Double
        var isHUD: Bool
    }

    private var places: [Place] = []
    public private(set) var suppressedCount = 0

    public init() {}

    public var hudPlaceCount: Int { places.filter(\.isHUD).count }

    public mutating func reset() {
        places.removeAll()
        suppressedCount = 0
    }

    /// Records a stable text and returns true when it is HUD text that should be suppressed.
    public mutating func isHUD(_ stable: StableText) -> Bool {
        let time = stable.firstSeenFrame.hostTime.seconds
        let box = stable.boundingBox
        guard let index = places.firstIndex(where: { samePlace($0.box, box) }) else {
            places.append(Place(box: box, keys: [stable.key], count: 1, lastSeen: time, isHUD: false))
            return false
        }
        var place = places[index]
        let similar = place.keys.contains { TextNormalizer.similarity($0, stable.key) >= textSimilarity }
        if similar && time - place.lastSeen <= window {
            place.count += 1
        } else if !place.isHUD {
            place.count = 1
            place.keys.removeAll()
        }
        place.keys.append(stable.key)
        if place.keys.count > 8 { place.keys.removeFirst(place.keys.count - 8) }
        place.lastSeen = time
        if place.count >= repeatThreshold { place.isHUD = true }
        places[index] = place
        let suppress = place.isHUD && similar
        if suppress { suppressedCount += 1 }
        return suppress
    }

    private func samePlace(_ a: NormalizedRect, _ b: NormalizedRect) -> Bool {
        guard let i = a.intersection(b) else { return false }
        let smaller = min(a.area, b.area)
        return smaller > 0 && i.area / smaller >= placeOverlap
    }
}
