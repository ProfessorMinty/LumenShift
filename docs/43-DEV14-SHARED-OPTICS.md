# Delivery 2 — shared optics, Night Vision and Clarity

**2026-11-08 · 0.2.0-dev.14 · schema 9 · Northern Lights Labs**

This implements Delivery 2 of [the implementation plan](41-IMPLEMENTATION-PLAN.md) on `feat/beta-integration`, PR #5. Delivery 1 was first rechecked at `61d21f5a08f8e5752955f381293de589b5e2c732`: its complete 284-test Lua 5.1 suite passed again. Those reliability, Camera, combat-presentation and bloom-capability regressions also pass in the expanded suite below. Implementation and simulated acceptance of both deliveries are complete; new native image-quality and UI acceptance remain unobserved. Deliveries 3–5 are not included in this increment.

## Player controls

Studio → Visual Modes now has **Detail**, **Style**, and **Before / After** sections below Light & Contrast. Editing saves preferences without changing graphics; the fixed **Apply** button applies the edited mode. Controls retain their scroll position when rebuilt.

| Control | Actual behavior |
| --- | --- |
| Inherit quality | Releases this mode's optical request and uses the current underlying detail-profile request, or the captured original when no quality request remains. |
| Off (extra) | Requests `ResampleAlwaysSharpen = 0`. Does not change render scale/upscaler or claim that upscaler-provided sharpening is off. |
| Custom detail | Requests `ResampleAlwaysSharpen = 1` and `ResampleSharpness = (100 - detail) / 50`. The UI is 0–100 in steps of 5; raw strength is 2–0 in steps of .1. Higher UI detail means stronger sharpening, not a measured improvement percentage. |
| Custom bloom / glare | Opt-in `bloomUserMult`, 0–1 in .2 steps. Lower requests less bloom; visible effectiveness depends on scene and renderer. The local native linear-renderer capability condition applies only to this option. |
| Clear / Goggles | Clear retains native visual changes and removes tint, vignette and letterbox. Goggles uses the existing optional Night Vision styling. Other modes call this Styled. The global Screen effects preference still applies. |
| Use return-look brightness | Uses the chosen Original/Game Defaults brightness, or releases to the exact original when no reference is chosen. The custom brightness slider is used when this toggle is off. |
| Before / After / Finish comparison | Performs sequential, verified changes in the actual scene. Before is the chosen visual reference plus underlying quality; After is the last applied native look. Finish returns to After. No split-screen world shader or animated CVar writes. |

Night Vision keeps Brightness 75 as its existing starting target and offers meaningful native detail independently of styling. New or explicitly reset Clarity settings inherit return-look brightness, use Clear styling and leave bloom/detail overrides off until chosen. Upgrades preserve existing customized modes, including old Clarity brightness and styling. Select **Use return-look brightness**, **Clear**, and your desired detail to update an existing Clarity look; a reset deliberately replaces its saved edits.

Resolution, antialiasing, filtering and native quality levels are not changed by these mode controls. This delivery does not create dark world outlines, thermal imaging, new scene lights or a shader pipeline.

## Shared ownership and operation ordering

`Core/Optics.lua` is a pure resolver for exactly three shared keys: `ResampleAlwaysSharpen`, `ResampleSharpness`, and `bloomUserMult`. `db.optics.visual` and `db.optics.quality` hold independent numeric requests. Explicit mode requests take precedence. Missing mode requests reveal quality requests; absence from both releases ownership to the original.

Each optical key has **one canonical physical recovery record in `db.experiments.journal`**. No separate visual original is persisted. The visual coordinator creates a temporary planner view of the participating records, then writes results back to that canonical location. Unrelated quality keys are retained. Brightness remains in its original journal; Contrast remains in the experimental journal. `Core/WriteBoundary.lua` still contains the single native CVar call site. Every optical apply, comparison and restoration goes through Planner/Recovery, fresh capability/value/conflict checks, capture before write, immediate readback and separate verification.

Example tested: original sharpness `1.000` → quality `.4` → Night Vision `.2` → quality preference `.7` while the effective value stays `.2` → leave Night Vision and reveal `.7` → release quality and restore **`1.000`**. These are regression values, not recommended defaults. Inverse ordering and no-setter release are also covered. Quality changes never recapture a mode value as the original.

Native normal/raid recipes do not directly request these three keys in the current source-backed mapping. Their operations serialize with mode/detail operations and watch the optical keys for unexpected side effects; they neither duplicate optical originals nor invent RAID variants. A detected side effect stops the operation and preserves the changed value for explicit review. Known non-optical overlaps between native-bank recipes and detail profiles retain the existing restore-first rule. This is not a claim that all renderer dependencies have been discovered.

## Comparison and recovery

Comparison stores bounded allowlisted before/after/expected raw snapshots and a pending/before/after/recovery state. The first pre-change originals stay in the canonical journal. After changing a setting, both immediate and subsequent fresh reads must match; an extra final snapshot cannot adopt an external edit as the expected endpoint.

- Mode, detail-profile, native-bank and temporary trial writes cannot interleave a comparison. Finish it with the visible button before changing those selections. Merely editing saved preferences remains read-only.
- Before hides mode cosmetics. After restores the last applied cosmetic settings, even if the editor changed in the meantime. No activation sound is replayed by comparison.
- Successful compensation returns the known prior look. Failed/clamped/uncertain changes retain originals and report recovery; they do not falsely report Original.
- External changes are preserved. Finish abandons a conflicted comparison without replaying After over them. Captured originals remain available for deliberate recovery.
- Startup and reload never replay a comparison or write graphics. An explicitly requested Finish can complete a saved, matching comparison; pending or conflicting data is not replayed automatically. Reload does not invent knowledge of an active cosmetic mode.

**Normal return mode versus full recovery:** Original/Game Defaults removes mode requests and reveals the latest quality requests. **Diagnostic Center → Restore captured visuals** deliberately restores captured Brightness, Contrast and the three optical originals, clearing both visual and quality optical requests. Other quality settings and saved mode/profile edits are retained. The UI explains this scope. This recovery action may deliberately replace an external current value; ordinary switching/comparison does not. It is not a whole-game reset.

SavedVariables are not immediately durable or crash-proof. No new automatic restore/reapply behavior is introduced.

## Schema and presets

Schema 9 migrates supported schemas 1–8, preserving setup completion, chosen reference, preferences, personal presets, native-bank records and exact originals. New fields default to inheritance or disabled overrides. For existing optical ownership, migration derives the quality request from the valid last verified value while retaining the original record unchanged; failed/pending records remain recovery data, not permission to write. Invalid state is quarantined read-only.

Personal Presets now exports/imports a bounded **LSMODE2** string containing the mode's validated typed fields. No Lua, arbitrary CVar names, paths or player/account identity is evaluated/imported. Imported settings become a new saved variation without changing the scene. Applying it uses the ordinary mode resolver. Export highlights the full copyable value; the transfer field permits 2048 characters instead of the ordinary name field's 64-character limit. Quality configuration and recovery originals are not embedded in a mode preset.

Reports distinguish visual requests, quality requests, effective requests, current observations and recovery originals. A requested value is not proof of a visible effect.

## Evidence for numeric/API choices

Source reviewed 2026-11-08, retained from the pinned research in [38](38-MODE-AUDIT-AND-OPTICS.md) and [39](39-GRAPHICS-CONTROL-LANDSCAPE.md):

- **Source-confirmed, Forever 70862 mirror:** Blizzard-authored [Graphics.lua, lines 1538–1561](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua#L1538) defines raw sharpness 0–2 in .1 steps with a reversed slider. Its bloom option uses the `C_VideoOptions.IsLinearEnabledOnStart()` condition. These establish implementation choices, not native visual acceptance.
- **Historical native metadata, Forever 70532:** [CVars.lua](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/CVars.lua) and [native strings](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/GlobalStrings/enUS.lua#L15635) describe sharpening outside FSR and the enable switch. Off is therefore labelled **Off (extra)**, not total sharpening removal. Historical sentinels and unbounded community values are not admitted.
- **Prior owner evidence:** [38](38-MODE-AUDIT-AND-OPTICS.md) records readable optical values on 70862, while earlier Brightness round trips remain in [28](28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md). Neither establishes this build's composite optical effect or performance.

## Validation actually run

All results below are **simulated/off-client**, not native game tests:

- `python tools/check.py --mocks --lua-runtime ../lua-test-runtime`: **314 passed, 0 failed**, Lua 5.1. Syntax: **49 Lua files plus four binding bodies**. Structural: **37 runtime modules**, matching TOC/module order and versions, one native CVar call site.
- `python -m unittest discover -s tests -p test_package.py -v`: **9 passed**. Deterministic archive bytes, source/build identity, hashes, install root, licensing/provenance and invalid archive rejection.
- New O01–O28 cases exercise composition in both orders, exact originals, steps/bounds, missing APIs, clamping, compensation, drift/conflicts, reload, serialization, no-setter recovery, migration/quarantine, preset round trips and actual Studio handlers. Native-bank N31–N32 cover coexistence and unexpected optical side effects. Delivery 1's R01–R16 and all earlier tests remain included.
- Recorded Lua UI geometry was rendered offline for Detail/Style, Before/After and preset transfer. Controls fit the scrolling region and comparison handlers preserve scroll position. This uses approximate fonts/textures and does not reproduce native strata, focus, protected frames or inter-addon rendering. No game or browser execution was used for this static inspection.

The development ZIP is built from the clean committed source with `tools/package.py`, with manifest/source identity, hashes and repeatability checks. No installed-game operation, native graphics test, FPS claim, merge or CurseForge publication is part of this delivery.

## Install and try it with buttons

1. Exit WoW. Back up the previous addon folder and keep SavedVariables. Extract the dev.14 ZIP. Copy the **entire extracted LumenShift folder** into the Forever installation's `_forever_/Interface/AddOns`, replacing the prior addon folder. `LumenShift/LumenShift.toc` must sit beside Core, UI, Media and Bindings.xml. Do not install the ZIP itself or only its TOC.
2. Log in; graphics should remain unchanged and completed setup should remain completed. Right-click the launcher/minimap button to open Studio. Diagnostic Center's report should say **0.2.0-dev.14** with the archive's source commit. No launcher-version reconfirmation is needed.
3. Select **Visual Modes → Night Vision**, scroll to **Detail**, choose **Custom**, and choose a detail amount. A middle setting is a comparison starting point, not a hardware recommendation. Select **Clear** to judge native detail without tint, then click **Apply Night Vision**. Wait for the checking message to finish. Inspect foliage, thin edges and terrain while stationary and moving; reduce detail if halos or shimmer worsen.
4. Scroll to **Before / After**. Alternate the buttons, waiting for each check. Before should show the return look and underlying quality; After should return to the applied look. **Finish comparison** returns to After. Select Goggles and Apply to compare the optional styling separately.
5. Select **Clarity**, enable **Use return-look brightness**, select **Clear**, and choose Custom detail. Enable Custom bloom / glare only if available and desired; use Before/After to judge it. Missing bloom support should leave the other controls usable when bloom is off.
6. Finish comparison, then select and apply **Original / Game Defaults**. The latest underlying quality sharpening should return. Use **Diagnostic Center → Restore captured visuals** when you instead want the exact captured visual/optical originals. This also clears optical quality requests, while other quality settings and saved edits remain.
7. Optional composition check: apply a detail profile, then a custom-sharpness mode; change the detail profile while the mode is active; return to Original/Game Defaults. Compare report requests/current values with the intended precedence. Finally use Current Baseline for remaining quality restoration or the explicit captured-visual recovery as appropriate.
8. Save a personal variation, click its **Export**, copy the highlighted string, and **Import preset** with a new name. Import must not change graphics. Apply the imported variation to exercise the same resolver. Reload afterward: saved choices remain, with no startup graphics write or automatic comparison replay.

If anything fails, preserve the originals and use **Diagnostic Center → Export Complete Diagnostic Report**. Remaining native observations include sharpness/glare appearance and performance, true API/setter behavior, comparison in motion, normal/raid dependency effects, native font/scroll/focus behavior and coexistence with other addons. Existing version/build warnings remain nonblocking; there is no calibration unlock or new confirmation-card requirement.
