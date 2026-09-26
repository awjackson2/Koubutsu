# Phase Index

Chronological (log-written) order. New entries append at the bottom.

Line format:
`- **Phase X.Y.Z** (YYYY-MM-DD) — [plan](phase_X.Y.Z_plan.md) · [log](phase_X.Y.Z_log.md) — One-sentence summary.`

## Timeline

- **Phase 1.0.0** (2026-09-26) — [plan](phase_1.0.0_plan.md) — Roadmap for Major 1: from a prerecorded Japanese video to on-screen OCR results.
- **Phase 1.1.0** (2026-09-26) — [plan](phase_1.1.0_plan.md) · [log](phase_1.1.0_log.md) — The iPad app project, a Linux-testable core library, and automatic builds on Mac and Linux now exist (CI: 2/2 workflows green).
- **Phase 1.2.0** (2026-09-26) — [plan](phase_1.2.0_plan.md) · [log](phase_1.2.0_log.md) — The shared building blocks for timing, frame sampling, overload protection, measurements and OCR results now exist and are tested (27 passed).
- **Phase 1.1.1** (2026-09-26) — [plan](phase_1.1.1_plan.md) · [log](phase_1.1.1_log.md) — Checked which Apple features actually exist in the current SDK and set the app to require iPadOS 26.
- **Phase 1.3.0** (2026-09-26) — [plan](phase_1.3.0_plan.md) · [log](phase_1.3.0_log.md) — The app plays a looping Japanese test video through the same display path a capture card will use.
- **Phase 1.4.0** (2026-09-26) — [plan](phase_1.4.0_plan.md) · [log](phase_1.4.0_log.md) — Video frames are handed to processing at a set rate without ever piling up, with a debug panel showing frame rates.
- **Phase 1.5.0** (2026-09-26) — [plan](phase_1.5.0_plan.md) · [log](phase_1.5.0_log.md) — Apple's Japanese text recognition runs on the video and its results appear on screen.
- **Phase 1.5.1** (2026-09-26) — [plan](phase_1.5.1_plan.md) · [log](phase_1.5.1_log.md) — Automated tests prove the recognized Japanese text and its position on real video frames (CI run 13: 25 passed).
- **Phase 2.1.0** (2026-09-26) — [plan](phase_2.1.0_plan.md) · [log](phase_2.1.0_log.md) — One consistent way to decide whether two pieces of Japanese text are the same.
- **Phase 2.1.1** (2026-09-26) — [plan](phase_2.1.1_plan.md) · [log](phase_2.1.1_log.md) — Lines of the same dialogue box are treated as one sentence.
- **Phase 2.2.0** (2026-09-26) — [plan](phase_2.2.0_plan.md) · [log](phase_2.2.0_log.md) — Text is only acted on once it stops changing, so letter-by-letter dialogue is translated once.
- **Phase 2.3.0** (2026-09-26) — [plan](phase_2.3.0_plan.md) · [log](phase_2.3.0_log.md) — Translation became a swappable, cached service that never translates the same text twice.
- **Phase 2.4.0** (2026-09-26) — [plan](phase_2.4.0_plan.md) · [log](phase_2.4.0_log.md) — Apple's on-device translator is connected, including the language download prompt.
- **Phase 2.5.0** (2026-09-26) — [plan](phase_2.5.0_plan.md) · [log](phase_2.5.0_log.md) — Japanese and its English translation appear under the video with timing and cache stats.
- **Phase 2.6.0** (2026-09-26) — [plan](phase_2.6.0_plan.md) · [log](phase_2.6.0_log.md) — A settings screen that remembers choices.
- **Phase 2.7.0** (2026-09-26) — [plan](phase_2.7.0_plan.md) · [log](phase_2.7.0_log.md) — A running log of dialogue and translations is kept and passed along as context.
