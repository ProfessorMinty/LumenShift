# Architecture proposal — for review, not approved implementation

## Separation of concerns
A user can activate **Night Vision + Ultra** or **Cinema + Performance**. Keep **mood/visual mode** and **engine quality profile** separate, each with its own delta set. Do not persist full undocumented config blobs or apply every key on every mode change.

### Proposed future modules (names tentative)
- Bootstrap/Compatibility: client/version detection, feature gates and safe addon startup.
- CVarCatalog: researched, build-scoped descriptors (type, validator, risk, restrictions, dependencies).
- CVarEngine: read/write/verify, plans, atomic-ish rollback on partial failure; no direct writes from UI widgets.
- BaselineStore: original/owned values with session and SavedVariable lifecycle.
- ProfileStore: schema-versioned visual modes, quality profiles, customization, migrations.
- ModeController: deterministic desired state; merges baseline + quality + visual deltas.
- VisualEffects: UI-only tint, gradient overlay, optional vignette/scanlines/letterbox with adjustable opacity.
- Audio: original activation/deactivation cues; channel and mute.
- QuickWheel: orb, keyboard binding, radial UI, focus input, optional key-release behavior after research.
- SettingsPanel: native Settings integration plus full custom panel if needed.
- Diagnostics: effective/current/desired values, rejection reasons, fallback and exportable sanitized reports.
- Testing: Lua mock environment, golden state transitions, optional in-game probe harness with separate approval.

## Rule: no direct graphics writes from UI
UI -> ModeController -> Plan/Validation -> CVarEngine -> Readback -> ModeState/Diagnostics. VisualEffects and Audio receive only the committed mode result. No 'it played a sound so the CVar must have applied' success claim.

## Proposed transition states
- BASELINE: no LumenShift mode deltas active.
- PREVIEW: optional uncommitted mode/settings preview.
- APPLYING: validate and attempt eligible changes.
- ACTIVE: changes validated or specific failed/pending keys clearly marked.
- DEFERRED: blocked by combat/reload; precisely describe if/when retry occurs.
- RESTORING: revert owned CVars to captured originals, subject to conflicts.
- PARTIAL/ERROR: expose failed keys and explicit recover action.
- UNKNOWN: client changed unexpectedly; do not overwrite blindly.

## CVar ownership policy (draft for Codex to decide)
- At first write to a given key, store original, intended, and observed readback.
- Before changing from one mode to another, compute delta from current observed state, not arbitrary guessed defaults.
- If current no longer equals last value LumenShift applied (maybe user or another addon changed it), flag a **conflict**. Proposed default: respect external modification, suspend ownership of that key and ask before overriding. Research exceptions and race conditions.
- When restoring, change only keys still owned and still matching last applied values. Otherwise preserve external changes and show a diff.
- Do not blindly restore 'engine defaults' on logout. Distinguish saved baseline, recent manual choices and current client values.
- On abnormal termination, a persistent journal of pending/restoration state may help; do not claim guaranteed crash restore (Lua does not run after a hard crash).
- Client may persist settings; uninstalling the addon cannot automatically execute cleanup. Document uninstall restore-first instruction.

## Preset merge example (concept only)
Baseline: Brightness 45, Contrast 60, existing graphics settings untouched.
Quality profile Ultra: explicit, verified foliage/LOD changes only.
Visual Night Vision: Brightness 75, optional green overlay, original activation sound.
Combined effective intent: baseline + Ultra deltas + Night Vision deltas.
Switch Night Vision -> Cinema: quality delta remains intact. Only visual deltas change.
Restore Visual: return to original visual CVar values, keep selected quality profile.
Restore All: explicitly restore both layers' owned keys.

## Compatibility investigations
- Most current Forever addons report Mainline-family APIs but interface number near 16001. Check current game build, not just a prior beta.
- UI texture overlay stacking relative to boss warnings/Blizzard Edit Mode/addon frames.
- Secure frames or key-release handling in and out of combat.
- Saver/restore lifecycle at logout, reload, disconnect; state changes external addons.
- Graphics menu can change multiple CVars and reassert preset-controlled values.
- Missing CVars and no-op writes should degrade without breaking the rest.

## Technical standards for Phase 01 proposal
- No monolithic source file; narrow ownership of each module.
- No unnecessary per-frame OnUpdate for static UI; event-driven updates.
- Avoid runtime string generation inside hot loops.
- Keep SavedVariables versioned and migratable.
- Strong namespace and slash-command ownership; no global name collisions.
- Controlled build packaging and easy installation path; source tree not installed directly.
- Separate read-only diagnostics from write tests.
- Unit/mock tests for mode transitions, conflicts, missing CVars, rejected writes and combat deferral.
- No external dependencies unless a measured need is established.
