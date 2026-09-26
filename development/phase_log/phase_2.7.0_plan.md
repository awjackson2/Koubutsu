# Phase 2.7.0 Plan — Dialogue history

## Phase
- **Number:** 2.7.0
- **Name:** Dialogue history
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
Keep a chronological log of stable dialogue with translations (§23) and feed recent lines as translation context (§24).

## Immediate Goal
1. Core `DialogueHistory` (bounded, repeat-merging, translation attach, `context(before:limit:)`).
2. `TranslationController` records history and passes previous dialogue in `TranslationContext`.

## Confirmed Starting Point
2.5.0 controller.

## Scope For This Phase
### In
- Core model + tests
- context passthrough
### Out
- History UI beyond debug (future learning-mode work)

## Recommended Implementation Direction
History stores original Japanese, geometry and timing so learning-mode features can build on it without re-running OCR.

## Technical Plan
`Sources/KoubutsuCore/Translation/DialogueHistory.swift`, `TranslationController`.

## Test Plan
`DialogueHistoryTests`; controller test asserts history contents.

## Key Decisions
- Apple translator ignores context (`usesContext == false`); the request carries it anyway.

## Expected Limitations At End Of Phase
- In memory only.

## What Comes Next
- Major 3 overlay.

## Summary
A dialogue log exists and flows into translation requests as context.
