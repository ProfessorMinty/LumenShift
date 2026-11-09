# Beta acceptance and eventual distribution

> Current beta.12 adds [standalone poses, capture sequences, names and look history](57-STANDALONE-PHOTO-WORKFLOW.md), preserving all prior photo tools. Beta.11 adds [live native photo sliders](55-LIVE-PHOTO-SLIDERS.md), retaining [the in-scene Photo Studio](54-IN-SCENE-PHOTO-EDITOR.md) and preserves [clean photo capture and Escape](53-PHOTO-MODE-RESEARCH-AND-CONTROLS.md), retaining the fix for [Camera name storage eligibility](52-CAMERA-NAME-STORAGE-FIX.md). It retains [single-launcher and wheel/Camera navigation fixes](51-LAUNCHER-AND-WHEEL.md), preserving [explicit addon-only reset and fresh setup](50-RESET-AND-RESTART-SETUP.md), and includes the [returned-original fix](49-RETURNED-ORIGINAL-AND-CLEAN-SETUP.md) and the [whole-addon forensic audit fixes](48-FORENSIC-AUDIT.md) to completed Delivery 5 and the Delivery 4 audit: [implementation, support matrix and verification](46-BETA2-POLISH-AND-AUDIT.md). Use the [current installation guide](21-BETA-USER-GUIDE.md). No repeated unlock/approval ritual is required for ordinary controls. The owner tests the actual game; development tools do not operate it. Public distribution still requires final approval.

Beta.12 verification: **519/519 Lua 5.1 mocks**, **10/10 packaging tests**, syntax **79 Lua files + four bindings**, **54 runtime modules**, one native write call and five inspected off-client views. The 26 new standalone workflow cases and native test procedure are in [57](57-STANDALONE-PHOTO-WORKFLOW.md). No beta.12 native pass is claimed.

Historical beta.11 verification: **493 Lua 5.1 mocks**, **10 packaging tests**, syntax **74 Lua files + four bindings**, **50 runtime modules**, one native write call, unchanged asset hashes and whitespace checks passed. Sixteen new live-preview regressions cover coalescing, endpoints, drag stability, lifecycle cancellation, capture ordering and failures. [Implementation and owner check](55-LIVE-PHOTO-SLIDERS.md).

Beta.10 automated verification: **477 Lua 5.1 mocks**, **10 packaging tests**, syntax **72 Lua files + four bindings**, **49 runtime modules**, one native write call, **121 current local documentation links**, original asset hashes and whitespace checks passed. The 26 new photo-editor regressions and off-client panel previews are detailed in [54](54-IN-SCENE-PHOTO-EDITOR.md). Native acceptance below remains separate.

## Current beta.12 acceptance record

Record the ZIP/source identity from BUILD.json or the diagnostic report. All rows below are **NOT RUN IN-CLIENT for beta.12**. Earlier owner-confirmed Brightness evidence remains valid only for its recorded scope. No launcher-version reconfirmation is needed.

| Area | Acceptance check |
|---|---|
| Startup / upgrade | Whole-folder install; preferences, presets, exact originals and completion survive; no startup write or repeated wizard |
| Navigation | Exactly one launcher before/after changing the option and reload; wheel labels/hints fit; mouse/7 reaches Camera and its visible exit; 8 opens Studio; chat focus and combat remain respected |
| Reset | Cancel changes nothing; confirm reloads into fresh setup; current graphics/other addons remain unchanged; old recovery is intentionally forgotten; next saved setup stays complete |
| Setup | Original/Game Defaults reads; optional optics; both normal/raid selectors scroll; Save & Close does not apply; deliberate Apply & Reload verifies and reloads; failed apply retains saved choices |
| Every mode | Original/Game Defaults, Night Vision, Cinematic, Lantern, Clarity, Moonlight; starting looks, intensity, optional Contrast, sharpening/bloom, effects off; exact pre-change recovery differs correctly from Game Defaults |
| Mode/quality independence | Mode overrides quality optics; releasing mode reveals quality request; native normal/raid choices remain independent; captured normal/raid/photo values restore |
| Personal presets | Save/Edit/Update/Reset/Rename/Delete/Undo; transfer LSMODE3 and legacy LSMODE2; changes persist after reload; no write until Apply |
| UI/accessibility | Keyboard focus and text edits, scrolling, chat focus, Escape, wheel, draggable title bars, native Settings/launcher; 1080p/1440p/ultrawide as available; readable labels/contrast at user's scale |
| Comfort / combat | Effects, letterbox, optional Night Vision audio, mute, reduced motion; HUD accessible on Camera combat; no queued graphics changes |
| Camera | Hide controls/H removes toolbar/guides from external screenshots while effects remain; H reveals controls; Escape exits even during pending capture; chat/ordinary keys pass through. Server-stored friendly names pass eligible preflight; mouse/7 hides HUD and names; visible Exit restores the prior names/HUD; export includes all flags and exact check result. Independent manual names preserved on exit; mixed names restored; pending capture cancelled on exit/reentry; native screenshot has no guides/bar; FOV/photo exact return and external camera-addon conflict behavior |
| Photo Studio | Six tabs, live filters/vignette/glow/grain, draggable glow, native sliders preview while held, retain the final endpoint and keep the knob stable; capture/clean view waits and Exit/combat cancels queued input, exact pre-photo return, Before/After, saved looks/transfer, clean external/native capture, missing-feature isolation; no model stage |
| Standalone photo workflow | Narcissus disabled: all tabs, poses/Stop/favorites, optional one-shot auto-capture, timed burst/Cancel, exit/combat cancellation, player/pet/NPC/bubble Apply and return, grouped look Undo/Redo; then optional Narcissus coexistence with its auto-hide names on/off and both entry orders |
| Performance | Deliberate finite same-scene observations, elapsed time and combat counts; no settings writes/background loop; actual CPU/memory observations recorded separately |
| Fallback macro | After a completed mode returns to the exact captured original, the next mode click succeeds; selecting Original releases it without a setter. Other external values and uncertain failures remain preserved |
| Recovery / reload | Explicit owner-operated interrupted/conflict testing; no startup replay, exact originals retained, no repeated overwrite; export gives actionable state |
| Audit regressions | Effects Apply reflects the edited opacity without graphics writes; wheel respects chat/held movement releases; already-matching native recipes finish without a new recovery record; Camera recovery export includes framing and photo failure details |
| Distribution | Single install root, deterministic commit/manifest/hash, split licenses and asset attribution; installation/update/uninstall and moderation requirements reviewed before publication |

A missing optional API should affect its own control, not freeze the addon. If a test fails, export the diagnostic report and record the visual result. Do not induce a crash merely to test persistence. SavedVariables is not immediately durable. A simulated UI render is not native input/font/taint evidence.

## Historical beta.1 record

**Historical beta.1 publication plan, not the current development priority.** The owner never installed/tested beta.1. Current work is the interactive diagnostic build in [23](23-INTERACTIVE-DIAGNOSTICS.md), with [one exploration/report workflow](21-BETA-USER-GUIDE.md). That document supersedes the old Brightness-only scope, schema/module counts and packaging detail below. Publication remains unapproved; no release-polish work is required before owner exploration.

The code and local archive are development deliverables. **Recommendation: owner acceptance testing next; no feature-complete beta sign-off or CurseForge publication yet.** Existing build identity is accepted; do not ask Arctic to reconfirm the launcher. Preserve previous Phase 00/01 evidence and mark only tests actually observed in this integrated build as passed.

## Owner test record

Use [21-BETA-USER-GUIDE.md](21-BETA-USER-GUIDE.md) for current installation; the following sequence records the superseded beta.1 proposal. Record the ZIP filename, SHA-256 and `BUILD.json` source commit. The following remain **NOT RUN IN-CLIENT** for 0.2.0-beta.1:

| Gate | Acceptance criterion |
|---|---|
| Installation / startup | Complete ZIP loads without errors; both slash aliases and Studio/Settings entry work; actual Brightness and Contrast unchanged at startup |
| Initial switching | Explicit setup writes nothing; one Night Vision toggle reaches 75; Natural restores the exact captured original, clears effects and releases ownership; no repeated token ritual |
| UI / input | Six icons readable; cursor edge correction, keyboard cancel/select, bindings, launcher drag, every scroll page and numeric edit work; opening UI cannot steal gameplay input after close |
| Presentation / audio | Original media decode correctly; tint/vignette strengths are comfortable; sound previews/mute/levels work; effects off, reduced motion, high contrast and scale work |
| Combat / HUD | No mode changes queued in combat; effects/bars disappear; essential HUD remains accessible; custom-frame layering and EllesmereUI coexistence tested |
| Experimental modes | Separately approve non-75 target testing, save the original externally, test each chosen target/mode and full return to Natural; do not infer all 0–100 values safe from one pass |
| Conflict / recovery | Separately approve adverse tests; external edit preserved without fight, explicit restore card matches intent; readback failure retains original and does not retry |
| Reload / migration | Separately approve reload while owned; no startup reapply/restore, original retained if SavedVariables persisted, explicit recovery works; schema-1 migration and unsupported-downgrade behavior observed |
| Accessibility / screens | Test native 1080p/1440p/ultrawide and UI scale as available, labels/focus/color contrast, keyboard alternative, combat handling; actual frame/memory/CPU cost acceptable |
| Quality / Contrast | Native domains, dependent keys, restrictions, effects and exact restoration established before enabling; profile targets reviewed together, performance claims backed by measurements |

Do not induce crashes as an initial test. Crash/disk-loss safety has an inherent limitation: no addon can guarantee immediate SavedVariables durability. A read-only diagnostic success is not a native write test. A mock screenshot is not an authentic game screenshot. Redact other players' chat and private paths from evidence.

## Reproducible local packaging

After committing a clean working tree:

```text
python tools/package.py --output PATH_OUTSIDE_REPOSITORY
```

The packager reads recorded Git blobs from HEAD, requires clean source, checks the complete runtime list and asset hashes, and writes two in-memory archives which must be byte-identical. Sorted ZIP_STORED entries, a fixed 1980 timestamp and regular-file permissions avoid timestamp/compression-library variance. Every archive has one `LumenShift/` root with the 21 Lua modules, TOC, Bindings.xml, 12 runtime assets, both license notices, user guide, changelog, provenance, asset manifest and BUILD.json. It excludes research, tests, tool dependencies, VCS data, creative masters, local paths, account state and secrets. The receipt contains the full source commit and all payload hashes; the adjacent `.zip.sha256` identifies the exact artifact. This is a local builder with no installation, network, upload, credentials or publish operation.

Asset generation is a separate creative-source operation, never an implicit package step. The manifest binds the committed creative output. An archive's deterministic structure is compatible with the documented WoW installation convention; the current Forever uploader/flavor identifiers and actual client install still require native/dashboard validation. No uploaded project, file ID, moderation outcome or CurseForge approval exists.

## Draft description for later review (not published)

LumenShift by Northern Lights Labs brings reversible brightness modes, a compact icon wheel and a configurable Visual Studio to World of Warcraft: Forever. Night Vision starts at Brightness 75 and returns to your own captured original. Optional tint, vignette, screenshot framing and original electronic cues can be adjusted or disabled. Personal mode presets, keyboard controls, accessibility settings and explicit recovery diagnostics keep the experience under your control.

This development candidate supports a Brightness-only native writer on Forever 1.60.1.70790. Other brightness targets are experimental; Contrast and graphics-quality profiles are unavailable pending validation. UI textures are overlays, not shaders or engine color grading. Nothing automatically reapplies on login. SavedVariables can lag behind disk; restore and verify before disabling or uninstalling. Do not advertise unavailable quality tuning or claim measured performance benefits.

Original code and technical documentation use MIT, copyright 2026 Northern Lights Labs. Original artwork, icons, textures, sounds, logo and branding are All Rights Reserved; installation/use as part of LumenShift is allowed, independent reuse or redistribution in other projects requires permission. Third-party components retain their own licenses. Link LICENSE, ASSET-LICENSE.md and the source repository together; never select or describe the full package as MIT-only.

## Publication gates

1. Resolve the material quality/Contrast feature gaps or obtain an explicit product-scope decision; pass native acceptance and review remaining risks with the owner.
2. Review the exact consolidated diff/merge strategy. PRs #2–4 remain unmerged; no automatic main changes. Issue #1 remains open for incomplete validation.
3. Approve branding, authentic game screenshots, version/channel, changelog, compatibility claims and exact archive checksum. The proposed 400×400 original logo is in assets, not an assertion of approved branding.
4. Recheck current Blizzard/CurseForge policies and the live author dashboard's Forever flavor/version and license options. Choose a custom/split terms field if supported, otherwise have the owner select a truthful available representation; the full description must link both terms. No guessed project/category/game IDs or MIT-only project label.
5. Obtain final explicit owner approval before creating a CurseForge project, configuring publisher credentials or uploading. Verify moderation/publication afterward; an upload alone is not publication. No automatic publication workflow is installed.

The Phase 00 [release plan](08-CURSEFORGE-RELEASE.md) remains historical/source context; the current license and local packaging authorization supersede its earlier undecided-license/no-packaging stage. Uninstall safety, third-party terms, visible/free code and truthful feature descriptions remain applicable.
