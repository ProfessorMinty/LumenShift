# Delivery 3 — distinct looks and optional contact depth

**2026-11-08 · 0.2.0-dev.15 · schema 10 · Northern Lights Labs**

This continues [the agreed implementation plan](41-IMPLEMENTATION-PLAN.md), after a source audit and fresh test run of Delivery 2 at `8cd01a097d7dd9b3cb108e43ba0bbd232f26b3fb`. Work remains on `feat/beta-integration`, PR #5. No installed-game changes, live graphics tests, merge or publication were performed. Deliveries 4–5 remain separate future work.

## Delivery 2 audit and corrections

The unmodified dev.14 suite passed **314/0** under Lua 5.1. Review traced mode/detail requests through the pure resolver, the canonical optical journal, comparison snapshots, restoration and the single native setter.

- **Corrected:** an already-original bloom record could not be released when the linear renderer became unavailable, even though no setter was needed. Capability admission now applies to actual planned writes, while no-setter release still requires safe observations and valid ownership. O29 reproduces and tests this case. The isolated audit/fix run passed **315/0** before Delivery 3 work.
- **Corrected during integration:** Product's redundant Contrast preflight used the experimental controller's entire recovery state, allowing an unrelated failed quality experiment to veto a valid visual transaction. The shared writer now owns that preflight, preserving Contrast step checks. Observation checks the Contrast record itself instead of treating unrelated quality recovery as a Contrast failure. T22 verifies that the unrelated original and recovery status remain intact while a valid mode applies.
- Existing one-owner precedence, exact raw restoration, conflict preservation, comparison verification, no-startup-write and old-preset behaviors remain covered. Unavailable unowned mode optics now have the explicitly disclosed preflight omission behavior described below; failures after writing starts still fail/compensate the transaction.

## Distinct starting looks

Studio → Visual Modes → **Starting Look** offers two authored variations for each active mode. Selecting one replaces that mode's saved editor values without changing the scene. **Apply** performs the change. Save a personal preset first if you want to retain your current edits. Hover a variation for its purpose. Upgrading does not select these variations or replace existing customized modes.

These are **LumenShift-authored starting preferences**, not Blizzard defaults, optimal hardware settings, or native image-quality test results. Numbers below are the targets at full light/style intensity; sharpening detail is an intuitive UI scale, not a measured improvement percentage.

| Mode / starting looks | Light and detail | Presentation and optional changes |
| --- | --- | --- |
| Original / Game Defaults | Chosen Brightness/Contrast reference, with explicit optional optical capture. | No tint/edges; quality preferences retain precedence over the optical reference. |
| Night Vision: Clear vision / Goggles | Brightness 75, detail 70. | Clear vision has no styling; Goggles adds restrained green tint/edges. Both use native detail independently of styling. |
| Clarity: Clean detail / Low glare | Inherit return-look brightness, detail 65. | Clear styling. Low glare additionally requests bloom 0 where available. |
| Cinematic: Atmosphere / Soft film | Brightness 42/detail 55, or Brightness 48/Contrast 58/detail 60. | Gentle amber styling. Soft film optionally requests bloom .6 and saves a .06 framing height; the separate screenshot-letterbox toggle remains required. |
| Lantern: Warm interior / Clear interior | Brightness 65, detail 55 or 60. | Subtle warm styling or a clear view. No world light is created. |
| Moonlight: Cool night / Quiet night | Brightness 55/detail 60, or Brightness 50/detail 55. | Restrained cool styling; Quiet night uses less tint/edge opacity. |

**Light & style intensity** blends custom Brightness/Contrast toward the chosen return reference (or the first captured original/current value when no reference exists). It also scales tint and edge opacity. It never uses the previous mode's target as a new baseline. At zero, light returns to the reference and tint/edges disappear. **Detail, bloom and deliberate screenshot framing remain independent**, as the control explains. Advanced Brightness/Contrast and Colors & Effects adjustments remain available. Effects resume and Before/After use the last applied intensity; they do not scale it repeatedly or write graphics to animate it.

## Explicit optical reference

Setup → Appearance adds **Include sharpening and bloom in return look**, initially off. Original reads valid values, using existing owned originals instead of capturing an active mode's targets. Game Defaults uses valid defaults actually reported by the client. Only the existing three optical keys are captured; unavailable/invalid values are omitted and the setup summary reports the captured count. Saving the choice does not apply it or alter quality selections. Missing optical fields are not silently filled during later mode clicks; recapture deliberately in Setup when desired.

The effective precedence is:

```text
explicit mode optics → current quality request → opted-in return reference → exact pre-change original
```

`db.baseline.values` holds the chosen reference; `db.optics.reference` records the last successfully applied reference request. This request map is needed to release a previously applied reference when the setup choice changes. It is not another recovery journal. Each optical original still exists only once, in `db.experiments.journal`. Disabling the reference, changing quality under a mode, Before/After, and full recovery preserve that first exact raw original.

**Original/Game Defaults** reveals the latest underlying quality/reference choices. **Restore captured visuals** deliberately restores captured Brightness, Contrast and optical originals and clears active optical requests, while preserving the selected reference and saved edits for a future explicit Apply. Other quality settings remain independent. SavedVariables are not immediately durable or crash-proof; reload never reapplies modes, references or uncertain recovery data.

## Optional availability and partial failures

Studio displays unavailable optional sharpening/bloom in its fixed action area before Apply, even if a previous operation had a status message. When an unavailable requested optical key is **unowned**, the mode can apply its available controls; omission is recorded in diagnostics and reported after success. The saved requested setting remains available for a later attempt. Custom sharpening is treated as a pair, so an unavailable member is not silently replaced with a guessed value.

Existing ownership cannot be discarded by omission. If an unavailable setting must be changed/restored from a retained record, the relevant operation still needs recovery. A setter rejection, clamping, dependency change or delayed failure **after writing starts** is a failed/partial operation with compensation and retained originals; it is never relabelled as successful omission. Contrast and Brightness remain fully preflighted. Unrelated failed quality records do not disable valid visual operations.

## Isolated contact-depth experiment

Visual Modes → **Explore contact depth (experimental)** opens Advanced Graphics with **Contact depth (trial)** selected. This is an optional, separate **Test & Restore** operation for `assaoDetailShadowStrength`. It is not automatically added to modes, saved quality profiles or native 1–10 recipes.

- **Source-confirmed historical metadata:** the Forever 70532 [native CVar capture](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/CVars.lua) describes detail AO over 0–5 and warns of reduced temporal stability. The addon intentionally limits this isolated experiment to **0–.5 in .05 steps**. This is an addon trial policy, not a native maximum or proven safe/optimal setting.
- **Source-confirmed selector:** the Forever 70862 [Blizzard graphics UI mirror](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua) exposes separate normal/raid AO selectors. This does not identify the active internal AO algorithm. Sources rechecked 2026-11-08; prior owner observations remain in [38](38-MODE-AUDIT-AND-OPTICS.md).
- **Current runtime admission:** target existence, numeric bounds, flags and normal AO must be readable; normal AO must be enabled. If separate raid settings are enabled, raid AO must also be readable and enabled. This avoids guessing the active bank from instance type. Unsupported context disables only this trial.
- The trial captures the exact original before its only leaf write and uses the existing separate verification/restore flow. Read-only watchers include normal/raid AO selectors and the named radius, multiplier, power, blur and edge controls. Context/neighbor changes preserve external values and retain recovery. It does not write those neighboring settings or claim complete dependency discovery.
- Active implementation, visible contact-depth effect, temporal stability and performance remain **Unknown**. The UI and report say so. A numeric round trip is only a numeric round trip. No world-outline shader or silhouette-darkening promise is made.

Use the existing explicit recovery controls after an interrupted trial. Native-bank changes wait for pending experiments and require unresolved contact-depth ownership to be restored first, because changing the AO tier underneath that trial would change its context. This does not lock the other visual modes. No automatic replay/repair occurs after reload.

## Architecture and data compatibility

`Core/Modes.lua` contains authored variations, pure light/style interpolation, return-anchor selection and read-only optical preflight. `Core/Optics.lua` remains the pure precedence resolver; its reference map is separate from visual/quality requests and canonical originals. Product commits only after the shared writer verifies. No new CVar setter call site or external dependency was introduced.

Schema **10** migrates schemas 1–9 while preserving completion, presets, baseline choice, native banks, requests and originals. Existing modes receive intensity 100, leaving their previous targets and styling unchanged. Return optics stay off for old light-only references. New exports use bounded data-only **LSMODE3**, including intensity; **LSMODE2** imports remain accepted with intensity 100. Invalid references, intensity values, extra keys and executable strings remain rejected/quarantined without graphics changes.

## Validation and remaining acceptance

All new automated/UI results are **simulated/off-client**. Native tests were not performed for this build. The final full Lua 5.1 run reports **340 passed, 0 failed**; the Python packaging suite reports **9 passed**. Changed-document relative links and whitespace checks passed.

- The full Lua 5.1 suite covers all earlier deliveries plus O29 and T01–T25: authored variants, independent quality, interpolation, exact/fractional references, zero-write setup/migration/import, reference priority/removal, comparisons/conflicts, optional availability versus actual failures, bounded AO trials, context drift and explicit interrupted recovery.
- Syntax/structural checks cover **38 runtime modules, 51 Lua files and four binding bodies**, exact TOC/version consistency and one centralized native CVar call site.
- Packaging tests cover deterministic bytes, hashes, source/runtime identity, single install root, asset/license notices and invalid archives.
- Offline recorded Lua geometry was reviewed for Starting Look/intensity, Setup's optical choice and the contact-depth trial. Controls fit in their scroll/window regions. Approximate font/texture rendering does not establish native strata, scaling, focus, taint or other-addon coexistence.

Final observed test counts and archive identity are recorded in the changelog and PR #5. New native sharpness/glare/AO appearance, motion artifacts, performance, UI input/layout and renderer dependency behavior remain to be observed. Delivery 4 Camera/graphics-comparison work and Delivery 5 polish have not begun in this increment.

## Install and use the new build

1. Exit WoW, back up the previous addon folder, and retain SavedVariables. Extract the dev.15 ZIP and replace the **whole LumenShift folder** inside Forever's `_forever_/Interface/AddOns`. `LumenShift.toc`, Core, UI, Media and Bindings.xml must be directly inside that folder. Install neither the ZIP nor the TOC alone.
2. Log in; startup should leave graphics unchanged and completed setup completed. Open Studio by right-clicking the LumenShift launcher/minimap button. Diagnostic export should show **0.2.0-dev.15** and the archive's source commit. No launcher-version reconfirmation is needed.
3. Select Night Vision, Clarity, Cinematic, Lantern or Moonlight in **Visual Modes**. Scroll to **Starting Look**, choose a variation, adjust **Light & style intensity** and **Detail**, then **Apply**. Use **Before / After** in a still scene and while moving; **Finish comparison** returns to the applied view. Lower detail if thin edges/foliage shimmer or halo. Existing custom settings remain until you select a variation/reset.
4. For optical reference capture, reopen **Setup → Appearance**, choose Original or Game Defaults, enable **Include sharpening and bloom in return look**, inspect the captured count, and **Save & Close**. Nothing should change until a later Apply. Try Original/Game Defaults, an independent detail profile, and a visual override; return to Original to confirm quality remains underneath. Use **Restore captured visuals** for the separate exact originals.
5. Save/export/import a personal preset containing a non-100 intensity; importing must not change the scene. Apply the imported variation. Reload: choices and originals remain, with no automatic mode or comparison replay.
6. Optional AO trial: first apply **Graphics Quality → Detail profiles → Current Baseline**, then **Diagnostic Center → Restore captured visuals**. This order releases detail changes and any opted-in return-optics ownership. Use **Explore contact depth (experimental)**. When available, choose a small different value within the displayed trial range and **Test & Restore**. It tests for roughly two seconds, then checks exact restoration. Observe contact areas and motion, without treating successful numeric readback as proof of a useful effect. If interrupted, use Advanced Graphics' explicit quality recovery; do not erase SavedVariables.

For problems, use **Diagnostic Center → Export Complete Diagnostic Report**. No commands, calibration certificates or recovery-card export are needed for ordinary mode use.
