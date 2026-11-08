# Implementation plan: richer modes and a dependable beta

**2026-11-08 — Northern Lights Labs**

Repository: **ProfessorMinty/LumenShift**. Continue `feat/beta-integration` and PR #5. Starting source is `d4e5f33`; the current playable archive remains **0.2.0-dev.12 / adf7763f**. This document plans implementation; it does not change the runtime or declare new live test results.

**Delivery 1 implementation:** [dev.13 reliability and presentation](42-DEV13-RELIABILITY.md), 2026-11-08. Runtime changes and simulated acceptance are recorded there; this plan retains its original starting snapshot. **Delivery 2 implementation:** [dev.14 shared optics](43-DEV14-SHARED-OPTICS.md), 2026-11-08. Delivery 1 was reverified and Delivery 2 is implemented with simulated acceptance. **Delivery 3 implementation:** [dev.15 distinct looks](44-DEV15-DISTINCT-MODES.md), 2026-11-08. Delivery 2 was audited; starting variations, intensity, explicit return optics and an isolated contact-depth trial are implemented. **Delivery 4 implementation:** [dev.16 Camera and graphics comparison](45-DEV16-CAMERA-AND-PERFORMANCE.md), 2026-11-08. Native observations remain separate; Delivery 5 remains planned.

## Working agreement

Proceed under the owner's existing full-product development authorization. Complete routine engineering decisions, fixes, tests, documentation and local development archives without adding approval checkpoints between increments. A working build should remain available while the next increment is developed.

- Normal use is through Setup, Studio, the wheel, launcher and keybindings. Commands are optional.
- No launcher-version reconfirmation, calibration unlock, recovery-card ceremony or global read-only mode. A changed build produces the existing warning, not a blanket lock.
- Capability checks affect the relevant control. An unavailable optional bloom/AO/camera feature must not disable Brightness, other modes or configuration.
- A supported experimental control can be tried with an ordinary deliberate Apply action. Diagnostics collect evidence in the background; users do not complete a proof checklist before using it.
- Runtime restrictions, external conflicts and failed writes still need accurate local handling. Explain the affected setting and offer a useful recovery action; do not discard originals or retry continuously.
- Server downtime, pending custom icons and unavailable native visual feedback do not stop independent implementation. Use existing licensed assets and label unobserved results honestly.
- Keep startup/reload free of graphics writes. No agent-operated changes to the installed game, automatic merges or CurseForge publication. The existing owner approval for merging/publication remains separate from development.

This replaces a milestone-by-milestone approval workflow with continuous delivery. It does not promise that every researched renderer technique exists in Lua or that mocks can prove image quality.

## Architecture to preserve and complete

Maintain three independently selected experiences: **Visual Mode**, **Graphics Quality** (everyday and raid/battleground choices), and **Camera**. A user must be able to combine Cinematic with Performance, or Night Vision with their current custom graphics.

Introduce one pure effective-settings resolver and a shared transaction coordinator for overlapping optical keys. Keep `Core/WriteBoundary.lua` as the only native CVar-writing call site. The resolver combines explicit mode overrides with the currently selected quality preference, then Planner/Recovery handles the resulting delta. Native quality tiers require their known dependency captures; they are not equivalent to independent one-key settings.

Keep these concepts separate in storage and UI:

1. The chosen **Original / Game Defaults** visual reference.
2. The first exact pre-change original for each owned key.
3. Saved mode/quality choices and uncommitted editor changes.
4. The current effective values, pending operation and recovery status.

Example regression: original sharpness 1; quality preference .4; Night Vision override .2. Selecting quality .7 while Night Vision remains active retains .7 underneath. Leaving Night Vision uses .7; restoring all owned changes returns the exact original 1. No step captures .2 as a new original. These are model-test values, not recommended presets.

Each new schema migration preserves existing setup completion, personal presets, chosen visual reference and recovery records. Optional fields default to inheritance/off so updates do not silently intensify the player's saved look.

## Delivery 1 — reliable switching and presentation

**Player outcome:** mode labels, the actual scene and visible effects agree; Camera/combat transitions behave consistently.

Implement the open findings from [38](38-MODE-AUDIT-AND-OPTICS.md):

- Correct composite Brightness/Contrast transitions. Preflight the requested operation, verify each change and use bounded compensation for freshly matching owned state. A failed apply must display Partial/Recovery with the actual changed members, not incorrectly label the scene Original.
- Add an explicit **Keep visual effects in Camera** preference and a supported presentation-root strategy. Keep a reliable way to show the HUD again. Never modify another addon's frames.
- Restore permitted cosmetic presentation after combat without reapplying CVars. Distinguish saved preference from currently visible effects.
- Enforce the source-backed bloom capability condition only for bloom. Preserve other controls when it is unavailable.
- Reconcile inaccurate labels, viewport-dependent edge sizing and Contrast inheritance wording. Retain the movable window, strata, wrapping and reload fixes already implemented.

**Acceptance:** regression mocks reproduce and then resolve the known failures; zero startup/diagnostic writes; no false Original state; Camera visibility and cosmetic resume are explicitly tested. UI model checks cover dragging, close controls and long labels. Native font/strata/visibility observations remain separately recorded.

**Delivery:** next development ZIP, changelog, exact artifact path/checksum and a short button-based check of switching, Camera and reload. Continue other development while feedback is pending.

## Delivery 2 — shared optics, Night Vision and Clarity

**Player outcome:** controls change useful image detail, with coherent restoration across modes and quality selections.

- Implement the shared resolver/coordinator and migrate overlapping ownership into one physical journal per key. Unify the relevant native-bank, detail-profile and visual-mode requests before adding competing optical writers.
- Add typed optional sharpness overrides to mode schemas, personal presets and Studio. Use a clear weak-to-strong UI mapped to the source-backed reversed raw value. Offer inherit and sharpening-off choices; do not mislabel raw strength 2 as a proven off switch.
- Add sequential **Before / After** comparison through the same writer and ownership model. Ending a comparison preserves intervening external changes. This is not a simulated split-screen world shader.
- Make Night Vision useful with styling disabled: retain Brightness 75 as its existing starting target, add adjustable detail, and provide Clear/Goggles styling. Preserve user edits rather than overwrite them with new defaults.
- Give Clarity neutral presentation, adjustable detail and optional effective glare reduction. Avoid mandatory brightness increases, tint or vignette.
- Keep native resolution/AA/filtering controls in Graphics Quality. A mode's sharpness override does not silently change resolution, AA or expensive quality tiers.

**Acceptance:** quality → mode → changed quality → mode off → full restore returns the correct values and exact raw originals. Tests cover no-setter releases, bounds, missing APIs, clamping, delayed drift, external edits, failed compensation, reload and old-schema migration. Comparison cancel/release and preset import use the same rules. No graphics write is used to animate a fade.

**Delivery:** usable Night Vision/Clarity controls and a separate owner comparison of detail in still scenes and motion. Raw trial values from the research are not adopted as universal defaults.

## Delivery 3 — distinct modes and optional contact depth

**Player outcome:** each mode serves a recognizably different purpose with a small set of understandable controls.

| Mode | Implementation direction | Done when |
| --- | --- | --- |
| Original / Game Defaults | Preserve the chosen visual reference; extend optical reference fields explicitly and independently of recovery originals. | Return-look behavior and full restoration remain distinguishable and correct. |
| Night Vision | Readable darkness, adjustable sharpening, optional thin goggle styling and original cue. | Detail/readability work without styling; the owner can reduce halos or shimmer through simple controls. |
| Clarity | Neutral detail and supported glare control, no obligatory screen edges. | Useful in ordinary gameplay without disguising an exposure increase as sharper rendering. |
| Cinematic | Controlled brightness/contrast, optional supported bloom, restrained styling and deliberate framing. | Preserves useful dark detail and works with any independently selected quality profile. |
| Lantern | Comfortable exposure, gentle detail and optional warm tint around the existing scene. | Warm interiors stay readable without washed-out torch highlights or a false world-light claim. |
| Moonlight | Modest, customizable night readability and subtle cool styling, with atmosphere retained. | Distinct from Night Vision without blue haze, crushed shadows or hidden peripheral cues. |

Preserve existing customized values. Add richer starting variants and reset options deliberately; do not silently replace all saved brightness values with new formulas. Use a consistent intensity/detail presentation, with advanced individual adjustments available.

Pursue AO contact-depth controls as an **optional work item**, not a dependency for completing the other modes. Add narrowly named descriptors only where available values, meaningful bounds and relevant dependencies can be checked. Provide a bounded experimental Apply/Restore control for eligible fields and record effective values. If the active method or effect remains uncertain, retain an accurate experimental status and continue the rest of the product. Do not import community maxima or promote numeric readback to a visible-effect result.

**Acceptance:** mode schema/composition tests pass; optional unavailable effects are identified before applying the supported portion. A failure after writing begins is handled as a failed/partial transaction, not silently skipped. Native visual comparisons later establish preferred sharpness, bloom and AO defaults separately; a weak AO result does not hold up Lantern, Camera or UI work.

## Delivery 4 — Camera and practical graphics selection

**Player outcome:** a clean view for screenshots and understandable quality choices for everyday play and raids.

**Camera:** finish separate HUD and friendly-name controls, clear exit behavior, optional thirds/aspect guides, and guide-free capture. Add manual framing only through supported APIs with captured originals and conflict-aware restoration. Coexist with DynamicCam/Narcissus rather than repeatedly overriding their settings. Add a separate opt-in temporary photo-quality choice; exiting restores owned changes without resetting the user's selected everyday/raid preferences.

**Graphics:** build on the existing Keep Current, WoW Recommendation and native 1–10 choices. Preserve separate raid/battleground settings. Explain the recommendation as native defaults, not hardware benchmarking. Offer plain-language priorities such as smooth gameplay, richer scenery and quieter operation without guessing a universal tier from a GPU name.

Add a user-started comparison workflow with the current scene, sampling window and FPS observations recorded. Ask for the desired experience rather than requiring hardware expertise. More expensive sampling, if available, stays opt-in; no permanent high-frequency polling or automatic quality hunting during play. Do not claim a short outdoor sample predicts raid performance or invent an auto-detect API.

**Acceptance:** shared optical keys remain single-owned across normal/raid recipes and modes; no invented RAID variants. Camera exit, other-addon changes, partial photo-quality failures and unsupported camera controls are covered. Results distinguish requested, effective and unobserved settings. Tests preserve important combat cues and verify current known dependency restoration without claiming a complete renderer snapshot.

## Delivery 5 — product polish and beta candidate

**Player outcome:** a coherent addon that is easy to set up, navigate, personalize and recover.

- Keep setup short: choose Original/Game Defaults and preferences, then optional graphics selection. Save & Close persists without applying; explicit Apply & Reload performs the selected operation. Completed setup does not reappear on every update.
- Refine Studio's hierarchy, aligned controls, selected states, scrolling, focus and responsive sizing. Keep windows movable and the wheel readable at common scales/aspect ratios. Commands remain optional.
- Finish personal preset save/edit/reset/import/export with data-only validation. Preserve mode/quality independence and saved choices across reloads/upgrades.
- Use the approved logo and existing licensed icon/art system now. Replace placeholders with the owner's matching mode assets when supplied, with source/license/hash records. Pending artwork does not stall functionality.
- Polish existing sound/effect controls and optional mode cues without forcing audio, flicker or motion. Preserve mute, reduced motion, high contrast and keyboard operation.
- Make diagnostics/export available from visible controls. Normal users see concise actionable status; detailed technical evidence stays in the diagnostic view.
- Update the current user guide, changelog, support matrix and beta QA document so old phase restrictions are clearly historical, not present-day instructions.
- Produce a reproducible local beta candidate with the complete addon folder, build identity, checksum, licenses and asset notices. No CurseForge upload occurs here.

**Acceptance:** complete current mock suite, Lua 5.1 syntax/structural checks and packaging tests pass; UI model inspection is clearly marked simulated. Record actual native observations separately for installation, every mode, restoration, Camera, normal/raid quality, UI scaling, reload and external conflicts. Unobserved behavior is listed plainly. Public beta claims reflect completed results, not the existence of a ZIP.

## Module and test map

Implementation paths are relative to `addon/LumenShift/`. A shortened filename in a row uses the preceding `Core/` or `UI/` directory; test filenames use `tests/`.

| Area | Existing implementation anchors | Test work |
| --- | --- | --- |
| Effective state and transactions | `Core/Product.lua`, `Planner.lua`, `Recovery.lua`, `WriteBoundary.lua`; new pure resolver/coordinator if needed | Extend `tests/product.lua`, `quality.lua`, `native_graphics.lua` and core cases in `tests/run.lua`. |
| Configuration and defaults | `Core/Store.lua`, `StudioConfig.lua`, `Profiles.lua`, `Baseline.lua` | Schema migration, import validation, saved edits, independent references/originals; `tests/baseline.lua`. |
| Capabilities and quality | `Core/ReadOnly.lua`, `Catalog.lua`, `ExperimentPolicy.lua`, `NativeGraphics.lua`, `Quality.lua` | Per-feature omission, unsupported ranges/flags, dependency observation, exact restoration. |
| Camera/presentation | `Core/Camera.lua`, `UI/Presentation.lua`, `UI/Audio.lua` | `tests/camera.lua`, `product.lua`, `ui_mock.lua`; native visibility/motion checks separately. |
| Product UI/reporting | `UI/Setup.lua`, `Studio.lua`, `Graphics.lua`, `Widgets.lua`, `Radial.lua`, `Core/Report.lua` | `tests/wizard.lua`, `diagnostic.lua`, off-client layout rendering and native input checks. |

For every runtime delivery, run:

```text
python tools/check.py --mocks --lua-runtime ../lua-test-runtime
python -m unittest discover -s tests -p test_package.py -v
git diff --check
```

Build archives from a clean committed tree with `tools/package.py`; retain exact source/ZIP identity and give Arctic the actual download/file path and extracted-folder installation steps. Add meaningful regression tests for failures, not counts for their own sake. Do not rerun or cite historical test counts as proof of a new image-quality effect.

## Scope and immediate next work

Execution order is **1 → 2 → 3 → 4 → 5**, with independent UI/assets/documentation work progressing alongside the current delivery. Optional AO research and owner visual feedback do not form mandatory stop points between deliveries. Do not accumulate a hidden rewrite before providing the first usable fix build.

As of dev.16, **Deliveries 1–4 are implemented** with their recorded simulated checks and native acceptance still separate. **Delivery 5** is the next planned implementation scope; it was not started as part of this increment. The original planning snapshot above remains historical. Native acceptance is recorded separately from implementation completion.

True scene-wide outlines, thermal imaging, world light creation and external shader injection are not promises of this Lua-addon beta. Their researched alternatives remain in [39](39-GRAPHICS-CONTROL-LANDSCAPE.md); useful native controls and composition tools proceed independently.

Design/evidence references: [baseline semantics](34-BASELINE-CHOICE.md), [reload/UI corrections](36-DEV11-RELOAD-AND-UI-FIXES.md), [native graphics banks](37-NATIVE-GRAPHICS-BANKS.md), [mode audit](38-MODE-AUDIT-AND-OPTICS.md), [graphics research](39-GRAPHICS-CONTROL-LANDSCAPE.md), [community research](40-COMMUNITY-VISUAL-RESEARCH.md). Historical publication requirements remain in [08](08-CURSEFORGE-RELEASE.md); current split licensing and explicit final publication approval are unchanged.

**Plan validation:** repository/branch/PR identity and local document links checked; structural and whitespace checks run for this documentation change. No runtime implementation, new mock-suite result, in-game test or rebuilt archive is claimed.
