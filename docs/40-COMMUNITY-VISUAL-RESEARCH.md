# Community approaches to a better WoW visual experience

Research date: **2026-11-07**. Repository: **ProfessorMinty/LumenShift**, branch `feat/beta-integration`. Documentation only; runtime/ZIP remain **0.2.0-dev.12 / adf7763f**.

## What this adds

The useful approaches combine image clarity, atmosphere, composition and sustainable performance. There is no single community recipe that establishes the best result across monitors, scenes and hardware. LumenShift should make those choices understandable and reversible, with distinct visual modes above independent everyday/raid quality choices.

This investigation reads firsthand Forever player reports, addon creators' descriptions and relevant native source captures. It extends [the mode audit](38-MODE-AUDIT-AND-OPTICS.md) and [the graphics-control landscape](39-GRAPHICS-CONTROL-LANDSCAPE.md). Those documents retain the implementation findings and external shader/driver research.

**Evidence labels:** player experiments are **Community-reported**; creator documentation establishes the described product design, not our interoperability; pinned Blizzard UI/native metadata are **Source-confirmed for the named build**. Proposed LumenShift behavior is a **Hypothesis/design proposal**. No new result here is **Verified in-client**. The owner's existing Brightness round trip and diagnostic observations remain accepted.

## Useful approaches, and what to borrow

| Firsthand source | What the author did or reported | Proposed LumenShift use |
| --- | --- | --- |
| [Altec1576's sharpening comparison][S1], tagged Forever | Compared the same scene with sharpening off/on, preferred raw strength around 0.2, and explicitly noted image-host compression. Replies disagree about the appearance. | Adjustable detail strength with an off option and matched comparisons; avoid a universal maximum. |
| [Weathertop94's Forever experiments][S2], September 27, 2026 | Explored secondary lighting, AO, shadow cascades, weather and sharpening. Reports that graphics tiers overwrite several leaf settings. | Investigate individual optical controls and their dependencies, instead of importing the command list. Numeric concerns are below. |
| [ozzy_roy's Beyond Ultra guide][S3], Forever | Combines 200% render scale, dense foliage and extended distances. The author acknowledges inherited commands may have no effect. | An optional scenery/screenshot quality direction with measured costs, independent of the visual mode. Do not ship this macro bundle. |
| [Hot_Persimmon7034's settings report][S4], Forever | On a 7800X3D/9070 XT system, reports quieter operation after limiting FPS and reducing the highest shadow/lighting choices. No controlled benchmark is supplied. | Ask whether the player values smoothness, scenery or lower fan noise. Do not infer an appropriate level from GPU branding alone. |
| [Shonenjumpboy's weather post][S5], Forever | Values the heavy-weather atmosphere shown in their post. | Preserve an atmospheric option; better visibility and stronger weather are different preferences. |
| [Dvalin's minimal Forever interface][S6] | Publishes native UI layouts that retain useful combat information while reducing clutter. | Keep LumenShift controls compact and make hiding HUD/names a deliberate Camera action. Do not overwrite an existing UI layout. |
| [DynamicCam's author description][S7] | Uses situation-based camera framing, shoulder offsets, zoom and interaction views. Its current listing includes Forever. | Optional manual camera framing, reduced-motion controls and coexistence with camera addons. Listing support is not a LumenShift integration test. |
| [Narcissus by Peterodox][S8] | Offers staged character photography, model lighting, text hiding and temporary photo-quality controls. The current main listing includes Forever; it also warns that camera views 2 and 5 are reset. | Treat photography as a separate session. Preserve camera ownership; distinguish staged model lighting from illumination of the live world. |
| [Immersion by MunkDev][S9] | Presents quest dialogue with accessible navigation and optional pacing; the author emphasizes avoiding extra friction. | Learn from its interaction design: visible controls, optional atmosphere, quick exit. Do not replace the user's dialogue addon. |

These are design precedents and reports, not endorsements of every setting in those projects. No third-party code, artwork, profiles or shaders were copied or installed.

## Check the recipes against the client

### Sharpening: useful, but strength and resolution are separate

The sharpening comparison [S1] supports trying native-scale sharpening rather than requiring the often-repeated 98/99% render-scale trick. Native metadata captures `ResampleAlwaysSharpen` separately and describes raw `ResampleSharpness` as **0 = full strength**; the 70862 UI reverses that value for its slider ([N1], [N2]). A larger raw value does not mean stronger sharpening.

The owner's recorded snapshot already has sharpening enabled, native render scale and raw strength 1. Therefore a meaningful Night Vision/Clarity experiment would compare strength, not merely turn an already-active feature on. Proposed initial comparisons: current value, 0.5 and 0.2, with an unsharpened reference. These are **trial candidates, not validated defaults**. Inspect moving foliage, stone edges and bright rims as well as still-image crispness. Avoid stacking native and driver sharpening without recording both.

### Darker creases: promising AO lead, problematic numeric recipe

[S2] suggests `assaoDetailShadowStrength = 5000`. The 70532 native help instead describes **0–5** and warns of reduced temporal stability ([N2], line 56). This does not prove the current engine's clamp behavior; it does disqualify 5000 as a source-backed preset target. The reported `ssaoType` selector is absent from that historical capture, so its existence and method mapping remain unverified here. A reported dramatic effect is not evidence that every supplied number was accepted.

Investigate modest contact-depth enhancement for Night Vision/Clarity through the shared optical layer. Keep it separate from sharpness and evaluate motion. AO darkens creases/contact regions; it is not an object-outline renderer. The external color-edge shader examined in [39](39-GRAPHICS-CONTROL-LANDSCAPE.md) remains a separate technique, not an addon capability.

### Beyond Ultra: a source of experiments, not an executable specification

Several [S3] names, including `overridefarclip`, `environmentDetail` and `smallcull`, are absent from the complete 70532 capture [N2]. Absence there is not proof of absence on every Forever build. Do not silently register, replace or assume aliases for them.

A 200% width/height scale entails four times the rendered pixel count, not a guaranteed fourfold GPU cost. Extra detail must earn its cost in matched scenes. Native readback alone cannot establish visual improvement. Keep scenery density/distance in quality profiles; selecting Moonlight must not silently select maximum foliage or supersampling.

### Performance and bank state need their own evidence

A historical native bug is particularly relevant: Blizzard's Rommax directly confirmed swapped normal/raid secondary-lighting settings on **October 3, 2026** [N3], during the 70205 beta period documented in [N4]. This establishes a past engine issue, not that the owner's 70862 client still has it. Add separate normal/raid transition observations; do not implement a permanent startup workaround from the old report.

A good-looking empty scene and a smooth raid are separate acceptance cases. Native recommendations are starting points, not a measurement of the player's target FPS. Proposed setup language: **Keep my settings**, **Use WoW's recommendation**, or **Choose a level**; then optional priorities such as **Smooth gameplay**, **Richer scenery** and **Quieter operation**. Keep the existing independent raid/battleground choice. Additional benchmarking should be opt-in and must not claim that a short test predicts every encounter.

## Concrete direction for each mode

These are proposed improvements, not features added by this research commit. Keep first originals, exact recovery, conflict handling and the single writer. Shared optics must compose with the current quality preference rather than overwrite it.

| Mode | Experience to aim for | Next meaningful work | Acceptance observation |
| --- | --- | --- | --- |
| **Original / Game Defaults** | A trustworthy reference | Preserve the chosen visual snapshot and independently selected quality; expose a clear before/after comparison. | Returning restores the chosen visual reference without losing current quality choices or exact recovery originals. |
| **Night Vision** | Readable darkness with crisp detail | Retain the successful Brightness target; add adjustable native sharpening and investigate restrained AO contact depth. Keep goggle tint optional. | Dark objects become easier to distinguish without bright-edge halos, crawling creases or obscured combat information. |
| **Clarity** | Neutral everyday readability | Tune sharpness and glare reduction separately; preserve color identity and avoid an obligatory tint. | Textures look clearer during motion, highlights retain detail, and the scene does not merely become brighter. |
| **Cinematic** | Composition and atmosphere | Improve Camera interaction, optional framing and restrained bloom/contrast. Offer a separate temporary photo-quality choice. | A useful composed view with an immediate exit and correct restoration; bars/tint remain optional. |
| **Lantern** | Comfortable warm interiors | Balance exposure, warm presentation and glare around existing light sources. | Useful warm visibility without washing out firelight. Do not promise a movable world light. |
| **Moonlight** | Cool, legible night atmosphere | Preserve shadow depth and weather character while tuning readability and restrained cool presentation. | Feels distinct from Night Vision; neither blue haze nor crushed shadows hide relevant detail. |
| **Camera** (independent) | Clean viewing and screenshots | Explicit HUD/name controls, optional framing, camera-addon coexistence and separate screenshot-quality restoration. | Exit returns owned state; other addons' camera changes are preserved; HUD hiding does not accidentally remove the chosen presentation. |

Before richer recipes, fix the open composite-mode, Camera/overlay, combat-presentation and bloom-preflight findings in [38](38-MODE-AUDIT-AND-OPTICS.md). This research does not resolve them.

## How to choose defaults that actually look better

Proposed owner-run comparison protocol, not tests performed in this research:

1. Capture the current settings, actual build, resolution/render scale, AA, GPU/driver, HDR/display mode and active external filters. Reuse the known identity; diagnostic export should collect context without a repeated launcher-verification request.
2. Compare one control at a time from the same camera position in a dark interior, foliage-heavy daylight scene, torch-lit room, water scene and distant landscape. Record server time/weather so changing illumination is not mistaken for an effect.
3. Use an A–B–A sequence, lossless original screenshots and a short moving-camera clip. Judge readability, highlight/shadow clipping, edge halos, shimmer and color separately. Do not rank settings from compressed social-media images alone.
4. Record repeated frame-time/FPS observations after equivalent warm-up. Test a crowded scene/raid separately. Ask whether fan noise and motion comfort are acceptable; do not promise percentage gains from anecdotal reports.
5. Test mode changes over each quality choice, normal/raid transitions, external edits and restoration. Repeat with Camera and another camera addon where installed. A screenshot win does not excuse lost originals or fighting another addon.
6. Keep a comparison only when Arctic prefers its appearance and its performance/restore behavior is acceptable. Expose a simple intensity control with Reset rather than presenting a wall of raw CVars.

## Source scope and verification

All linked community/creator pages were consulted on 2026-11-07. Exact client builds are generally **not supplied** in their public descriptions. Relative page timestamps are not converted into invented publication dates. Forever listings identify declared flavor support, not comprehensive compatibility.

Text, descriptions and source metadata were inspected. No video was watched or pixel-level image comparison performed in this investigation. The Beyond Ultra author's linked spreadsheet exposed its title but no usable cells; its detailed test data were **not audited**. A Nexus cinematic-preset page returned HTTP 403 and contributes no findings. Secondary summaries of unavailable creator videos were excluded as technical evidence.

Documentation validation: repository identity/branch, source-metadata cross-checks, local document links, repository structural checks and Git whitespace checks. No runtime files changed, so the previous **268 Lua 5.1 mock / 9 packaging** results are historical; this research does not add a native or simulated graphics pass. No installed-game change, packaging, merge or publication.

## Sources

- S1: [Altec1576: sharpening comparison][S1], firsthand Forever-tagged comparison and discussion; build unspecified.
- S2: [Weathertop94: useful console commands][S2], 2026-09-27 Forever beta experiments; build unspecified.
- S3: [ozzy_roy: Beyond Ultra][S3], Forever recipe, caveats and discussion; build unspecified.
- S4: [Hot_Persimmon7034: graphics settings][S4], firsthand hardware/settings report; build unspecified.
- S5: [Shonenjumpboy: Forever weather][S5], firsthand aesthetic preference; build unspecified.
- S6: [Dvalin: minimal native Forever UI][S6], creator's layout explanation; build unspecified.
- S7: [DynamicCam][S7], current author listing and feature description; Forever 2.21.6 listing observed.
- S8: [Narcissus][S8], Peterodox's current main project description; Forever 1.8.7 c listing observed. The [Classic project][S8b] points Forever users to that main listing.
- S9: [Immersion][S9], MunkDev's author description; Forever listing observed.
- N1: [Blizzard graphics UI, Forever 70862][N1], pinned mirror; reversed sharpening accessor at lines 1551–1558.
- N2: [Native CVar metadata, Forever 70532][N2], pinned capture; full capture used for absence checks, not only graphics-category rows. See [39](39-GRAPHICS-CONTROL-LANDSCAPE.md) for capture provenance and inventory limitations.
- N3: [Rommax's direct secondary-lighting bug confirmation][N3], 2026-10-03; historical evidence only.
- N4: [Rommax's 70205 deployment update][N4], 2026-10-02; also requests location/time/hardware context for reproducible graphics reports.

[S1]: https://www.reddit.com/r/classicwow/comments/1wkp7ry/ingame_sharpness_resamplealwayssharpen_0_vs_1/
[S2]: https://www.reddit.com/r/wowforever/comments/1wr7bim/useful_console_commands/
[S3]: https://www.reddit.com/r/wowforever/comments/1x3hbv4/wow_forever_beyond_ultra_graphics_settings/
[S4]: https://www.reddit.com/r/wowforever/comments/1xp4944/graphics_settings/
[S5]: https://www.reddit.com/r/wow/comments/1xoz4jg/wow_forever_weather_gives_me_feels/
[S6]: https://www.reddit.com/r/Dvalin/comments/1xpnxw1/the_cleanest_wow_forever_ui_setup_no_addons/
[S7]: https://www.curseforge.com/wow/addons/dynamiccam
[S8]: https://www.curseforge.com/wow/addons/narcissus
[S8b]: https://www.curseforge.com/wow/addons/narcissus-classic
[S9]: https://www.curseforge.com/wow/addons/immersion
[N1]: https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua#L1551-L1558
[N2]: https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/CVars.lua
[N3]: https://us.forums.blizzard.com/en/wow/t/mac-8-different-graphics-bugs-each-isolated-to-one-setting-%E2%80%94-with-repro-steps-for-each/2354050/434
[N4]: https://us.forums.blizzard.com/en/wow/t/mac-8-different-graphics-bugs-each-isolated-to-one-setting-%E2%80%94-with-repro-steps-for-each/2354050/373
