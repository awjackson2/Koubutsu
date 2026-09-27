# Phase 10.7.1 Log — PortraitDeck compile fix

## Phase
- **Number:** 10.7.1
- **Name:** PortraitDeck compile fix
- **Status:** Completed
- **Date completed:** 2026-09-27

## Phase Goal
🔧 Fix (Patch on 10.7.0): CI on 247744b failed to compile `App/UI/PortraitDeck.swift:395` ("failed to produce
diagnostic for expression"). `let entry = sentence.flatMap { entry(for: $0) }` referred to the local `entry` inside
its own initializer instead of the method `entry(for:)`.

## Major Changes
- The helper is `historyEntry(for:)`; the local is `line`.

## Current Limitations
- 10.7.0 and 10.8.0 compile together for the first time in the next CI run.

## Artifacts Produced
- `App/UI/PortraitDeck.swift`.

## Summary
The info deck's save path compiles.
