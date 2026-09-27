# Phase 8.3.1 Log — Lookup engine fix

## Phase
- **Number:** 8.3.1
- **Name:** Prefer specific de-inflection rules
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
See `phase_8.3.0_plan.md` (umbrella 8.0.0).

## Major Additions
- `Deinflection.specificity` / `LookupResult.specificity`: matched suffix characters.

## Major Changes
- 🔧 Fix (Patch on 8.3.0): 行った resolved to 行う (った → う) instead of 行く; at equal step count the more specific rule wins. Found by the app test on the bundled dictionary.

## Progress Made
- Core 136 tests; CI green on a411d91 (iOS build + all app tests incl. `lookupOnTheBundledDictionary`).

## Key Decisions
- None

## Current Limitations
- None

## Artifacts Produced
- None

## What Comes Next
- Next roadmap item (umbrella 8.0.0).

## Summary
Prefer specific de-inflection rules.
