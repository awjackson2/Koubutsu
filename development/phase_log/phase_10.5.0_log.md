# Phase 10.5.0 Log — Study mode on compact layouts

## Phase
- **Number:** 10.5.0
- **Name:** Study mode on compact layouts
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
See `phase_10.5.0_plan.md` (umbrella 10.0.0). Study mode fits the compact layouts: the study panel fills the space
under the video in portrait and is a collapsible strip of at most 40 % of the stage height in landscape, the word
card opens full height when the screen is short, taps on small glyphs still hit, and every study panel button is a
labelled 44 pt target. The iPad keeps its layout and selection behaviour.

## Major Additions
- Core (`VideoStageLayout`): `regularStudyPanelHeight` (210), `overlayStudyFraction` (0.4),
  `studyPanelCollapsedHeight` (56), `overlayStudyPanelHeight(stageHeight:collapsed:)`, `studyLoupeMaxSize` (130),
  `studyLoupeSize(stageHeight:)` (min(130, 45 % of the stage height)), `studyTapTravel(for:)` (12 regular / 8
  compact), `studyMinimumTapSlop(for:)` (0 regular / 10 pt compact).
- Core (`CoordinateMapper`): `normalizedLength(fromView:)` — a view distance in normalized units per axis of the
  displayed video.
- Core (`StudySelection`): `character(at:minimumSlopX:minimumSlopY:)` (the existing `character(at:)` forwards with
  zero minimums, so its behaviour is identical) and `characterCentre(at:minimumSlopX:minimumSlopY:)`.
- 8 tests in `StudyCompactLayoutTests`, one parameterized over three iPhone sizes (strip ≤ 40 % on iPhone SE/15/Pro Max landscape stages, collapsed height,
  loupe unchanged on iPad stages, per-class tolerances, `normalizedLength` with letterbox/pillarbox/degenerate
  mappers, a tap 6 pt below a 5 pt line misses without and hits with the compact minimum and its snapped centre
  resolves to the same character, zero minimum equals the old tap, nearest of two close lines).

## Major Changes
- `StudyPanel` reads `@Environment(\.layoutClass)` and `verticalSizeClass`:
  - height: regular 210 pt (from the core constant, same value); compact portrait no fixed height, fills what the
    layout offers (`frame(maxHeight: .infinity)`); compact landscape `overlayStudyPanelHeight` of the new
    `overlayStageHeight` input, or the 56 pt header when collapsed;
  - selected text 34 / 26 / 22 pt (regular / portrait / landscape); context line `.body` on compact; translation
    16 pt on compact; landscape uses the compact `WordSummary` for the best match;
  - header one line (`lineLimit(1)`): compact drops `BlockMarks`, uses an 18 pt icon, 16 pt STUDY and 12 pt SEL;
    Clear and Done use `kButtonTarget()` (44 pt); landscape adds a chevron collapse/expand button
    (`KIconButtonStyle`, 44 pt); a new selection re-expands the strip;
  - VoiceOver: header group is one heading ("Study", value "N characters selected"); "Clear selection",
    "Done studying" (hint "Returns to the live video"), "Collapse/Expand study panel"; the best-match row
    ("Card ▶") and token rows read "headword, reading" with the first meanings as value and hint "Opens the word
    card"; blinking cursors hidden; word rows at least 44 pt tall, token rows full width;
  - word card detents: `[.large]` when the vertical size class is compact or the layout is compact landscape,
    else `[.medium, .large]` as before.
- `StudyView`: tap/drag threshold, loupe size and status font (14 pt compact) from the layout class via core; on
  compact a tap snaps to the centre of the nearest character within the minimum tolerance (converted by
  `CoordinateMapper.normalizedLength`), then goes to the unchanged `StudySession.tap(at:)`. Regular: minimum 0, the
  tap point is passed through unchanged; threshold 12 pt and loupe 130 pt as before.
- `CompactPortraitLayout`: the study panel fills the chrome region (the spacers around it removed).
- `CompactLandscapeLayout`: study mode shows `studyPanel(overlayStageHeight: stage.height)`; the chrome stays up
  and the CONTROLS tab hidden for the whole of study mode (existing `chromeShown = chromeRevealed || study.isActive`,
  confirmed and documented).
- `RootView` (minimal): `func studyPanel(overlayStageHeight:)`; `var studyPanel` forwards with nil.

## Progress Made
- `swift test --package-path Packages/KoubutsuCore` (Linux): 163 tests in 30 suites pass.

## Key Decisions
- Landscape: a bottom strip capped at 40 % with collapse, not a side column (the stage already uses the full height
  and nearly the full width; a column would shrink the video) and not a sheet (it would cover the frozen frame and
  have to be dismissed before every new selection). Collapsing to the header shows the whole frame; details go to
  the word card sheet, which opens full height in landscape.
- Small-glyph taps: a minimum tolerance in view points, converted through the coordinate-mapping layer, and a snap
  to the character centre in `StudyView`, so `StudySession` is untouched and the iPad path (minimum 0) is exact.
- 44 pt Clear/Done apply on the iPad too (as 10.6.0 did for sheet buttons): the regular header grows about 16 pt
  inside the unchanged 210 pt panel, leaving slightly less room for the scrolling content.

## Current Limitations
- Not yet compiled; verified by macOS CI after merge. APIs relied on: `@Environment(\.verticalSizeClass)`,
  `presentationDetents(_: Set<PresentationDetent>)`, `frame(height:alignment:)` / `frame(maxHeight:alignment:)`
  with nil values, `onChange(of:_:)` on `[SelectedSpan]`, `accessibilityValue`/`accessibilityHint` on a `Button`.
- Tap tolerance values (10 pt, 8 pt travel) are reasoned, not measured on a device.
- In iPhone landscape the system may present sheets at full height regardless of detents; `[.large]` is then a
  no-op, which is fine.
- No iPhone study screenshots yet.

## Artifacts Produced
- `App/UI/StudyPanel.swift`, `App/UI/StudyView.swift`, `App/UI/CompactPortraitLayout.swift`,
  `App/UI/CompactLandscapeLayout.swift`, `App/UI/RootView.swift`
- `Packages/KoubutsuCore/Sources/KoubutsuCore/Geometry/VideoStageLayout.swift`,
  `Packages/KoubutsuCore/Sources/KoubutsuCore/Geometry/CoordinateMapper.swift`,
  `Packages/KoubutsuCore/Sources/KoubutsuCore/Study/StudySelection.swift`,
  `Packages/KoubutsuCore/Tests/KoubutsuCoreTests/StudyCompactLayoutTests.swift`
- `development/phase_log/phase_10.5.0_plan.md`, `development/phase_log/phase_10.5.0_log.md`

## What Comes Next
- macOS CI build; iPhone study screenshots (portrait, landscape expanded/collapsed, word card); on-device check of
  tap accuracy on small glyphs.
- Design-doc sync (architecture "Screen layout" / "Study mode") and index append.

## Summary
Study mode now works on an iPhone: in portrait the study panel takes the whole space under the video with smaller
type and a header that fits 375 pt; in landscape it is a scrolling strip of at most 40 % of the video that
collapses to one line, and the word card opens full height. Taps near small text snap to the nearest character
using a tolerance converted by the coordinate layer, and every study button is a labelled 44 pt target; the iPad
keeps its panel and selection behaviour.
