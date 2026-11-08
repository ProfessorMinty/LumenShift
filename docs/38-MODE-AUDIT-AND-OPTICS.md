# Mode audit and optical design

Audit date: 2026-11-07. Runtime reviewed: **0.2.0-dev.12**, commit `adf7763fa0dc19b41fc39b10ebf80815c3a5cf6e`, branch `feat/beta-integration`, ProfessorMinty/LumenShift. This is a research and source-audit delivery, **not a new runtime build**. No installed game, graphics value, preset or asset was changed for this audit.

## Conclusions

LumenShift has a substantial configuration/recovery foundation, but its six visual modes still primarily change Brightness, optional Contrast and UI decoration. They do not yet have distinct native optical recipes. Stronger Night Vision sharpening is practical through existing native controls. Darker contact areas are a separate ambient-occlusion investigation. Arbitrary black contours around all world geometry, thermal vision, true monochrome phosphor and programmable world color grading have no supported implementation path in the inspected addon APIs.

Prioritize **useful detail and readable shadows**, then optional goggle styling. Do not equate a brighter green veil with better night vision, a maximum quality level with an optimal configuration, or a successful getter/setter with an effective visual improvement. The next engineering work is shared-key ownership/composition, presentation consistency and per-mode optics, followed by controlled visual comparisons. Existing usable controls should stay usable; this work does not call for new confirmation cards or build-number locks.

## Evidence and audit scope

- **Verified in-client, owner supplied:** prior dev.6 Brightness 45 → 75 → 45 on Forever `1.60.1:70862:16001`, with the owner confirming both visual changes. See [28](28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md). Earlier 70790 identity evidence is also retained; no version reconfirmation is needed.
- **Verified read-only observations, not effect tests:** the owner's dev.10 report, addon commit `bb3d6b23d1a4cee796dd241370f9ac3a872a5ff5`, on `1.60.1:70862:16001`, contains the values below. These are a past snapshot, not claims about the owner's current session. Only the relevant allowlisted numbers are reproduced; the original attachment remains private.
- **Source-confirmed for a named build:** mirrored Blizzard UI/API definitions for Forever 70862 at F1, and older native metadata captured at 70532 at F2. The mirrors are evidence of Blizzard-authored interfaces and captured metadata, not a guarantee that every renderer/hardware combination behaves identically.
- **Source-confirmed implementation:** inspected mode schemas, baseline selection, Product transitions, Presentation/Audio, Quality, NativeGraphics, Camera, policies, the single write boundary, Studio and associated tests. This is a mode/graphics/product audit, not an exhaustive security or platform certification of every repository line.
- **Hypotheses/proposals:** all new recipes, preference defaults, added controls and visual improvements in this document. They are not implemented by this change.
- **Unknown:** full native quality dependency closure, effective bloom/ASSAO internals, cross-addon UI/rendering behavior and acceptance of dev.12's expanded controls. Passing mocks does not resolve these.

| Owner dev.10 observation | Current then | Native default then | Implication |
| --- | --- | --- | --- |
| `ResampleAlwaysSharpen` | `1` | `0` | The sharpening pass was already enabled. Enabling it again would not add detail. |
| `ResampleSharpness` | `1` | `0.2` | There is room to test a stronger setting: **lower raw values are stronger**. |
| `textureFilteringMode` | `5` | `5` | Already the native 16x filtering option; do not advertise enabling 16x as a new improvement in this snapshot. |
| `graphicsSSAO` / `SSAO` | `4` / `4` | `3` / `0` | Already the highest exposed SSAO tier. The selector's default and underlying leaf's default are different concepts. |
| `assaoDetailShadowStrength` | `0` | `0` | Fine contact detail is a research candidate, not an admitted writer or proven missing effect. |
| `assaoRadius` / `assaoShadowMult` / `assaoSharpness` | `1.85` / `1.1` / `.98` | same | Existing values must be preserved during any future isolated trial. |
| `bloomUserMult` / `bloomEnable` | `1.000000` / `0` | same | Existence and multiplier alone do not establish the active bloom path. Do not automatically flip the older engine toggle. |
| `ResampleQuality` | `1` | `3` | Native choices identify these as bilinear and FSR respectively. This alone says nothing about whether upscaling was active or worthwhile. |

The extra observations reported accessible values and unrestricted flags for the listed research candidates. That is read capability evidence, not a native write/restore or visual acceptance result.

## What each mode actually does today

Defaults below are **LumenShift-authored starting preferences**, not Blizzard defaults or measured optimal settings. They can be edited. The schema has no per-mode sharpening, bloom, filtering, AA or AO field.

| Mode | Default implementation | Important limitation |
| --- | --- | --- |
| **Original / Game Defaults** | Uses the chosen Brightness/Contrast snapshot; clears presentation effects. | Covers visual values, not all graphics. Exact pre-change recovery originals are separate from the chosen return look. Internal `natural` remains a compatibility identifier; its placeholder Brightness 50 is not the active return target. |
| **Night Vision** | Brightness 75; optional green tint at alpha .04 and vignette .04. | No extra mode-specific sharpening, local contrast, monochrome conversion, automatic gain or edge detection. |
| **Cinematic** | Brightness 42; optional amber tint .025 and vignette .06. | Does not select cinematic lighting/shadow/water quality. Bars default to zero and require the screenshot option; they cover UI space, not change world-camera framing. |
| **Lantern** | Brightness 65; optional warm tint .045 and vignette .035. | The addon does not emit a light into the world. Warmth is a UI overlay. |
| **Clarity** | Brightness 70; no default tint or vignette. | No special native texture filtering, AA or sharpening recipe. Raising brightness can make a scene less contrasty rather than clearer. |
| **Moonlight** | Brightness 55; optional blue tint .045 and vignette .04. | Does not change world time, moon position, fog, directional lighting or material colors. |
| **Camera**, independent utility | Native HUD visibility; optional friendly-player/pet name hiding with captured restoration. | Not a seventh visual mode. Does not move the camera or provide depth of field. See the presentation conflict below. |

Every non-return mode initializes `useContrast=false`. In `Product.Select`, when a chosen baseline includes Contrast, **false means use that baseline Contrast**, not necessarily leave the current value untouched. Balanced/Vista/Performance are independent detail profiles; their built-ins enable sharpening but preserve/release its original strength, and Vista/Performance use bounded relative detail changes. Their names do not establish a measured performance or quality outcome. Dev.12's native normal/raid recipes are broader, separate controls described in [37](37-NATIVE-GRAPHICS-BANKS.md).

## Audit findings to address

| Priority | Finding and code evidence at the reviewed commit | Recommended correction / completion criterion |
| --- | --- | --- |
| High | **No per-mode optics composition.** `Core/StudioConfig.lua:34` admits only brightness/contrast and presentation fields; `Core/Quality.lua:28` omits strength from built-in recipes. | Add typed optical overrides and one effective-value planner. Leaving Night Vision must return to the currently selected quality preference, while preserving the first pre-addon original for full restoration. |
| High | **Camera hides the look's UI effects.** `UI/Presentation.lua:8` parents effects to UIParent; `Core/Camera.lua:22` uses native UI visibility; `UI/Studio.lua:333` says the visual mode stays active. | Native Brightness can remain active while tint, vignette and bars disappear with their parent. Define a visible “Keep visual effects in Camera Mode” choice and a supported presentation-root strategy. Test actual visibility, not only saved active mode/brightness. Source-derived finding; not a new native observation. |
| High | **Composite mode application is not all-or-nothing.** `Core/Product.lua:143` starts Contrast after verified Brightness. A later failure reports `MODE_PARTIAL`, clears effects and assigns `natural` while brightness may remain changed. Existing D17 covers this partial failure. | Extend the shared transaction model across the requested mode keys; retain a clearly displayed Partial/Recovery state. Do not label the actual scene Original after an incomplete apply. Compensate only freshly verified owned changes, never overwrite external edits. |
| Medium | **Bloom eligibility is incomplete.** F1 shows the slider only when `C_VideoOptions.IsLinearEnabledOnStart()` is true. `ExperimentPolicy` labels it conditional, but `WriteBoundary`'s leaf bounds/Apply path does not evaluate that condition. | Read and report the native capability; omit an unavailable bloom control while leaving other controls usable. A matching value alone must not be reported as visible glare reduction. |
| Medium | **Presentation can undermine visibility.** A uniform color texture blends across the image; vignette deliberately darkens edges. Fixed 110-UI-unit edge widths vary with screen/UI scale. | Make Night Vision's clear, unobstructed variant primary; keep tint/rim optional and modest. Fit decorative edges by viewport/aspect. Preserve peripheral and ground-effect readability. |
| Medium | **Effect state is inconsistent after combat.** `Product.Combat` clears presentation; the return event observes state but does not reapply presentation. | Separate native write restrictions from permitted cosmetic preferences. Define and test cosmetic resume after combat without any CVar reapply. Show the actual effect state. |
| Medium | **Known quality capture is not full renderer capture.** Native banks capture named parents/leaves and monitor selected foreign values. Shared sharpening/bloom/AA effects are not thereby comprehensively covered. | Expand dependency observation for new optical keys and overlapping native tiers before promising complete restoration. Preserve unavailable/unknown findings. Do not infer a complete snapshot from a matching tier selector. |
| Low | **Some wording overstates or obscures behavior.** “Warm light,” “Adjust Contrast” off, older quality-scan “not implemented” labels and the stale calibration comment in `StudioConfig.lua:38` need reconciliation with current behavior. | Use “warm tint,” “Use return-look Contrast,” and accurate current control/support labels. Describe rendering effects separately from lens styling and quality. |

These findings do not erase existing recovery safeguards. The boundary still captures originals, checks fresh observations and retains failure records. They explain why passing restoration tests alone is insufficient to call the complete visual product finished.

## How real night vision informs the design

Image-intensifier goggles collect available light, convert photons to electrons, multiply them and turn the amplified signal back into an image on a phosphor screen. Green or white phosphor determines the display appearance; it is not simply green light added to the real scene. Gain, resolution and signal-to-noise quality affect useful detail. Auto-gating helps manage rapidly changing illumination. [Exosens N1](https://www.exosens.com/frequently-asked-questions-faq).

Thermal imaging is different: it maps emitted infrared energy and temperature differences rather than amplifying the same reflected-light image. [FLIR N2](https://www.flir.com/discover/ots/thermal-vs-night-vision/). Some advanced fused goggles combine intensified and thermal images and offer outline modes. That does **not** mean ordinary night-vision tubes trace black borders around everything. [L3Harris N3](https://engage.l3harris.com/envg-b/p/1).

For LumenShift, borrow the useful goals: dark-scene readability, detail, comfortable brightness and an optional optical identity. Grain, blur, large halos, flicker and heavy tunnel vision are poor default accessibility choices. There is no scene-luminance measurement or real thermal input in the inspected API, so do not promise automatic optical gain, hidden-unit detection or genuine white-phosphor monochrome. A neutral/cool lens style can be inspired by white phosphor but must not be presented as a monochrome shader.

## Sharper detail versus darker lines

**1. Native sharpening: the first practical improvement.** Forever's own UI exposes `ResampleSharpness` over 0–2 in .1 steps and reverses the slider because lower raw values are stronger. Older native help describes `ResampleAlwaysSharpen` as allowing the sharpness pass without FSR upscaling. Keep this a detail-strength control with an intuitive weak-to-strong direction. A displayed percentage would be a UI normalization, not a measured percentage improvement. Do not equate raw 2 with a proven off switch or admit the older metadata's -1 sentinel without separate handling. [F1, F2]

For the owner's recorded raw 1, a future controlled A/B sequence could compare **1 → .7 → .4 → .2**, one choice at a time, keeping render scale, AA, filtering, scene and lighting unchanged. These are proposed comparisons, not prescribed defaults or commands to execute now. Stop at the preferred image; maximum strength 0 is not automatically best. Inspect moving foliage, thin fences, distant edges, text/nameplates and torch highlights for objectionable shimmer or edge halos. Re-read and restore the captured original after the comparison.

AMD documents separate upsampling and contrast-adaptive sharpening passes in FSR1, and recommends considering noisy/high-frequency effects in pipeline ordering. This explains why detail strength and resolution scaling are different decisions; it does not prove the exact compiled algorithm or shader order in Forever. There is no need to lower render scale merely to enable the independently exposed sharpening pass. [G1](https://gpuopen.com/fidelityfx-superresolution/)

**2. Ambient occlusion: the promising dark-crease effect.** AO reduces ambient illumination in corners and places where surfaces occlude one another. It can improve separation around rocks, wall joints and object contacts; it does not draw every silhouette. [G2](https://gpuopen.com/fidelityfx-cacao/). Use the native SSAO tier first, but the owner was already at tier 4. That makes careful investigation of `assaoDetailShadowStrength` and `assaoShadowMult` more relevant than blindly increasing the tier again. Native metadata explicitly warns that added detail strength can reduce temporal stability. `assaoSharpness` controls AO edge bleeding, not texture sharpness. Huge internal radius ranges are not sensible preset targets. [F2]

Those ASSAO fields are currently read-only research observations in LumenShift. Before a new isolated trial: determine the active AO implementation, read native current/default/flags, capture relevant normal/raid tiers and neighboring AO leaves, observe dependencies and test exact restoration. A successfully changed number with no visible effect is inconclusive, not a feature pass. Native SSAO quality remains the primary supported route. Darkening too much can work against Night Vision, so AO should be an optional quality/detail choice, not an unconditional high-cost mode dependency.

**3. True contour drawing: unavailable through the inspected surface.** F2's outline tooltip describes selection outlines; quest/mouseover/target options are not a general scene edge detector. The inspected F1 texture APIs manipulate addon-owned textures and model scenes, not arbitrary scene color/depth buffers or custom GPU programs. `SetDesaturated` on a UI texture does not desaturate the rendered world. No supported path was found for a scene-wide black-ink outline, thermal fusion, LUT, selective shadow lift or depth-aware blur. This is a bounded API finding, not proof about every future client. Do not advertise these effects as implemented or replace them with misleading UI decoration.

## Recommended identity and controls for every mode

| Mode | Primary experience | Native work to pursue | Optional personality / boundary |
| --- | --- | --- | --- |
| **Original / Game Defaults** | A trustworthy return look. | Extend the chosen look only as new optical fields are explicitly included. Keep captured originals separate from native defaults and recovery. | No decorative effect. Clearly show what belongs to the visual look versus independent quality. |
| **Night Vision** | Reveal useful dark detail while preserving navigability. | User brightness boost (75 remains the existing preference), stronger optional sharpness, restrained Contrast, reduced bloom only on an effective supported path. | **Clear** and **Goggles** variants: neutral image first; subtle green/cool styling, thin lens rim and original on/off cue optional. Contact-depth enhancement is a separate optional quality experiment. |
| **Cinematic** | Depth, material detail and composition. | Optional companion quality using supported lighting, shadows, water and AO; coordinated AA/filtering; moderate sharpness. Preserve dark detail rather than forcing every scene to Brightness 42. | Framing guides/bars for deliberate capture; restrained warm or neutral style. No forced expensive profile, fake depth of field or claimed film LUT. |
| **Lantern** | Warm, readable interiors with softer styling than Night Vision. | Moderate brightness lift, gentle detail, preserve native local-light quality and useful highlights. | Warm lens tint and optional quiet activation cue. No claim that the addon creates a player-following world light or shadows. Avoid animated full-screen flicker by default. |
| **Clarity** | Crisp everyday gameplay in motion. | Prioritize appropriate resolution/AA, native texture filtering, restrained sharpen and effective glare reduction. Preserve spell/projected-texture cues. | Neutral colors, zero vignette and no bars. Brightness should fit the player's baseline/display rather than blindly remain 70. |
| **Moonlight** | A readable night scene that still feels like night. | Modest baseline-relative lift, comfortable detail, supported native shadow/lighting quality where affordable. | Subtle cool lens styling; keep fog/atmosphere and peripheral vision. No world-time, weather or moonlight replacement. |
| **Camera utility** | Reliable composition and clean screenshots while retaining the chosen look. | Keep visuals/quality independent; optional explicit screenshot-quality selection and exact return. Fix overlay visibility first. | Rule-of-thirds, center/aspect guides, independent names/HUD choices and clear exit keybinding. Guides hidden for capture when requested. No automatic camera movement required. |

Native AA/resolution/filtering and expensive shadow/AO settings belong primarily in Graphics Quality. A mode may offer an explicit companion choice; ordinary mode switching must not silently replace the everyday or raid profile. “Cinematic + Performance” must remain a meaningful supported combination.

## Architecture needed before richer recipes

The selected visual mode and selected quality profile stay independent in saved configuration. Their **effective values** need a shared resolver when both care about the same optical key:

1. Keep the exact first pre-change original in the recovery journal. Preserve the chosen Original/Game Defaults look separately.
2. Resolve the active normal/raid quality preferences and any explicit per-mode optical override into one desired map. A single key has one physical owner/writer, with recorded logical reasons. Do not give two journals competing ownership of sharpness.
3. Preflight and apply the resolved delta through Planner/Recovery and the one WriteBoundary. Expand typed descriptors only for source-backed features; never accept arbitrary user CVar names/scripts.
4. On leaving a mode, remove its override and resolve the **current** quality preference. On full restore, release to the exact first original. If the player changes quality while a mode overrides sharpness, retain the new underlying choice for when the override ends.
5. Handle native normal/raid switching without a per-frame CVar loop. Shared optical keys must not masquerade as separate native raid keys. Observe the game's bank transitions before specifying any additional automatic behavior.
6. Failed, conflicting or interrupted operations retain explicit recovery state; startup does not guess. Do not silently skip a mandatory setting and announce a complete mode. Optional unsupported effects can be omitted with a concise status.

Example: original raw sharpness **1**, chosen quality **.4**, Night Vision override **.2**. Night Vision uses .2; leaving it returns .4; full quality restoration returns 1. If the player selects a different quality preference of .7 while Night Vision is active, leaving it returns .7. Capturing .2 as the new original would be a bug. These example values are tests of composition, not recommended presets.

Use a versioned data migration that preserves all current modes, personal presets, choices and journals. Separate live effective state from saved selection and pending edits. Extend the existing copy/validation/import bounds rather than embedding executable preset code.

## Special additions worth building

| Order | Addition | Value and limits |
| --- | --- | --- |
| 1 | **Sharpness per mode, with a real before/after comparison** | Directly addresses the request. A button switches between captured comparison states using the existing writer; no fake split-screen world rendering. Cancel/release must not overwrite intervening external changes. |
| 2 | **Clear / Goggles Night Vision styles** | Keep native readability useful with all styling disabled. Optional thin original lens artwork, quiet cue and cosmetic fade; no repeated CVar writes to animate brightness. |
| 3 | **Detail and glare controls** | Separate sharpen, contact depth and bloom in plain language. Capability-dependent controls explain only the affected option, without locking the rest of the addon. |
| 4 | **Camera composition tools** | Preserve the active look with HUD hidden; add aspect/thirds guides, explicit guide-free capture and separate names/HUD controls. |
| 5 | **Favorite variants and quick comparison** | Existing personal presets can become clear “Cave,” “Soft Night” or “Clean Gameplay” variants, selected by the player. Do not infer ambient darkness from zone names or add automatic indoor switching. |
| 6 | **User-started quality comparison** | Compare the same scene/route with normal/raid choices and record timing observations. WoW recommendations stay recommendations, not a benchmark or guaranteed best result. Avoid automatic profile switching on short FPS dips. |
| 7 | **Mode-specific original cues and assets** | A coordinated set of six readable icons and restrained transitions; preserve mute/reduced-motion/high-contrast choices. Continue the supplied artwork's recorded licensing. No loud continuous hum or essential information conveyed only by color/sound. |

## Implementation and acceptance order

**A. Correctness and presentation.** Address Camera/effect coexistence, honest partial-mode state, bloom capability and Contrast wording. Test effects through Camera entry/exit, combat and reload with zero unintended graphics writes. Fix source comments and user-facing claims together. Retain draggable foreground windows and existing layout regressions.

**B. Shared optics and Night Vision/Clarity.** Add resolver/schema/descriptors, intuitive strength controls and explicit Apply/A-B/Restore. Test quality → mode → different quality → mode off → full restore, repeated switches, exact raw originals, no-setter cases, missing capabilities, clamps, delayed drift, late restrictions, compensation failure, reload and migration. Optional effect failure must not strand native graphics or misreport a complete transition.

**C. Native visual evaluation.** First compare sharpening alone on the owner's already-supported path. Then evaluate bloom and AO independently before combining them. Use a dim interior with a torch, an outdoor night scene, stone/wood contacts, thin foliage/fences and moving spell/ground effects. Keep camera, route, resolution/scale, AA, weather/time and quality stable as far as practical; disclose changes that cannot be controlled. Record before/after effective values, screenshots and short moving comparisons. Static screenshots alone cannot establish temporal quality.

Acceptance is: the intended feature is visibly distinguishable; useful dark and peripheral detail is retained; no objectionable halos/shimmer or hidden encounter cues; measured cost is acceptable to the owner in that scenario; all captured changed values restore; external edits survive. A numerical change or improved still image alone is insufficient. No universal FPS or best-value claim follows from one machine.

**D. Remaining modes and product finish.** Tune Cinematic, Lantern and Moonlight against their stated intents, offer explicit companion quality choices, finish Camera composition and custom icons, and rerun native window/scale/input/accessibility coexistence tests. Keep source-backed but unproven options labeled accurately. The public beta still requires [release QA](22-BETA-RELEASE-QA.md), current policy/packaging review, honest compatibility/licensing information and final owner publication approval.

## Validation performed for this audit

On the reviewed runtime commit, reran `python tools/check.py --mocks --lua-runtime ../lua-test-runtime`: **268 simulated Lua 5.1 tests passed, 0 failed**. Structural checks passed for the exact TOC list, 35 runtime modules, versions and single native call site. Syntax passed for 45 Lua files and four binding bodies. `python -m unittest discover -s tests -p test_package.py -v`: **9 tests passed**. These are existing suite results, not new tests proving the proposed effects. Existing Camera C04 checks brightness/name/HUD state but does not assert that presentation remains visibly rendered; existing D17 deliberately records partial composite failure.

An additional isolated Lua 5.1 probe reused the existing `fixture` and `tests/ui_mock.lua`, with a simulated native setter and visibility API. It reproduced three findings, without changing repository runtime/test code or running the game:

- Select Night Vision, flush callbacks, inspect `presentation.frame:IsVisible()`: **true**. Enter Camera and flush: **false**, while Brightness remains **75**.
- Set the mock `C_VideoOptions.IsLinearEnabledOnStart()` to return **false**; call `lab.CanApply("quality", { bloomUserMult = 0.8 })`: a plan is returned, with **zero writes during preflight**. The linear capability does not currently filter that plan. The probe did not execute it.
- Exit Camera, call `product.Combat()` then `product.Observe()`: presentation remains **not visible**, while `product.active` remains **nightVision**.

These are reproductions of gaps, not three passing feature-acceptance tests and not additional native observations. They are separate from the 268-test suite count. The native visibility result still needs confirmation in the actual game; the mock models parent visibility explicitly.

No new native test, FPS benchmark, screenshot comparison or graphics write was executed. Runtime, version and dev.12 ZIP are unchanged. Findings remain open engineering work; documenting them does not mark them fixed.

## Source ledger

All sources inspected 2026-11-07. No renderer code or third-party creative assets were copied for this audit.

- **F1 — Blizzard UI/API source mirror, Forever 70862**, commit `9dc84f0d3bbae1768ac3405b3716000bd93eda06`: [Graphics.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua) (SSAO options 201–210; outline 236–243; filtering 1275–1289; resampling 1311 onward; reversed sharpening 1538–1561; brightness/contrast/gamma 1564–1585; conditional bloom 1589 onward), [GraphicsOverrides.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Settings_Shared/Mainline/GraphicsOverrides.lua), [Video API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/VideoDocumentation.lua), [UI texture API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua), [ClientScene API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/ClientSceneDocumentation.lua). Model-scene/texture interfaces are not a verified live-world post-processing API.
- **F2 — Native console/API/string capture, Forever 70532**, commit `d1ee569878094270c0ad8d8b00de0762158fd578`: [CVars.lua](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/CVars.lua) (ASSAO detail/radius/strength/edge handling 56–65; sharpen 1330–1332), [English strings](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/GlobalStrings/enUS.lua) (selection-outline tooltip 15569; sharpening tooltip 15635), [GlobalAPI.lua](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/GlobalAPI.lua). Historical defaults/ranges are evidence, not universal safe targets. Current read observations above independently establish only the named values' availability on 70862.
- **N1 — Exosens manufacturer explanation:** [Image intensification, phosphor, gain and auto-gating](https://www.exosens.com/frequently-asked-questions-faq). Physical design context, not a WoW capability claim.
- **N2 — FLIR manufacturer explanation:** [Thermal versus night vision](https://www.flir.com/discover/ots/thermal-vs-night-vision/). Used for the sensing distinction; not adopting broader product-comparison marketing claims.
- **N3 — L3Harris manufacturer product explanation:** [Fused intensified/thermal and outline modes](https://engage.l3harris.com/envg-b/p/1). Establishes that outline-equipped fused goggles exist, not that an addon can reproduce them.
- **G1 — AMD GPUOpen:** [FSR1 upsampling and RCAS sharpening](https://gpuopen.com/fidelityfx-superresolution/). General rendering context; the exact Forever shader implementation is not established by this page.
- **G2 — AMD GPUOpen:** [Ambient occlusion explanation](https://gpuopen.com/fidelityfx-cacao/). Explains darker corners/contact areas and quality/cost tradeoffs. Its Shadowlands example does not prove Forever's active AO implementation.

Related decisions: [graphics deep dive](33-FOREVER-GRAPHICS-DEEP-DIVE.md), [baseline choice](34-BASELINE-CHOICE.md), [recommendation/normal/raid research](35-GRAPHICS-SELECTION-AND-RECOMMENDATIONS.md), [native bank implementation and limitations](37-NATIVE-GRAPHICS-BANKS.md).
