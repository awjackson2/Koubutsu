/// Playback state of a file-backed source (Video mode). Live capture sources do not have one.
public struct PlaybackStatus: Sendable, Equatable {
    public var isPlaying: Bool
    /// Current media time in seconds.
    public var currentTime: Double
    /// Media duration in seconds (0 when unknown).
    public var duration: Double
    public var loops: Bool

    public init(isPlaying: Bool, currentTime: Double, duration: Double, loops: Bool) {
        self.isPlaying = isPlaying
        self.currentTime = currentTime
        self.duration = duration
        self.loops = loops
    }

    public var progress: Double { duration > 0 ? min(max(currentTime / duration, 0), 1) : 0 }

    /// Clamps a target time into the playable range.
    public func clamped(_ time: Double) -> Double {
        duration > 0 ? min(max(time, 0), max(0, duration - 0.05)) : max(time, 0)
    }
}

/// Transport control, adopted only by sources that play media files. Kept separate from `VideoSource`
/// so live capture is unaffected and downstream consumers stay source-agnostic.
public protocol PlaybackControlling: AnyObject, Sendable {
    func play() async
    func pause() async
    /// Seeks exactly to `seconds` of media time.
    func seek(to seconds: Double) async
    func setLooping(_ loops: Bool) async
    func playbackStatus() async -> PlaybackStatus
}

public enum MediaTimeFormat {
    /// `m:ss` below an hour, `h:mm:ss` above; SRT uses `srt(_:)`.
    public static func clock(_ seconds: Double) -> String {
        let total = Int(max(0, seconds).rounded(.down))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    /// SubRip timestamp `HH:MM:SS,mmm`.
    public static func srt(_ seconds: Double) -> String {
        let ms = Int((max(0, seconds) * 1000).rounded())
        return String(format: "%02d:%02d:%02d,%03d", ms / 3_600_000, (ms / 60_000) % 60, (ms / 1000) % 60, ms % 1000)
    }
}
