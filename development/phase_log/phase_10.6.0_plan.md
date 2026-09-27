# Phase 10.6.0 Plan — Sheets and accessibility pass

## Phase
- **Number:** 10.6.0
- **Name:** Sheets and accessibility pass (settings, word bank, review, recent lines, word card)
- **Status:** Planned
- **Date drafted:** 2026-09-27

## Purpose
Umbrella 10.0.0 makes Koubutsu usable on an iPhone. The five sheets (settings, word bank, review, recent lines, word
card) are laid out for an iPad-width sheet: header rows and list rows overflow a 375 pt width, the review screen has
no scroll view and does not fit a 390 pt tall landscape iPhone, controls are below 44 pt, and icon-only or pixel-art
controls have no VoiceOver labels. This Minor fixes the sheets. It is developed in parallel with 10.1–10.5, ahead of
its roadmap position (approved).

## Immediate Goal
1. At 375 pt wide and at about 390 pt tall, every sheet shows all of its content without clipping or horizontal
   scrolling, and its Done button is always on screen.
2. Layouts survive Dynamic Type up to the accessibility sizes (content that can grow scrolls; no fixed heights).
3. Every icon-only or pixel-art control has a VoiceOver label; decorative art is hidden; rows read as one element
   where that reads better; review grade buttons have clear labels.
4. Controls in these sheets have hit areas of at least 44×44 pt.
5. The iPad look is unchanged apart from taller hit areas.

## Confirmed Starting Point
Major 9 complete (`5f01abf`). From the code:
- `App/UI/SettingsView.swift`: `KSegmented` rows (about 33 pt tall), `KToggleStyle` rows (about 24 pt tall),
  `KSlider` with no accessibility element, two links in one `HStack`, the wordmark at a fixed `frame(height: 36)`.
- `App/UI/WordBankView.swift`: header with Anki + Done; search field and Review button in one `HStack`; rows are
  one `HStack` of a 110×44 thumbnail, text, due label, Learn/Known and an icon-only trash button.
- `App/UI/ReviewView.swift`: no `ScrollView`; card with a 64 pt headword and `FuriganaText` (fixed size), four
  grade buttons in one `HStack` (labels such as "1 · AGAIN" are truncated below about 500 pt).
- `App/UI/RecentLinesView.swift`: header with Copy all + Clear + Done (about 445 pt with the title); icon-only copy
  button per row.
- `App/UI/WordCardView.swift`: `FuriganaText` at 52 pt (fixed size), reading/romaji/tag and the three action
  buttons in `HStack`s, conjugation in one `HStack`, 72×72 kanji tiles, other-match rows with `■/□` glyphs.
- Buttons use `KButtonStyle` (compact: 10×6 pt padding, about 28 pt tall). `App/Theme/Components.swift` is owned by
  another phase (10.2.0), which makes `KIconButtonStyle`/`KIconLabel` 44 pt; it is not edited here.
- 0 `accessibilityLabel` in `App/`.

## Scope For This Phase
### In
- The five sheet files above and new helper files under `App/UI/`.
- Width-driven compact layouts, Dynamic Type resilience, VoiceOver labels/grouping/traits, 44 pt targets.
### Out
- `RootView.swift`, `VideoTransportBar.swift`, `StudyPanel.swift`, `StudyView.swift`, `App/Theme/Components.swift`,
  `Packages/`, `Tools/`, `.github/` (other phases or out of scope).
- `KSearchField`'s clear button, `KSlider`'s 36 pt track and `KSheetHeader` internals (in `Components.swift`).
- Phase index and design-doc sync (done at merge by the umbrella owner).

## Recommended Implementation Direction
- Sheets have their own width (an iPad sheet is narrower than the window), so compact decisions inside a sheet use
  the sheet's measured width (`onGeometryChange`, narrow below 500 pt) or `ViewThatFits`, plus
  `dynamicTypeSize.isAccessibilitySize`; `verticalSizeClass == .compact` for short heights. iPad sheets are wider
  than 500 pt, so they keep the regular layout.
- Hit areas grow inside the button label (a `frame(minWidth:minHeight:)` sized to the style's padding), because a
  frame or content shape outside a `Button` does not enlarge its hit area.
- Keep the theme: new pieces reuse K tokens and the look of existing components.

## Technical Plan
- New `App/UI/SheetSupport.swift`:
  - `SheetLayout.narrowWidth` and `View.onNarrowWidthChange(_:)` (`onGeometryChange` on the sheet width).
  - `View.kButtonTarget(compact:)`: minimum label frame so a `KButtonStyle` button is at least 44×44 pt.
  - `View.kHeading()`: section header as one VoiceOver heading.
  - `View.kAdjustable(label:value:binding:range:step:)`: VoiceOver adjustable element for `KSlider`.
  - `KChoicePicker`: `KSegmented`'s look with 44 pt segments, `.isSelected` traits, and a vertical list when the
    options do not fit (`ViewThatFits`) or at accessibility sizes.
- `SettingsView`: `KChoicePicker` instead of `KSegmented`; toggles with 44 pt label height (grouped with no extra
  spacing so the row pitch stays close); toggle trait; slider accessibility; links wrap; wordmark height from
  `@ScaledMetric` and hidden from VoiceOver; 16 pt padding when narrow; "never leave the device".
- `WordBankView`: narrow header (icon-only Anki with a label), search and Review stacked, rows stacked with a
  smaller thumbnail and a vertical action column; controls scroll with the list when height is compact or at
  accessibility sizes; labels for trash and thumbnails hidden.
- `ReviewView`: card in a `ScrollView`, grade buttons pinned below it (2×2 when narrow), grade labels and values
  for VoiceOver, headword and furigana scale to width, smaller padding when narrow or short.
- `RecentLinesView`: narrow moves Copy all / Clear into a row inside the scroll view; row text combined for
  VoiceOver; copy buttons labelled.
- `WordCardView`: `FuriganaText` sized to fit and read as one element; reading line, action buttons and conjugation
  stack when they do not fit; kanji tiles 56 pt when narrow; other-match rows stack when narrow, selected trait,
  glyphs hidden; 44 pt targets.

## Test Plan
- No KoubutsuCore changes; `swift test` is unaffected. App code cannot be compiled on Linux: verified by the
  macOS CI job (iOS build, tests, screenshots on iPad and, once 10.1.0 lands, iPhone) after merge.
- Manual review: iPhone simulator screenshots at 375 pt portrait and landscape for each sheet; VoiceOver pass.

## Key Decisions
- Measured sheet width over `horizontalSizeClass` — a sheet's width differs from the window's, and an iPad sheet's
  size class does not describe its width reliably.
- Replace `KSegmented` in settings with a same-look `KChoicePicker` in `App/UI/` — `Components.swift` is owned
  elsewhere this Minor, and segments need 44 pt and a vertical fallback.

## Expected Limitations At End Of Phase
- Not compiled locally; verified by macOS CI after merge.
- `KSearchField` clear button and `KSlider` track remain below 44 pt until `Components.swift` is revisited.

## What Comes Next
- Follow-up in `Components.swift`: 44 pt `KSearchField` clear button and `KSlider`; fold `KChoicePicker` back into
  `KSegmented` if wanted.

## Summary
The sheets fit an iPhone in either orientation, grow with Dynamic Type, read well with VoiceOver and have 44 pt
targets, while the iPad keeps its layout.
