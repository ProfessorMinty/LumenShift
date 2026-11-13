# Photo tools: reference review, capabilities and clean capture — beta.9

**2026-11-09 · Northern Lights Labs**

The owner requests an in-scene photo editor: hide all Camera controls for external screenshots/recording, Escape to exit, filters and sliders for a campfire portrait, and possibly a separate model stage later. The current two-button capture bar is insufficient for that workflow. This update implements the clean-view/Escape fixes and records the researched editor design. **It does not claim the proposed photo editor, filters or model stage are implemented.**

## Supplied visual evidence

The screenshot shows the world with the normal HUD hidden but LumenShift's Capture/Exit bar still visible. That confirms the visible state, not every Camera restoration result. The supplied 53-second recording was sampled throughout, with full-resolution inspection at 12, 36 and 44 seconds. Narcissus displays an additional character model over the live world, light-direction widgets, color swatches, darkness/vignette sliders, animation selection, model/equipment/ground-shadow controls and compact mode. The player's actual world character remains separately visible. No private paths, character names or reference media are committed.

The useful design principle is **controls beside the live composition**. The model-stage feature is optional; it should not be required to edit a landscape or actual campfire scene.

## Source findings and limits

Research was refreshed on 2026-11-09. Sources are pinned below where possible. The existing Forever UI-source pin is build 70862; source declarations are not newly completed in-client tests.

| Feature | What the evidence supports | LumenShift direction |
|---|---|---|
| Clean external capture | Addon-owned controls/guides can be hidden independently of scene effects. Windows/Snagit captures need no addon screenshot call. | **Implemented in beta.9:** Hide controls, H to restore controls, Escape to exit. No invisible mouse-blocking panel. |
| Vignette | Narcissus changes the alpha of vignette textures; LumenShift already renders edge textures. [N2] | Build a photo-specific soft oval vignette with strength, size, feather and movable center. Current edge darkness is simpler; do not relabel it as a finished lens vignette. |
| Warm/cool and colored looks | Narcissus uses a colored additive screen overlay. Texture blending is declared in the Forever API. [N3, F2] | Live tint/color/strength controls, authored Warm Ember, Cool Night and Soft Portrait recipes. These are screen treatments, not calibrated white balance or a 3D color-grading LUT. |
| Brightness, contrast and sharpening | Existing LumenShift controllers already handle these named native settings; the native sharpness slider reverses its CVar mapping. [F1] | Put the controls in the photo editor using existing native bounds/policies and one writer. Commit native edits on slider release; no setter spam on each mouse-move event. |
| Native bloom / glow | The native UI offers `bloomUserMult` from 0 to 1 only when `IsLinearEnabledOnStart()` is true. [F1] | Offer a renderer-dependent whole-scene bloom slider through the existing optical policy. It can emphasize eligible bright material effects, but must be visually tested on an actual fire. At the current supported maximum it may offer no further brightening. No arbitrary higher values. |
| Local campfire glow | UI texture blending can add a soft colored sprite over a selected screen position. [F2, N3] | A separately labeled **Glow accent**: drag its center and adjust size, softness, color and strength. It is decorative 2D light; it cannot illuminate terrain/characters, respect depth automatically or follow a flame by itself. Keep it static/optional for photos. |
| Film grain and light leaks | Texture opacity/tiling/blending can produce decorative overlays. [F2] | Original static grain and soft light-leak assets with strength/scale. No frame-by-frame noise loop required. Screen treatment, not actual camera-sensor simulation. |
| Framing | Existing FOV uses native-reported bounds; aspect/thirds guides already exist. [45](45-DEV16-CAMERA-AND-PERFORMANCE.md) | Bring FOV, thirds and aspect choice into the in-scene editor. Guides disappear in clean view; optional letterboxing remains a deliberate output effect. Aspect guides alone do not crop the exported image. |
| Model stage lighting | Narcissus directs its light API calls to model frames/model scenes. Forever's ModelScene API declares light direction, color, position and visibility. [N2, F3] | A later optional **Portrait Stage** can pose/light a separately rendered model. These APIs are not a way to move the live world's sun or attach a real point light to a world campfire. |
| True scene desaturation, LUTs, curves, selective color, bokeh/DOF | Texture desaturation affects that texture; ModelScene desaturation affects its scene. The reviewed APIs expose no general capture of WorldFrame color/depth buffers or arbitrary postprocess shader. [F2, F3] | **Unsupported by the reviewed addon API surface**, not an assertion about all external software. Do not promise a gray overlay as true black-and-white, or a blurred overlay as depth-aware bokeh. External postprocessing remains a separate workflow. |
| Editing an existing saved screenshot | Native screenshot APIs capture the scene; no reviewed addon API opens arbitrary saved image files for editing. | This is an in-game composition tool. Cropping/retouching an already saved image belongs in the user's screenshot editor. |

`bloomEnable`, `ffxGlow`, `ffxDeath`, `ffxNether` and HDR fields appear in the older Forever 70532 inventory, but that does not prove current writable domains or their rendered effects. `bloomEnable` and `ffxGlow` are already diagnostic research keys. Do not toggle death/nether effects or hardware HDR settings as a shortcut to photographic filters. See [the wider inventory and distinctions](39-GRAPHICS-CONTROL-LANDSCAPE.md).

## Proposed in-scene editor

Use a compact movable side panel over the world, with the scene taking most of the screen. Keep the LumenShift dark-steel/teal hierarchy. Three groups are enough initially:

1. **Look:** Neutral / Warm Ember / Cool Night / Soft Portrait, strength, tint, vignette strength/size/feather/center, grain and Reset look.
2. **Light & Detail:** Brightness, Contrast, supported Bloom and Sharpness. A separate Glow accent section has color/strength/size and a draggable screen position. Tell the user when a control affects the whole scene or is decorative.
3. **Frame:** Field of view, thirds, frame guide/letterbox and optional photo quality. Retain independent manual name choices.

Keep **Before/After**, **Capture**, **Hide controls** and **Exit** consistent. H restores controls without a persistent overlay/hotspot contaminating the shot. Escape exits from both editing and clean view. External capture keys must pass through normally. Do not simulate OS shortcuts or try to detect every screenshot application.

For a campfire portrait: choose Warm Ember, increase the soft vignette, add modest warmth, adjust contrast and native bloom if available, then optionally place a subtle amber glow accent near the fire. The exact visual balance should be tuned in the owner's scene; these are proposed controls, not claimed optimal numeric presets.

### Configuration and restoration

Photo styling needs its own data and live preview rather than overwriting the six saved visual modes. Photo native intent should resolve above the current visual/quality requests using their canonical per-key originals, not start a second owner for Brightness or sharpening. Exit removes photo intent and restores the appropriate prior composition while preserving external edits. Keep a transaction snapshot of the pre-photo intent; uncertain native failures retain the existing recovery record.

Overlay sliders can preview immediately without native writes. Native sliders commit bounded transactions on release with current readback. Add Save photo look / Reset photo look and a versioned data-only photo preset format when the editor is implemented. Routine edits need no token/approval ritual; unavailable optional features affect their own control. Keep startup/reload free of automatic graphics writes. Capture still distinguishes native completion events from a timeout; an OS capture has no native completion result to certify.

### Delivery order and acceptance

- **This update:** clean view and Escape, with lifecycle/input tests and a diagnostic state field.
- **Next photo-editor delivery:** in-scene panel, photo-specific vignette/tint/grain, live strength sliders, Before/After and independent photo looks. Acceptance: visible adjustments while composing; hidden controls stay hidden through resizing/capture; exit removes temporary styling and preserves the selected mode.
- **Native light/detail integration:** reuse native brightness/contrast/optics/FOV controls and resolver ownership. Acceptance: exact pre-photo return, missing-feature isolation, conflicting external edits preserved, no writes at startup or every drag tick, scene comparison at the campfire.
- **Optional creative expansion:** original glow/light-leak artwork and eventually Portrait Stage with model-only lighting. Acceptance: clearly distinct world versus model behavior, asset provenance, no unsupported world-lighting claim.

This is an implementation sequence, not a new blanket permission gate. The current task asks to research photo features; the larger editor remains a proposed next scope. No model stage or new graphics writer was added by this fix.

## Implemented clean view and Escape

`UI/Composition.lua` now separates visible controls/guides from a pixel-free, mouse-transparent keyboard frame. The keyboard frame is active only during Camera Mode outside combat, including during a clean view or pending native screenshot. Escape invokes the existing `camera.Exit()` path; it shows the HUD first and restores Camera-owned names/FOV/photo settings under the existing conflict policy. It cancels a queued screenshot; a request already issued to the game can only finish, not be recalled.

Hide controls or H hides the complete bar, guides and its tooltip while retaining the chosen scene effects. H reveals them again. No timer or cursor hotspot automatically reveals them. Native screenshot completion/layout refresh does not undo clean view. Exit/re-entry starts with controls visible; clean view is session-only, with no schema change. Combat reveals the HUD and hides the input frame without graphics restoration.

The existing keyboard helper handles focus, per-key propagation and errors. Empty navigation frames now pass Tab through. A small failure callback returns visible Exit controls if keyboard handling becomes unavailable; the ordinary Capture/Exit buttons remain usable. Print Screen, Alt and movement keys are not intercepted. Native input priority and external capture remain owner-tested behaviors, not proven by mocks.

Ten new PHOTO regressions cover clean view with retained effects, exact name/FOV return via Escape, queued and issued capture exit, late events/display changes, chat focus and paired-key propagation, missing/failing keyboard fallback, combat/reload/re-entry, readable export and toolbar fitting. Final validation: **451/451 Lua 5.1 mock tests**, syntax for **67 Lua files + four binding bodies**, structural checks for **45 runtime modules**, **10/10 packaging tests**, **116 current local documentation links** and whitespace checks passed. Native keyboard priority, actual external screenshot contents and restoration on the owner's client remain to be observed. No game installation/operation, merge or CurseForge publication occurs in this update.

## Sources

- **N1 — project author:** [Narcissus project and feature description](https://www.curseforge.com/wow/addons/narcissus), accessed 2026-11-09. It now lists Forever, but that does not certify every module on the owner's client. The project page labels its distribution Custom License.
- **N2 — pinned Narcissus implementation:** [PlayerModel.lua](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/PhotoMode/PlayerModel.lua#L523), model-light calls around 523–543, darkness/vignette around 1476–1492; [PhotoMode.xml](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/PhotoMode/PhotoMode.xml#L3063), vignette slider; [LightingPreset.lua](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/PhotoModeNew/LightingPreset.lua), saved lighting controls. These prove author implementation, not a compatible API for modifying world lights.
- **N3 — additive screen treatment:** [CameraEffect.lua](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Filters/CameraEffect.lua#L8), color and additive overlay; [Toolbar.lua](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/ScreenshotTool/Toolbar.lua#L1091), native screenshot-start toolbar hiding. OS screenshots need the separate clean view.
- **F1 — Forever 70862 UI mirror:** [Graphics.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua), native FOV, reversed sharpening and conditional 0–1 bloom controls.
- **F2 — Forever 70862 texture API:** [SimpleTextureBase API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua#L383), texture blend/desaturation scope; [SimpleTexture API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureAPIDocumentation.lua), texture masks.
- **F3 — Forever 70862 model and input APIs:** [ModelScene frame API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameDocumentation.lua#L488); [SimpleFrame API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua#L1426).

No Narcissus code or artwork is copied. Its repository [LICENSE at the inspected pin](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/LICENSE) is MPL 2.0; the distribution's Custom License label and asset terms must not be conflated with permission to reuse every bundled asset. LumenShift's split licensing remains unchanged.
