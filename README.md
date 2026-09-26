# Koubutsu

<p align="center"><img src="docs/art/cover.png" width="420" alt="Koubutsu cover art"></p>

An iPad app that turns the iPad into a real-time translated display for a Nintendo Switch 2 running
Japanese games. Video (and audio) arrive over a USB-C UVC/UAC capture adapter; the app shows the game with
minimal latency, recognizes Japanese text with Apple Vision, translates it on device with Apple Translation,
and replaces the Japanese on screen with English, in place, as it appears.

Nothing is injected into the Switch or the game: everything works on the external video/audio stream.

## Status

| Area | State |
|---|---|
| Prerecorded test video source, shared low-latency display path | implemented, CI-tested |
| Frame sampling with latest-frame backpressure | implemented, tested |
| Vision Japanese OCR (text, confidence, boxes, latency) | implemented, CI fixture + benchmark tests |
| Text stabilization (typewriter-aware), translation cache, dialogue history | implemented, tested |
| Apple on-device translation (ja→en) with language download flow | implemented; needs a device with the model |
| Replace-in-place overlay (English fitted into each Japanese block's box, updates on every change) | implemented, default |
| Video mode (imported file: play/pause/seek/loop; same pipeline as capture) | implemented, CI-tested on real footage |
| UVC capture + hot-plug, UAC audio passthrough | implemented; unverified without capture hardware |
| Physical iPad / capture hardware measurements | procedure in `docs/device_testing.md` |
| Fixed video stage; full screen, English/Japanese toggle, hold-to-peek, recent lines, keyboard shortcuts | implemented, CI-built; gestures unverified on device |
| Study mode: freeze & select, offline JMdict/KANJIDIC2 lookup with conjugation, word card, word bank, FSRS review, Anki export, furigana overlay | implemented, CI-tested; gestures unverified on device |

## Screenshots

Study mode (Major 8, CI screenshots on 8139770, iPad simulator, synthetic clip): drag over the frozen dialogue to
list its words; tap 強 to get the word card; furigana over the game's own Japanese.

| Drag selection | Word card | Furigana |
|---|---|---|
| ![drag](docs/screenshots/study860_drag.jpg) | ![card](docs/screenshots/study860_card.jpg) | ![furigana](docs/screenshots/study860_furigana.jpg) |

Full screen and the fixed video stage (Phase 7.8.0, CI screenshots on 14d7a2b, iPad simulator, synthetic clip,
demo translator). The video keeps the same position and size with or without the controls.

| Full screen | Controls shown |
|---|---|
| ![full screen](docs/screenshots/qol780_fullscreen.jpg) | ![controls](docs/screenshots/qol780_overlay_controls.jpg) |

Replace-in-place on real footage (Persona 3 Reload, Japanese; CI footage run 10 on commit ecd62ee, Phase 7.6.1,
iPad simulator). The simulator has no translation model, so the English is a labelled `[EN] …` placeholder of
realistic length: these frames check where and how the English replaces the Japanese, not translation
quality. The footage itself is not in the repository.

| Dialogue | Classroom (board, dialogue) | Dialogue, two lines | Dialogue, split lines |
|---|---|---|---|
| ![12s](docs/screenshots/p3r761_replace_12s.jpg) | ![106s](docs/screenshots/p3r761_replace_106s.jpg) | ![274s](docs/screenshots/p3r761_replace_274s.jpg) | ![314s](docs/screenshots/p3r761_replace_314s.jpg) |

Synthetic clip:

Latest (CI screenshots run 1 on commit ce7e5d0): translation overlay over each scene of the synthetic clip.

| Dialogue box | Katakana menu | Title menu | Panel + OCR boxes + debug |
|---|---|---|---|
| ![dialogue](docs/screenshots/ci20_overlay_dialogue.jpg) | ![menu](docs/screenshots/ci20_overlay_menu.jpg) | ![title](docs/screenshots/ci20_overlay_title.jpg) | ![panel](docs/screenshots/ci20_panel_dialogue_boxes_debug.jpg) |

### Earlier captures

iPad Pro 13" simulator, CI run 13, bundled synthetic clip. The simulator has no Japanese→English model, so these
use the labelled demo translator (`--demo-translator`, shown as "Demo table (synthetic clip)" in the debug
panel); OCR, stabilization, caching, layout and all metrics are the real pipeline. Simulator OCR is CPU-only
(~1.4–1.8 s per 1080p frame here); device numbers come from `docs/device_testing.md`.

| Dialogue: OCR box, JP/EN panel, debug metrics | Title screen | Overlay mode (bug: stale menu overlays) |
|---|---|---|
| ![panel](docs/screenshots/ci13_panel_debug_dialogue.jpg) | ![title](docs/screenshots/ci13_panel_debug_title.jpg) | ![overlay bug](docs/screenshots/ci13_overlay_stale_menu_bug.jpg) |

CI run 15, after the delivery-path crash fix (Phase 1.4.1): the app stays up for the whole 270 s session.

| Dialogue with OCR boxes + debug | Title with OCR boxes | Overlay at a scene change (OCR lag on the simulator) |
|---|---|---|
| ![dialogue](docs/screenshots/ci15_panel_dialogue_boxes_debug.jpg) | ![title](docs/screenshots/ci15_panel_title_boxes.jpg) | ![lag](docs/screenshots/ci15_overlay_scene_change_lag.jpg) |

## Video mode

Import a gameplay video (source menu → Import, or Files app → *On My iPad → Koubutsu*) and it runs
through exactly the same pipeline as a capture device: Japanese is replaced by English as it appears.
The transport bar adds play/pause, ±10 s, a scrubber and looping. A paused frame keeps being read, so a
line can be held on screen. Videos stay on the iPad; nothing is bundled or uploaded.

## Requirements

- Xcode 26.x, iPadOS 26.0+ on a USB-C iPad.
- For capture: a UVC/UAC capture device (e.g. CABLETIME CC19L or HDMI capture card + Switch dock/adapter).

## Install on an iPad

See [docs/install.md](docs/install.md): CI builds `Koubutsu.ipa`; sign and install it from Linux
(AltServer-Linux with an Apple ID, or zsign + ideviceinstaller with a developer account).

## Build & run

Open `Koubutsu.xcodeproj`, select an iPad (simulator or device), Run. The app starts a bundled synthetic
Japanese clip. Import your own gameplay footage via the source menu or the Files app (*On My iPad → Koubutsu*).

The project file is generated: after changing targets/settings edit `Tools/gen_xcodeproj.py` and run
`python3 Tools/gen_xcodeproj.py`. New Swift files need no project changes (synchronized folders).

## Tests

- Core logic (Linux or macOS): `swift test --package-path Packages/KoubutsuCore`
- App (macOS): `Tools/ci_simulator_test.sh test`
- CI: `.github/workflows/core-linux.yml`, `.github/workflows/ios.yml` (also produces an SDK report artifact)

## Layout

- `App/` — iPad app (UI, adapters for AVFoundation/Vision/Translation)
- `Packages/KoubutsuCore/` — platform-independent pipeline logic
- `Tools/` — project generator, test-clip generator, CI scripts
- `docs/` — device test procedures
- `development/` — phase plans/logs and living design docs (`development/design/`)
