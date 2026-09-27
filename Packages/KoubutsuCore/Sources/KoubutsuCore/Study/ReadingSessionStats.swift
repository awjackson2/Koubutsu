import Foundation

/// Reading statistics for the current app session, shown on the portrait info deck's SESSION page (10.7.0).
/// Counts are derived from state the app already keeps (dialogue history, word bank) filtered by the session start.
public struct ReadingSessionStats: Sendable, Hashable {
    public var started: Date

    public init(started: Date) {
        self.started = started
    }

    /// Dialogue lines first seen during this session.
    public func linesRead(in entries: [DialogueEntry]) -> Int {
        entries.reduce(0) { $0 + ($1.date >= started ? 1 : 0) }
    }

    /// Of those, the lines that have a translation.
    public func translatedLines(in entries: [DialogueEntry]) -> Int {
        entries.reduce(0) { $0 + ($1.date >= started && $1.translation != nil ? 1 : 0) }
    }

    /// Words saved to the bank during this session.
    public func wordsSaved(in bank: WordBank) -> Int {
        bank.words.reduce(0) { $0 + ($1.created >= started ? 1 : 0) }
    }

    /// Seconds since the session started at `now` (never negative).
    public func elapsed(at now: Date) -> TimeInterval {
        max(0, now.timeIntervalSince(started))
    }

    /// "HH:MM:SS" (hours keep counting past 99).
    public static func clock(_ seconds: TimeInterval) -> String {
        let total = seconds.isFinite ? max(0, Int(seconds)) : 0
        let hours = total / 3600, minutes = total / 60 % 60, secs = total % 60
        return (hours < 10 ? "0" : "") + "\(hours):" + (minutes < 10 ? "0" : "") + "\(minutes):"
            + (secs < 10 ? "0" : "") + "\(secs)"
    }

    /// Lit segments of a `segments`-block pixel meter showing `value` against `full`: rounded, clamped to
    /// 0…segments; any positive value lights at least one block. Nil or non-finite values light none.
    public static func meterSegments(value: Double?, full: Double, segments: Int) -> Int {
        guard let value, value.isFinite, value > 0, full > 0, segments > 0 else { return 0 }
        let lit = Int((value / full * Double(segments)).rounded())
        return min(segments, max(1, lit))
    }
}
