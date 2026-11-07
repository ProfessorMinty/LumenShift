# Creative asset provenance

Copyright 2026 Northern Lights Labs. All Rights Reserved; see the root `ASSET-LICENSE.md`. Original technical source tools are MIT; the rendered artwork and recordings are reserved creative output.

The six mode icons, vignette and synthesized sounds were created 2026-11-06 using original geometry and audio synthesis written with Codex. No historical alpha files, Blizzard artwork, stock assets or film/game sounds were copied into those assets. Their editable source recipe is `tools/create_assets.py`.

On 2026-11-07, Arctic supplied and designated a new logo: a brushed-metal ring crossed by a teal/green aurora. `assets/branding/LumenShift-master.png` preserves that supplied 1254×1254 RGBA PNG byte-for-byte (SHA-256 `918d46801f4b9679d517ec130a40e083e046912a9ce4d2c24856792e7120e8b2`). Artist/generator and earlier creation history were not supplied; this asset is identified as owner-supplied, not falsely attributed to the geometry script. The owner has approved its use as LumenShift's logo. The project's selected creative-asset terms remain in ASSET-LICENSE.md; this provenance record does not assert an independently verified third-party license.

`tools/export_logo.ps1` performs only size/format exports through Windows System.Drawing: 256×256 runtime TGA and a 400×400 PNG preview. It preserves the source composition and transparency. `tools/create_assets.py` now preserves the approved logo and its provenance instead of overwriting them with the old placeholder. Runtime UI already shares `Media/logo.tga` across the launcher, minimap entry, Studio and setup header.

`manifest.json` records all 12 runtime files and hashes. Packaging uses committed exports, never regeneration. Output from different image/audio libraries may vary; the source master hash and committed export hashes identify the exact artwork being shipped.

| Files | Design / technical details |
|---|---|
| natural.tga | Sun, neutral baseline |
| nightVision.tga | Electronic goggles, green visibility mode |
| cinematic.tga | Clapperboard, warm cinematic mode |
| lantern.tga | Lantern, amber interior mode |
| clarity.tga | Eye, neutral readability mode |
| moonlight.tga | Crescent, cool blue mode |
| logo.tga | Owner-approved brushed-metal ring and teal/green aurora, exported from preserved master |
| vignette.tga | Original quadratic black alpha edge ramp |
| night-on-soft/normal.wav | Rising harmonic electronic cue, quieter and regular gain |
| night-off-soft/normal.wav | Falling harmonic electronic cue, quieter and regular gain |

Icons are 128×128, the runtime logo is 256×256, vignette is 64×64; all use uncompressed 32-bit BGRA TGA with alpha. WAV files are 0.32 seconds, mono, 16-bit PCM at 22,050 Hz with bounded peaks. `logo-400.png` previews the approved logo outside the runtime archive. `icon-review.png` is the historical 2026-11-06 placeholder contact sheet, including the superseded logo; it is not current branding or a game screenshot. The game supplies the font; no font files are distributed.

Native decoding, small-size legibility and sound balance remain acceptance checks. Development-only tools and the full-size source master are not copied into the addon ZIP. The logo design is approved by Arctic; public-distribution approval remains separate.
