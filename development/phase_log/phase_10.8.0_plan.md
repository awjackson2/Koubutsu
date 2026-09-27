# Phase 10.8.0 Plan — Study navigator: arrow controls

## Phase
- **Number:** 10.8.0
- **Name:** Study navigator — arrow controls for words, lines and characters
- **Status:** Planned
- **Date drafted:** 2026-09-27

## Purpose
In iPhone portrait study mode the frozen frame is about 375 pt wide and glyphs are a few points tall. Even with the
10.5.0 tap tolerances, picking one character or one word by touch is slow and error-prone. Arrow controls let the
learner walk the recognized Japanese word by word and line by line, and grow or shrink the selection a character at
a time, without touching the video. This is a follow-up in the 10.7–10.9 slot of the Major 10 umbrella
(`phase_10.0.0_plan.md`, "follow-ups found in on-device testing").

## Immediate Goal
1. A `StudyNavigator` in KoubutsuCore: reading-order lines, word units per line from `DictionaryLookup.segment(_:)`
   (per-character fallback), and the steps next/previous word, next/previous line, extend/shrink by one character,
   extend by one word. Linux tests.
2. `StudySession.move(_:)`: applies a step to the current selection through the same lookup/translate/segment path
   as a tap (word steps) or a drag (every other step).
3. A navigator pad in `StudyPanel` (◀ ▶ word, ▲ ▼ line, − ＋ character, ＋▶ word) with 44 pt targets and VoiceOver
   support, on every layout class.
4. Hardware keyboard: ←/→ word, ↑/↓ line, ⇧←/⇧→ shrink/extend, ⌥⇧→ extend by word while study is active.
5. The selection highlight on the frozen frame follows every move (it already draws `session.spans`).

## Confirmed Starting Point
Branch at `0157679` (10.1.0–10.6.0 done).
- `Packages/KoubutsuCore/Sources/KoubutsuCore/Study/StudySelection.swift`: `SelectedSpan` (observation ID, character
  range, text, line text); `StudySelection.spans(in:)` orders lines by `(minY, minX)` — the reading-order convention.
- `Packages/KoubutsuCore/Sources/KoubutsuCore/Dictionary/DictionaryLookup.swift`: `segment(_:)` returns
  `LookupToken`s (text, character offset, results) that tile the phrase; unknown runs merge into one token.
- `App/Study/StudySession.swift`: `tap(at:)` → `spans = [span]`, translate the line, `lookUpWord` (widens to the
  matched word); `select(rect:)` → spans, translate and `segment` the joined text; lookups run in
  `Task.detached(priority: .userInitiated)`.
- `App/UI/StudyPanel.swift`: header (title group, Clear, landscape collapse chevron, Done) and a scrolling content
  area; regular 210 pt, compact portrait fills its region, compact landscape strip ≤ 40 % of the stage.
- `App/UI/StudyView.swift`: `highlights` draws `session.selectionBoxes()` through `CoordinateMapper`, animated on
  `session.spans` — navigator moves are drawn with no change.
- `App/UI/KeyboardShortcuts.swift`: ←/→ skip the file source by 10 s; no ↑/↓.
- Pixel icons (`App/Resources/Assets.xcassets/px.*`): `chevron` (points right), `plus`; no arrows, no minus.

## Scope For This Phase
### In
- `StudyNavigator` (new core file) + `StudyNavigatorTests`; `StudySelection.readingOrder(_:)` shared helper.
- `StudySession`: segmentation of every Japanese line once when the frame is read, navigator, `move(_:)`,
  `canMove(_:)`, `select(spans:asWord:)`.
- `StudyPanel`: navigator pad; header adapts (pad inline on regular and compact landscape, own row in portrait).
- `KeyboardShortcuts`: arrow keys route to the navigator while study is active; `RootView` passes the session.
### Out
- `CompactPortraitLayout.swift` / `PortraitDeck.swift` (10.7.0 in parallel) and all other layout files.
- New pixel-icon assets (arrows are the rotated chevron; minus is drawn — see Key Decisions).
- Vertical (tategaki) reading order; navigating non-Japanese lines (study only uses Japanese lines).
- Design docs and the phase index (synced separately).

## Recommended Implementation Direction
Keep every rule in the pure navigator so it is Linux-tested; the session only applies its result and the UI only
calls steps. Lines are the Japanese observations in reading order (top-to-bottom, then left-to-right, the
`StudySelection.spans(in:)` convention, factored into one helper). Each line has word units: the segmentation tokens'
character ranges with leading/trailing whitespace and punctuation trimmed and all-punctuation tokens dropped (so ▶
never stops on 「 or 。); without tokens, one unit per non-punctuation character. Lines with no units are skipped.

Steps on the selection (the first span for backward steps, the last for forward ones):
- **Next word**: the first unit that starts after the selection's start and ends after its end (so a tapped
  character skips the rest of its word, and a widened tap never gets stuck); otherwise the first unit of the next
  line. **Previous word**: the last unit that starts before the selection's start; otherwise the last unit of the
  previous line.
- **Next / previous line**: the whole adjacent line (first unit start to last unit end — a "phrase").
- **Extend by a character**: the last span's end grows by one; at the end of its line a one-character span of the
  next line's first unit is appended (multi-span, as a drag across lines). **Shrink**: the last span's end shrinks
  by one; a one-character last span is dropped when other spans remain; a single one-character selection does not
  shrink.
- **Extend by a word**: the last span's end moves to the end of the next unit; at the line end the next line's first
  unit is appended.
- No selection: word and character steps select the first word of the first line; line steps select the first
  line.
- Ends stop (no wraparound): the step returns nil and the selection stays; the UI disables that control.

## Technical Plan
- `Packages/KoubutsuCore/Sources/KoubutsuCore/Study/StudyNavigator.swift`: `StudyNavigator` (`Sendable`,
  `Equatable`) with `Line`, `Step` (`CaseIterable`), `init(observations:wordRanges:)`,
  `static wordRanges(tokens:length:)`, `static units(in:ranges:)`, `initialSelection`, `move(_:from:) ->
  [SelectedSpan]?`.
- `StudySelection.readingOrder(_:)` (public static) used by `spans(in:)` and the navigator.
- `App/Study/StudySession.swift`: `navigator` (observable), built character-level as soon as OCR finishes, then
  replaced by the word-level navigator from a detached segmentation task (cancelled on `end()`/new `begin`);
  `move(_:)`, `canMove(_:)`; `select(spans:asWord:)` — word steps take the tap path (translate the line, look up
  and widen the word), the others the drag path (translate and segment the selection).
- `App/UI/StudyPanel.swift`: `StudyNavigatorPad` (private view in the same file, no project-file change): three
  groups ◀▶ │ ▲▼ │ −＋＋▶, `KIconButtonStyle` 44 pt buttons, `PixelIcon("chevron")` rotated, `PixelIcon("plus")`,
  a drawn minus bar matching the plus icon's stroke. VoiceOver: the ◀▶ pair is one adjustable element ("Word",
  value = selected text; swipe up/down = next/previous word); the other buttons are labelled ("Previous line",
  "Next line", "Shrink selection", "Extend selection", "Extend selection by a word").
- `App/UI/KeyboardShortcuts.swift`: `study` parameter; ←/→ → previous/next word while studying (else skip ±10 s as
  before); ↑/↓, ⇧←/⇧→, ⌥⇧→ enabled only while studying. `App/UI/RootView.swift`: passes `study`.

## Test Plan
- `swift test --package-path Packages/KoubutsuCore` (scoped: new `StudyNavigatorTests`, `StudySelectionTests`).
- Navigator tests: reading order of unsorted lines; word stepping within and across lines; ends stop (no wrap);
  empty and punctuation-only lines skipped; punctuation trimmed from units; line steps select whole lines; extend /
  shrink by a character within a line and across a line end (two spans); shrink floor; extend by a word; stepping
  after an extended selection; tapped single character and widened tap; per-character fallback; invalid token ranges
  ignored; stale observation ID restarts; integration with `DictionaryLookup.segment` on the fixture dictionary.
- App code: macOS CI build and iPhone/iPad simulator tests after merge.

## Key Decisions
- Pad on every layout class. Regular (iPad): inline in the header row, which has spare width, so the 210 pt panel
  gains no height. Compact landscape: inline in the header too (the strip is short); the title group falls back to
  the icon and SEL count via `ViewThatFits` on narrow phones. Compact portrait: its own row under the header.
- Word steps take the tap path (dictionary word card, line translation) because a word is what a tap selects; line,
  character and extend steps take the drag path (phrase segmentation, selection translation).
- Arrows are the rotated `chevron`, and minus is a drawn bar matching the `plus` icon (14×4 of 16). Adding icons via
  `Tools/pixel_art.py` would regenerate every asset; not worth it for one glyph.
- ← / → on a hardware keyboard navigate while study is active (the file source is paused then, so skipping is not
  useful) and keep skipping ±10 s otherwise.
- No wraparound: stopping at the ends gives the learner a clear boundary and a disabled control as feedback.

## Expected Limitations At End Of Phase
- App code not compiled locally (Linux container); verified by macOS CI after merge.
- Horizontal reading order only; vertical text is walked in its box order.
- Until the segmentation task finishes (a few ms per line) or when the dictionary is not unpacked, word steps move
  one character at a time.

## What Comes Next
- Design-doc sync (architecture "Study mode") and phase index entry, done separately.
- On-device check of the pad in iPhone portrait and landscape.

## Summary
A pure, tested `StudyNavigator` walks the frozen frame's Japanese by word, line and character; the study session
applies its steps through the existing tap and drag paths; a compact 44 pt arrow pad in the study panel and the
hardware arrow keys drive it, so studying on a small iPhone video no longer depends on hitting tiny glyphs.
