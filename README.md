# Koubutsu

An iPad app that turns the iPad into a real-time translated display for a Nintendo Switch 2 running
Japanese games. Video (and audio) arrive over a USB-C UVC/UAC capture adapter; the app shows the game with
minimal latency, recognizes Japanese text with Apple Vision, translates it on device with Apple Translation,
and shows English in a panel or over the game.

Nothing is injected into the Switch or the game: everything works on the external video/audio stream.

## Status

| Area | State |
|---|---|
| Prerecorded test video source, shared low-latency display path | implemented, CI-tested |
| Frame sampling with latest-frame backpressure | implemented, tested |
| Vision Japanese OCR (text, confidence, boxes, latency) | implemented, CI fixture + benchmark tests |
| Text stabilization (typewriter-aware), translation cache, dialogue history | implemented, tested |
| Apple on-device translation (ja→en) with language download flow | implemented; needs a device with the model |
| Spatial overlay (OCR boxes, translated text over Japanese) | implemented |
| UVC capture + hot-plug, UAC audio passthrough | implemented; unverified without capture hardware |
| Physical iPad / capture hardware measurements | procedure in `docs/device_testing.md` |

## Requirements

- Xcode 26.x, iPadOS 26.0+ on a USB-C iPad.
- For capture: a UVC/UAC capture device (e.g. CABLETIME CC19L or HDMI capture card + Switch dock/adapter).

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
