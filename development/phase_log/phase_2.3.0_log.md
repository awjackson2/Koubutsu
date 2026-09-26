# Phase 2.3.0 Log — TranslationService abstraction, LRU cache, coordinator

## Phase
- **Number:** 2.3.0
- **Name:** TranslationService abstraction, LRU cache, coordinator
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
Abstract, context-capable translation with caching, in-flight dedup and metrics.

## Major Additions
- `TranslationService`, `TranslationRequest`, `TranslationContext`, `TranslationAvailability`, `TranslationError`
- `TranslationCache` (LRU)
- `TranslationCoordinator` actor

## Major Changes
- None

## Progress Made
- `TranslationTests` (6) pass.

## Key Decisions
- `sendsDataOffDevice` on the protocol for future consent.

## Current Limitations
- Cache in memory only.

## Artifacts Produced
- Packages/KoubutsuCore/Sources/KoubutsuCore/Translation/*

## What Comes Next
- 2.4.0.

## Summary
Translation is swappable, cached and measured.
