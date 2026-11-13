# Phase 5 audit and work remaining

2026-11-08 · Northern Lights Labs · **0.2.0-beta.3** · `feat/beta-integration` · draft PR #5

The owner requested verification of Phase 5 and an accurate account of what remains before LumenShift is complete. The checkout and PR were verified against `ProfessorMinty/LumenShift`, beginning at beta.2 commit `41a5864a1e799b3d600ffa0dd7df815acde6b244`, with no unrelated local changes. The audit uses Delivery 5 in [41](41-IMPLEMENTATION-PLAN.md) and the beta.2 record in [46](46-BETA2-POLISH-AND-AUDIT.md). No installed game, main branch, release or CurseForge project was changed.

## Findings and fixes

**Keyboard capture failure — corrected.** After a consumed Tab, an exception reading keyboard focus/modifiers could leave propagation disabled. Initial propagation setup could also fail after enabling the window's keyboard handler. Activation previously called the action before establishing whether the key could be consumed, allowing an action plus unintended game input when propagation failed. The keyboard controller now establishes pass-through before fallible queries, consumes before activation, and disables its own keyboard capture on failure. A key-up handler pairs consumption with each key so a consumed Tab does not suppress the release of an unrelated held movement key. Mouse controls remain usable. If native keyboard release itself fails, only that addon window is hidden. Exceptions are reduced to allowlisted diagnostic codes; private native text is not retained. This is a local fallback, not a new version check, setup unlock or graphics restriction.

**Saved comfort preferences not reflected immediately — corrected.** Save & Close could save effects off while leaving an already-active tint/vignette visible. Saving now refreshes the applied presentation using its captured applied settings, stops a cue when muted, and stops running menu fades when motion is disabled. It does not apply other changes sitting in the mode editor, write CVars, switch modes or restore/reapply graphics after reload.

**Preset capacity/Undo — verified.** At the 24-preset limit, an undo that would exceed capacity preserves the deleted snapshot. Removing a different preset allows that undo to complete. Edits, transfer and undo do not apply graphics or modify independent quality choices.

The new adversarial tests were first run against beta.2: five reproduced failures and one capacity test passed. Four additional cases cover handler exceptions, unexpected focus results, mute/reload persistence and overlapping movement/navigation key releases. The full previous suite is retained. SavedVariables remains schema 12; no reset or new migration is necessary.

## Phase 5 requirement review

| Requirement | Result |
|---|---|
| Short setup and meaningful save/apply actions | Implemented; expanded graphics scrolls, actions remain fixed, Apply is explicit, comfort preferences now refresh correctly |
| Completion/preferences preserved on upgrades | Implemented and simulated; no version-driven wizard repetition or startup graphics replay |
| Studio hierarchy, scrolling, window movement/scale, wheel | Implemented; existing geometry tests retained; actual font/input/strata behavior remains a native check |
| Keyboard/accessibility/comfort | Implemented; failure paths now release capture; native input routing, high contrast and playback need owner acceptance |
| Personal preset save/edit/update/reset/rename/delete/undo/import/export | Implemented with validated visual-only data; capacity and reload tests retained |
| Logo/licensed artwork and cues | Existing supplied assets and original placeholders integrated with provenance; owner's final custom mode-icon family is optional outstanding polish |
| Visible diagnostics and readable status | Implemented; errors stay local, export retains technical evidence without automatic uploads |
| Current guide, support matrix and QA | Updated; old phase restrictions remain explicitly historical |
| Reproducible beta candidate | Builder/manifest/license checks present; new local beta.3 archive generated from the recorded clean commit |

## Verification

Validation on 2026-11-08:

- **393 Lua 5.1 tests passed; 0 failed**: the existing 383 plus ten audit regressions.
- **10 Python packaging tests passed**, including reproducibility, manifests, asset/license coverage and pinned guide links.
- **44 runtime modules**, **60 Lua syntax files and four binding bodies** passed syntax/structural checks; the single native CVar call site is unchanged.
- Current relative documentation links and whitespace checks passed.
- The local candidate is built twice from its clean recorded commit and compared byte for byte; its exact commit and archive checksum are recorded in BUILD.json, the adjacent SHA-256 receipt and PR #5.

These are off-client tests, not native graphics, input or performance measurements. The changes do not alter layout geometry or admit new CVars. The pinned Forever 70862 [UI schema](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXML/UI.xsd) declares both OnKeyDown and OnKeyUp; the [Frame API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua) declares keyboard propagation. This confirms source availability, not native event ordering or input acceptance. Earlier primary-source references in [46](46-BETA2-POLISH-AND-AUDIT.md) remain applicable.

## What remains before the addon is finished

The five-delivery feature scope is implemented. A passing mock suite and a packaged beta do not establish that the integrated addon is finished in the actual game. Remaining work is concrete:

| Remaining work | Completion criterion | Who / next step |
|---|---|---|
| Integrated game testing | Actual beta build loads, setup persists, every mode applies/returns, settings remain independent, no Lua errors or startup graphics changes | Arctic operates the game; export a report and note visual outcomes. Existing launcher/client evidence is accepted |
| Visual tuning | Check Night Vision sharpening/halos, Lantern warmth, Moonlight readability, Cinematic framing and Clarity neutrality in dark interiors, outdoors and movement | Owner feedback plus targeted setting/asset adjustments; no claimed optimal values from mocks |
| Native graphics and restoration coverage | Normal/raid/photo banks return captured known values; external edits are preserved; native dependencies and renderer-specific behavior are assessed | Owner-operated graphics/recovery tests, then implementation fixes for observed gaps. Full dependency closure is still unverified |
| Camera and addon coexistence | HUD escape/combat, names independence, FOV, capture timing and photo restoration work with the user's other UI/camera addons | Arctic tests visible Camera controls; developer investigates any conflicts |
| Native UI/accessibility | Wrapping, focus/text entry, drag/strata, small/large UI scales, reduced motion, high contrast, optional audio and capture work on available screens | Real in-game inspection; offline models cannot prove this |
| Install/update/removal and performance | Fresh whole-folder install, preserving update, reload/relog and explicit restore-before-removal succeed; real CPU/memory cost is acceptable | Manual native QA plus fixes. No deliberate crash is needed; SavedVariables is never immediately durable |
| Final creative polish | Choose whether to ship the existing icons or replace them with the promised matching custom family; validate small-size readability and sound balance | Owner assets/choice plus export/provenance checks. Missing decorative Fractal Haze and extra per-mode sounds do not block functionality |
| Release preparation | Review/approve the final source and merge strategy, tested compatibility claims, version/changelog, authentic screenshots, split licensing and exact ZIP | Developer prepares the concrete release materials; owner approves. Existing code/assets licenses are already decided |
| CurseForge publication | Verify actual dashboard owner/flavor/version/license fields and current policies, then submit and verify moderation/install behavior | Only after explicit owner publication approval; no guessed IDs or automatic upload |

A repository CI workflow would be useful maintenance work; the complete test/build commands already exist. CI is not a missing gameplay feature. Automatic hardware benchmarking/autotuning, all possible console variables, thermal imaging, scene-wide black outlines, new world lights and external shader injection are not part of the implemented addon scope. Native sharpening, optional bloom and the isolated contact-depth trial are the available researched alternatives; no hidden shader feature is promised.

## Focused owner retest

Install the whole extracted beta.3 `LumenShift` folder under Forever's `Interface/AddOns`, keeping SavedVariables. No reset, launcher reconfirmation or slash-command setup is needed.

1. Right-click the launcher for Studio. Use Tab/Shift+Tab, text fields and Enter/Space, then close Studio and confirm normal movement/chat input. Do not intentionally break native APIs; those adverse paths are simulated in tests.
2. Apply Night Vision, open Setup, turn Screen effects off, and Save & Close. Its tint/edges should disappear while Brightness stays at the active mode's value. Re-enable effects through Setup to restore the applied appearance. A mode-editor edit should remain unapplied until Apply.
3. Save, edit, update, reset and transfer a personal preset; try Delete/Undo. Reload and confirm presets/preferences remain, completed setup stays closed and startup does not replay graphics.
4. Continue the [integrated beta checklist](22-BETA-RELEASE-QA.md), then use Diagnostic Center → Export Complete Diagnostic Report. Record actual visible results separately from numeric readback. The [current support matrix](46-BETA2-POLISH-AND-AUDIT.md#current-support-and-evidence-matrix) identifies unobserved areas.

The immediate next step is an owner-run integrated beta test and fixes driven by its results, followed by the final asset/release pass. There is no new feature-development phase or blanket read-only gate added by this audit.
