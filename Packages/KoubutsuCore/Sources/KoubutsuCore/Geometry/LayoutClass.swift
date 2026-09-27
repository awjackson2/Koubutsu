/// Which layout the app uses for a window (10.1.0). Chosen from the window size, not the device, so a narrow iPad
/// window (Split View, Slide Over, Stage Manager) gets the compact layouts too.
public enum LayoutClass: Sendable, Hashable, CaseIterable {
    /// iPad-sized window: the monitor housing with bars below the video.
    case regular
    /// Narrow and tall (iPhone portrait, narrow iPad windows).
    case compactPortrait
    /// Short (iPhone landscape, short iPad windows).
    case compactLandscape

    /// Every iPhone landscape height is ≤ 440 pt.
    public static let compactHeight = 500.0
    /// Every full-screen iPad width is ≥ 744 pt; iPhone portrait widths are ≤ 440 pt.
    public static let compactWidth = 600.0

    public static func classify(width: Double, height: Double) -> LayoutClass {
        if height < compactHeight { return .compactLandscape }
        if width < compactWidth { return .compactPortrait }
        return .regular
    }

    public var isCompact: Bool { self != .regular }
}
