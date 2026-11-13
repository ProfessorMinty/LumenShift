# In-scene Photo Studio — beta.10

2026-11-09 · Northern Lights Labs. The owner authorized the complete in-scene photo editor following [the reference review and API research](53-PHOTO-MODE-RESEARCH-AND-CONTROLS.md). Portrait/model staging remains deferred. This document records implemented behavior, not a new approval gate.

## What ships

Camera opens a movable dark Photo Studio panel beside the world. Four tabs keep controls separate; long pages scroll with the mouse wheel or visible scrollbar. The fixed footer provides Before/After, Reset photo look and operation feedback. The bottom bar retains Capture screenshot, Hide controls and Exit Camera Mode. H hides/reveals all editor chrome, guides and glow handles. Escape exits through normal restoration, including after an already-running native edit finishes. Clean view also releases focus from the editor's text fields, without clearing another addon's chat focus.

| Tab | Implemented controls |
|---|---|
| Look | Neutral, Warm Ember, Cool Night, Soft Portrait; overall strength, warmth and green/rose tint; oval vignette strength, size, feather and horizontal/vertical center; glow strength, size, softness, RGB color, Amber/Ice/White swatches, draggable center and numeric position; grain strength/scale |
| Light | Current native Brightness, Contrast, reversed Sharpness and renderer-dependent Bloom; apply once on mouse release or numeric Enter; Restore photo lighting; readable pre-photo values |
| Frame | Thirds, none/16:9/2.39:1/square guides, output letterbox height, native-bounded FOV and Restore FOV; friendly-name and optional photo quality preferences for the next Camera entry |
| Saved | Up to 12 named photo looks, save/replace, load, delete and validated data-only LSPHOTO1 copy/paste transfer |

Photo looks contain styling only. They never change the six saved visual modes, graphics quality choices or a later session's native lighting automatically. Neutral retains the selected mode's existing presentation; an applied photo treatment replaces that cosmetic presentation while composing. Before compares the pre-photo lighting and prior mode styling (framing/FOV stay in place); After returns the edited photo. Exit removes photo cosmetics and restores the underlying mode presentation. Reset photo look resets styling; Restore photo lighting separately returns native edits. Names/photo quality choices are explicitly labeled for the next entry; FOV and look controls act in the current composition.

These filters use screen textures. Warmth/tint are not calibrated white balance or a LUT. Glow accent is additive two-dimensional decoration, with no depth occlusion, tracking or actual world illumination. Bloom uses the existing 0–1 renderer-dependent policy, not arbitrary higher values. Guides do not crop files; letterboxing visibly draws bars. Grain is static, without a recurring update loop. Existing screenshot files are not opened/retouched by the addon. No 3D model stage, world shader, DOF, custom sun or unsupported camera light is claimed.

## Architecture and restoration

- `Core/PhotoConfig.lua` defines finite bounded photo look data, four original recipes, 12-slot validation and the strictly parsed LSPHOTO1 format. No scripts or arbitrary keys are accepted.
- Schema **13** adds `camera.editor` with data version 1. Earlier schema migrations retain preferences, completion, presets, graphics originals and independent name return intent. Existing installations do not need a reset or new setup.
- `Core/PhotoEditor.lua` owns the editing session. Native keys join only when explicitly edited, after fresh capability/value reads. `session.before` is the **pre-photo return intent**, not a competing ownership journal; `after` and `expected` track verified photo values. The canonical original remains in `db.journal` or `db.experiments.journal`.
- `WriteBoundary.NewVisual.Photo` uses the existing planner, canonical per-key originals, single native call, immediate and scheduled readback, compensation and conflict detection. A subset limits participation to explicitly edited keys; missing unedited Contrast/Bloom does not block Brightness. Saved optical mode/quality/reference intent is not replaced by temporary photo intent. No other writer was added.
- Native sliders change only their local numeric draft during dragging. Mouse release or Enter requests one bounded transaction. A late release after hiding/exiting cannot apply FOV or lighting. Comparison and Exit return exact pre-photo strings; an unexpected normalization cannot silently count as exact restoration.
- Exit returns unaffected keys and retains records for external changes or failed/uncertain operations. It shows the HUD first. A pending photo edit can finish its existing verification, then honors the owner's Exit request; combat never queues a graphics restore. Reload retains data without applying/restoring graphics or opening the photo editor automatically. SavedVariables is not immediately durable.
- `UI/PhotoEffects.lua` renders the independent tint, soft oval, additive glow, grain and letterbox root. It remains visible with HUD and editor chrome hidden, and clears on exit/combat. Missing effect APIs return usable Camera controls. `UI/PhotoEditor.lua` builds the panel using pooled widgets, bounded scrolling and a mouse-only glow handle.
- Diagnostic export includes numeric look fields and pre-photo/edited/expected/current native values, without personal look names or transfer text.

The source-confirmed texture blend, wrapping and texture-coordinate API surface is the pinned [Forever 70862 SimpleTextureBase declaration](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua). The wider source findings and limits remain in [53](53-PHOTO-MODE-RESEARCH-AND-CONTROLS.md). Source declarations and mocks are not native rendering evidence.

## Assets and performance

`tools/create_photo_assets.py` deterministically produces original soft radial alpha textures (128×128 vignette, 64×64 glow, 11 feather levels each) and 128×128 static grain. All are uncompressed power-of-two 32-bit TGA, with hashes in the manifest and the existing original-asset license. Native bilinear sampling handles enlargement; actual smoothness on the owner's display remains a visual acceptance check. This uses original analytic geometry/noise, not Narcissus artwork or generated substitutes for supplied branding. Runtime texture payload remains under the existing 8 MiB packaging limit. Rendering updates only on deliberate edits/display changes, with no permanent frame-update callback.

## Owner test — no commands required

1. Close WoW, replace the whole addon folder with the beta.10 ZIP's `LumenShift` folder, and keep SavedVariables. Start the game. Confirm beta.10 in the report/build information; no setup reset is needed.
2. Click the LumenShift launcher, then **Camera** on the wheel. The Photo Studio panel should appear beside the world. Drag its title to move it; scroll Look to reach Vignette, Glow and Texture.
3. At a campfire, choose **Warm Ember**. Adjust warmth and vignette darkness/size/softness. Increase Glow strength slightly, select Amber, and drag the + to the flame. Adjust size/softness and grain to taste. This screen glow will move with the screen, not follow the fire.
4. On **Light**, note current values, drag Brightness/Contrast a little, and release. Check the scene and reported result. Try Sharpness and available Bloom; unavailable Bloom should explain itself while other controls remain usable. Use **Show Before / Show After** to compare.
5. Try Frame guides, FOV and letterbox. Save a named look on Saved, reset the photo look, then load it. Confirm these edits did not change a visual-mode preset.
6. Click **Hide controls** or press **H**. All panels, guides and the glow + must disappear while styling remains. Use your screenshot program or Alt+Print Screen. Press H to return, or use Capture screenshot for the native screenshot flow.
7. Press **Escape**. HUD/names return, temporary lighting/FOV/photo quality return to the appropriate prior values, and the photo overlay disappears. Re-enter to confirm the saved style is available without auto-applying native lighting values. Restore Camera changes remains available from Studio after reload.
8. Export diagnostics if an edit, comparison or return fails; include the visible result. Do not delete recovery records to hide a failure. Test external-change/reload failure scenarios deliberately, rather than inducing a crash.

## Validation record

Final frozen-source checks: **477/477 Lua 5.1 mock tests**, including **26 PE photo-editor regressions**; syntax for **72 Lua files + four binding bodies**; structural checks for **49 runtime modules** and one native write call; **10/10 Python packaging tests**; **121 current local documentation links**; asset hashes and whitespace checks passed. The TGA payload is **7,902,192 bytes**, below the existing 8 MiB budget. Four off-client panel tabs were rendered and inspected; these models cannot certify native pixels or input. The new PE regressions cover schema migration, pure look bounds, preview/write separation, numeric Enter, exact native return, canonical optical ownership, comparison, missing APIs, external conflicts, rejection/clamping, reload, clean capture, Escape while verifying, transfer validation, scrolling/small screens, draggable glow, combat, text focus, failed effect APIs, diagnostics privacy hidden-slider release and no-setter release after the owner fallback returns a canonical original. All actual beta.10 in-client image appearance, decoding, input priority, smoothness/performance and combined restoration acceptance remain **NOT RUN** by the development tools. No installed game files/settings, main branch, merges or CurseForge publication are changed.
