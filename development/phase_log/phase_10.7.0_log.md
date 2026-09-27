# Phase 10.7.0 Log — Portrait info deck

## Phase
- **Number:** 10.7.0
- **Name:** Portrait info deck — live log, on-screen words, session HUD
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
See `phase_10.7.0_plan.md` (umbrella 10.0.0, follow-up slot 10.7). In compact portrait outside full screen with no
scrolling panel enabled (overlay mode, Japanese text list off — the default), the empty housing gap between the
transport and control bars becomes an info deck: a `LOG | WORDS | SESSION` tab strip over swipeable pages. The
iPad and compact landscape layouts, full screen and study mode are unchanged.

## Major Additions
- Core (`VideoStageLayout`): `portraitDeckTabHeight` (44), `portraitDeckMinHeight` (120),
  `showsPortraitDeck(fillerHeight:)`.
- Core (`Study/DeckWords.swift`, new): `DeckWord` (surface, headword, reading, first gloss, all matches, source
  block index; failable init), `DeckWordState` (known / learning / new with OSD labels), `DeckWords.isUseful(_:)`
  (drops tokens without a glossed match, lone kana, non-Japanese text and words whose parts of speech are all
  function words: particles, copula, auxiliaries, affixes, counters), `words(from:sourceIndex:)`,
  `words(texts:lookup:limit:)` (line-by-line segmentation, de-duplicated by entry + headword, first occurrence
  kept), `state(of:in:)`.
- Core (`Study/ReadingSessionStats.swift`, new): `linesRead(in:)`, `translatedLines(in:)`, `wordsSaved(in:)`,
  `elapsed(at:)`, `clock(_:)` ("HH:MM:SS"), `meterSegments(value:full:segments:)`.
- 10 tests in `PortraitDeckTests` (deck threshold; filler fits the deck on iPhone SE / 15 / Pro Max portrait;
  word order, particle/copula/punctuation filtering, cross-block de-duplication, limit and empty input, word-bank
  state; session counts since start; clock text; meter clamping).
- App (`App/UI/PortraitDeckModel.swift`, new): `@MainActor @Observable PortraitDeckModel`, owned by `RootView`
  (`@State var deck`), so the session outlives the deck view. `update(texts:lookup:)` keeps only Japanese blocks,
  ignores unchanged text, debounces 250 ms, segments with `Task.detached(priority: .utility)`, cancels superseded
  runs; keeps the last words (marked stale) while no Japanese is on screen; counts distinct words seen.
- App (`App/UI/PortraitDeck.swift`, new):
  - `PortraitDeck`: tab strip (block marks, three 44 pt tab buttons, red filled active tab, word count on WORDS,
    VoiceOver label/hint and `.isSelected` trait) over `TabView(selection:)` with
    `.tabViewStyle(.page(indexDisplayMode: .never))`; tab in `@SceneStorage("portraitDeck.tab")`; ink panel at
    88 % over the housing texture with red corner ticks; tab changes animate with `K.snap` unless Reduce Motion.
  - `DeckWordFeed`: invisible view that observes `displayed` texts and the dictionary state and feeds the model,
    so geometry-only box updates do not re-evaluate the deck.
  - LOG: last 80 history entries, Japanese (`.footnote`) over English (`K.osd(15, relativeTo: .subheadline)`),
    HH:MM:SS stamp, red 3 pt bar on lines still on screen, "TRANSLATING" + blinking cursor while translating;
    `defaultScrollAnchor(.bottom)` plus `ScrollViewReader` scroll on a new line or when the newest line's
    translation arrives (no animation under Reduce Motion); empty state "WAITING FOR DIALOGUE" + cursor.
  - WORDS: "ON SCREEN" / "LAST SEEN" header with count; rows of headword, reading, first gloss and a
    KNOWN / LEARNING / NEW tag, 44 pt tall, opening `WordCardView` in a sheet (`[.medium, .large]`); a bookmark
    save button (disabled once saved) saving the best match with its block as the sentence, the block's translation
    and presentation time from the dialogue history, no image; empty states for loading / missing dictionary /
    no words.
  - SESSION (`TimelineView(.periodic(by: 1))`): tiles for session time, lines (+ translated), words seen, words
    saved this session; reviews due with a REVIEW button (opens `RootView.showingReview`); PIPELINE section with
    12-block pixel meters for OCR rate vs the configured target, OCR latency (full scale 500 ms) and translation
    latency (1.5 s), latency meters red past three quarters; every tile/meter one VoiceOver element.

## Major Changes
- `CompactPortraitLayout.swift` (non-study branch only): the housing filler `Spacer` becomes
  `portraitDeckFiller`, a `GeometryReader` that shows the deck when `showsPortraitDeck(fillerHeight:)` and is
  otherwise empty (housing shows through as before).
- `RootView.swift`: one `@State var deck = PortraitDeckModel()` line; nothing else.

## Progress Made
- `swift test --package-path Packages/KoubutsuCore` (Linux): 173 tests in 31 suites pass.

## Key Decisions
- Deck state lives in `RootView`, not the deck view: study mode, full screen and rotation remove the deck, and the
  session counters must survive that.
- `@SceneStorage` for the tab, leaving `AppSettings` and its Codable file untouched.
- Words are fed by text changes only (the `displayed` array also changes for box geometry); the debounce keeps
  typewriter reveals from segmenting each character.
- Words from the last dialogue box stay up as "LAST SEEN" while nothing is on screen, so the list does not flash
  empty between boxes.
- Saving from the deck records the line, translation and media time (rule 4) but no crop — there is no frozen frame
  outside study mode.
- New core files beside the study code instead of edits to `StudySelection.swift`, which 10.8.0 is changing.

## Current Limitations
- Not yet compiled; verified by macOS CI after merge. APIs relied on: `@SceneStorage` with a `String`
  raw-value enum, `TabView(selection:)` + `.tabViewStyle(.page(indexDisplayMode: .never))`,
  `defaultScrollAnchor(_:)`, `ScrollViewReader.scrollTo(_:anchor:)`, `onChange(of:initial:_:)`,
  `TimelineView(.periodic(from:by:))`, `Grid`/`GridRow`, `accessibilityAddTraits(.isSelected)`,
  `presentationDetents`.
- A paging `TabView` inside the chrome region is unverified on device (horizontal swipes versus the chrome's tap
  gesture; page background transparency).
- "Words seen" counts only while the deck is on screen (segmentation does not run otherwise).
- Session statistics reset on relaunch; "lines" come from the in-memory history (capacity 500, cleared with the
  history).
- Meter full scales (500 ms OCR, 1.5 s translation) are reasoned, not measured.
- No iPhone screenshots of the deck yet; design docs and the phase index are not synced in this commit.

## Artifacts Produced
- `App/UI/PortraitDeck.swift`, `App/UI/PortraitDeckModel.swift`, `App/UI/CompactPortraitLayout.swift`,
  `App/UI/RootView.swift`
- `Packages/KoubutsuCore/Sources/KoubutsuCore/Geometry/VideoStageLayout.swift`,
  `Packages/KoubutsuCore/Sources/KoubutsuCore/Study/DeckWords.swift`,
  `Packages/KoubutsuCore/Sources/KoubutsuCore/Study/ReadingSessionStats.swift`,
  `Packages/KoubutsuCore/Tests/KoubutsuCoreTests/PortraitDeckTests.swift`
- `development/phase_log/phase_10.7.0_plan.md`, `development/phase_log/phase_10.7.0_log.md`

## What Comes Next
- macOS CI build; `device=iphone` portrait screenshots of each deck page; on-device check of paging and scrolling.
- Design-doc sync (architecture "Screen layout", ui_theme compact housing) and index append.

## Summary
iPhone portrait no longer shows a blank housing under the video: a three-page HUD deck shows the running Japanese /
English transcript, the dictionary words on screen with their word-bank state and one-tap save or word card, and a
session readout with review access and pipeline meters. It reads only existing observable state, segments off the
main actor on text changes, and keeps its layout rule and pure logic in KoubutsuCore with Linux tests.
