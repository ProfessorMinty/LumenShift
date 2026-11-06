# Beta integration — development record

**Authorization:** Arctic's full-product directive, 2026-11-06. **Branch:** `feat/beta-integration`, starting at PR #4 head `0737800fcbcca789f1f65e7c972d926215c2cd06`. This branch preserves all seven commits above main from PRs #2–4. Those PRs are open and unmerged; their latest comments/review and contents were reviewed. No formal approval is inferred from Aurora's COMMENTED review. Main is unchanged.

**Current status: integrated development candidate, 0.2.0-beta.1; not an accepted feature-complete beta.** The mode system, UI, presets, optional media, schema migration and local deterministic packaging are implemented. Contrast and operational quality profiles remain evidence-blocked; integrated native UI/media/recovery acceptance is still required. See [feature matrix and tests](20-BETA-FEATURES-AND-TESTS.md), [installation](21-BETA-USER-GUIDE.md) and [QA/publication](22-BETA-RELEASE-QA.md).

## Product decisions

- Retain the tested Brightness transaction/recovery engine. Add an explicit initial-setup grant for user-triggered switching, with fresh planner/preflight checks every time. Legacy numbered recovery previews remain available for uncertain recovery, not as a routine switching ritual.
- The second read is scheduled 0.15 seconds later as an interaction policy, not a measured settling guarantee. The callback only verifies; it never writes. Unavailable scheduling refuses or retains recovery. Effects/audio commit after successful verification.
- New per-mode brightness numbers are aesthetic authored choices, not Blizzard defaults or validated native ranges. The source UI domain is 0–100; non-75 targets need the separately labeled experimental option. Ordinary initial setup does not silently grant that option.
- Contrast has readable values but no native round-trip evidence. Its mode field is validated and shown as unavailable; no Contrast writes are admitted. UI overlays supply optional warm/cool/green treatment honestly, not engine-level grading.
- No quality key has adequate native range, dependency and restoration evidence. Implement the independent profile/capability interface and explicit refusal, with live read-only scans of source candidates. No fake quality application, skipped required keys, guessed default/reset values or claimed performance gains. This remains a material acceptance gate.
- Six distinct mode editors, a labeled/clickable/keyboard radial wheel, draggable launcher and seven Studio pages use only native UI objects. No global-key reassignment, no shader injection, no world-viewport resize, no automatic hidden HUD. Optional screenshot bars/effects clear on combat; they do not automatically return afterwards.
- Original geometric iconography and synthesized electronic cues have reproducible creative source recipes. Runtime assets use the owner's All Rights Reserved terms; source code is MIT. Fonts are native game UI fonts, not redistributed font files.
- Schema 2 migrates validated schema-1 configuration by adding Studio defaults, preserving the original journal and returning a copied table. Unknown/corrupt schemas remain quarantined. Saved preferences never imply an active mode after login.
- Personal presets contain only validated mode settings, capped at 24. No executable imports, arbitrary CVar names or native-writing keys. Graphics quality selection remains independent.

## Evidence boundaries

The existing 64-test Lua 5.1 suite passed before integration. One prior owner-operated Brightness 45/75/45 round trip is recorded in [18](18-BRIGHTNESS-CLIENT-RESULTS.md). Native UI/audio, multi-mode switching, other Brightness targets, persistence, combat and adverse paths in this integrated build require fresh owner testing. No game changes are performed during development.

Pinned 70790 UI references used for the new interface: [native Settings category/canvas registration](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Settings.lua), [native frame APIs](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua), and [Camelot bindings](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_FrameXML/Bindings_Camelot.xml). These establish source availability, not native compatibility of the integrated addon. See [07](07-EVIDENCE-AND-DECISIONS.md) for existing CVar, texture, animation and audio evidence.

## Integration and distribution gates

Create one consolidated development PR to main containing the inherited history and new product changes. Existing PRs remain open for owner-directed review: either merge #2/#3/#4 in order and re-evaluate the consolidated diff, or approve the consolidated history once; do not merge overlapping PRs blindly or drop history. Check actual repository review requirements before merging; integration previously lacked permission to read branch protection.

Only create a local reproducible development ZIP, with one top-level LumenShift folder and both license notices. Do not create a CurseForge project or upload. The eventual description must disclose split licensing and experimental/unavailable functionality. Native acceptance, broader graphics evidence and final owner publication approval remain required.

## Recorded off-client result — 2026-11-06

- Lua 5.1 (development-only Lupa 2.6): **91 passed, 0 failed** — the original 64 and 27 product integration cases. Syntax passed for 21 runtime modules plus three Lua test files.
- Structural checks passed: exact TOC/runtime paths, version and binding-call alignment, original-asset hashes, only one hardcoded Brightness setter, no other graphics-writing module or OnUpdate loop.
- Python packaging/asset validation: **5 passed**. Original asset regeneration reproduced the manifest and 400×400 avatar exactly on this development runtime. The committed assets are the distribution inputs.
- Local archive construction requires clean recorded source and compares two generated ZIPs byte-for-byte; its source commit and final SHA-256 belong to the generated delivery receipt/PR.
- No integrated native tests, installed-game changes, live graphics operations, automatic merges or CurseForge upload occurred. Browser security policy blocked the local HTML layout preview; no browser/native rendering pass is claimed. Native acceptance remains open.
