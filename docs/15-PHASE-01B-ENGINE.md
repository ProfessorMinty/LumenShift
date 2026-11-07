# Phase 01B — reversible Brightness engine

**Recorded:** 2026-11-06. **Version:** `0.1.0-dev.2`, unreleased. **Implementation branch:** `feat/phase-01b-brightness-engine`, based on PR #3 head `ddf04c91c72dec80468c9a41cf07cd0d7dad7407`.

Arctic authorized implementation and mocks, with a separate approval gate for actual in-game graphics tests. No live writes or installed-game changes were performed by the agent. Docs/00–14 retain their historical evidence and scope. [16](16-BRIGHTNESS-ACCEPTANCE.md) is the current user handoff; [17](17-MERGE-SEQUENCE.md) records merge readiness and remaining approval requirements.

**Owner-operated follow-up:** Arctic subsequently completed the first controlled native round trip. [18](18-BRIGHTNESS-CLIENT-RESULTS.md) records the 45 → 75 → 45 readbacks, exact-original release, final BASELINE/zero records and owner-confirmed visual change/restoration. This evidence does not promote the catalog or authorize additional tests automatically.

## Evidence and admission

| Classification | Evidence and limit |
|---|---|
| Verified in-client, owner-observed | [Phase 01A smoke reports](14-CLIENT-SMOKE-RESULTS.md): Forever `1.60.1:70790:16001`, readable Brightness `45`, Contrast `60`, native getters/access guards, all relevant observed flags false. This tested dev.1 diagnostics, not dev.2 writes. |
| Verified in-client, owner-observed | [Phase 01B result](18-BRIGHTNESS-CLIENT-RESULTS.md): dev.2 Brightness 45 → 75 → exact 45, successful verification messages, ownership released, final BASELINE and zero records. Contrast is 60 in the before/final reports. Arctic separately confirmed both visual changes looked correct. |
| Source-confirmed for 70790 | [CVar documentation](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/CVarDocumentation.lua#L208) declares the namespaced setter and boolean result; restrictions/predicates can prevent a usable result. This is a pinned Blizzard UI-source mirror, not binary verification. |
| Source-confirmed UI bounds | [Graphics.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua#L1564) declares 0–100 UI sliders. These are not measured native limits or a safe-range certification. |
| Controlled experiment policy | Only Brightness, on the exact observed build/interface, may plan a target of 75 or restoration of a captured original inside the conservative 0–100 UI domain. Descriptor evidence is `CONTROLLED_TEST_01B`, never `VERIFIED_CLIENT`. |
| Unknown | Native adverse setter/recovery paths, measured settling interval, originals other than 45, combat transitions, persistence, crash recovery and other machines/renderers. Successful guard checks on this one path are inferred from source and success messages, not direct API instrumentation. |

The production catalog remains unadmitted. `Catalog.BrightnessExperiment` provides an explicitly separate test context; the planner rejects any other participating key, even a historical recovery entry. Renderer verification is still absent: the test exception permits measurement on this observed setup, not general support. The legacy compatibility string `FOREVER_CANDIDATE_UNVERIFIED` describes write admission; known loading/getter evidence remains valid. Unknown builds cannot enter the test context. No fallback to legacy globals or other writers exists.

## Modules and execution

The existing 13-module TOC and schema version 1 remain. `Bootstrap` binds validated SavedVariables, registers the two slash aliases and a notification-only `CVAR_UPDATE` handler. It never invokes an operation. `ReadOnly` still provides getters, capability inspection and guarded API-result handling. Its `Call` helper also validates the boundary's setter result; it does not select or discover any writer itself.

`Catalog` defines the narrow experiment descriptor. `Planner.Build` independently validates numeric, restorable originals, flags, ownership, layer separation and targets. `Recovery` remains a pure transaction model with before/observe/verify, rollback and observation-only release transitions. `Profiles` keeps six visual modes and four quality profiles as independent, disabled metadata; the test engine does not activate their generic target maps or change their selections.

`Controller.Command` dispatches explicit commands to `WriteBoundary.New`. The existing generic pure controller model is preserved for its tests/future orchestration; runtime experiment state is held privately by the boundary. There is exactly one native graphics mutation call site: `C_CVar.SetCVar("Brightness", target)` inside `WriteBoundary.lua`. The private writer is used by both planned operations and model-approved compensation. No public raw setter is exported. The old generic `Request`/`Controller.Apply` still refuses with `TEST_NOT_ENABLED`.

Before a write, the boundary requires a valid bounded journal with no other keys, the exact client signature, setter availability, an accessible boolean `false` from `InCombatLockdown`, readable numeric Brightness and all five flags explicitly false. It checks fresh current values at plan, confirmation, model preflight and immediately before the setter. The last combat check is after the final read. No timer, polling loop, event handler, startup path or saved setting grants write permission.

## Confirmation, ownership and recovery

1. `/ls on`, `/ls off` or `/ls restore` reads and plans only. The chat recovery card shows build, exact original, current and proposed target. Failure to display the card prevents a token. The user must save the card outside the game before confirming.
2. `/ls confirm N` consumes that one-use token even on refusal. It checks that neither current Brightness nor the source recovery journal changed, replans, and enters the pure transaction model. The journal holds the original in memory before any possible write. This is **not** an immediate disk save.
3. A setter must return exactly one accessible boolean `true`. An immediate fresh observation must match the target (numeric equivalence allowed for activation; exact raw equality required for restoration). Nil, false, errors, secret/unexpected values, no-op success and clamps cannot become verified success.
4. The engine stays `AWAITING_VERIFICATION`. `/ls verify` later performs a separate fresh read. Only a matching observation finalizes active ownership or drops a restored record. There is no invented settling delay; this is a second observation, not proof of indefinite stability.
5. External drift detected by commands/status or later verification retains the original, enters `CONFLICT`, invalidates permission and does not retry. Events merely coalesce a pending-notification bit; they do not trust payloads, read or write.
6. `/ls restore` is explicit reconciliation, including after conflict/reload. It previews replacing the freshly observed current value with the retained original. A new confirmation is mandatory. The original is never recaptured from the uncertain current value. Wrong-build, malformed, other-key or out-of-domain recovery is refused and preserved.

For a normal same-session on/off failure, the pure rollback model can authorize at most one compensating Brightness write. The compensation must pass the same fresh restrictions and exact expected-value comparison. It restores the transaction's prior value, which can be 75 for a failed deactivation; it does not discard the first original. Immediate successful compensation keeps the recovery record until a separate `/ls verify`. Partial failure keeps a failed/conflict record. A changed/unreadable value prevents compensation. This bounded compensation is disclosed in the preview, not a background retry policy.

An explicit recovery after reload, a pending operation or external conflict **never automatically compensates back to its uncertain current value** if restoration fails. Late drift during manual verification likewise never triggers automatic compensation. Reload creates `RECOVERY` from every saved ownership record and restores no session permission. Missing/unwritten SavedVariables cannot be reconstructed; the external card is the fallback evidence.

Already at 75 without ownership means no operation and no capture. If a retained original already exactly equals current Brightness, explicit restore takes `Recovery.ReleaseObserved`: no setter, no invented setter result, and a later verification before release. Numeric equality alone does not satisfy exact raw restoration.

## Visible states

| State | Meaning / next action |
|---|---|
| BASELINE | No owned setting; `on` may preview a controlled test. |
| ACTIVE | Current-session activation passed both reads; `off` previews exact restoration. No recurring writes. |
| AWAITING_VERIFICATION | Immediate result or compensation observed; original retained; use `verify`. |
| CONFLICT | Current setting drifted or became restricted; preserve it, inspect diagnostics, explicitly preview `restore` only if intended. |
| RECOVERY | Reloaded, cancelled pending operation or failed explicit recovery; no automatic action. |
| PARTIAL_ERROR | Compensation unresolved; original retained; inspect and use explicit recovery only after review. |

Preview token and operation are separate displayed fields. `cancel` revokes a token; it does not restore a setting. Cancelling pending verification retains recovery. Generic data/schema errors preserve SavedVariables in quarantine and refuse the engine. Synchronous command reentry is refused as busy.

## Validation — simulated, not in-game

On 2026-11-06, the prior PR #3 suite passed **38/38** before changes. The final Phase 01B suite passes **64/64 under Lua 5.1**, using development-only Lupa 2.6. The 38 foundation scenarios, including Aurora's numeric-baseline and no-setter regressions, remain. The phase-specific refusal string and command dispatch expectations were updated; no old scenario was dropped.

Run from the repository root:

```text
python tools/check.py --mocks
```

The runner requires the pinned development dependency in `tests/requirements.txt`; an isolated installation may be passed through `--lua-runtime PATH`. Alternatively run `lua tests/run.lua` with Lua 5.1 and `python tools/check.py` for structural checks. No dependency is shipped in the addon.

| Coverage | Result |
|---|---|
| Existing M01–M17 and subsequent pure-model regressions | 38 PASS; includes 101 generated starting-value round trips |
| B01–B08: locked startup/diagnostics, exact round trips, tokens, invalid baselines, card display, APIs/flags/build and fresh drift | PASS |
| B09–B17: setter/result failures, bounded/failed compensation, delayed drift, external edits, reload, explicit recovery, no-setter release and combat | PASS |
| B18–B26: reentry/events, corrupt/revised journals, stale previews, normalized readback, admission, slash routing and restoration failure | PASS |
| Lua 5.1 syntax | PASS: 13 runtime modules plus test harness |
| Structural checks | PASS: exact TOC/runtime file list, versions, one Brightness-only mutation call site; other writer/fallback/effect APIs prohibited |

The native-boundary mocks call the real executor with a fake `C_CVar.SetCVar`; every other writer remains a failing trap. They only mutate Lua tables. Tests assert originals and a displayed card precede every attempted call. Structural scans are regression checks, not a proof against arbitrary malicious code. These are local results, not GitHub CI or an independently reviewed native pass.

## Remaining risks and release gates

- One owner-operated native write/restoration and visual round trip now passed; see [18](18-BRIGHTNESS-CLIENT-RESULTS.md). Other baselines, native failures, repeated-cycle reliability and broader rendering behavior remain untested. Readbacks alone do not prove a visual effect; the visual result is a separate owner report.
- Getter checks and setter are not atomic. Same-value external writes, ABA changes and a writer acting inside that gap cannot be reliably attributed. A synchronous clamp and an external change can be indistinguishable; compensation uses observed values and fresh comparison, not a claim of exclusive control.
- Exact raw restoration may fail if the client canonicalizes a value. It fails closed, retains the original and requires review; it does not silently redefine the baseline.
- `InCombatLockdown` absence, nil or an unexpected shape refuses the experiment. Source plus the successful round trip implies the guard allowed that path; direct result capture and native combat transitions remain untested. Its strict policy is unchanged.
- SavedVariables can lag in-memory state or be lost on a crash. No immediate persistence or crash-proof restoration claim is made. No automatic on-login recovery is attempted.
- Other CVar targets, broad preset activation, effects/audio/shaders/radial UI, performance claims, Phase 02, licensing and release packaging are not implemented here. [CurseForge requirements](08-CURSEFORGE-RELEASE.md) remain open: owner-selected license, asset provenance, actual version/flavor tagging, reproducible release packaging, native QA and approval. No release, project or upload was created.
