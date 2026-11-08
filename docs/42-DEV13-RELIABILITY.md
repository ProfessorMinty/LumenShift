# Delivery 1 — reliable switching and presentation

**2026-11-08 · 0.2.0-dev.13 · Northern Lights Labs**

Implements Delivery 1 of the [implementation plan](41-IMPLEMENTATION-PLAN.md) on `feat/beta-integration`, PR #5. This is an interactive development build. It adds no new sharpening, AO, shader or graphics-tier targets. The shared optical resolver and stronger Night Vision/Clarity controls remain Delivery 2.

## Player-visible changes

- Brightness and Contrast now form one mode operation. Both originals are captured before the first write. A successful mode is shown only after the complete operation passes a separate readback.
- A failed ordinary apply attempts one bounded compensation pass over freshly matching changes. Successful compensation keeps the previous mode and its applied appearance. An incomplete restore, conflict or late drift shows **Partial / Recovery**, retains originals and does not keep overwriting settings.
- **Diagnostic Center → Restore captured visuals** deliberately restores the exact captured pre-change Brightness and Contrast. It is a direct button action, without a recovery card. Applying **Original / Game Defaults** remains a separate action using the chosen visual reference. The panel shows current and captured values for both settings.
- **Camera → Keep visual effects in Camera** keeps the selected tint, edges and permitted bars visible when the HUD is hidden. It defaults on, is saved, and can be turned off. The existing Camera toggle/keybind and native Alt+Z remain available to show the HUD.
- Combat suspends cosmetic effects. After combat, matching active ownership resumes the previously applied cosmetics without graphics writes or replaying activation audio. External drift keeps effects suspended for recovery.
- Vignette thickness follows the viewport's shorter dimension. Scale/display changes update LumenShift's presentation geometry without moving or resizing the HUD.
- Bloom alone checks the native linear-renderer capability. Missing, false, malformed or failing capability results explain why that control is unavailable. Other pages and mode controls remain usable. Contrast inheritance wording and recovery labels are corrected; existing window dragging, close controls, layering and wheel wrapping fixes remain.

## Implementation and evidence

`WriteBoundary.NewVisual` coordinates only Brightness and Contrast using the existing pure Planner and Recovery modules. It temporarily combines their two existing journal records, preserves original raw strings and writes results back without replacing quality records. It does not implement a second native setter: `nativeSet` remains the sole native CVar call site. Legacy Brightness, experiment, name and native-bank operations cannot interleave with a pending visual transaction, including getter callbacks during preflight.

The coordinator checks identity, availability, flags, combat and fresh expected values before writes; records intended values before the first call; and verifies the complete outcome on a later timer turn. The 0.15-second interval provides a separate observation, not proof of renderer settling. Unexpected watched side effects or external changes stop further writes. Only immediate ordinary-apply failures qualify for bounded compensation; explicit recovery failures and uncertain reload/conflict state do not automatically reapply values. A failed compensation retains originals for all participating members until a later explicit recovery succeeds.

Presentation uses an addon-owned, unprotected frame whose parent is cleared out of combat. It remains anchored/scaled to UIParent while its visibility is independent. UIParent visibility hooks respect the saved Camera preference without replacing foreign handlers or reparenting other addons. No polling loop or CVar animation is introduced. This design is **source-confirmed for the named API, simulated for behavior, and not yet visually verified in-client**.

Source references inspected 2026-11-08, pinned Forever 70862 UI mirror commit `9dc84f0d3bbae1768ac3405b3716000bd93eda06`:

- [SimpleScriptRegion API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScriptRegionAPIDocumentation.lua): `SetParent` accepts a nil parent and is marked a protected attribute. Construction/reparenting is limited to LumenShift's own unprotected frame, outside combat.
- [Native graphics settings](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua): the bloom multiplier slider is conditional on `C_VideoOptions.IsLinearEnabledOnStart()`. A true result admits a bounded attempt; it does not prove a visible bloom effect.
- [Prior audit and evidence](38-MODE-AUDIT-AND-OPTICS.md): reproductions of the composite, hidden-HUD, combat-resume and bloom findings on dev.12. Its other optics proposals remain separate future work.

Schema **8** adds the boolean `camera.keepEffects`. Migrations preserve setup completion, visual/quality preferences, chosen baseline, personal presets, graphics banks and all recovery records. Old Camera settings default to keeping effects; migration and startup do not activate them or write settings. Existing SavedVariables are not immediately durable or crash-proof.

## Validation

**Simulated, not native game acceptance:**

- `python tools/check.py --mocks --lua-runtime ../lua-test-runtime`: **284 Lua 5.1 tests passed, 0 failed**. Syntax: **46 Lua files and four binding bodies**. Structural: **35 runtime modules**, exact TOC/module order and version consistency, one native CVar call site.
- `python -m unittest discover -s tests -p test_package.py -v`: **9 tests passed**. Covers deterministic bytes, manifest/build identity, content hashes, one install root, license/asset provenance and rejected unsafe/inconsistent archives.
- New R01–R16 regressions cover complete capture, exact restore, compensation and preserved applied appearance, clamping, partial rollback, external edits, delayed drift, interleaving, reload, timer/combat interruption, failed explicit recovery, no-setter release, Camera visibility/preferences, cosmetic resume without writes/audio, viewport scale, bloom capabilities and schema migration. Existing startup/diagnostic no-write, independent quality, dragging and long-label checks still pass.
- Recorded Lua widget geometry was rendered locally for an **off-client** review of Visual Modes, Camera, Diagnostic Center, Setup and the wheel. The added Camera preference/help and two-setting recovery rows fit without overlap in this model. Substitute fonts, simplified texture rendering and mock anchors cannot establish native font metrics, strata, protected-frame behavior or inter-addon compatibility. No browser or game execution is involved in the static render.

No game installation, native graphics change, FPS benchmark, merge or CurseForge publication was performed for this delivery. Existing owner native Brightness evidence remains valid for those earlier tests; it is not relabelled as dev.13 acceptance.

## Install and check with buttons

1. Exit WoW. Back up the previous addon folder, retaining SavedVariables. Extract the development ZIP and copy its entire **LumenShift** folder into the Forever installation's `_forever_/Interface/AddOns`. The TOC should be directly at `LumenShift/LumenShift.toc`, alongside Core, UI, Media and Bindings.xml. Do not put the ZIP itself into AddOns or copy only the TOC.
2. Log in. Graphics should stay unchanged; completed setup should remain completed. Right-click the launcher/minimap button for Studio. Diagnostic Center's export should identify **0.2.0-dev.13** and include the archive's source commit.
3. In Visual Modes, apply **Night Vision**, then **Original / Game Defaults**. To exercise the composite path, use your existing custom Contrast setting, or enable **Custom Contrast** and choose a nearby value before Apply. Both values should finish together; the active mode must agree with the scene. Diagnostic Center displays the current and captured originals. **Restore captured visuals** returns to the first pre-change values, which can differ from Game Defaults.
4. With Night Vision and screen effects enabled, open Camera and leave **Keep visual effects in Camera** on. Toggle Camera: the HUD should disappear while the chosen effects remain. Use Alt+Z to bring the HUD back, then the Camera toggle to finish Camera/name restoration if names were included. Repeat with the preference off; the effects should hide with the HUD and return when it is shown.
5. Observe an ordinary combat entry/exit with an active mode: cosmetics suspend and resume, while Brightness/Contrast remain unchanged and the activation sound does not replay. If another addon/user changes a value, LumenShift must preserve it and show recovery instead of fighting it.
6. Reopen setup, leave both graphics banks on **Keep current**, then **Finish & Reload UI**. Saved preferences remain; reload does not reapply graphics or cosmetics. A new explicit mode click continues freshly matching completed ownership. Failed/pending/conflicting ownership retains its recovery action.

If something fails, use **Diagnostic Center → Export Complete Diagnostic Report**. Keep saved originals. Native Camera visibility/Alt+Z coexistence, combat rendering, bloom's actual appearance, font wrapping and transaction behavior on the installed client remain owner observations to collect; no launcher-version reconfirmation or calibration unlock is required.
