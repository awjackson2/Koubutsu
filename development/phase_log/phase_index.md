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
- **Phase 2.2.1** (2026-09-26) — [log](phase_2.2.1_log.md) — When on-screen Japanese changes, its old English disappears immediately.
- **Phase 4.1.1** (2026-09-26) — [log](phase_4.1.1_log.md) — Fixed a resource leak in CPU measurement; CI now collects crash reports.
- **Phase 1.4.1** (2026-09-26) — [log](phase_1.4.1_log.md) — Fixed a crash that closed the app after a minute or two of playback.
- **Phase 2.1.2** (2026-09-26) — [log](phase_2.1.2_log.md) — Small text split into pieces by the recognizer is put back together before translation.
- **Phase 3.0.0** (2026-09-26) — [plan](phase_3.0.0_plan.md) — Roadmap for putting English over the game where the Japanese is.
- **Phase 3.1.0** (2026-09-26) — [plan](phase_3.1.0_plan.md) · [log](phase_3.1.0_log.md) — One tested place converts positions between the video and the screen.
- **Phase 3.2.0** (2026-09-26) — [plan](phase_3.2.0_plan.md) · [log](phase_3.2.0_log.md) — Recognized text can be outlined on the video to check positions.
- **Phase 3.3.0** (2026-09-26) — [plan](phase_3.3.0_plan.md) · [log](phase_3.3.0_log.md) — English is drawn over the Japanese it translates.
- **Phase 4.0.0** (2026-09-26) — [plan](phase_4.0.0_plan.md) — Roadmap for performance, benchmark and device testing.
- **Phase 4.1.0** (2026-09-26) — [plan](phase_4.1.0_plan.md) · [log](phase_4.1.0_log.md) — The debug panel shows CPU, memory, heat and dropped frames.
- **Phase 4.2.0** (2026-09-26) — [plan](phase_4.2.0_plan.md) · [log](phase_4.2.0_log.md) — An automatic benchmark scores text recognition on the test clip in CI.
- **Phase 4.3.0** (2026-09-26) — [plan](phase_4.3.0_plan.md) · [log](phase_4.3.0_log.md) — Step-by-step instructions and an in-app benchmark for testing on a real iPad (awaiting hardware).
- **Phase 5.0.0** (2026-09-26) — [plan](phase_5.0.0_plan.md) — Roadmap for using a real USB capture device.
- **Phase 5.1.0** (2026-09-26) — [plan](phase_5.1.0_plan.md) · [log](phase_5.1.0_log.md) — The app picks the best 1080p60 video mode offered by any capture device.
- **Phase 5.2.0** (2026-09-26) — [plan](phase_5.2.0_plan.md) · [log](phase_5.2.0_log.md) — Live video from a USB capture device feeds the same pipeline (untested on hardware).
- **Phase 5.3.0** (2026-09-26) — [plan](phase_5.3.0_plan.md) · [log](phase_5.3.0_log.md) — Plugging in a capture device switches to it automatically (untested on hardware).
- **Phase 6.0.0** (2026-09-26) — [plan](phase_6.0.0_plan.md) — Roadmap for capture audio.
- **Phase 6.1.0** (2026-09-26) — [plan](phase_6.1.0_plan.md) · [log](phase_6.1.0_log.md) — Game audio from the capture device plays through the iPad (untested on hardware).
- **Phase 4.2.1** (2026-09-26) — [log](phase_4.2.1_log.md) — Benchmark results are printed on every CI run (first result: 92% exact, 95% characters).
- **Phase 4.2.2** (2026-09-26) — [log](phase_4.2.2_log.md) — Benchmark scores what the app actually translates: 99% of characters correct.
- **Phase 7.0.0** (2026-09-26) — [plan](phase_7.0.0_plan.md) — Roadmap for Video mode (rewritten in 7.5.0).
- **Phase 7.1.0** (2026-09-26) — [plan](phase_7.1.0_plan.md) · [log](phase_7.1.0_log.md) — File sources can pause, seek, skip and loop.
- **Phase 7.2.0** (2026-09-26) — [plan](phase_7.2.0_plan.md) · [log](phase_7.2.0_log.md) — Video mode transport bar and import.
- **Phase 7.3.0** (2026-09-26) — [plan](phase_7.3.0_plan.md) · [log](phase_7.3.0_log.md) — Transcript export (removed in 7.5.0).
- **Phase 7.3.1** (2026-09-26) — [log](phase_7.3.1_log.md) — Whole-video analysis and CI footage workflow (analysis removed in 7.5.0).
- **Phase 7.4.0** (2026-09-26) — [plan](phase_7.4.0_plan.md) · [log](phase_7.4.0_log.md) — Speaker labels and HUD suppression (reverted in 7.5.0).
- **Phase 7.4.1** (2026-09-26) — [log](phase_7.4.1_log.md) — A paused video keeps being read; footage screenshots in CI.
- **Phase 7.4.2** (2026-09-26) — [log](phase_7.4.2_log.md) — HUD rule refinements (reverted in 7.5.0).
- **Phase 7.5.0** (2026-09-26) — [plan](phase_7.5.0_plan.md) · [log](phase_7.5.0_log.md) — Video mode is game mode on a file; analysis layers removed.
- **Phase 7.6.0** (2026-09-26) — [plan](phase_7.6.0_plan.md) · [log](phase_7.6.0_log.md) — Japanese is replaced by English in place, instantly.
- **Phase 7.6.1** (2026-09-26) — [log](phase_7.6.1_log.md) — Replacement boxes are opaque, keep words intact and follow their text.
- **Phase 7.7.0** (2026-09-26) — [plan](phase_7.7.0_plan.md) · [log](phase_7.7.0_log.md) — CI builds an iPad IPA to sign and sideload from Linux.
- **Phase 7.6.2** (2026-09-26) — [plan](phase_7.6.2_plan.md) · [log](phase_7.6.2_log.md) — Only Japanese is replaced, list items stay separate, shown English changes only on confirmed text.
