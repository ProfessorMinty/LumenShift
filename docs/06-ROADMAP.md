# LumenShift roadmap and stage gates
**This is a proposal. No implementation phase begins without Arctic's explicit approval.**

## Phase 00 — Research and architecture (REVIEW PENDING)
Deliverables: actual Forever client compatibility; CVar evidence register; feasible sound/UI effects; baseline/restore/conflict state machine; UX proposal; test plan; implementation architecture; risk/decisions document.
Source investigation and proposal are complete for review in [09](09-PHASE-00-FINDINGS.md). Client compatibility acceptance remains open. Exit requires reviewed evidence/unknowns, a separately authorized client validation path and explicit approval of Phase 01 scope. There is currently **no verified safe launch CVar list**. Keep Issue #1 open; do not silently mark its client checks complete.

## Phase 01 — Minimal reversible core
Deliverables: addon skeleton/TOC, module architecture, capability detection, baseline capture, safe CVar read/write/readback, explicit Restore My Settings, SavedVariables schema, basic slash commands and mock tests. One approved CVar only at first.
Exit: confirmed in-game round-trip restoration and no unrelated writes.

## Phase 02 — Visual modes
Deliverables: baseline, Night Vision, Clarity, Lantern, Cinema and Moonlight using verified CVar deltas; honest tint/vignette/letterbox layers and original sound; ability to disable effects.
Exit: approved mode matrix works in client and returns to baseline; Cinema cannot obstruct gameplay by default.

## Phase 03 — Interface experience
Deliverables: compact radial wheel; draggable orb; configurable bindings; advanced settings window; accessible tooltips; active mode and pending state; effect controls; responsiveness.
Exit: comfortable at different aspect ratios, accessible, and no protected/mouse input errors; hold/release only after API validation.

## Phase 04 — Advanced graphics quality
Deliverables: validated CVar catalogs, independent Baseline/Balanced/Vista/Performance profile system, per-key warnings, restore/conflict resolution, benchmarking records and selective graphics-menu interaction handling.
Exit: known behavior on target build, measured cost where possible and zero silent destructive changes.

## Phase 05 — User-created presets and polish
Deliverables: safe preset clone/edit/import/export, visual transition polish, onboarding/warnings, error and diagnostics improvements, optional zone suggestions only if user explicitly approves.
Exit: no data loss on migration and all presets validate against capability set.

## Phase 06 — CurseForge packaging / release
Deliverables: approved public license, source/asset provenance review, verified Forever-flavor TOC, reproducible clean runtime ZIP with one top-level addon folder, automated syntax/structure checks, version/changelog, installation/uninstallation and CVar recovery instructions, real in-game compatibility and UI smoke tests, CurseForge description/logo/authentic screenshots, correct game-version/release-channel tagging, and policy/moderation compliance. See docs/08-CURSEFORGE-RELEASE.md.
Exit: owner-approved release artifact and submission, with confirmed moderation outcome before claiming it is published. No automatic publishing without explicit opt-in. The release distribution pipeline must be designed before Phase 01 code architecture is finalized.

## Out-of-scope until separately authorized
Game hooks/injectors, OS/GPU filters, automated light sensing, live frame-based adaptive resolution, automatic raid combat responses, external key presses, DRM or prohibited game automation.

## Decision log
Use docs/07-EVIDENCE-AND-DECISIONS.md for decisions, source links and unresolved blockers. Avoid multiplying features before Phase 01 restoration is proven.

## Actionable Phase 01 proposal (no authorization implied)

Split the minimal reversible core into two approval scopes so approving architecture does not imply permission to change a player's settings.

### Phase 01A — Diagnostic foundation and pure core

Entry: Arctic approves this scope; R1 establishes the actual interface/build; source/API discrepancies are reviewed. Implementation may then create a minimal Forever-only TOC and modules, read-only diagnostics, schema, pure planner and mocks. No automatic writes, live setting experiments, imported alpha, wheel, effects, audio, quality presets or publisher configuration.

Acceptance:

- Exact client identity recorded; required functions checked; unsupported builds enter read-only mode.
- Fresh load and saved-state load produce zero graphics/audio writes.
- Diagnostics capture allowlisted raw values/defaults/flags without private data and distinguish unknown from unsupported.
- Saved data binds at the correct lifecycle event; mock corruption/migration handling preserves recovery data.
- Pure planning and ownership cases M01–M17 pass off-client; tests state which security behavior is simulated.
- The proposed runtime file list/load order is reviewable; no release artifact or upload is implied by a development TOC.

Installation and any persistence test still require their own approval. A mock pass alone does not authorize Phase 01B.

### Phase 01B — One reversible CVar

Entry: approved installation/test environment, successful read-only checks, approved recovery card, verified flags and allowed target, persistence test plan, and explicit permission for the exact Brightness round trip. First target proposed: 75; baseline must be the actual captured value. Do not expand to Contrast/quality merely because the writer is generic.

Acceptance:

- W1 demonstrates actual baseline -> 75 -> exact baseline, including a non-45 baseline when safely available; immediate/settled readback and visible effect recorded.
- W2 demonstrates external-edit preservation and no unrelated-key changes; all discrepancies remain visible.
- W3 demonstrates load/save timing and read-only recovery across approved reload/relog/cold start; no baseline recapture from an active delta.
- W4 demonstrates combat deferral without restricted setter attempts; no automatic later application or false cue.
- Restore failure leaves a usable journal and actionable diagnostics; crash/uninstall limits documented.
- No live errors or unexplained mutations in the approved test matrix. Only after review does C01 become admitted for that build.

## Later phase acceptance refinements

| Phase | Dependency | Concrete exit evidence |
|---|---|---|
| 02, modes/effects | Approved C01 and separately admitted additional visual keys | Exact numeric mode matrix reviewed; all six names retained as concepts until ready; each mode round-trips; tint/audio/motion independently off; no quality-key writes |
| 03, interface | Stable core and reviewed input API results | V1 matrix passes; click/keyboard/Escape work; no accidental selection or critical HUD obstruction; hold/release/gamepad explicitly tested or clearly omitted |
| 04, quality | Each key's R/W/V/B evidence and dependency closure | Exact profiles populated from measured values; no tier/low-level collision; no unapproved keys or overall-preset shortcut; per-key restore and visual independence verified |
| 05, custom presets | Stable schema and catalogs | Data-only bounded imports, finite values, unknown-key rejection, migration/rollback tests, accessible onboarding and diagnostics |
| 06, release | All supported features tested and owner-reviewed scope | Exact ZIP validated; license and asset ledger approved; live flavor/interface/tagging checked; fresh install/upgrade/uninstall pass; owner approves specific artifact and metadata; moderation outcome observed |

Each phase needs explicit approval. No launch date, license, CurseForge account or project identifier is selected here.
