# LumenShift roadmap and stage gates
**This is a proposal. No implementation phase begins without Arctic's explicit approval.**

## Phase 00 — Research and architecture (ACTIVE)
Deliverables: actual Forever client compatibility; CVar evidence register; feasible sound/UI effects; baseline/restore/conflict state machine; UX proposal; test plan; implementation architecture; risk/decisions document.
Exit: reviewed, sourced findings; list of safe launch CVars; approval of Phase 01 scope.

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

## Phase 06 — Packaging/release
Deliverables: repeatable packaging, version/changelog, installation/uninstallation and recovery guides, license/distribution decision, game build smoke tests.
Exit: signed-off release QA and honest compatibility statement.

## Out-of-scope until separately authorized
Game hooks/injectors, OS/GPU filters, automated light sensing, live frame-based adaptive resolution, automatic raid combat responses, external key presses, DRM or prohibited game automation.

## Decision log
Use docs/07-EVIDENCE-AND-DECISIONS.md for decisions, source links and unresolved blockers. Avoid multiplying features before Phase 01 restoration is proven.
