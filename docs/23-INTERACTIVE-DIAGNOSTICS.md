# Self-diagnosing interactive development build

This records the dev.2 diagnostic/calibration implementation. [Dev.3 guided setup](24-GUIDED-SETUP.md) supersedes its command-first handoff, module/schema counts and test totals; the engine policies and diagnostic limits below remain applicable.

**0.2.0-dev.2 · schema 3 · Forever 1.60.1:70790:16001 · 2026-11-06**

This implements the owner's newer directive on existing `feat/beta-integration` / draft PR #5. Functionality and diagnostic feedback take priority over publication preparation. **Arctic has not installed/tested 0.2.0-beta.1 or this integration.** The older 0.1.0-dev.2 Brightness 45/75/45 result in docs/18 does not certify these builds. No game files or settings were changed by development tools.

## Connected experience

All six modes, wheel/launcher/bindings, eight Studio pages, customization, optional textures/audio and bounded personal presets remain connected. Audio is muted initially. Brightness retains setup and a separate non-75 experimental opt-in. Successful same-login Contrast calibration enables that exact target for optional use by a mode. Natural releases visual ownership independently of quality.

Balanced, Vista and Performance are user-configured experimental target sets, initially empty, maximum eight leaf keys. Every target needs successful calibration this login. Partial profiles are refused; no defaults or FPS benefits are invented. Current Baseline restores owned quality keys only. The older `Quality.Select` production metadata API remains closed for nonbaseline profiles; Studio uses the boundary's experimental `SelectProfile` path. Production catalog admission remains empty.

## Diagnostic architecture

The TOC loads 27 Lua modules without runtime libraries. New modules:

| Module | Responsibility |
|---|---|
| Core/Build | Checkout marker replaced deterministically with source commit in the ZIP |
| Core/Log | 240-event session ring, last 32 warnings/errors, per-key latest operation and severity totals |
| Core/ExperimentPolicy | Exact leaf allowlist, test bounds, strict profile/schema validation and descriptors |
| Core/Report | Runtime observations, read-only checks, structured redacted report and export fallback |
| UI/DiagnosticWindow | Reusable scrollable multiline EditBox, Select All, Ctrl+C instructions and refresh |
| UI/Calibration | Capability/target preview, explicit confirmation, quality editing and recovery previews |

Events include sequence/available runtime time, subsystem, operation, severity, result and allowlisted original/before/request/setter/immediate/follow-up/error fields. No polling/OnUpdate or debug chat stream. One error notice per login points to `/ls report`. Owned slash, binding, event, widget and scheduled handlers are guarded. Raw native error text/stacks are discarded because they can expose names/paths/third-party data. No global error hook; pre-bootstrap syntax failures and unrelated errors may be outside the report.

Startup and Run Diagnostics read actual GetBuildInfo, API availability, flags/default/current values, physical resolution, UI dimensions/effective scale, renderer enum, combat, module/UI/data state. PASS means the named read/availability/structure check passed, not native graphics acceptance. FAIL, BLOCKED and NOT TESTED are distinct. Last-completed check results are labeled; report environment/CVar observations are fresh. Reads are not an atomic snapshot.

Report sections cover build/environment, capabilities, watched graphics/security/session-tested targets, configuration without preset names, both journals/previews/watched changes, tests not performed, availability reasons, recent issues, chronological history and problem counts. Missing values include reason codes. Names/chat/account IDs/credentials/install paths/unrelated globals are never queried; numeric data, version/date formats and renderer enums are validated. History is bounded; export has a 120,000-character cap with a truncation notice. No upload, clipboard API or game-side file access is assumed.

Asset API acceptance and sound handles are distinguished from actual rendering/audibility. Visible effects, decoding, audio, native input, persistence and unobserved dependencies remain NOT TESTED by the read-only checks. User-initiated Audio previews and interaction test them. Native export focus/scroll/copy still needs acceptance.

## Experimental policy and source evidence

Observed 2026-11-06; exact client signature required. Accessible numeric reads and all required false security/restriction flags precede every write. Missing APIs/timer, unknown flags, combat, malformed data and mismatched builds refuse. A source UI range is not a measured safe/effective native range.

| Leaf | Explicit test policy | Evidence classification |
|---|---|---|
| Contrast | 0–100, integer | Source-confirmed UI domain for 70790; write/effect/restore unknown |
| ResampleSharpness | Raw 0–2, step 0.1 | Source-confirmed reversed UI mapping; native effect unknown |
| bloomUserMult | 0–1, step 0.2 | Source-confirmed conditional UI control; pipeline/effect unknown |
| ResampleAlwaysSharpen | 0/1 | Experimental boolean hypothesis, not native admission |
| groundEffectDensity / groundEffectDist | At most ±32 / ±40 from original | Addon test-size limit, not a native range |
| lodObjectCullSize / lodObjectFadeScale | At most ±2 / ±20 | Addon test-size limit, not a native range |
| farclip / terrainLodDist | At most ±250 / ±100 | Addon test-size limit, not a native range |
| weatherDensity | At most ±1 | Addon test-size limit; spelling/effect unconfirmed in-client |

Relative radius is `min(key_limit, max(1, abs(original) * 0.1))`, clipped to the addon's 0–10000 envelope; integer targets. These are **experiment limits, not safe maxima or performance promises**. Out-of-policy originals refuse. No target is automatically selected/applied. Preview shows exact current/original/target and watch coverage.

Pinned Blizzard UI mirror for 70790: [Graphics.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua), Contrast/ResampleSharpness/bloomUserMult sections; [SimpleEditBox API](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleEditBoxAPIDocumentation.lua), SetMultiLine, SetFocus and HighlightText (0 to -1 selects all). Source evidence is not a live result. Earlier candidate provenance remains in docs/07 and Quality.Candidates; inclusion in this allowlist does not promote community/code evidence to native validation.

Shadow/light/water tiers, reflection enums, HDR/renderer/camera and overall presets remain observation-only: indirect child-setting changes, domains and hardware/restart contracts are unmapped. This is a specific unresolved dependency limitation, not a claim that the whole graphics feature group is impossible.

## One writer and restoration protocol

WriteBoundary has exactly one private native `C_CVar.SetCVar` invocation, shared by the preserved Brightness engine and new leaf engine. All operations use pure Planner/Recovery proposals and fresh checks. There is no raw setter interface. Schema 3 adds a disjoint experimental journal, numeric quality profiles and bounded numeric watched-change records. Schema 1/2 migration copies validated data and retains original strings; malformed/newer data is quarantined untouched. Brightness stays in its old journal. Calibration permissions are memory-only, at most eight targets per key, and expire on reload.

1. Preview an exact permitted change and export/save it externally. Page opening and previews are read-only.
2. Confirm its one-use token. Re-read/replan, reject changed journal/observations and capture all originals before any setter.
3. Apply once, check native boolean success and immediate effective read, then observe named watched settings.
4. After about two seconds, make a fresh read/watch check. This is an observation interval, not a measured settling guarantee.
5. If trustworthy, plan exact-original restoration and verify again after a later timer turn (0.15 seconds). Only then grant the exact experimental target this login. Activation may accept numeric equivalence; restoration must match the captured raw string exactly.

Watch coverage includes Brightness/Contrast, quality candidates, Gamma/render scale and selected graphics/tier controls. Changed or newly unreadable previously readable non-target values stop automation. Numeric before/after changes persist; attribution is explicitly “dependency or external change.” Unknown/unreadable keys and unenumerated engine state are coverage gaps. No guessed dependency closure or automatic overwrite of unrelated watched values. Watch observations remain marked unresolved for review; restoring the primary key does not prove the whole scene restored or clear these records.

Synchronous ordinary failures may make one bounded reverse compensation per attempted key, followed by fresh readback. Errors/clamping/no-op/partial failure never earn permission. Conflict, late drift, reload uncertainty, watch drift or explicit recovery failure never causes an uncertain automatic reapply/restore. Explicit recovery requires a fresh displayed preview/confirmation; already-original recovery releases without a setter. Cancel revokes callbacks/preview and retains recovery; it is not restoration.

Quality uses one multi-key transaction. Brightness then Contrast use disjoint engines: Contrast eligibility is preflighted before any Brightness write, but **the combined visual operation is not atomic**. Second-leg failure suppresses presentation commit, reports MODE_PARTIAL and preserves originals. Natural or explicit recovery can restore them. Identical-value external writes cannot be attributed. SavedVariables are not immediately durable or crash-proof.

## Offline validation and handoff

Current result 2026-11-06: **125 passed, 0 failed on actual Lua 5.1 (development-only Lupa 2.6)**: 64 foundation/boundary + 27 product + 34 diagnostic/calibration tests. Prior cases remain; schema assertions follow schema 3, and Contrast injection tests now reject invalid types instead of the newly authorized boolean feature.

D01–D06 cover read-only collection, privacy, bounded export/history, guarded errors and pending-operation noninterference. D07–D14 cover exact calibration, invalid targets, stale previews, late drift, false/nil/thrown/clamped/no-op setters, failed recovery, watch drift and unavailable/restricted APIs. D15–D24 cover independent layers, Contrast preflight, composite partial failure, reverse compensation, reload, timers, cancellation, re-entry, migration and whole-profile refusal. D25–D34 cover UI-to-export flow, descriptor domains, getter/timer re-entry, no-setter release, altered journals, export construction retry, active-test selection, media failures, chat limits and partial compensation.

Structural/syntax checks cover TOC/casing/version/bindings, one native call, forbidden writers elsewhere, no OnUpdate and original asset hashes, plus Lua 5.1 compilation of runtime/tests/binding snippets. Static token checks are guardrails, not proof against all possible aliases. Six Python cases cover deterministic bytes, single install root, all hashes, runtime build/manifest identity, path safety, asset formats and archive tampering. Final command output and artifact receipt accompany the delivery/PR.

The existing local builder reads clean Git blobs; its only generated runtime substitution is Core/Build.lua with the source commit. BUILD.json declares/hashes it. Two byte-identical archives are compared. This produces the requested installable development build only, with no upload/release operation.

Native status: **NOT INSTALLED / NOT TESTED**. Rendering, input/copy focus, audio, visual judgment, native failure paths, real dependencies, hardware/performance, persistence and addon coexistence remain unknown. Follow [the single exploration/report workflow](21-BETA-USER-GUIDE.md). Main and prior PR history are preserved, Issue #1 stays open, and nothing is merged or published automatically.
