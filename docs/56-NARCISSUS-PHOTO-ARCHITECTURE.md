# Narcissus photo architecture and LumenShift expansion

Implementation follow-up: [Delivery A / beta.12](57-STANDALONE-PHOTO-WORKFLOW.md), [Delivery B / beta.13 plus Phase 1 audit](58-PHOTO-COMPOSITION-AND-OUTPUT.md), and [Delivery C / beta.14 plus Phase 2 audit](59-PORTRAIT-STAGE.md) are now implemented. The research below retains its original findings and planned scope; native stage acceptance remains pending.

> Follow-up: Delivery A is implemented in [beta.12](57-STANDALONE-PHOTO-WORKFLOW.md). The research snapshot and proposed later deliveries below remain historical evidence.
2026-11-09 · Northern Lights Labs · Source investigation; runtime remains **0.2.0-beta.11**.

The owner asks how Narcissus implements photography so LumenShift can become a complete photo toolkit. This investigation follows its installed source, current upstream source and Forever API declarations. It extends [53](53-PHOTO-MODE-RESEARCH-AND-CONTROLS.md), compares the implemented [Photo Studio](54-IN-SCENE-PHOTO-EDITOR.md) and [live sliders](55-LIVE-PHOTO-SLIDERS.md), and defines the remaining deliveries. **The additions below are proposed, not shipped.** The earlier instruction to do 3D model work later remains respected.

**Owner clarification: LumenShift must work with Narcissus completely uninstalled.** Every photo feature must be implemented in LumenShift using WoW's native APIs and its own code/assets. Narcissus is a research reference, never a required library, API provider, actor database, asset source or TOC dependency. Any coexistence adapter is optional and inert when Narcissus is absent. Primary acceptance uses LumenShift alone; running both is a separate compatibility test.

## Evidence and scope

- **Source-confirmed:** installed Narcissus TOC reports **1.8.7 c**, interfaces **120105, 16001**. Upstream main resolves to `0a6d5985f6604fdb39190f284def6864f3622a8b`, release merge dated 2026-11-07. Thirteen inspected installed source files match that commit's Git blob hashes after CRLF-to-LF normalization. This is not a whole-install integrity claim. [N1]
- **Observed in the owner's screenshot:** LumenShift Photo Studio and the Narcissus screenshot/emote toolbar are visible together. This does not establish the effective values behind MSAA/RTX labels or prove restoration.
- **Source-confirmed for named build:** Forever **70862**, UI-source commit `9dc84f0d3bbae1768ac3405b3716000bd93eda06`, supplies the API declarations below. A declaration is not an in-client acceptance result. Previously accepted owner identity/readbacks remain valid; no new version confirmation is needed.
- **Not run:** native emote, new camera-offset, stage-rendering or coexistence acceptance tests. No installed addon, saved data or game setting was changed during this investigation.

The thirteen matching files are `Main.lua`, `API/Camera.lua`, `API/APITransition_DF.lua`, `API/APITransition_MID.lua`, `Filters/CameraEffect.lua`, `Modules/ScreenshotTool/Toolbar.lua`, `Modules/ScreenshotTool/EmoteList.lua`, `Modules/ScreenshotTool/ScreenshotTool.xml`, `Modules/PhotoMode/PlayerModel.lua`, `Modules/PhotoMode/PhotoMode.xml`, `Modules/PhotoModeNew/LightingPreset.lua`, `Modules/Storyboard/Controller.lua` and `SettingsFrame.lua`. Paths here are relative to upstream's `Narcissus/`; private installation paths and account data are excluded.

## What Narcissus actually does

### 1. World screenshot tools

The toolbar's `Blizzard` layout contains Camera, Emote, Hide Texts, Top Quality and Location. It is independent of the more elaborate model stage. [N2]

| Tool | Source mechanism | LumenShift status and direction |
|---|---|---|
| HUD and clean capture | Hooks `SetUIVisibility`; fades its toolbar on `SCREENSHOT_STARTED`, and reveals it on mouse hover. | LumenShift already offers explicit H/Hide controls and Escape. Add coexistence handling so another toolbar does not contaminate external captures. Native screenshot events alone do not cover Snagit or OS captures. |
| Emotes and auto capture | Button selects an emote token; transition adapter chooses `C_ChatInfo.PerformEmote` or legacy `DoEmote`. A one-second timer then calls `Screenshot` if auto capture is enabled. | Add a visible Pose panel with curated emotes, favorites, optional delay and one-shot capture. An emote animates the actual player; it is not a frozen arbitrary animation frame. [N3, F1] |
| Names and clutter | Captures a group of name, bubble, floating-text and soft-target CVars, then clears them; also changes battle-pet tracking. | Current LumenShift handles only friendly player/pet names. Add independent Players/Pets/NPCs/Bubbles groups after validating each member. Do not copy tracking or targeting changes into a cosmetic toggle. [N2] |
| Camera composition | Zoom uses `GetCameraZoom` with `CameraZoomIn/Out`. Shoulder offset uses `test_cameraOverShoulder`; the control labeled Pitch uses dynamic-pitch CVars, rather than a general world-camera angle setter. FOV writes `cameraFov`. | FOV is implemented. Add zoom/distance, horizontal composition and a separately named dynamic-framing control. Native zoom can be constrained by world collision. Do not promise free-flight or exact world-position bookmarks. [N4] |
| Photo quality | Temporarily writes a group of graphics tiers; Forever-specific secondary lighting, PBR water and bloom have capability checks. Separate controls change MSAA and `shadowrt`. | Existing LumenShift photo-quality bank can provide this role. Add individual AA/shadow choices only with native option/dependency handling. Do not import a hard-coded “everything maximum” table. [N2, F4] |
| Screenshot quality | Settings write `screenshotQuality`; the slider is 3–10. | Consider output quality as a separate preference, with its own original and restoration. This is JPEG/compression quality, not a way to add world detail. The historical inventory also lists `screenshotFormat`, but current writable domains still need verification. [N5] |

The `RTX 3` label is derived from the ray-traced-shadow CVar. The inspected toggle requests level 3, and its validity flag is hard-coded true; the label alone does not prove hardware support or a visible ray-tracing result. The MSAA slider uses a console command with compound values. Neither is a reason to introduce a second writer or console execution into LumenShift. [N2]

### 2. A separately rendered portrait stage

Narcissus creates `DressUpModel` frames for players and `CinematicModel` frames for NPCs, loads the selected unit into them, and provides independent transform, animation, equipment and lighting controls. It checks unit-identity access before loading a target. Its stage includes actor selection, animation variations, pause/frame selection, model-only light direction and ambient/diffuse colors, outfit/weapon previews, spell visuals, and decorative shadow textures. These are client-rendered representations, not commands that move or equip the actual player or NPC. [N6]

`FreezeAnimation`, `SetPaused` and sequence-time controls freeze or scrub these models. They cannot pause the live world. `SetLight` receives model light data; other calls target a `ModelScene`. The newer Storyboard module demonstrates `CreateActor`, model positioning and scene-camera transforms, but is a separate scene system, not evidence that the legacy PhotoMode has been replaced wholesale. [N6, N7, F2, F3]

Layer capture changes what is visible and takes successive ordinary screenshots: world background, model masks, colored chroma backgrounds and text layers. That supports external compositing; it does not create a layered PSD or a transparent world screenshot. Model-lighting presets store reusable lighting data independently of the camera. [N6, N8]

For LumenShift, this supports a later **Portrait Stage** with its own actor data, camera and lighting. It should be lazy-created and optional, without loading a large NPC catalogue or model frames for someone taking a landscape photo. Use native model identifiers/APIs and original controls/art; do not bundle extracted Blizzard models or copy Narcissus databases.

### 3. Screen treatments

Narcissus's warm/cool camera effect is a colored additive texture. Its darkness and vignette sliders adjust texture alpha. This is not a hidden full-world shader API. LumenShift already has independently authored warmth/tint, soft movable vignette, grain, additive glow, letterbox, native lighting/detail sliders, comparison and saved looks. [N9]

Useful improvements are additional original light leaks, more carefully tuned recipes, optional multiple glow accents and look-only undo/redo. Native bloom can affect eligible bright world materials on a supported renderer; a draggable glow accent remains a two-dimensional decoration. Model lights can illuminate staged actors, not the terrain behind them. The reviewed Forever model/texture APIs do not expose general WorldFrame color/depth-buffer processing for true world LUTs, selective grading, depth-aware bokeh or relighting an actual campfire. Model desaturation and model lighting remain useful for the later stage. [F2, F3]

## Why both addons appear in this screenshot

The source chain is explicit:

1. LumenShift `Core/Camera.lua` calls native `SetUIVisibility(false)` to hide the HUD.
2. Narcissus `Main.lua:1340` has an unconditional secure hook on that function. Outside its own active character view, a false state opens the `Blizzard` toolbar layout, except during its dialogue-interaction exception.
3. `ShowUI` runs button initialization. If Narcissus's saved `HideTextsWithUI` preference is enabled, this can also capture/change its broader names group. This occurs before any LumenShift code that merely hides the resulting toolbar. **Hiding the toolbar is therefore not a complete ownership fix.**
4. When the HUD is shown again, Narcissus can run `HideUI`/`RestoreAll`; its hook can also schedule `actioncam off` when its Keep ActionCam option is false. Which branches ran in the owner's session is unknown; the screenshot only confirms the overlapping presentation. [N10, N2]

This is a reproducible source-level integration risk, not evidence of two installed LumenShift copies. It can cause hidden cross-addon writes or delayed changes beyond the two visible interfaces. The inspected hook has no direct toolbar-enable preference check. No claim is made that every possible upstream integration mechanism has been exhausted.

The compatibility delivery must preserve native HUD behavior and explicitly handle both entry orders. Prefer a cooperative addon integration point if one is available. If a targeted adapter is necessary, confine it to the known passive `Blizzard` toolbar, inspect pre-entry state, and model temporary UI suppression separately from graphics ownership. Do not overwrite Narcissus saved preferences, replace its functions, unhook it, enumerate/hide arbitrary addon frames, or invoke its `HideUI` as though it were a harmless visual operation: that method restores foreign CVars.

A passive-toolbar presentation adapter must not claim to prevent its hidden name/action-camera writes. Those need separate observation and conflict handling, or a supported handoff. If Narcissus's full studio already owns a session, offer a visible handoff instead of starting competing controls. This should affect only the overlapping photo controls; visual modes and unrelated features must remain usable. Validate against the installed version and degrade locally if its interface changes. No compatibility adapter has been implemented in this research update.

## Original implementation plan

### Delivery A — complete the world-photo workflow

Keep the existing Look / Light / Frame / Saved organization; add clearly labeled Pose and Capture sections without crowding the fixed Capture, Hide controls and Exit actions.

- Build and test the complete workflow with LumenShift as the only enabled addon. Implement targeted coexistence separately, including pre/post visibility observations and late foreign restores, without making the standalone tools depend on that adapter.
- Add user-clicked emotes and Stop pose. Prefer the declared `C_ChatInfo.PerformEmote` result; use a legacy API only when the modern API is absent, not to retry a rejected operation. The Forever declaration marks it restricted. No recurring emotes or automatic messages; explain briefly that world emotes can be visible to other players.
- Add a countdown and a small bounded burst, with Cancel. Reuse the existing capture path and drain live-preview edits before capture. Hide countdown, guides, handles and both applicable toolbars before the image is taken; keep artistic effects. Advance on completion/failure with timeout handling, not an unbounded screenshot timer.
- Expand world name/bubble groups using fresh read capabilities and independently owned originals. Optional unavailable members should not disable all photo controls. Keep targeting behavior and combat text out of the initial clean-name group.
- Add look-only undo/redo and separate Reset look / Restore photo lighting / Restore framing actions. Saved looks should not silently become native graphics profiles.

**Acceptance:** all tools load and work with Narcissus uninstalled, with no Narci globals, files or exported functions required; a pose button performs one requested emote; canceled countdown/burst produces no later captures; Escape, combat and re-entry invalidate pending work; external screenshot keys pass through; no empty chrome contaminates clean view. Separately test both Narcissus load orders and enabled/disabled auto-hide-text preference. External CVar changes remain preserved, and exact original strings are retained. Normal use needs buttons, not commands or confirmation cards.

### Delivery B — stronger camera composition and output

- Extend the existing framing controller for bounded shoulder offset and dynamic framing after current Forever metadata is established. Keep FOV's native-reported bounds; Narcissus's fixed slider ranges are not authoritative LumenShift ranges.
- Put world zoom and any deliberate orbit operation behind a small camera-action adapter. Camera movement functions are not CVar writers, but need the same explicit start/stop lifecycle. Capture actual zoom before changing it; label collision-limited readback honestly. Stop motion on release, Escape, combat and hidden/failed controls. Do not reserve/reset the player's saved view slots.
- Retain the independent photo-quality bank. Add AA/ray-traced-shadow options from supported native enumeration, including renderer and restart requirements, rather than a universal RTX toggle. Graphics changes continue through `Core/WriteBoundary.lua` only.
- Add output-quality preferences only after current API/domain checks. Offer richer original light treatments and saved composition settings separately from looks; loading a look remains free of unrequested native changes.

**Acceptance:** current bounds are honored; missing camera features disable only themselves; failed/clamped movement reports the actual result; native photo/quality/framing return is coordinated; no ongoing orbit or render work survives exit; changing camera angle manually never causes an automatic fight. AA changes must verify both direct and source-defined dependent values. Native cost and image differences are owner observations, not inferred from mock success.

### Delivery C — optional Portrait Stage, later

Start with one player actor and an optional target. Provide move/rotate/scale, sheathe/appearance preview, curated animations, play/pause/scrub and model-light color/direction/intensity. Expand to a small bounded cast, independent light presets, neutral/chroma backgrounds and optional mask capture after single-actor loading and teardown are reliable. World Photo and Portrait Stage should be explicit choices, with the same familiar capture controls.

Prefer a ModelScene actor backend where the actual Forever API supports the required features; use a deliberate model-widget backend when it does not. The source declares animation speed/offset, paused state, actor transforms, spell visual kits and model lighting, but runtime support, unit access and model availability still need capability checks. Load asynchronously, time out missing models, limit actors, and stop updates when hidden. Animation IDs and spell visual kits need a curated tested catalogue rather than arbitrary text execution. [F2, F3]

**Acceptance:** staged pose/light changes never alter world actors or world lighting; the user's actual equipment is unchanged; missing/restricted targets leave existing actors usable; animation/model-loading callbacks cannot resurrect an exited stage; capture freezes only staged actors; saved scene data is versioned and validated; mask captures are correctly described as separate images. This is the deferred 3D work, not a prerequisite for Deliveries A/B.

## Architecture integration and regression work

Keep `PhotoConfig` for validated preferences/looks, `PhotoEditor` for pre-photo intent, `PhotoPreview` for coalesced native edits, `Camera` for coordinated lifecycle, `Composition` for capture/input, and `PhotoEffects` for artistic overlays. Add small modules for pose actions, capture sequencing and specific compatibility behavior instead of growing another monolithic editor. Any new native CVar belongs in the catalog/policy/planner and sole write boundary. Model rendering actions belong in an isolated stage adapter, without creating a second route to graphics settings.

Session timers need generation/cancellation tokens and finite lifetimes. Emotes remain user-started; no arbitrary macro/console input. New saved settings migrate without dropping current looks, setup completion or recovery. The current schema is 13; this research does not increment it. Privacy-conscious reports can include capability/error/state identifiers without character names, chat, private paths or third-party saved data.

Add meaningful mocked scenarios for: Narcissus entirely absent (every normal feature remains available); native emote rejection/absence; stale pose/capture timers; burst failure; clean external capture/input focus; friendly/pet/NPC/bubble subsets; both photo-tool entry orders; foreign names restoration; late action-camera changes; optional camera API failures; exact per-key return; stage load timeout/restriction and late callbacks. Follow with standalone in-client checks first, then compatibility checks for appearance, timing, hardware-dependent rendering, UI input priority, collision and actual coexistence. Mocks cannot certify those results.

## Licensing and verification record

The author's license page explicitly assigns **MPL 2.0 to source** and **CC BY-NC-SA 4.0 to artwork**. The repository LICENSE is MPL 2.0. This resolves the earlier research's uncertain Custom License label; it is not permission to relabel copied source/art as LumenShift MIT/ARR. This plan uses API/behavior research and original implementation/art. No Narcissus source, databases or artwork is copied into LumenShift. [N11]

This update changes documentation only. The latest prior runtime result remains beta.11's **493/493 Lua 5.1 mocks and 10/10 package tests**, recorded in [55](55-LIVE-PHOTO-SLIDERS.md); these are not new tests of the proposed features and were not rerun for this documentation change. This update passes the structural check (50 runtime modules, exact TOC/assets/versions, one native CVar writer), 102 relative links across the four changed documents, and whitespace checks. A source scan finds no Narcissus code-symbol/XML/TOC dependency; its sole runtime textual mention is explanatory Camera help. An initial broader text scan caught that help string and was refined to distinguish text from a dependency. No new install ZIP is needed, no native tests were performed, and no merge or publication is authorized by this investigation.

## Pinned primary sources

All accessed 2026-11-09. Narcissus links use its inspected 1.8.7c commit; Forever links use the named 70862 UI-source mirror. The author project page is descriptive evidence, not proof every feature works on Forever.

- **N1:** [Author repository release commit](https://github.com/Peterodox/Narcissus/commit/0a6d5985f6604fdb39190f284def6864f3622a8b); [author project description](https://www.curseforge.com/wow/addons/narcissus).
- **N2:** [Toolbar.lua](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/ScreenshotTool/Toolbar.lua): groups 94–166, backup/restore 176–281, name initialization 321–330, layouts 421–433, MSAA 459–495, screenshot/exit 1072–1135, ray-traced shadow toggle 1183–1249.
- **N3:** [EmoteList.lua:26](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/ScreenshotTool/EmoteList.lua#L26); [API transition:55](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/API/APITransition_MID.lua#L55).
- **N4:** [Camera toolbar handlers:504](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/ScreenshotTool/Toolbar.lua#L504); [camera API adapter](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/API/Camera.lua); [slider ranges:398](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/ScreenshotTool/ScreenshotTool.xml#L398).
- **N5:** [Screenshot quality preference:677](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/SettingsFrame.lua#L677); [historical Forever inventory](reference/FOREVER-70532-GRAPHICS-CVARS.csv), discovery only.
- **N6:** [PlayerModel.lua](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/PhotoMode/PlayerModel.lua): light 521–543, effects 1476–1538, layer sequence 1677–1759, actors 2582–2644, animation 2733–2756, screenshot listener 4463–4495; [model templates:584](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/PhotoMode/PhotoMode.xml#L584); [modern light-data adapter:43](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/API/APITransition_DF.lua#L43).
- **N7:** [Storyboard scene/actors:28](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/Storyboard/Controller.lua#L28).
- **N8:** [Model light presets:55](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/PhotoModeNew/LightingPreset.lua#L55).
- **N9:** [Additive camera effect](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Filters/CameraEffect.lua).
- **N10:** [HUD hook:1336](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Main.lua#L1336), and camera-view operations in the same file. LumenShift comparison: [Camera.lua](../addon/LumenShift/Core/Camera.lua).
- **N11:** [Author license terms](https://www.curseforge.com/wow/addons/narcissus/license); [repository LICENSE](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/LICENSE).
- **F1:** [Forever ChatInfo:451](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua#L451): restricted PerformEmote arguments and boolean result; CancelEmote at line 36.
- **F2:** [ModelScene actor base API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorBaseDocumentation.lua): animation 341, unit model 447, spell kit 577; [actor dressing/paused state](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorDocumentation.lua).
- **F3:** [ModelScene lighting](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameDocumentation.lua); [model camera/light/sequence APIs](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleModelAPIDocumentation.lua); [model FFX lights](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleModelFFXAPIDocumentation.lua).
- **F4:** [Native graphics UI](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua); [FOV bounds API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/CameraDocumentation.lua#L10).
