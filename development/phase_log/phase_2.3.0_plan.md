# Phase 2.3.0 Plan — Translation Contracts, Cache, Coordinator

## Phase
- **Number:** 2.3.0
- **Name:** TranslationService abstraction, LRU cache, coordinator
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Milestones 6–7 groundwork: an abstract, context-capable translation interface and a cache so repeated text is
never retranslated — independent of Apple's framework and testable on Linux.

## Immediate Goal
1. `TranslationService` protocol (`providerName`, `sendsDataOffDevice`, `usesContext`, `availability`, `translate(TranslationRequest)`).
2. `TranslationRequest` with `TranslationContext` (previous dialogue, speaker, game title, screen region, audio transcript).
3. `TranslationCache` — LRU keyed by normalized text + languages + quality; hit/miss/eviction stats.
4. `TranslationCoordinator` actor — cache → service, in-flight de-duplication, metrics (hits, misses, latency, capture→translation, failures).

## Confirmed Starting Point
- 2.2.0 `StableText`; `PipelineMetrics` translation counters exist.

## Scope For This Phase
### In
- Core types + tests with a fake translator.
### Out
- Apple implementation (2.4.0).

## Recommended Implementation Direction
Failures are not cached. The coordinator returns `TranslatedText` carrying the stable text, provider, cache flag and timings.

## Technical Plan
`Sources/KoubutsuCore/Translation/{TranslationService,TranslationCache,TranslationCoordinator}.swift`.

## Test Plan
`TranslationTests` (LRU, key normalization, cache hit path, concurrent dedup, failures, context passthrough).

## Key Decisions
- `sendsDataOffDevice` on the protocol makes privacy consent enforceable for any future cloud backend.

## Expected Limitations At End Of Phase
- Cache is in-memory only.

## What Comes Next
- 2.4.0 AppleTranslationService.

## Summary
Translation becomes a swappable, cached, measured service with room for context.
