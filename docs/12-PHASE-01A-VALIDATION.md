# Phase 01A — test evidence and local diagnostic handoff

**Date:** 2026-11-06. **Source version:** 0.1.0-dev.1. **Result after Aurora's review fixes:** 38 mock tests passed, 0 failed under stock Lua 5.1, plus syntax and structural checks. **Native update:** Arctic installed the diagnostic folder and supplied three matching in-game reports; load/readback/repeated-output checks passed for the observed setup. See [14-CLIENT-SMOKE-RESULTS.md](14-CLIENT-SMOKE-RESULTS.md) for exact evidence and limits. The agent did not install or operate the game. Native write/restoration/persistence tests remain NOT RUN; no release package was created.

The runtime structure and API decisions are in [11](11-PHASE-01A-FOUNDATION.md). The Phase 00 [M01–M17 definitions](05-TEST-PLAN.md) remain historical specifications; their earlier NOT RUN status is superseded for the explicitly simulated coverage below. Native evidence is limited to the separate owner-observed smoke-test record; it does not turn the mock cases into native passes.

## Reproduce the off-client checks

From the repository root, with Python 3 and a standalone Lua 5.1 interpreter:

```text
python tools/check.py
lua tests/run.lua
```

The tests load every module in TOC order, so syntax is checked during loading. Alternatively use an isolated Python virtual environment, install `tests/requirements.txt`, and run:

```text
python -m pip install -r tests/requirements.txt
python tools/check.py --mocks
```

This uses [Lupa](https://github.com/scoder/lupa) **2.6**, specifically `lupa.lua51`, for actual stock Lua 5.1 execution. It is an optional development dependency, never an addon dependency. An already isolated installation can be supplied with `--lua-runtime <directory>`. Validation here used Python 3.13 on Windows and Lupa 2.6 in a task-local scratch directory outside the repository. No system-wide package install or game modification was needed. Stock Lua has no WoW secret-value or taint system; those paths are mocked.

Executed results:

```text
STRUCTURAL PASS: 13 Lua modules, exact TOC paths, versions, zero writer references
SYNTAX PASS: 14 files under Lua 5.1
SIMULATED: 38 passed, 0 failed (Lua 5.1); no native game tests
```

The suite includes an additional generated check over all integer starting brightness values 0–100, exact raw `052.00` restoration, and a demonstration that same-value/ABA edits cannot be attributed. Fixtures use fake descriptors/client/renderer for planning and replace all known writer paths with counting traps. Only tests mutate in-memory value tables; no fixture changes a game setting.

The original implementation passed 30 tests. Before applying the review fixes, two new regression tests reproduced the findings: the falsely OK nonnumeric baseline was accepted, and the observation-only release API did not exist (30 passed, 2 failed). After the fixes, the original 30 and eight added regressions pass. Added coverage includes numeric/domain checks for new and retained originals; exact-original release with no setter result; stale/duplicate/routing refusal; fresh read/restriction failures; late drift; mixed rollback without compensation for observation-only releases; and exact raw equality versus numeric equivalence. The successful release test makes the synthetic setter-result method raise if invoked.

## Coverage and limits

| Phase 00 ID | Simulated result and coverage | Native/integration gap |
|---|---|---|
| M01 | PASS: initial load, unrelated/duplicate ADDON_LOADED, reconnect, both aliases and command arguments; zero writer/sound calls | Native load/repeated diagnostics observed; command attribution and broader collision/lifecycle testing remain limited |
| M02 | PASS: originals 45, 52, 052.00 survive repeated modes and exact release | Native accepted values, rendering, restoration |
| M03 | PASS: equal unowned target grants no ownership; an owned value at its exact original releases through verified observations with zero setter attempts, including failure cases | Native normalization; no native release executor |
| M04 | PASS: visual/quality operations and ownership remain independent both directions; all metadata target maps empty | Future populated profiles and native side effects |
| M05 | PASS: absent APIs/keys, false/nil/error/unexpected/secret values, unavailable access guards, secure/read-only/locked flags, getter drift | Readable getter results observed; native adverse secret/taint/error paths remain untested |
| M06 | PASS: NaN/infinity, strings/code payload, tables, unknown keys, missing reads, invalid ranges; falsely OK nonnumeric observations and unrestorable new/retained originals refused; no executable imports | Native domains remain unmeasured |
| M07 | PASS: synthetic success/no-op, clamp, error-after-change, unreadable readback, permitted numeric normalization | Actual setter behavior; no native setter exists in this phase |
| M08 | PASS: fail each of three ordered operations; reverse compensation to prior active values without replacing originals | Actual dependency/fan-out mapping and rollback execution |
| M09 | PASS: failed compensation retains journal and PARTIAL_ERROR | Native restrictions/failures during restoration |
| M10 | PASS: drift at planning, before operation, after readback and before compensation; one-sided cross-layer conflicts; outside values preserved | Race between final read and future write cannot be eliminated |
| M11 | PASS: 1,000 duplicate model notifications coalesce to one pending flag; no recursive apply; reads authoritative | Native synchronous events not registered/integrated in 01A |
| M12 | PASS: stale IDs/tokens, duplicate results, busy requests, cancel and late drift before final verification | No timers, delayed settle or request scheduler implemented |
| M13 | PASS: combat before first and after an earlier operation; deferred/rollback state, no automatic combat-end retry | Native combat restrictions not exercised |
| M14 | PASS: reload/character-style startup preserves records, stale/unknown/build-changed recovery, missing crash journal never captures an active value | Real reload/logout persistence and crash durability unknown |
| M15 | PASS: valid copy, corrupt/older/newer/cyclic/oversized/metatable/function/profile data refusal, originals retained | No predecessor migrations exist; live save timing unknown |
| M16 | PASS: layer overlap, tier/child conflicts both directions, dependency closure/order/cycles | Real admitted dependency catalog still empty |
| M17 | PASS: candidate/unknown build/interface, unknown renderer, unadmitted shipped catalog, unconditional boundary refusal | Version/build/interface observed; renderer and native write eligibility still open |

M18 effects/assets is outside Phase 01A. V/W/B graphics/effect/performance tests are NOT RUN and require their own approval. Passing the pure model portions above does not mean a future native executor passes M07–M13 integration tests. The implementation deliberately has no native executor or delay policy.

## Focused diagnostic smoke test

Forever **1.60.1.70790 is confirmed through the owner's Battle.net launcher and subsequent native diagnostics**, which report interface **16001**. No further launcher proof is requested. [13-DIAGNOSTIC-SMOKE-TEST.md](13-DIAGNOSTIC-SMOKE-TEST.md) preserves the installation/command protocol; the observed results are now in doc 14. No repeat of the initial smoke sequence is required merely to restate this evidence.

The more detailed guarded probes in [10-CLIENT-VALIDATION.md](10-CLIENT-VALIDATION.md) remain available for targeted follow-up if a diagnostic discrepancy needs investigation. Do not run setter commands, change Graphics sliders or enable a preset for this check. A successful read or a false security flag is not a write test.

## Optional local diagnostic installation instructions

These are instructions for a maintainer-run test after selecting/approving a test setup. The agent has not installed the addon or changed the user's game. Installing source can create/update LumenShiftDB when the client normally saves; **diagnostic-only refers to graphics settings**, not to the absence of addon configuration storage.

1. Use the already-confirmed Forever installation. The development TOC currently says **16001**, a candidate supported by prior evidence. If the client marks it incompatible/out of date or its diagnostic report shows a different interface, stop and report the mismatch; do not enable “load out of date addons” to claim compatibility. No launcher-version reconfirmation is needed.
2. With the game closed, copy **only** `addon/LumenShift/` from the reviewed implementation commit to the verified Forever AddOns directory. The result must be `World of Warcraft/_forever_/Interface/AddOns/LumenShift/LumenShift.toc`, with `Core/` beside the TOC. Do not copy the whole repository, add a wrapper folder, or overwrite Interface/WTF. If a LumenShift folder from an older prototype exists, preserve it separately and use a clean diagnostic test setup; do not mix versions.
3. Launch the Forever client and enable LumenShift for the test character. Invoke `/lumenshift`, then `/ls`. Both should print the same type of report; neither takes an apply/reset command. Check Brightness and Contrast against the independent read-only probes. Expect `FOREVER_CANDIDATE_UNVERIFIED` for the candidate tuple and zero admitted write capabilities.
4. Record the reviewed Git commit, tuple, date, addon list and sanitized report. Confirm no unsolicited sound/effect, no native Lua error, no Graphics change, and correct unavailable/unknown reporting. If CVars are not loaded yet, invoke the diagnostic again later. It does not poll or guess.
5. Stop on a native error, unexpected setting change or stale/secret output. Record the failure; do not attempt an automatic repair/reset. New evidence belongs in a reviewed follow-up, not an undocumented expansion of this phase.

Native reload/relog, cold-start and SavedVariables upgrade/persistence experiments remain separate test decisions. No hard-crash test is requested here. Do not copy private SavedVariables into an issue; report only the allowlisted diagnostics.

For an update test later, retain a private backup of existing LumenShiftDB and unresolved recovery data while the game is closed. Unknown/corrupt versions are intentionally preserved and quarantined; there is no reset command. This source version has no released predecessor schema to migrate.

For removal of **this diagnostic-only version**, close the game and remove/disable only LumenShift. This implementation has not acquired graphics ownership or changed CVars, so it has no graphics restoration step to run. SavedVariables can remain; removing addon files does not delete those files. Preserve any pre-existing recovery data for review. Settings changed by another addon, an older prototype or a future write-capable version are not restored by deleting this addon. Future write-capable uninstall requires verified restoration before removal, per [08](08-CURSEFORGE-RELEASE.md).

## Remaining approval gates

- Broader command/API compatibility and native inaccessible-value/error handling; initial 70790/16001 load and readable diagnostics are now observed.
- Real SavedVariables lifecycle, schema/update behavior and journal durability limits.
- Separately authorized Brightness write experiment with actual captured original, exact target, readback/settle/recovery card, conflict and combat tests. No targets become admitted automatically.
- Native transaction executor, timing/event integration and user recovery choices before Phase 01B acceptance.
- Eventual license/provenance, clean reproducible archive, CurseForge flavor/version metadata, policy review, installation/update/uninstall QA and explicit publication approval.

Keep Issue #1 open. Review this implementation PR without automatic merging. Stop at Phase 01A; the test results grant no further graphics, effects, UI or publication authority.
