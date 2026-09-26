import Foundation

/// One line of a video transcript: stable Japanese text with its media time span and translation.
public struct TranscriptEntry: Sendable, Hashable, Identifiable {
    public var id: String
    public var trackID: UUID
    /// Media (presentation) time the final text first appeared, in seconds.
    public var start: Double
    /// Media time it left the screen or changed; nil while still visible.
    public var end: Double?
    public var japanese: String
    public var english: String?
    public var speaker: String?
    public var confidence: Float
    public var boundingBox: NormalizedRect
}

/// Builds a timestamped transcript from stable-text events, on the media clock so exported subtitles line
/// up with the video file. Seeking or looping backwards starts a new segment rather than corrupting order.
public struct TranscriptBuilder: Sendable {
    public private(set) var entries: [TranscriptEntry] = []
    /// Default on-screen duration used for entries that never received an end time.
    public var fallbackDuration: Double = 3
    private var openByTrack: [UUID: Int] = [:]

    public init() {}

    public mutating func stabilized(_ stable: StableText) {
        let start = stable.firstSeenFrame.presentationTime.seconds
        close(trackID: stable.trackID, at: start)
        entries.append(TranscriptEntry(id: stable.id, trackID: stable.trackID, start: start, end: nil,
                                       japanese: stable.text, english: nil, speaker: stable.speaker,
                                       confidence: stable.confidence,
                                       boundingBox: stable.boundingBox))
        openByTrack[stable.trackID] = entries.count - 1
    }

    /// The block left the screen or its text changed.
    public mutating func ended(trackID: UUID, at mediaTime: Double) {
        close(trackID: trackID, at: mediaTime)
    }

    public mutating func translated(id: String, english: String) {
        guard let index = entries.lastIndex(where: { $0.id == id }) else { return }
        entries[index].english = english
    }

    /// Playback jumped (seek/loop): close everything open at its last known state.
    public mutating func discontinuity() {
        for index in openByTrack.values where entries[index].end == nil {
            entries[index].end = entries[index].start + fallbackDuration
        }
        openByTrack.removeAll()
    }

    public mutating func removeAll() {
        entries.removeAll()
        openByTrack.removeAll()
    }

    private mutating func close(trackID: UUID, at time: Double) {
        guard let index = openByTrack.removeValue(forKey: trackID), entries[index].end == nil else { return }
        entries[index].end = time > entries[index].start ? time : entries[index].start + fallbackDuration
    }

    /// Entries in media-time order with resolved end times.
    public var resolved: [TranscriptEntry] {
        let sorted = entries.sorted { $0.start == $1.start ? $0.boundingBox.minY < $1.boundingBox.minY : $0.start < $1.start }
        return sorted.map { entry in
            var e = entry
            if e.end == nil { e.end = e.start + fallbackDuration }
            return e
        }
    }

    public enum SubtitleLanguage: Sendable { case japanese, english, bilingual }

    /// SubRip subtitles. English-only output skips untranslated lines.
    public func srt(_ language: SubtitleLanguage) -> String {
        var blocks: [String] = []
        for entry in resolved {
            let text: String
            switch language {
            case .japanese: text = entry.speaker.map { "【\($0)】\(entry.japanese)" } ?? entry.japanese
            case .english:
                guard let english = entry.english else { continue }
                text = english
            case .bilingual: text = entry.english.map { "\(entry.japanese)\n\($0)" } ?? entry.japanese
            }
            blocks.append("\(blocks.count + 1)\n\(MediaTimeFormat.srt(entry.start)) --> "
                          + "\(MediaTimeFormat.srt(entry.end ?? entry.start + fallbackDuration))\n\(text)")
        }
        return blocks.joined(separator: "\n\n") + (blocks.isEmpty ? "" : "\n")
    }

    /// CSV with a header row; fields quoted per RFC 4180.
    public func csv() -> String {
        func q(_ s: String) -> String { "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        var lines = ["start_s,end_s,speaker,japanese,english,confidence"]
        for e in resolved {
            lines.append(String(format: "%.3f,%.3f,", e.start, e.end ?? e.start)
                         + "\(q(e.speaker ?? "")),\(q(e.japanese)),\(q(e.english ?? "")),"
                         + String(format: "%.2f", e.confidence))
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
