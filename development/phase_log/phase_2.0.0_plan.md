# Phase 2.0.0 Plan — Umbrella: Text State, Translation, Cache

## Phase
- **Number:** 2.0.0
- **Name:** Umbrella roadmap for Major 2 (stabilized Japanese text → English)
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Turn raw per-frame OCR into stable, deduplicated Japanese text blocks, translate them to English through an
abstract translation service (Apple Translation first), cache translations, and show JP/EN in a panel with
latency and cache diagnostics. Milestones 5–7 of the product plan, plus the settings model surfaced in UI.

## Immediate Goal
```
OCRResult → line grouping → block tracking + stabilization (typewriter-aware) → stable text events
         → translation coordinator (cache, in-flight dedup, context) → TranslationService → JP/EN panel
```

## Confirmed Starting Point
- Major 1 complete: OCR results (`OCRResult`, per-line observations with boxes/confidence/timing) arrive on the main actor at ~5 FPS.
- `PipelineMetrics` already has translation latency, cache hit/miss, duplicate-text counters.
- Translation API facts in `development/design/platform_apis.md`.

## Scope For This Phase (Major 2)
### In
- Japanese text normalization and similarity; line → block grouping.
- Block tracker/stabilizer with typewriter handling and change events.
- `TranslationService` abstraction with a context-capable request; LRU translation cache; coordinator with in-flight dedup and metrics.
- `AppleTranslationService` (installed-language session, availability check, download prompt via SwiftUI).
- Translation panel (JP/EN per stable block, latencies, cache status).
- Settings UI + persistence for the settings model; in-memory dialogue history.
### Out
- Spatial overlay (Major 3), benchmark (Major 4), cloud translators (future, explicit opt-in only).

## Roadmap checklist
```
- [x] 2.1.0 — Text normalization + similarity (NFKC-style width folding, punctuation/ellipsis folding,
              whitespace, Levenshtein ratio, prefix relation)            deps: 1.2.0  risk: low
- [x] 2.1.1 — Line → block grouping (adjacent lines of one dialogue box become one block)
                                                                         deps: 2.1.0  risk: med
- [x] 2.2.0 — Block tracker + stabilizer (IoU/similarity matching across OCR results, stability
              window, typewriter growth suppression, appeared/changed/disappeared events,
              duplicate counting)                                        deps: 2.1.1  risk: HIGH
- [x] 2.3.0 — Translation contracts: TranslationService protocol, TranslationRequest (text + context),
              TranslationCache (LRU), TranslationCoordinator (cache, in-flight dedup, metrics)
                                                                         deps: 2.2.0  risk: low
- [x] 2.4.0 — AppleTranslationService + language availability/download UI  deps: 2.3.0  risk: HIGH
- [x] 2.5.0 — Translation panel wired end to end                         deps: 2.4.0  risk: med
- [x] 2.6.0 — Settings UI + persistence                                   deps: 2.5.0  risk: low
- [x] 2.7.0 — Dialogue history (in-memory log, panel)                     deps: 2.5.0  risk: low
  (2.8–2.9 reserved: context-aware translation, alternative translators)
```

## Technical Plan
Pure logic (2.1–2.3, history model) in `KoubutsuCore` with Linux tests; Apple adapters (2.4) and UI (2.5–2.7) in the app.

## Test Plan
Core: `swift test`. App: CI simulator tests with a fake translator (Translation models are unavailable in the simulator).

## Key Decisions
- Translation input is a `TranslationRequest` carrying optional context (previous dialogue, block id, timing), not a bare `String`.
- Stabilization before translation: a block is translated only once its text has been unchanged for a stability window, so typewriter reveals translate once.

## Expected Limitations At End Of Phase
- Real translation quality/latency is unverified until run on a device with the ja→en model installed.

## What Comes Next
- Major 3: coordinate mapping and spatial overlay.

## Summary
Stable, deduplicated Japanese text blocks translated to English through an abstract, cached translation service, visible in a JP/EN panel.
