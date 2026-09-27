/// Where the video is drawn on screen. The stage depends only on the container (window) size, never on which
/// panels or bars are showing: UI chrome overlays the space below it, so the video and every replacement box
/// stay put when chrome appears, hides or changes height.
public enum VideoStageLayout {
    /// Switch output (and most capture) is 16:9; other aspects fit inside the stage.
    public static let defaultAspect = 16.0 / 9.0

    /// Space kept around the stage for the monitor housing drawn outside full screen (9.4.0).
    public struct StageInsets: Sendable, Hashable {
        public var top: Double
        public var left: Double
        public var bottom: Double
        public var right: Double

        public init(top: Double, left: Double, bottom: Double, right: Double) {
            self.top = top
            self.left = left
            self.bottom = bottom
            self.right = right
        }

        public static let zero = StageInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    /// Header strip height of the monitor housing, below the status bar.
    public static let headerHeight = 38.0

    /// Housing insets outside full screen. `safeTop` is the status-bar inset (floored so the header never
    /// collides with the status bar when the inset is reported as zero).
    public static func windowedInsets(safeTop: Double) -> StageInsets {
        StageInsets(top: max(safeTop, 24) + headerHeight, left: 18, bottom: 16, right: 18)
    }

    /// Full container width, top-aligned, height from `aspect`; clamped (and centred horizontally) when the
    /// container is too short for full width.
    public static func stage(containerWidth: Double, containerHeight: Double,
                             aspect: Double = defaultAspect) -> PlaneRect {
        framed(containerWidth: containerWidth, containerHeight: containerHeight, insets: .zero, aspect: aspect)
    }

    /// The stage inside the container minus `insets`: as wide as fits, top at `insets.top`, centred horizontally.
    public static func framed(containerWidth: Double, containerHeight: Double, insets: StageInsets,
                              aspect: Double = defaultAspect) -> PlaneRect {
        let availableWidth = containerWidth - insets.left - insets.right
        let availableHeight = containerHeight - insets.top - insets.bottom
        guard availableWidth > 0, availableHeight > 0, aspect > 0 else { return .zero }
        let height = min(availableHeight, availableWidth / aspect)
        let width = min(availableWidth, height * aspect)
        return PlaneRect(x: insets.left + (availableWidth - width) / 2, y: insets.top, width: width, height: height)
    }
}
