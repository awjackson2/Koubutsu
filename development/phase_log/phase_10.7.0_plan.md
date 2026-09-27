# Phase 10.7.0 Plan — Portrait info deck

## Phase
- **Number:** 10.7.0
- **Name:** Portrait info deck — live log, on-screen words, session HUD
- **Status:** Planned
- **Date drafted:** 2026-09-27

## Purpose
In compact portrait (iPhone held upright) with no scrolling panel enabled — overlay display mode with the Japanese
text list off, the default — the chrome region leaves a large empty housing gap between the transport bar and the
control bar (about 350–400 pt on a 6.1" phone, `docs/screenshots/iphone1032_portrait.jpg`; noted as a 10.7
candidate in the 10.3.2 log). Fill it with information a player reading a Japanese game actually wants, in the
Koubutsu VCR/HUD look, without touching the display path. Umbrella: `phase_10.0.0_plan.md` (Minors 10.7–10.9 left
free for follow-ups).

## Immediate Goal
1. A "deck" in that gap: a one-line tab strip `LOG | WORDS | SESSION` (44 pt targets, red active tab, VoiceOver
   selected trait) over horizontally swipeable pages; the selected page is remembered per scene.
2. LOG: the live dialogue transcript from `TranslationController.history` (Japanese over English, newest at the
   bottom, auto-scroll, red marker on lines on screen, blinking cursor while a line translates, empty state).
3. WORDS: dictionary words of the Japanese currently on screen (segmented off the main actor, only when the text
   changes), with reading, first gloss, word-bank state (KNOWN / LEARNING / NEW), a save button and the word card
   on tap.
4. SESSION: elapsed time, lines read, words seen, words saved this session, reviews due (opens review), and OCR
   rate / OCR latency / translation latency as pixel bar meters.
5. Pure logic and the new layout rule in KoubutsuCore with Linux tests.

## Confirmed Starting Point
Branch at `0157679` (Major 10 through 10.6.0 and 10.3.2).
- `App/UI/CompactPortraitLayout.swift` `compactPortraitChrome`: outside full screen with no flexible panel a
  `Spacer(minLength: 0)` ("housing filler") sits between `panels(...)` and `controlBar`; the `CompactMonitorFrame`
  texture shows through.
- `TranslationController` (`App/Translation/TranslationController.swift`): `history: DialogueHistory` (entries with
  `source`, `translation`, `date`, `id`), `displayed: [DisplayedText]` (`stable.text`, `status`,
  `stable.firstSeenFrame`).
- `DictionaryProvider.lookup: DictionaryLookup?` (`segment(_:) -> [LookupToken]`, Sendable);
  `ReadingAidModel` and `StudySession` already segment with `Task.detached`.
- `WordBankStore.bank: WordBank` (`word(entryID:headword:)`, `isKnown`, `due(at:)`, `SavedWord.created`),
  `save(_:sentence:translation:source:mediaTime:image:)`, `isSaved(_:)`.
- `WordCardView(content:store:onSave:isSaved:)` + `WordCardContent` (used by `StudyPanel`).
- `AppModel.metrics: PipelineMetricsSnapshot` (refreshed every 250 ms): `ocrProcessedPerSecond`, `ocrLatency`,
  `translationLatency` (`LatencySummary.last/p50`); `settings.ocrRate.rawValue` is the OCR target.
- `RootView.showingReview` presents `ReviewView`.
- `VideoStageLayout` holds the compact portrait constants (`compactChromeGap`, `compactPanelMinHeight`, …).

## Scope For This Phase
### In
- Core: `VideoStageLayout.portraitDeckMinHeight` / `portraitDeckTabHeight` / `showsPortraitDeck(fillerHeight:)`;
  `DeckWords` (token → deck word filtering, de-duplication, word-bank state); `ReadingSessionStats` (lines/words
  this session, elapsed clock text, meter segments). Linux tests.
- App: `App/UI/PortraitDeck.swift` (deck view, three pages, tab strip), `App/UI/PortraitDeckModel.swift`
  (observable session + words state, owned by `RootView` so it survives layout switches).
- `CompactPortraitLayout.swift`: the non-study housing filler becomes the deck (hidden below the minimum height).
- `RootView.swift`: one `@State` property for the deck model (no other change).
### Out
- Regular (iPad) and compact landscape layouts; full screen; study mode (10.8.0 is in parallel on the study
  files — `StudySession`, `StudyPanel`, `StudyView`, core `Study/` selection code are not edited).
- `AppSettings` (Codable persistence untouched; the tab is `@SceneStorage`).
- Design docs and `phase_index.md` (synced by the integrating session).
- Persisting session statistics across launches.

## Recommended Implementation Direction
- The deck replaces only the filler `Spacer`: a `GeometryReader` takes the same flexible space, and the deck is
  shown when `VideoStageLayout.showsPortraitDeck(fillerHeight:)` says the space is at least 120 pt (tab strip +
  two log rows); otherwise the housing shows as before.
- Paging: `TabView(selection:)` with `.tabViewStyle(.page(indexDisplayMode: .never))`, driven by the custom tab
  strip; selection in `@SceneStorage("portraitDeck.tab")` (a `String` raw-value enum).
- WORDS segmentation runs in `PortraitDeckModel` on a detached task, debounced 250 ms, keyed on the on-screen
  Japanese texts (not on geometry updates), cancelled when superseded. The last non-empty word list stays up with
  a "LAST SEEN" tag while no text is on screen, so the list does not flicker between dialogue boxes.
- Engineering rule 1: the deck only reads `@Observable` state the UI already reads; no per-frame work. The session
  clock is a `TimelineView(.periodic(by: 1))` inside the SESSION page only; metrics come from the existing 4 Hz
  snapshot.
- Reduce Motion: no animated scroll or tab transitions; the cursor already respects it.

## Technical Plan
Core (`Packages/KoubutsuCore`):
- `Geometry/VideoStageLayout.swift`: `portraitDeckTabHeight = 44`, `portraitDeckMinHeight = 120`,
  `showsPortraitDeck(fillerHeight:) -> Bool`.
- `Study/DeckWords.swift` (new file; the 10.8.0 work edits `StudySelection.swift` only): `DeckWord`
  (id, surface, headword, reading, gloss, results, sourceIndex), `DeckWordState` (known / learning / new),
  `DeckWords.words(from:sourceIndex:)`, `DeckWords.words(texts:lookup:limit:)`, `DeckWords.isUseful(_:)`
  (skips tokens without results, particles/copula/auxiliaries/suffixes, and single-kana tokens),
  `DeckWords.state(of:in:)`.
- `Study/ReadingSessionStats.swift` (new): `ReadingSessionStats(started:)` with `linesRead(in:)`,
  `translatedLines(in:)`, `wordsSaved(in:)`, `static clock(_:)` ("HH:MM:SS"), `static meterSegments(value:full:segments:)`.
- Tests: `PortraitDeckTests.swift`.

App:
- `App/UI/PortraitDeckModel.swift`: `@MainActor @Observable final class PortraitDeckModel` — `started`,
  `words`, `wordsAreStale`, `seenWordIDs`, `update(texts:lookup:)`.
- `App/UI/PortraitDeck.swift`: `PortraitDeck` (strip + pages), `DeckTab`, `DeckLogPage`, `DeckWordsPage`,
  `DeckSessionPage`, `DeckMeter`.
- `App/UI/CompactPortraitLayout.swift`: filler → `portraitDeckFiller`.
- `App/UI/RootView.swift`: `@State var deck = PortraitDeckModel()`.

## Test Plan
- `swift test --package-path Packages/KoubutsuCore` on Linux (new `PortraitDeckTests`: deck threshold, word
  filtering on the fixture dictionary, de-duplication order, word-bank state, session counts, clock text, meter
  clamping).
- macOS CI build (App code cannot compile on Linux); iPhone portrait screenshot after merge.

## Key Decisions
- Deck model in `RootView` state, not in the deck view — session counters must survive study mode, full screen and
  rotation, which remove the deck from the hierarchy.
- `@SceneStorage` for the tab, not `AppSettings` — a view preference, no change to the Codable settings file.
- Words seen are counted while the deck is on screen (segmentation is not run when nothing shows it).
- New core files rather than edits to the study files the parallel 10.8.0 work touches.

## Expected Limitations At End Of Phase
- Not compiled until macOS CI; SwiftUI paging inside the chrome region is unverified on device.
- "Words seen" counts only while the deck is visible.

## What Comes Next
- Design-doc sync (architecture "Screen layout", ui_theme) and index append by the integrating session.
- iPhone portrait screenshots with the deck on each tab.

## Summary
The empty housing gap under the video in iPhone portrait becomes a three-page HUD deck — a live Japanese/English
transcript, the dictionary words currently on screen with save and word-card access, and a session/pipeline
readout — built from state the app already has, off the display path, with its geometry rule and pure logic in
KoubutsuCore.
