# Phase 9.1.0 Log — Design system

## Phase
- **Number:** 9.1.0
- **Name:** Tokens, fonts, textures, Koubutsu components and pixel art
- **Status:** Completed
- **Date completed:** 2026-09-26

## Phase Goal
See `phase_9.1.0_plan.md` (umbrella 9.0.0).

## Major Additions
- Fonts: VCR OSD Mono (`VCROSDMono`) and DotGothic16 (`DotGothic16-Regular`, OFL) registered via `UIAppFonts`.
- `App/Theme/Theme.swift`: `K` tokens (paper #ECEAE4, ink #0D0D0F, red #E3261F, grey, inkRaised, paperShade), font
  helpers, `snap`/`reveal` curves, `applyUIKitAppearance()`, `KSurface` environment.
- `App/Theme/Textures.swift`: grain tile, scanlines, `CornerTicks`, `BlockMarks`, `kTexture`, `kFrame`.
- `App/Theme/Components.swift`: `PixelIcon`, `KButtonStyle`, `KIconButtonStyle`, `KIconLabel`, `KToggleStyle`,
  `KSlider`, `KSegmented`, `KMenu`/`KMenuItem`, `KSectionHeader`, `KTag`, `KSheetHeader`, `kSheet`, `kPanel`,
  `KSearchField`.
- `Tools/pixel_art.py`: 31 template icons (`px.*`, 16×16), logo mark, wordmark, grain, app icon, launch logo, cover
  art; writes `App/Resources/Assets.xcassets` and `docs/art/`.
- `AppTests/ThemeTests.swift`: fonts registered, icons present at 16×16.

## Major Changes
- Asset catalog wired through the project generator (`ASSETCATALOG_COMPILER_APPICON_NAME`,
  `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`); generated launch screen replaced by a `UILaunchScreen` dict.
- Art (app icon, launch, cover) folded into 9.1.0 because the build references the app icon; roadmap renumbered
  to 9.1–9.3.

## Progress Made
- CI green on `6bd3301` (iOS, IPA).

## Key Decisions
- All art drawn in code as grids and scaled nearest-neighbour: original, reproducible, crisp.
- The supplied "Cyber Sigils" pack is not used (no licence, public repository).

## Current Limitations
- VCR OSD Mono has no kana/kanji; Japanese falls back to the system font or DotGothic16.

## Artifacts Produced
- `App/Theme/{Theme,Textures,Components}.swift`, `App/Resources/Fonts/*`, `App/Resources/Assets.xcassets`,
  `Tools/pixel_art.py`, `docs/art/*`, `docs/licences/DotGothic16-OFL.txt`, `AppTests/ThemeTests.swift`.

## What Comes Next
- 9.2.0.

## Summary
The Koubutsu component kit, fonts and original pixel art.
