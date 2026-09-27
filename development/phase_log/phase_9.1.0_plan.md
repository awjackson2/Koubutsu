# Phase 9.1.0 Plan — Design system

## Phase
- **Number:** 9.1.0
- **Name:** Tokens, fonts, textures, Koubutsu components and pixel art
- **Status:** Planned
- **Date drafted:** 2026-09-26

## Purpose
The building blocks every screen will use (umbrella 9.0.0).

## Immediate Goal
1. Fonts bundled and registered (`UIAppFonts`): VCR OSD Mono (UI Latin), DotGothic16 (decorative Japanese, OFL).
2. `K` tokens: paper/ink/red/grey, OSD and pixel-Japanese font helpers, animation curves; `KSurface` (ink/paper).
3. Textures: grain tile, scanlines, HUD corner ticks, block marks.
4. Components: `PixelIcon`, `KButtonStyle` (primary/secondary/ghost, hard shadow press), `KIconButtonStyle`,
   `KToggleStyle`, `KSlider`, `KSegmented`, `KMenu` (replaces `Menu`), `KSectionHeader`, `KTag`, `KSheetHeader`,
   `kPanel`, `kSheet`, `KSearchField`.
5. UIKit appearance for remaining system pieces (navigation bars, alerts, text fields, lists).
6. `Tools/pixel_art.py`: 31 pixel icons (16×16 templates), logo mark (32×32 dithered eye with red pixel
   pupil in detection brackets), wordmark, app icon (64×64 grid → 1024), launch screen (ink + logo),
   cover art (1080×1352 poster) — asset catalog + docs/art.

## Confirmed Starting Point
`9c4d3d9` + umbrella 9.0.0.

## Scope For This Phase
### In
- `App/Theme/*`, `App/Resources/Fonts/*`, `App/Resources/Assets.xcassets` (icons, grain, accent), Info.plist,
  generator settings (asset catalog app icon/accent names).
### Out
- Applying components to screens (9.2.0).

## Test Plan
App test: fonts registered, assets present at 16×16; CI build.

## Summary
The Koubutsu component kit.
