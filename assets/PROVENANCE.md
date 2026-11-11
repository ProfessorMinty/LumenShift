# Creative asset provenance

Beta.22 adds six original filter illustrations, `Media/look-*.tga`. Each depicts the same mountain lake and observatory in a different palette. The editable geometry and palettes are in [create_look_swatches.py](../tools/create_look_swatches.py). The 128×64 uncompressed 32-bit TGA exports use Pillow 13.0.0 at build time. Their hashes are recorded in the asset manifest. The rendered illustrations use the Northern Lights Labs creative asset license.

Copyright 2026 Northern Lights Labs. All Rights Reserved; see the root `ASSET-LICENSE.md`. Original technical source tools are MIT; the rendered artwork and recordings are reserved creative output.

The six mode icons, vignette and synthesized sounds were created 2026-11-06 using original geometry and audio synthesis written with Codex. No historical alpha files, Blizzard artwork, stock assets or film/game sounds were copied into those assets. Their editable source recipe is `tools/create_assets.py`.

On 2026-11-07, Arctic supplied and designated a new logo: a brushed-metal ring crossed by a teal/green aurora. `assets/branding/LumenShift-master.png` preserves that supplied 1254×1254 RGBA PNG byte-for-byte (SHA-256 `918d46801f4b9679d517ec130a40e083e046912a9ce4d2c24856792e7120e8b2`). Artist/generator and earlier creation history were not supplied; this asset is identified as owner-supplied, not falsely attributed to the geometry script. The owner has approved its use as LumenShift's logo. The project's selected creative-asset terms remain in ASSET-LICENSE.md; this provenance record does not assert an independently verified third-party license.

`tools/export_logo.ps1` performs only size/format exports through Windows System.Drawing: 256×256 runtime TGA and a 400×400 PNG preview. It preserves the source composition and transparency. `tools/create_assets.py` now preserves the approved logo and its provenance instead of overwriting them with the old placeholder. Runtime UI already shares `Media/logo.tga` across the launcher, minimap entry, Studio and setup header.

`manifest.json` records every runtime asset and hash, including the later theme additions listed below. Packaging uses committed exports, never regeneration. Output from different image/audio libraries may vary; the source master hash and committed export hashes identify the exact artwork being shipped.

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

## Supplied theme artwork — dev.9

On 2026-11-07 the owner supplied Core Essential UI Icons, Lumen Loops, Mesh Gradients and separate Steel/Midnight images for the interface. Fractal Haze was named but absent from the supplied directory. `theme-sources.json` records the 16 selected third-party inputs, creators, licenses, changes and source hashes; `THIRD-PARTY-NOTICES.md` contains the attribution and source links. These files are exceptions to the original-asset rights notice above. The source packs, videos, editable Figma files and full-resolution downloaded masters are not included in Git or the addon.

`tools/export_theme.py` exports 12 Core Line/Solid utility icons at 64×64, two panel textures and two teal light accents at 512×512. It also renders nine original functional UI shapes: wheel base, six matching selected sectors, switch track and knob. Those shapes use original SVG geometry in the MIT-licensed tool; the rendered original artwork follows ASSET-LICENSE.md. These are technical exports, not AI-generated substitutes for the supplied art. No source assets were sent to an image generator.

The complete Media directory has 37 files totaling 6,991,746 bytes. The six mode icons and original audio remain unchanged. TGA exports are uncompressed BGRA with alpha and power-of-two dimensions. The reproducible archive uses the committed exports; source re-export uses isolated Pillow 13.0.0 and resvg-py 0.5.0 build tools, never addon runtime dependencies.

## Original photo textures — beta.10

On 2026-11-09, `tools/create_photo_assets.py` created 23 deterministic analytic/noise textures: `photo-vignette-0` through `photo-vignette-10` (128×128), `photo-glow-0` through `photo-glow-10` (64×64), and `photo-grain` (128×128). These original smoothstep radial alpha shapes and seeded monochrome noise contain no reference/third-party artwork. All use uncompressed power-of-two 32-bit TGA. Code is MIT; creative output follows ASSET-LICENSE.md. The manifest records all hashes; the full TGA payload remains below the 8 MiB packaging budget. Native decoding and smoothness remain owner-tested acceptance.

## Original pose illustrations

Northern Lights Labs created six 128×64 pose illustrations for beta.23. The joint coordinates, colors and drawing routine are in `tools/create_pose_swatches.py`. The exports depict generic figures and do not contain game screenshots or third-party models. The generator uses Pillow at build time. The original illustrations are covered by ASSET-LICENSE.md and recorded by hash in the asset manifest.
