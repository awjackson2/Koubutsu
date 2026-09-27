# UI theme — the Koubutsu look

Last synced: Phase 9.4.1 (2026-09-26)

Heisei-era (late 90s–2005) VCR on-screen display meets surveillance HUD: paper white, ink black, signal red,
1-bit dithered imagery, detection boxes with corner ticks, monospaced OSD lettering.

## Tokens (`App/Theme/Theme.swift`)

| Token | Value | Use |
|---|---|---|
| `K.paper` | #ECEAE4 | sheets, cards, settings (paper side) |
| `K.ink` | #0D0D0F | bars and panels around the video (ink side), replacement boxes |
| `K.red` | #E3261F | accents, selection, active state, primary buttons, section markers |
| `K.grey` | #8A8A8A | idle indicators |
| `K.osd(size)` | VCR OSD Mono | all Latin UI text; `osdFixed` for text fitted into boxes |
| `K.dot(size)` | DotGothic16 | pixel Japanese: furigana labels, decoration (not dictionary content) |
| `K.snap`, `K.reveal` | 0.18 s / 0.24 s | state changes, reveals |

Japanese content (headwords, sentences, readings in cards) uses the system font for kanji detail.
`KSurface` (`.ink` / `.paper`) in the environment picks component colours.

## Components (`App/Theme/Components.swift`, `Textures.swift`)

`PixelIcon` (16×16 template art at integer scales), `KButtonStyle` (primary/secondary/ghost, hard offset shadow
the button presses into), `KIconButtonStyle`, `KToggleStyle` (sliding block + ON/OFF), `KSlider` (tick ruler,
square thumb), `KSegmented`, `KMenu` (ink popover list replacing `Menu`), `KSectionHeader` ("■ ■ ■ TITLE —— 01"),
`KTag`, `KSheetHeader` (replaces navigation bars), `kPanel`, `kSheet` (square, paper), `KSearchField`,
`GrainOverlay`, `Scanlines`, `CornerTicks`, `BlockMarks`. UIKit appearance covers remaining system bars/alerts.

## Monitor housing (`App/Theme/MonitorFrame.swift`)
Outside full screen the video sits in a surveillance-monitor console: header strip (CH-01 tag, source name,
blinking REC/STBY dot and 24-hour clock), tick rails (red every 1/4 of the stage), recessed bezel, red corner
ticks, maker's plate below. The stage comes from `VideoStageLayout.framed` with `windowedInsets(safeTop:)`
(top = max(safe top, 24) + 38, sides 18, bottom 16), so it depends only on the window. Full screen uses the
edge-to-edge stage; the switch animates with `K.reveal`. The housing fills the window; chrome overlays it.

## Art (`Tools/pixel_art.py`)

Drawn on pixel grids, scaled nearest-neighbour: 31 icons (`px.*`), `LogoMark` (dithered eye, red pixel pupil,
detection brackets), `Wordmark`, `AppIcon` (64×64 grid → 1024), `LaunchLogo` on ink, `Grain`, and
`docs/art/cover.png`. Re-run the script after editing; outputs are committed.

## Motion (`App/Theme/Animations.swift`)

Boot sequence (mosaic → logo, typed wordmark, scanline wipe), freeze flash + red scan sweep while reading,
selection brackets snapping in, blinking block cursors, pulsing due badge, press offsets. Reduce Motion disables
sweeps/pulses and shortens the boot. No animation on live replacement boxes (would distract while playing).

## Licences

VCR OSD Mono — Riciery Leal (dafont "100% free"). DotGothic16 — SIL OFL 1.1 (`docs/licences/DotGothic16-OFL.txt`).
Pixel art — original. The "Cyber Sigils" pack offered as reference was not used (no licence file; public repo).
