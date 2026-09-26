/// Where the video is drawn on screen. The stage depends only on the container (window) size, never on which
/// panels or bars are showing: UI chrome overlays the space below it, so the video and every replacement box
/// stay put when chrome appears, hides or changes height.
public enum VideoStageLayout {
    /// Switch output (and most capture) is 16:9; other aspects fit inside the stage.
    public static let defaultAspect = 16.0 / 9.0

    /// Full container width, top-aligned, height from `aspect`; clamped (and centred horizontally) when the
    /// container is too short for full width.
    public static func stage(containerWidth: Double, containerHeight: Double,
                             aspect: Double = defaultAspect) -> PlaneRect {
        guard containerWidth > 0, containerHeight > 0, aspect > 0 else { return .zero }
        let height = min(containerHeight, containerWidth / aspect)
        let width = min(containerWidth, height * aspect)
        return PlaneRect(x: (containerWidth - width) / 2, y: 0, width: width, height: height)
    }
}
