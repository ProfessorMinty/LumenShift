# Photo Phase 3 audit and completion — beta.15

2026-11-09 · Northern Lights Labs. The owner requested a Phase 3 correctness review and an honest remaining-work list, with Narcissus independence preserved. This audits [Portrait Stage](59-PORTRAIT-STAGE.md) against Delivery C of the [photo plan](56-NARCISSUS-PHOTO-ARCHITECTURE.md). Existing World Photo, settings, recovery records and schema **16** remain intact.

**Outcome:** the three planned photo deliveries have implementations and automated coverage. Phase 3 needed the corrections below. The updated candidate is usable for testing; complete native rendering, capture and interaction acceptance has not been established. No new activation gate, confirmation card, prerequisite addon or reset was added.

## Findings and corrections

| Reproduced problem | Correction and regression evidence |
|---|---|
| After staging target A and targeting B, an appearance edit loaded B into A's slot. | Keep each loaded slot's identity in session memory. Appearance refresh requires the same accessible unit; a mismatch keeps the actor and explains how to refresh. Transforms and poses continue working. Identity is neither saved nor exported. PCA01/PCA10. |
| A saved ModelScene time offset/playback speed could make the entire cast fail to load on DressUpModel. | The fallback renders its supported pose parameters while preserving the stored advanced values. Only time/speed controls are unavailable there. PCA02. |
| Missing optional transmog, tilt, clothing or weapon methods prevented otherwise usable models from loading. | Load supported properties and label the unavailable controls locally. Explicit unsupported edits leave saved choices unchanged. Present methods that actually reject an operation still report failure and retain the previous actor. PCA03/PCA09; existing PC09/PC31. |
| Model lighting was treated as a prerequisite for ModelScene selection and saved-scene loading. | Select the renderer by its core model/camera methods. Missing optional light methods keep the stronger backend and its timeline. Cast/layout loading continues; the current light record and saved presets remain intact. The Light tab explains the local limitation. PCA05/PCA11. |
| The general actor editor accepted a unit-source edit without reloading its model. | Restrict it to actual actor controls; unit replacement remains in the checked loading path. PCA04. |
| Portrait's letterbox slider clamped an existing 0.30 value to 0.25 on display. | Use the same range as World Photo. PCA06. |
| Compositing pair returned success even if its first screenshot could not start. | Return the capture-start result and unwind the pending pair/frozen state. PCA08. |

The original focused reproduction produced six failing scenarios and one passing storage check. After the fixes and additional capability tests, the focused suite passes **42/42** (PC01–PC31 and PCA01–PCA11). PCA07 also fills all eight three-actor scenes, eight lights, twelve photo looks and twenty-four visual presets, then opens the saved data successfully. No storage-limit increase or migration was needed. The existing timeout case now reselects the original target before exercising timeout; a changed target correctly stops earlier.

## What is implemented

| Photo delivery | Current scope |
|---|---|
| Phase 1 / A: world-photo workflow | World emotes/favorites, one-shot pose capture, countdown/burst/cancel, name/bubble subsets, look undo/redo, clean capture/H/Escape and standalone operation. [Details](57-STANDALONE-PHOTO-WORKFLOW.md). |
| Phase 2 / B: composition and output | Native zoom/held orbit, shoulder/dynamic framing, supported native AA/ray-shadow/JPEG controls, edge light and saved compositions separate from looks. Exact native return and conflicts use existing ownership. [Details](58-PHOTO-COMPOSITION-AND-OUTPUT.md). |
| Phase 3 / C: Portrait Stage | Up to three staged player/target/pet copies, transforms, appearance previews, six poses, native timeline/playback, model lights, backgrounds, stage lens, saved scenes/lights and background/chroma capture. Optional API support is local to each feature. [Details](59-PORTRAIT-STAGE.md). |

All three use LumenShift and native WoW APIs. Narcissus does not supply a renderer, pose function, asset, database or runtime library. The optional coexistence adapter deals with a foreign toolbar only; it does not implement photo features. No dependency was added to the TOC. Stage actions operate on owned UI models, not live equipment or world actors; no new native CVar writer was introduced.

## What remains before calling photo mode complete

These are development acceptance tasks, not restrictions that prevent ordinary use of the beta.

1. **Standalone native rendering acceptance.** With Narcissus disabled, verify real player/NPC/pet models, representative races/forms, load timing, scale/centering, appearance refresh, the six poses, timeline and lighting. Native methods and mocks cannot certify the image produced by every model. Large or unusual models may need framing adjustments or fixes. Confirm no equipment/world-light changes.
2. **End-to-end capture and return.** Inspect the actual saved single, delayed, burst and compositing-pair files. Confirm H/external screenshot tools omit controls, guides and handles while retaining the desired art. Test cancel, Escape, re-entry, combat interruption and normal reload; check that existing world-photo lighting/framing/output return correctly and external changes remain preserved. The audit did not operate the game.
3. **Visual/input/performance polish from those observations.** Check common resolutions/UI scales, scrollable controls, text entry, rapid slider use, keyboard focus, model clipping/depth and a full cast's cost. Correct observed defects, then run the same acceptance cases again. Basic two-layout off-client review passed here; native input, taint and smoothness remain unverified.
4. **Compatibility acceptance.** Standalone success comes first. Separately test optional Narcissus coexistence and common UI/camera addons for both entry orders, HUD ownership and late foreign restores. A third-party failure must stay local and must not become a standalone dependency.

The planned implementation does not have an unstarted mandatory Phase 4. The remaining core work is native validation and any resulting fixes/polish. A public distribution additionally needs the repository's [release QA, licensing/attribution review, packaging metadata and final owner approval](08-CURSEFORGE-RELEASE.md); that is separate from being able to use/test Photo Studio now.

## Optional extensions and present limits

- A broader tested pose/variation catalogue, model-only spell effects, outfit/item browsing and additional creative recipes would expand the package. They are not implemented by this audit and are not required to enable current controls.
- Compositing pair currently produces two ordinary files: the backdrop and a green-screen cast. True silhouette/depth masks, transparent PNGs and layered PSD export are not implemented. The original plan made mask capture optional; chroma capture should not be described as a completed true-mask feature.
- Saved scenes restore the selected animation offset, speed and pause flag. Pausing a playing actor does not read back and save its exact instantaneous animation time. Use the explicit offset slider for a reproducible selected offset on ModelScene. Native model APIs reviewed here expose animation identity/variation but no playhead getter; exact arbitrary paused-frame persistence is not promised.
- Scene sources are symbolic player/target/pet references. Loading a saved target slot uses the current target; it is not a permanent catalogue of copied NPCs. The new identity check protects an existing live slot during appearance edits only.
- DressUpModel is a reduced-capability fallback: it does not provide the ModelScene timeline/lens or shared-scene depth sorting. Unsupported advanced choices are retained for a capable renderer rather than discarded.
- A live world backdrop cannot be frozen with the staged cast. Model lighting does not illuminate terrain or a real campfire. Vignette/glow/edge-light are screen treatments; this does not provide arbitrary world shaders, depth-aware blur or LUT processing.

## Verification and source review

- **589/589 Lua 5.1 mock tests passed**, including all previous 578 cases and eleven new audit regressions. These use isolated environments without Narcissus. Existing coexistence tests are additional cases, not prerequisites.
- **10/10 Python package tests passed**. Syntax: **90 Lua files plus four binding bodies**. Structure: **62 runtime modules**, exact TOC/version/assets and one native CVar call site.
- Whitespace, changed-document relative links and the stage dependency/writer scan pass. Two changed off-client fallback layouts were rendered and inspected (unavailable lighting and optional actor controls); they contain no actual native actor rendering.
- The recorded ZIP is generated twice from clean committed source and checked for byte equality, CRC, manifest membership and file hashes. Its receipt contains the exact commit-derived filename and SHA-256.
- No installed addon, SavedVariables, game session or graphics setting was modified by development tools. No merge or publication was performed. Earlier owner observations remain evidence for those earlier builds, not a new native pass for Portrait Stage.

Source review on 2026-11-09 revisited the pinned Forever 70862 [actor-base declarations](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorBaseDocumentation.lua), [actor appearance/pause declarations](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorDocumentation.lua) and [DressUpModel declarations](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIDressUpModelDocumentation.lua). These confirm the documented setter signatures, local-pause flag and dressing operations. They do not prove runtime rendering or model-specific animation support. Full primary-source context remains in [59](59-PORTRAIT-STAGE.md#primary-source-decisions).

## Install and try the corrected candidate

1. Exit WoW, extract the **beta.15 ZIP**, and replace only the complete installed **LumenShift** addon folder. The final path ends in `_forever_/Interface/AddOns/LumenShift/LumenShift.toc`, with Core/UI/Media beside it. Keep SavedVariables; no reset or repeated setup is required.
2. Disable Narcissus for the standalone check. Start WoW, open the LumenShift wheel, choose **Camera**, then **Portrait Stage** at the top of Photo Studio.
3. Add a target, then retarget a different unit. Moving/turning the existing actor should work; an appearance refresh should keep it and ask you to select the staged target again. Selecting that original unit allows appearance refresh. Loading a saved scene still deliberately uses the current target.
4. Follow the [Phase 3 native test](59-PORTRAIT-STAGE.md#installation-and-owner-test) for Actors, Light, Scene, Look, Saved, capture, H and Escape. Try the existing World Photo controls too. Report the failing control and visible result if anything differs; there is no need to reconfirm the launcher version or erase settings.
