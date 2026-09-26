import Foundation

/// One line of dialogue as it appeared on screen, with its translation once available.
/// Keeps the original Japanese and geometry so future features (learning mode, replay, vocabulary) have
/// the data they need.
public struct DialogueEntry: Sendable, Hashable, Identifiable {
    public var id: String
    public var trackID: UUID
    public var date: Date
    public var source: String
    public var translation: String?
    public var provider: String?
    public var boundingBox: NormalizedRect
    public var confidence: Float
    public var firstSeenFrame: FrameTiming

    public init(stable: StableText, date: Date) {
        id = stable.id
        trackID = stable.trackID
        self.date = date
        source = stable.text
        boundingBox = stable.boundingBox
        confidence = stable.confidence
        firstSeenFrame = stable.firstSeenFrame
    }
}

/// Chronological, bounded log of stable dialogue. Consecutive repeats of the same text are merged, and a
/// block that grows in place (typewriter reveal) replaces its own previous, shorter entry.
public struct DialogueHistory: Sendable {
    public let capacity: Int
    public private(set) var entries: [DialogueEntry] = []

    public init(capacity: Int = 500) {
        precondition(capacity > 0)
        self.capacity = capacity
    }

    /// Records newly stable text. Returns false if it repeats the most recent entry (same text).
    @discardableResult
    public mutating func record(_ stable: StableText, date: Date = Date()) -> Bool {
        if let last = entries.last, last.id == stable.id || last.source == stable.text { return false }
        if let index = entries.lastIndex(where: { $0.trackID == stable.trackID }),
           TextNormalizer.isGrowth(from: TextNormalizer.key(entries[index].source), to: stable.key) {
            entries[index] = DialogueEntry(stable: stable, date: date)
            return true
        }
        entries.append(DialogueEntry(stable: stable, date: date))
        if entries.count > capacity { entries.removeFirst(entries.count - capacity) }
        return true
    }

    public mutating func setTranslation(_ translation: String, provider: String, for id: String) {
        guard let index = entries.lastIndex(where: { $0.id == id }) else { return }
        entries[index].translation = translation
        entries[index].provider = provider
    }

    /// The most recent lines before `id` (or overall), oldest first, for context-aware translation.
    public func context(before id: String? = nil, limit: Int = 5) -> [DialogueContextLine] {
        var slice = entries[...]
        if let id, let index = entries.lastIndex(where: { $0.id == id }) { slice = entries[..<index] }
        return slice.suffix(limit).map { DialogueContextLine(source: $0.source, translation: $0.translation) }
    }

    public mutating func removeAll() { entries.removeAll() }
}
