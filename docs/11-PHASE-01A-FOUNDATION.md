# Phase 01A — foundation and API decisions

**Date:** 2026-11-06. **Source version:** 0.1.0-dev.1, unreleased. **Authority:** Arctic explicitly approved Phase 01A implementation after the engineering review accepted Phase 00 in principle. This supersedes the earlier implementation hold only for the diagnostic foundation and pure models. Live identity verification remains incomplete; it has not been inferred from that authorization.

Repository origin was verified as `https://github.com/ProfessorMinty/LumenShift.git`. PR [#2](https://github.com/ProfessorMinty/LumenShift/pull/2) was open and unmerged at `99e86236683764603d86b579e56b7dfb76a20287`, with no GitHub review comments. The implementation branch `feat/phase-01a-foundation` starts at that exact head, retaining both research commits. The engineering acceptance is the owner's conversation instruction, not a fabricated GitHub approval. Main and the research branch are not modified. Docs 00–10 and the historical prototype reference are preserved unchanged.

## Runtime boundary

The installed runtime consists only of [the TOC](../addon/LumenShift/LumenShift.toc) and its ordered Lua modules. No libraries, images, audio, XML, timers, hooks, world scanning, polling or networking are required. The diagnostic interface prints a bounded text report to the default chat frame using either `/lumenshift` or `/ls`; arguments do not execute operations. No settings UI or presets are active.

**Core/WriteBoundary.lua is the single future graphics-writing boundary.** Its only operation returns `PHASE_01A_READ_ONLY` unconditionally. There is no native writer, injected setter, enable flag or hidden bypass. The controller's runtime apply entry delegates only to this boundary. The read adapter and every other module are prohibited from using setters or equivalent writers. Source checks reject writer references throughout this phase, including the dormant boundary; mock globals trap writer calls. These checks support code review, not a claim of a formal security sandbox against arbitrary future edits or other addons.

| Module | Implemented responsibility |
|---|---|
| Namespace / Value | Version and namespace; finite values; bounded acyclic data copies; no executable configuration |
| ReadOnly | Exact namespaced getters, API presence, readiness, accessibility, typed results, explicit errors; no legacy aliases or console fallback |
| Compatibility | GetBuildInfo readback and exact candidate tuple comparison; all future writes disabled |
| Catalog | Brightness/Contrast diagnostic candidates, evidence and UI domains; **zero admitted write descriptors** |
| Profiles | Six visual modes and four quality profiles; separate selections/definitions; metadata and empty target maps only |
| Store | Schema 1; validation before replacing saved globals; invalid/unknown data preserved in place |
| Planner | Pure, bounded diff planning; measured-catalog admission predicate; layers, dependencies, conflicts and per-key captures |
| Recovery | Pure transaction/ownership model; immediate/final verification, reverse compensation plans and retained conflicts; read-only startup inspection |
| Controller | Serialized state/token model, coalesced observation flag, stale-event rejection; dormant runtime apply |
| Diagnostics | Allowlisted build/API/value/flag/status report; bounded static error codes; no account data or raw saved-table export |
| Bootstrap | Bind SavedVariables on the addon's own ADDON_LOADED, register slash commands, then unregister the load event |

Only Bootstrap and ReadOnly access the native environment. Compatibility and Diagnostics use the adapter's inspected environment for their specific read/output responsibilities. Pure modules neither call game APIs nor execute their plans. Runtime never calls the synthetic transaction path. CVAR_UPDATE is not subscribed in 01A; the controller's notification-coalescing model is tested without a native event handler. User-invoked diagnostics read fresh values. Missing readiness information prevents CVar reads; there is no timer waiting for CVars to load. Invoke the command again when the client is ready.

## Identity and source decisions

- **Owner-observed in-game update:** version 1.60.1, build 70790, interface 16001, addon loading and Brightness/Contrast getter/flag output are now documented in [14](14-CLIENT-SMOKE-RESULTS.md). **Still unknown:** full GetBuildInfo tuple including date, renderer, native write permission/behavior and SavedVariables persistence. Earlier source-only assumptions below remain separate from this narrow native observation.
- **Source-confirmed for 70790:** the pinned [CVar API declaration](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/CVarDocumentation.lua) declares namespaced readiness/get/default/info functions. GetCVarInfo is interpreted as seven separate results: current, default, account storage, character storage, user lock, secure, read-only. Unexpected shapes are reported, never treated as writable evidence. See SRC-02/10 in [the evidence ledger](07-EVIDENCE-AND-DECISIONS.md).
- **Source-confirmed UI domains only:** [Graphics.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua#L1564) declares Brightness/Contrast sliders from 0 to 100. The runtime keeps these as UI evidence, not measured native ranges. No other register entry is automatically promoted into the diagnostic or write catalog.
- **Candidate TOC:** a single Forever-targeted `LumenShift.toc` uses interface 16001, supported by older third-party captures/TOCs (SRC-01/03). It remains explicitly provisional until native R1 and load checks confirm it. A tuple match reports `FOREVER_CANDIDATE_UNVERIFIED`, not certified compatibility. Other tuples report unsupported; diagnostics remain read-only where the client loads the addon. There is no invented Forever project constant or Retail threshold.
- **Access handling:** available `canaccessvalue` / `issecretvalue` checks must permit every native result before comparison, formatting or storage. If both are absent or a check fails, report `ACCESS_UNVERIFIED`. Native errors are not exported. Getter/default/info results remain separate; inconsistent reads report drift. Security flags are observations, never authorization.

The absence of an active writer means no rendering change, accepted target, combat permission, taint behavior or native restoration has been verified. Source declarations and stock Lua tests cannot establish those facts.

## Configuration and admission

Visual metadata: Natural, Night Vision, Cinematic, Lantern, Clarity, Moonlight. Quality metadata: Current Baseline, Balanced, Vista, Performance. Each has its own namespace and selection. Saved selections are preferences, never evidence that a mode is active. Every target map is empty and disabled; user imports/custom targets are refused in this phase. Sound and animation preferences default off, reduced motion on; no presentation component consumes them yet.

Brightness 75 occurs only as a future design example and an off-client test fixture. Natural must eventually release only visual ownership and restore the captured original, including a non-45 value. Current Baseline releases only quality ownership. Tests use **synthetic admitted descriptors and a MOCK client/renderer**, held exclusively in tests/run.lua, to exercise these cases. They do not populate the shipped catalog.

A future admitted descriptor must name exact client signature/renderer, measured numeric domain, client scope, descriptor version, reviewed dependencies/conflicts and an evidenced immediate settling policy. Flags must explicitly permit the operation. No universal asynchronous settling assumption is implemented. Keys with different timing or storage scope need a later reviewed extension. Unknown keys, missing dependencies, cycles, one-sided tier/child conflicts, layer overlap and mixed dependent release/apply transitions refuse the entire plan. Existence or a successful getter never admits a key.

## Ownership, transactions and recovery

Schema 1 stores addon version, separate configuration layers and a journal `{entries, nextEpoch}`. A key retains originalRaw, lastVerifiedRaw, intendedRaw, layer, epoch, state, descriptorVersion, signature and optional static failure code. Raw baselines are never replaced across mode switches. Up to 64 entries are accepted; copies are also bounded to 4096 data nodes, depth 12 and 256-character strings. Raw values have a stricter 64-character bound. Extremely large in-memory transaction copies may be refused at the copy limit; a future executor must treat refusal as no permission to operate.

Validation copies data before committing the new root. Invalid, cyclic, executable, metatable-bearing, oversized or unfamiliar schema data leaves the original global untouched and reports RECOVERY/quarantine. There is **no released predecessor schema**; older/newer versions are explicitly refused, not guessed or reset. Thus no speculative migration runs. A future migration must implement copy/validate/migrate/validate/commit with retained rollback data and its own tests. Unknown historical journal names can be retained for recovery, but are never read or planned as newly admitted keys. No character-specific startup replaces an existing account-level journal.

The internal pure API consumes a validated planner result, not arbitrary deserialized operations:

1. Planner returns operations with transaction beforeRaw, epoch originalRaw, intended target and dependency order. It independently parses finite numeric observations, even when a caller labels them OK; new and retained originals must be numeric and within the admitted descriptor's domain. An unowned value already equal to its target generates no operation or ownership. Numeric equivalence is descriptor-specific; release retains the exact original string.
2. Recovery.Begin copies the journal and captures all originals before any simulated operation. Before checks transaction ID, operation order, combat/restrictions, security flags and fresh raw equality for `write=true` operations. It refuses `write=false` operations. It never authorizes a native call.
3. Observe consumes a **mock result** and readback only for `write=true`. Setter success alone is insufficient. Failed/no-op/clamped/unreadable results request rollback. For `release=true, write=false`, ReleaseObserved instead checks a fresh safe observation against the exact captured original and releases ownership without a setter result. Its observation is tracked in `releases`, separately from setter `attempts`. Both paths remain AWAITING_VERIFICATION until Verify checks their observations again. Late drift prevents VERIFIED and preserves recovery data.
4. RollbackPlan walks attempted keys in reverse to their **transaction before-values**, preserving the epoch baseline. It proposes compensation only if a fresh value matches the observed result of that attempt. Observation-only releases undo journal bookkeeping without any compensation operation; fresh drift or an unreadable value retains a conflict record. BeforeRollback requires another fresh read, safe flags, explicit absence of combat and correct reverse order. ResolveRollback verifies the result. Conflicts and failures retain originals and PARTIAL_ERROR; unattempted conflicts are not falsely reported as recovered.
5. Startup Inspect never resumes or restores. Even equal values report matching **unverified** ownership. Changed builds, inaccessible keys and external drift remain recovery problems. Nothing auto-retries after combat or reload.

These are models and plans, not a deployed transaction executor. A future executor must supply fresh observations, serialize callbacks through the controller, honor every refusal, retain journals and validate native behavior. No timer scheduling, actual setter/readback integration, partial restore UI or live conflict-resolution choices exist yet. Controller state transitions model INSPECTING, BASELINE, PREVIEW, DEFERRED, APPLYING, ACTIVE, RESTORING, ROLLING_BACK, CONFLICT, PARTIAL_ERROR and RECOVERY; applying/restoring transitions have no runtime callers. Test-only result processing also uses AWAITING_VERIFICATION/VERIFIED.

There is no atomic compare-and-set. Equal values cannot reveal same-value writes or ABA changes; even the last read can race a later native write. SavedVariables are memory until the client saves them. A crash may lose or stale the journal, and a missing journal does not prove settings are original. No crash-proof restoration, immediate flush or cleanup after uninstall is claimed.

## Distribution boundary

The ordered TOC gives a reviewable runtime path list; tools/check.py checks exact membership/casing, duplicates and version alignment. This supports a later deterministic packaging manifest but creates **no archive, tag, release workflow or upload**. All implementation is readable original Lua; no third-party runtime code or assets were imported, including the historical alpha. The optional Lupa development runner is outside the runtime tree.

The owner has not selected a license. No license was invented. The [CurseForge release requirements](08-CURSEFORGE-RELEASE.md) remain open: native Forever compatibility/flavor/interface validation, policy/license/provenance review, artifact QA, installation/update/uninstall tests, authentic captures, owner-approved metadata and moderation. Issue #1 remains open. Completion of this source phase does not authorize Phase 01B or publication.

## Aurora review follow-up — 2026-11-06

The numeric-baseline and observation-only release refinements above address [Aurora's review on PR #3](https://github.com/ProfessorMinty/LumenShift/pull/3#pullrequestreview-5806213704). The motivating case is original 52 -> owned 75 -> another selected mode returns 52 while ownership remains -> Natural releases ownership without another setter attempt. Exact raw equality is required; numeric equivalence alone does not qualify. Fresh-read errors, restrictions, stale IDs, final drift and mixed transaction failures are covered by regressions. The runtime boundary, namespace, SavedVariables schema and diagnostic behavior are unchanged. See [updated results](12-PHASE-01A-VALIDATION.md) and the [focused smoke test](13-DIAGNOSTIC-SMOKE-TEST.md).
