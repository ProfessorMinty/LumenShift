# Original creative assets

Copyright 2026 Northern Lights Labs. All Rights Reserved; see the root `ASSET-LICENSE.md`. Original technical source tools are MIT; the rendered artwork and recordings are reserved creative output.

Created 2026-11-06 for LumenShift using original geometry and audio synthesis written with Codex. No historical alpha files, Blizzard artwork, stock assets, film/game sounds or third-party media were copied. `tools/create_assets.py` is the editable source recipe. `manifest.json` records the 12 runtime files and their SHA-256 hashes. Regeneration uses the Python standard library; generated audio can vary at rounding boundaries on other math-library implementations, so release builds consume committed assets, never regenerate them implicitly.

| Files | Design / technical details |
|---|---|
| natural.tga | Sun, neutral baseline |
| nightVision.tga | Electronic goggles, green visibility mode |
| cinematic.tga | Clapperboard, warm cinematic mode |
| lantern.tga | Lantern, amber interior mode |
| clarity.tga | Eye, neutral readability mode |
| moonlight.tga | Crescent, cool blue mode |
| logo.tga | Original crescent, aurora sweep and star |
| vignette.tga | Original quadratic black alpha edge ramp |
| night-on-soft/normal.wav | Rising harmonic electronic cue, quieter and regular gain |
| night-off-soft/normal.wav | Falling harmonic electronic cue, quieter and regular gain |

Icons are 128×128, the runtime logo is 256×256, vignette is 64×64; all use uncompressed 32-bit BGRA TGA with alpha. WAV files are 0.32 seconds, mono, 16-bit PCM at 22,050 Hz with bounded peaks. `logo-400.png` is an original proposed distribution avatar, outside the runtime archive. `icon-review.png` is an artwork contact sheet, not a game screenshot. The game supplies the font; no font files are distributed.

Native decoding, visual appearance and sound balance remain acceptance checks. No third-party components are shipped in this build. Development-only Lupa is not copied into the addon or ZIP. Final branding and public-distribution approval remain with Northern Lights Labs.
