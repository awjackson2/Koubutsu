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

    /// Header strip height of the slim housing in compact portrait (10.1.0).
    public static let compactHeaderHeight = 24.0

    /// Housing insets outside full screen for `layout`. `safe` is the window's safe-area insets.
    /// - regular: as `windowedInsets(safeTop:)`.
    /// - compact portrait: slim header under the status bar, 6 pt bezels clear of the safe area.
    /// - compact landscape: no header; the stage stays inside the safe area (Dynamic Island/notch, home indicator).
    public static func windowedInsets(for layout: LayoutClass, safe: StageInsets) -> StageInsets {
        switch layout {
        case .regular:
            return windowedInsets(safeTop: safe.top)
        case .compactPortrait:
            return StageInsets(top: max(safe.top, 20) + compactHeaderHeight, left: max(safe.left, 6),
                               bottom: max(safe.bottom, 6), right: max(safe.right, 6))
        case .compactLandscape:
            return StageInsets(top: max(safe.top, 4), left: max(safe.left, 6),
                               bottom: max(safe.bottom, 4), right: max(safe.right, 6))
        }
    }

    /// Compact landscape overlay chrome (10.4.0): the bars and panels never cover more than this fraction of the
    /// stage height.
    public static let overlayChromeFraction = 0.6

    /// Panels shorter than this are not worth showing in the overlay (one 44 pt row).
    public static let minimumOverlayPanelHeight = 44.0

    /// Height the panels may share in the compact landscape overlay: `overlayChromeFraction` of the stage height
    /// minus the bars (`barsHeight`); zero when less than `minimumOverlayPanelHeight` remains.
    public static func overlayPanelBudget(stageHeight: Double, barsHeight: Double) -> Double {
        let budget = stageHeight * overlayChromeFraction - barsHeight
        return budget >= minimumOverlayPanelHeight ? budget : 0
    }

    /// Padding of the compact landscape overlay chrome: the leading, trailing and bottom safe area (the chrome is
    /// bottom-anchored, so the top is free).
    public static func overlayChromeInsets(safe: StageInsets) -> StageInsets {
        StageInsets(top: 0, left: safe.left, bottom: safe.bottom, right: safe.right)
    }

    // MARK: Study mode (10.5.0)

    /// Study panel height in the regular (iPad) layout.
    public static let regularStudyPanelHeight = 210.0

    /// Compact landscape: the study strip never covers more than this fraction of the stage height.
    public static let overlayStudyFraction = 0.4

    /// Height of the study strip collapsed to its one-line header (a 44 pt row plus 6 pt padding above and below).
    public static let studyPanelCollapsedHeight = 56.0

    /// Height of the compact landscape study strip over a stage `stageHeight` tall: `overlayStudyFraction` of it,
    /// never less than the collapsed header; the collapsed header alone when `collapsed`.
    public static func overlayStudyPanelHeight(stageHeight: Double, collapsed: Bool) -> Double {
        guard !collapsed else { return studyPanelCollapsedHeight }
        return max(stageHeight * overlayStudyFraction, studyPanelCollapsedHeight)
    }

    /// Largest study loupe (the iPad size).
    public static let studyLoupeMaxSize = 130.0

    /// Side of the study loupe over a frozen frame `stageHeight` tall: at most 45 % of it, so it fits above the
    /// finger on a short video; 130 pt on every iPad stage.
    public static func studyLoupeSize(stageHeight: Double) -> Double {
        min(studyLoupeMaxSize, max(stageHeight, 0) * 0.45)
    }

    /// Finger travel (points) below which a study touch is a tap rather than a drag. Short words on a small
    /// compact video are only about 10 pt wide, so compact layouts use a smaller threshold.
    public static func studyTapTravel(for layout: LayoutClass) -> Double {
        layout == .regular ? 12 : 8
    }

    /// Minimum distance (points) outside a recognized line at which a study tap still hits it. Zero on the iPad
    /// (the line-height-relative slop alone applies, as before); on compact layouts glyphs can be about 5 pt tall,
    /// so a tap within 10 pt of the line still selects its nearest character.
    public static func studyMinimumTapSlop(for layout: LayoutClass) -> Double {
        layout == .regular ? 0 : 10
    }

    // MARK: Compact portrait (10.3.0)

    /// Gap between the compact portrait stage and the chrome stacked below it (clears the bezel).
    public static let compactChromeGap = 6.0

    /// Minimum height of each scrolling panel sharing the compact portrait chrome region.
    public static let compactPanelMinHeight = 88.0

    /// Height budgeted for the transport and control bars when deciding whether the panels get their minimum.
    public static let compactBarsAllowance = 100.0

    /// The slim housing header strip directly above `stage` (compact portrait, outside full screen).
    public static func compactHeader(above stage: PlaneRect) -> PlaneRect {
        PlaneRect(x: stage.x, y: stage.y - compactHeaderHeight, width: stage.width, height: compactHeaderHeight)
    }

    /// The full-width strip below `stage` that holds the bars and panels in compact portrait: from `gap` under the
    /// stage down to `bottomInset` above the container bottom. Never overlaps the stage; zero height when the stage
    /// leaves no room.
    public static func chromeRegion(below stage: PlaneRect, containerWidth: Double, containerHeight: Double,
                                    gap: Double = compactChromeGap, bottomInset: Double = 0) -> PlaneRect {
        let bottom = max(containerHeight - bottomInset, 0)
        let top = min(stage.maxY + gap, bottom)
        return PlaneRect(x: 0, y: top, width: max(containerWidth, 0), height: bottom - top)
    }

    /// Minimum height for each of the two scrolling panels in a chrome region `regionHeight` tall: the full
    /// minimum when two panels and the bars fit, otherwise zero (the panels then share what is left rather than
    /// pushing the chrome over the video).
    public static func compactPanelMinHeight(regionHeight: Double) -> Double {
        regionHeight >= compactPanelMinHeight * 2 + compactBarsAllowance ? compactPanelMinHeight : 0
    }

    // MARK: Portrait info deck (10.7.0)

    /// Height of the deck's tab strip (one 44 pt row of targets).
    public static let portraitDeckTabHeight = 44.0

    /// Smallest filler that gets the deck: the tab strip plus about two transcript rows. Below this the housing
    /// shows through as before.
    public static let portraitDeckMinHeight = 120.0

    /// Whether the compact portrait housing filler (the space between the transport and control bars when no
    /// scrolling panel is enabled) is tall enough for the info deck.
    public static func showsPortraitDeck(fillerHeight: Double) -> Bool {
        fillerHeight.isFinite && fillerHeight >= portraitDeckMinHeight
    }

    /// As `framed`, but centred vertically in the available height as well (full screen in compact portrait).
    public static func centered(containerWidth: Double, containerHeight: Double, insets: StageInsets = .zero,
                                aspect: Double = defaultAspect) -> PlaneRect {
        var stage = framed(containerWidth: containerWidth, containerHeight: containerHeight, insets: insets,
                           aspect: aspect)
        guard stage != .zero else { return .zero }
        let availableHeight = containerHeight - insets.top - insets.bottom
        stage.y = insets.top + (availableHeight - stage.height) / 2
        return stage
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
