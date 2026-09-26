# Phase 2.1.0 Log — Japanese text normalization + similarity

## Phase
- **Number:** 2.1.0
- **Name:** Japanese text normalization + similarity
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
One canonical definition of Japanese text equality/similarity for stabilization, caching and benchmarking.

## Major Additions
- `TextNormalizer.display/key/editDistance/similarity/isGrowth/characterAccuracy`.

## Major Changes
- None

## Progress Made
- `TextNormalizerTests` pass (Linux + CI).

## Key Decisions
- NFKC width folding; decoration glyphs removed only from keys.

## Current Limitations
- No reading normalization (future learning mode).

## Artifacts Produced
- Packages/KoubutsuCore/Sources/KoubutsuCore/Text/TextNormalizer.swift

## What Comes Next
- 2.1.1.

## Summary
Text equality is defined once.
