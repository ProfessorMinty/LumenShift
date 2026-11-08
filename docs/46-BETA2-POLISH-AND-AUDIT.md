# Delivery 4 audit and Delivery 5 beta candidate

2026-11-08 · Northern Lights Labs · **0.2.0-beta.2** · `feat/beta-integration` · draft PR #5

The owner authorized verification of Delivery 4 and implementation of Delivery 5 in [the five-delivery plan](41-IMPLEMENTATION-PLAN.md). This completes the planned implementation and produces a local candidate for owner testing. It is not a claim that the new integration has passed native acceptance or is approved for CurseForge. Historical phase restrictions and beta.1 results remain historical. No game files/settings were changed by development tools, and nothing was merged or published.

## Delivery 4 audit

The unchanged dev.16 source at `8233b6678c3770416adf7b1b136337f948054d7d` passed all **366 Lua 5.1 mocks** before this work. The audit preserved the single CVar call site, independent mode/quality requests, photo-bank restoration, framing bounds, no-startup-write behavior and finite FPS observations.

Two defects were corrected:

1. **Camera exit could undo an independent names toggle.** Camera now saves the prior names intent separately before its own names operation. Exit restores that intent through the existing planner. It releases Camera-only changes, preserves a separately chosen names setting, and retains the first exact-original record for later restoration. HUD-only Camera no longer restores unrelated manual names changes. The explicit **Restore original name settings** button still restores all captured names. A pending Camera name return must finish before a new Camera entry or independent names toggle. Other controls remain available.
2. **An old scheduled screenshot could fire after exit/re-entry.** Exit and combat cancel a capture that has not reached the native screenshot request. An already-issued request cannot be recalled; it drains to its native event or timeout before another request. Native screenshot events have no request identifier: late external events cannot establish perfect request correlation, and a timeout is reported as unobserved rather than success.

`camera.nameReturn.targets` stores only the two allowlisted numeric name targets. Schema 12 preserves preferences, setup completion, presets and recovery originals. Older records do not acquire invented Camera-session intent; **Restore original name settings** remains available for them. Failures/conflicts retain both intent and recovery data. No reload or startup attempts restoration.

## Delivery 5 implementation

- **Setup:** a two-step Appearance/Graphics flow, scrollable expanded graphics, fixed final actions and window fitting on display/UI-scale changes. Save & Close stores choices without graphics writes. Apply & Reload deliberately applies the selected banks, verifies, then reloads. Reopening/editing is prevented only while that operation is running. Failure keeps saved preferences and recovery data and allows the wizard to close. Completed setup remains completed across migration.
- **Personal Presets:** Save variation; Edit without applying; Update from mode editor; Reset editor to the saved snapshot; rename feedback; Delete and session-local Undo; strict LSMODE3 export/import and LSMODE2 import. Typed name/transfer drafts survive rebuilding. Original/Game Defaults is not a savable mode variation. Presets contain visual settings only; quality choices are untouched. At most 24 presets and existing data/range limits remain enforced.
- **Keyboard/UI:** Studio and Setup support Tab/Shift+Tab focus, a visible focus outline, Enter/Space button activation, native text editing and automatic scrolling to focused controls. Rebuilding/changing pages/hiding clears old edit focus. Native chat/other text focus wins. If the needed keyboard APIs are unavailable, mouse controls remain usable. The existing wheel, movable title bars, viewport sizing, labeled cards and fixed action area remain. Native focus propagation and font wrapping still need in-game inspection.
- **Comfort:** reduced motion or disabling menu animation now stops a fade already running. Existing effects/mute/high-contrast controls remain. Sound wording correctly identifies the Night Vision on/off cues; no new audio or unprovided mode artwork is claimed.
- **Feedback:** player-facing operation/FPS messages use readable explanations, composite recovery/partial states take precedence in Studio, and diagnostics retain technical codes, exact originals and Camera names return targets. Diagnostic Center/export stays accessible through visible controls. No new telemetry or upload.
- **Assets/distribution:** existing approved logo, mode art, Streamline controls, mesh panels, Lumen Loops accents and original cues are retained with their hashes/notices. Pending owner mode assets and absent Fractal Haze are not fabricated. MIT code/technical documentation, original assets All Rights Reserved and third-party licenses remain separate. Packaging still uses committed, allowlisted files, one install root, a stamped runtime commit, `BUILD.json` hashes and deterministic ZIP bytes.

## Source/API decisions

The existing architecture and [Delivery 4 source record](45-DEV16-CAMERA-AND-PERFORMANCE.md) remain the basis for Camera/FOV/photo/FPS behavior. No new native graphics CVar was admitted.

Keyboard APIs were checked against the historical Forever [70532 global inventory](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/GlobalAPI.lua) (`GetCurrentKeyBoardFocus`, `IsShiftKeyDown`) and the pinned [70862 EditBox API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleEditBoxAPIDocumentation.lua). Keyboard propagation remains restricted as recorded in [SRC-18](07-EVIDENCE-AND-DECISIONS.md); our windows close on combat and do not configure protected frames or game bindings. Source availability does not prove native focus/rendering acceptance.

## Verification

Final checks on 2026-11-08:

- **383 Lua 5.1 mocks passed; 0 failed** (366 retained plus 17 new regression cases).
- **10 Python packaging tests passed**, including complete install layout, deterministic bytes, manifests/licenses/assets and commit-pinned guide links. The bundled guide's relative repository links are rewritten to the packaged commit; source files are not mutated.
- **44 runtime modules**, **59 Lua syntax files plus four binding bodies**, exact TOC/version/path and centralized-writer structural checks passed.
- Whitespace and current local documentation links passed.
- Offline geometry renders inspected for Appearance, expanded normal/raid setup and personal presets. These use approximate fonts/textures and do not certify native strata, text wrapping, keyboard propagation or mouse input.

All Lua tests and UI models are simulated. The strict mock covers capture-before-write, readbacks, failures, reload recovery, conflicts, independent manual/Camera names, screenshot lifecycle, validated preset edits, keyboard/focus, setup scroll/apply and resize behavior. Existing restoration, security, optical, native-bank and lifecycle suites remain included.

## Current support and evidence matrix

| Feature | Implementation/evidence | Native acceptance still needed |
|---|---|---|
| Brightness and exact return | Owner-confirmed earlier round trips on 70790/70862; unchanged writer model | Regression in this integrated candidate |
| Original/Game Defaults, optional return optics | Capture/read native defaults; never a whole-game reset | Capture/return appearance, unsupported defaults |
| Night Vision, Cinematic, Lantern, Clarity, Moonlight | Authored/editable light, optional Contrast, sharpening/bloom and UI styling; pure/planner mocks | Every starting look, sharpness in motion, scene readability, comfort |
| Independent quality | Native normal/raid recipes and bounded detail profiles; known originals captured | Native recipe dependency coverage, every bank's exact restoration, actual raid performance |
| Camera | HUD/names, guides/capture, bounded FOV, temporary photo banks | Real captures, HUD escape/combat, other camera addons, return values |
| FPS comparison | Ten readings after settling; two session results; no writes/continuous polling | Meaningful same-scene comparison; not a benchmark or hardware autodetection |
| Presets/setup/accessibility | Schema migration, validated data-only transfer, visible controls and keyboard mocks | Real font wrapping, focus, scale, reload persistence, texture/audio playback |
| Recovery | Per-key exact originals, explicit operations, external changes preserved | Native failure/conflict observations; SavedVariables never immediately durable |
| AO contact depth | Separate bounded temporary experiment, not a mode or saved profile | Visible effect, native renderer dependency and movement stability |
| World outlines/thermal/new world light/HDR injection | Not Lua-addon features offered by this build | Not included; driver/shader research does not authorize implementation |

## Install and test this candidate

1. Exit WoW, back up the old addon folder, and **keep SavedVariables**. Extract the supplied beta.2 ZIP. Copy the complete `LumenShift` folder into Forever's `_forever_/Interface/AddOns/`. The TOC must be directly at `AddOns/LumenShift/LumenShift.toc`, beside Core, UI, Media and Bindings.xml. Neither the ZIP nor a lone TOC is sufficient. Nothing is installed by this development task.
2. Enable LumenShift. Existing completed setup should stay closed. Right-click its launcher/minimap button for Studio; use Settings → AddOns → LumenShift if the launcher is hidden. Confirm startup has not switched modes or altered the scene.
3. Open Setup through Settings or Studio → Accessibility. Check Appearance and both expanded graphics selectors. **Save & Close** should preserve choices without applying. Reopen to check them. With both banks kept, **Finish & Reload UI** saves/reloads only; selected recipes explicitly change that action to **Apply & Reload UI**. Do not erase saved data to force setup.
4. In Personal Presets, save a variation, Edit it, change its mode editor, return and Update from mode editor. Reset editor should restore the saved snapshot without applying. Export/import the whole code, rename, Delete/Undo, then reload and check preservation. Apply separately when you want to inspect the scene.
5. Check Tab/Shift+Tab, numeric text entry, Enter/Space buttons, keyboard scrolling, Escape, chat focus, title-bar dragging and your usual UI scale. No keyboard capture should remain after closing. Toggle reduced motion, high contrast, effects and sound off/on; sounds are optional Night Vision cues.
6. In Camera, first toggle names separately, leave Hide friendly names off, enter and exit: the separate names setting should stay. Toggle it back to restore. Then enable Camera name hiding, enter/capture/exit and check the original mixed player/pet settings return. An exit before capture begins must cancel that capture. Optional FOV/photo-quality tests follow [Delivery 4's procedure](45-DEV16-CAMERA-AND-PERFORMANCE.md#install-and-try-it).
7. Use the [current beta acceptance checklist](22-BETA-RELEASE-QA.md) for all six return/visual modes, quality banks, effects and recovery. Export through **Diagnostic Center → Export Complete Diagnostic Report**. Include the build identifier and what you actually observed; no launcher reconfirmation is needed.

This implementation is ready for owner acceptance testing. Public release approval, integrated native acceptance and new owner artwork remain separate; no CurseForge project/upload is created.
