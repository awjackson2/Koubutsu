# Phase 10.5.0 Plan — Study mode on compact layouts

## Phase
- **Number:** 10.5.0
- **Name:** Study mode on compact layouts
- **Status:** Planned
- **Date drafted:** 2026-09-27

## Purpose
Study mode (Major 8) was built for the iPad: a fixed 210 pt study panel, a 34 pt selected-text font, a word card
sheet with a half-height detent, and tap tolerances tuned for iPad-sized glyphs. On an iPhone the panel covers most
of the frozen frame in landscape, the header overflows 375 pt in portrait, the word card opens as a sliver in
landscape, and a tap on a 5 pt glyph misses. This phase makes study mode usable on the compact layouts (umbrella
`phase_10.0.0_plan.md`, roadmap item 10.5.0) without changing the iPad.

## Immediate Goal
1. Compact portrait: the study panel fills the chrome region below the video (no fixed 210 pt), with a smaller
   selected-text font and a header that fits 375 pt.
2. Compact landscape: the study panel is a bottom strip capped at 40 % of the stage height, scrolling inside,
   with a collapse/expand button; the header stays one line.
3. Word card from study: large detent only when the height is compact.
4. Taps and drags on a small frozen frame hit the intended characters; the loupe fits a short video.
5. VoiceOver labels and 44 pt targets for every study panel button, including the word rows ("Card ▶").
6. Regular (iPad) layout and behaviour unchanged.

## Confirmed Starting Point
- `App/UI/StudyPanel.swift`: `.frame(height: 210)`, 34 pt selected text, header HStack (icon, STUDY 20 pt,
  `BlockMarks`, SEL count, Clear, Done), word card sheet `.presentationDetents([.medium, .large])`; no
  accessibility labels; Clear/Done are compact `KButtonStyle` buttons (about 28 pt tall).
- `App/UI/StudyView.swift`: `tapTravel` 12 pt, loupe 130 pt, status font 20 pt; tap → `CoordinateMapper` →
  `StudySession.tap(at:)` → `StudySelection.character(at:)` with `tapSlop` 0.35 × line height (normalized).
- `App/UI/CompactPortraitLayout.swift`: study mode puts `studyPanel` at the top of the chrome region followed by
  a `Spacer` (the panel stays 210 pt).
- `App/UI/CompactLandscapeLayout.swift`: `chromeShown = chromeRevealed || study.isActive`, so the chrome stays up
  and the CONTROLS tab is hidden during study; the study panel is 210 pt ≈ 57 % of an iPhone 15 landscape stage.
- `RootView.studyPanel` is a shared computed property used by all three layouts.
- `VideoStageLayout` (KoubutsuCore) holds all layout geometry; `overlayPanelBudget` caps the non-study overlay at
  60 %.

## Scope For This Phase
### In
- `StudyPanel` adapts via `@Environment(\.layoutClass)` (and `verticalSizeClass` for the card detents).
- Core geometry: study strip height for compact landscape, loupe size, tap travel and minimum tap tolerance per
  layout class; `CoordinateMapper` conversion of a view distance to normalized units; `StudySelection` tap with a
  minimum tolerance and snapping to the character centre. Linux tests.
- Compact portrait and landscape layouts place the adapted panel; `RootView.studyPanel` gains an overload that
  passes the stage height (minimal change).
- VoiceOver labels, hints and 44 pt targets in the study panel.
### Out
- Other sheets (10.6.0 done), bars (10.2.0 done), the word card's own layout (10.6.0).
- `StudySession` behaviour (lookup, translation) and the display/OCR paths.
- Design docs and the phase index (synced separately).

## Recommended Implementation Direction
**Compact landscape: bottom strip with collapse, not a side column or a sheet.** The stage fills the full height and
nearly the full width in landscape, so a side column would shrink the video; a sheet would cover the frozen frame
and would have to be dismissed before every new selection. A bottom strip capped at 40 % of the stage height keeps
the top 60 % of the frame (where most selections start, and all of it once collapsed) visible and touchable; the
strip scrolls internally, and a chevron button collapses it to its one-line header (56 pt) to reveal the whole
frame, or expands it again. Detail beyond the strip is already one tap away in the word card sheet, which opens at
the large detent in compact height. The strip auto-expands when a new selection arrives so results are never hidden.

**Tap tolerance through the coordinate layer.** Keep `StudySelection.tapSlop` (fraction of line height) and add a
minimum tolerance given in view points (`VideoStageLayout.studyMinimumTapSlop(for:)`: 0 regular, 10 pt compact)
converted to normalized units by `CoordinateMapper.normalizedLength(fromView:)`. `StudyView` asks
`StudySelection.characterCentre(at:minimumSlopX:minimumSlopY:)` for the nearest character and sends its centre to
`StudySession.tap(at:)`, so `StudySession` is unchanged and the regular path (minimum 0) resolves exactly as before.
Drag threshold: 12 pt regular, 8 pt compact (short words on a small video are only about 10 pt wide). Loupe:
`min(130, 45 % of the stage height)`, which is 130 on every iPad stage.

## Technical Plan
- `VideoStageLayout` (core): `overlayStudyFraction` (0.4), `studyPanelCollapsedHeight` (56),
  `overlayStudyPanelHeight(stageHeight:collapsed:)`, `studyLoupeSize(stageHeight:)`,
  `studyTapTravel(for:)`, `studyMinimumTapSlop(for:)`, `regularStudyPanelHeight` (210).
- `CoordinateMapper` (core): `normalizedLength(fromView:) -> (x: Double, y: Double)`.
- `StudySelection` (core): `character(at:minimumSlopX:minimumSlopY:)` (existing `character(at:)` forwards with 0),
  `characterCentre(at:minimumSlopX:minimumSlopY:)`.
- `StudyPanel`: `overlayStageHeight: Double?` input; per-class height (regular 210; portrait fills the offered
  height; landscape the strip or collapsed header), fonts (34/26/22), padding, header (no `BlockMarks` and smaller
  type on compact; collapse button in landscape; `lineLimit(1)`), `kButtonTarget()` on Clear/Done, labels and hints;
  word rows `frame(minHeight: 44)` with label/value/hint; card detents `[.large]` when the vertical size class is
  compact or the layout is compact landscape, else `[.medium, .large]`.
- `StudyView`: per-class tap travel, minimum tap slop, loupe size and status font from core.
- `CompactPortraitLayout`: study panel fills the chrome region (spacers removed).
- `CompactLandscapeLayout`: `studyPanel(overlayStageHeight: stage.height)`.
- `RootView`: `func studyPanel(overlayStageHeight:)`; `var studyPanel` forwards with nil.

## Test Plan
- `swift test --package-path Packages/KoubutsuCore` on Linux: new tests for the strip height (iPhone SE/15/Pro Max
  landscape stages ≤ 40 %, collapsed height, tiny stage), loupe size (iPad unchanged at 130), tap travel and slop per
  class, `normalizedLength(fromView:)` (aspect-fit letterboxing), tap snapping (a tap just outside a thin line misses
  without and hits with a minimum slop; the returned centre resolves to the same character; regular path unchanged).
- App code: macOS CI build after merge; iPhone study screenshots when the screenshot workflow runs.

## Key Decisions
- Bottom strip with collapse for landscape (see above) — keeps the frozen frame selectable.
- Minimum tap tolerance in points, only on compact — iPad behaviour unchanged; conversion lives in the mapper.
- Snap-to-centre in `StudyView` instead of a new `StudySession` API — keeps session logic untouched.

## Expected Limitations At End Of Phase
- Not compiled locally; verified by macOS CI after merge.
- No on-device check of finger accuracy on small glyphs yet.

## What Comes Next
- CI build; iPhone study screenshots (portrait, landscape, card); on-device check with the umbrella's other Minors.

## Summary
Study mode fits the iPhone: the panel fills the space under the video in portrait and becomes a collapsible 40 %
strip in landscape, the word card opens full height when the screen is short, and taps on small text snap to the
nearest character with tolerances computed by the coordinate layer; the iPad stays as it is.
