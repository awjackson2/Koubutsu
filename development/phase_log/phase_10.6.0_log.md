# Phase 10.6.0 Log — Sheets and accessibility pass

## Phase
- **Number:** 10.6.0
- **Name:** Sheets and accessibility pass (settings, word bank, review, recent lines, word card)
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
See `phase_10.6.0_plan.md` (umbrella 10.0.0; developed in parallel, ahead of its roadmap position). The five sheets
fit 375 pt wide and about 390 pt tall sheets, survive Dynamic Type up to the accessibility sizes, read well with
VoiceOver and have 44 pt targets, without changing the iPad layout beyond taller hit areas.

## Major Additions
- `App/UI/SheetSupport.swift`: `SheetLayout.narrowWidth` (500 pt) and `trackingNarrowWidth(_:)` (measured with
  `onGeometryChange`); `kButtonTarget(compact:)` (label frame that makes a `KButtonStyle` button 44×44 pt);
  `kHeading()` (section header as one VoiceOver heading); `kAdjustable(...)` (VoiceOver adjustable element for
  `KSlider`); `KChoicePicker` (the `KSegmented` look with 44 pt segments, `.isSelected` traits and a vertical list
  when the options do not fit or at accessibility sizes).
- `FittingFuriganaText` in `WordCardView.swift`: `FuriganaText` at the largest of 100/75/55/40 % of its size that
  fits the width (`ViewThatFits`). `FuriganaText` now reads as one VoiceOver element (word, then reading).

## Major Changes
- **Settings:** `KChoicePicker` replaces `KSegmented`; toggles have 44 pt labels, grouped without extra spacing so
  the row pitch stays close to the old one, plus the `.isToggle` trait; sliders are VoiceOver-adjustable; licence
  links stack when they do not fit; wordmark height from `@ScaledMetric` and hidden from VoiceOver; 16 pt padding
  when narrow; "never leave the device" (not "the iPad").
- **Word bank:** narrow or accessibility sizes → icon-only Anki button (labelled "Export to Anki"), search and
  Review stacked, rows stacked (88×35 thumbnail above the text, Learn/Known and delete in a column, headword line
  stacks when it does not fit, two-line meaning/sentence). Short height or accessibility sizes → the search controls
  scroll with the list. Thumbnails hidden from VoiceOver; delete labelled with the word.
- **Review:** the card sits in a `ScrollView` and the Show answer / grade buttons are pinned below it, so they stay
  on screen in landscape; grades 2×2 when narrow and one column at accessibility sizes; grade buttons read
  "Grade 1, Again" with "Next review in …" as the value; question headword scales down to one line, answer furigana
  fits; the empty state scrolls; "[SPACE]" hint dropped when narrow; margins 16 pt when narrow or short.
- **Recent lines:** narrow or accessibility sizes → Copy all and Clear move from the header into the top of the list;
  row number and text combined for VoiceOver ("Line 3, …"); copy buttons labelled "Copy line N".
- **Word card:** reading line, action buttons and conjugation stack when they do not fit; kanji tiles 56 pt when
  narrow; other-match rows put the gloss under the headword when narrow, are 44 pt tall, carry `.isSelected`, and
  hide the ■/□ glyphs; senses and kanji rows combined for VoiceOver; section headers are headings; Save labelled.
- All text-labelled `KButtonStyle` buttons (Done, Copy all, Clear, Learn/Known, links, Show answer, grades) and
  icon-only ghost buttons get 44 pt through `kButtonTarget`. `KIconLabel` buttons rely on 10.2.0's 44 pt
  `KIconLabel`.

## Progress Made
- All five sheets and one helper file changed; no KoubutsuCore changes.

## Key Decisions
- Compact decisions inside sheets use the sheet's measured width (500 pt threshold) and
  `dynamicTypeSize.isAccessibilitySize`, and `verticalSizeClass` for short heights — a sheet's width differs from
  the window's, and an iPad sheet's size class does not reliably describe it. iPad sheets are wider than 500 pt.
- `ViewThatFits` only where children have honest ideal widths (short labels, buttons); rows with truncating text
  use the measured width instead, because a `lineLimit(1)` text's ideal width is its full length.
- Hit areas grow inside button labels: a frame or content shape outside a `Button` does not enlarge its hit area.
- `KChoicePicker` lives in `App/UI/` because `Components.swift` is owned by 10.2.0 this round.

## Current Limitations
- Not yet compiled; verified by macOS CI after merge. APIs relied on: `onGeometryChange(for:of:action:)`,
  `ViewThatFits`, `@ScaledMetric(relativeTo:)`, `scrollBounceBehavior(.basedOnSize)`,
  `accessibilityAdjustableAction`, `AccessibilityTraits.isToggle`/`.isSelected`/`.isHeader`,
  `DynamicTypeSize.isAccessibilitySize`.
- iPad look changes slightly: settings segments are 44 pt tall (were about 33), toggle rows 44 pt, and text buttons
  in sheet headers and rows are 44 pt tall (were about 28).
- Still below 44 pt (in `Components.swift`, not owned here): `KSearchField`'s clear button and `KSlider`'s 36 pt
  track. `KSheetHeader`'s title truncates at the largest accessibility sizes.
- `KToggleStyle` still reads its "ON/OFF" readout as part of the label.
- No simulator screenshots or VoiceOver pass yet.

## Artifacts Produced
- `App/UI/SheetSupport.swift` (new), `App/UI/SettingsView.swift`, `App/UI/WordBankView.swift`,
  `App/UI/ReviewView.swift`, `App/UI/RecentLinesView.swift`, `App/UI/WordCardView.swift`,
  `development/phase_log/phase_10.6.0_plan.md`, `development/phase_log/phase_10.6.0_log.md`.

## What Comes Next
- CI build; iPhone screenshots of each sheet (portrait, landscape, an accessibility text size) once 10.1.0 adds
  the iPhone simulator.
- `Components.swift` follow-up: 44 pt `KSearchField` clear button and `KSlider`; fold `KChoicePicker` into
  `KSegmented`; toggle value for VoiceOver.

## Summary
The sheets stack instead of overflowing on an iPhone, keep their Done and grade buttons reachable in landscape, scroll
at large text sizes, label every icon-only control for VoiceOver and give their controls 44 pt targets; the iPad
keeps its layout apart from taller hit areas.
