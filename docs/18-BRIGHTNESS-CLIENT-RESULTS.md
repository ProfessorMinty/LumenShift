# Phase 01B — first native Brightness round-trip result

**Recorded:** 2026-11-06. **Tester/source:** Arctic's owner-operated test, supplied in-game text and explicit visual confirmation. **Classification:** Verified in-client, owner-observed/reported. The agent read the evidence and guided commands; it did not operate the game, install files or execute graphics writes.

**Observed client:** Forever `1.60.1`, build `70790`, interface `16001`. **Displayed addon version:** `0.1.0-dev.2`. The supplied local test folder was extracted from source commit `7138245b1616a9811948fb265a38492e1fc26e46`, with its 14 runtime files checked against that commit. Installed-file hashes were not independently captured; the displayed version and source handoff identify the intended build, not a verified installed-file fingerprint.

Only relevant addon findings are retained here. Unrelated chat, player names, other addon details and private paths are excluded. The excerpts are user-provided observations, not an independent native API trace or a universal compatibility certification.

## Observed sequence

| Step | Observed result |
|---|---|
| Before the successful round trip | Earlier dev.2 diagnostic report: Brightness `45`, Contrast `60`, BASELINE, no original or token, zero recovery records; getter/access APIs and native writer API available. |
| Fresh activation preview | Recovery card **2**, signature `1.60.1:70790:16001`, original `45`, current `45`, target `75`. The recovery value was retained outside the game in this conversation before confirmation. |
| Activation confirmation | Addon reported immediate readback matched and original `45` retained. |
| Separate activation verification | Addon reported Night Vision verified by readback and offered `/ls off` for exact restoration. |
| Restoration preview | Recovery card **3**, same signature, original `45`, current `75`, target `45`. This independently exposes the current 75 after activation. |
| Restoration confirmation | Addon again reported immediate readback matched, original `45`. |
| Separate restoration verification | Addon reported original Brightness verified by exact readback and ownership released. |
| Final diagnostic report | Brightness `45` (OK), Contrast `60` (OK); defaults both `50.000000`; security/read-only/locked/server-account/server-character flags all false for both keys. |
| Final state / recovery | `BASELINE`; original `not captured`; last verified `none`; operation `off`; no preview confirmation; **0 recovery records**. The operation field records the last action, not a pending operation. |
| Visual result | In a separate follow-up, Arctic explicitly confirmed that the scene visibly brightened and returned to its previous appearance: **both changes looked correct**. No screenshot or photometric measurement is claimed. |

**Result: PASS for one owner-operated 45 → 75 → exact 45 round trip on this setup**, including displayed verification, ownership release and owner-reported visual effect/restoration. Contrast was 60 in the before and final diagnostics; no intermediate Contrast sampling or full setter trace was supplied. No failure or compensation message appears within the successful round trip.

For the supplied implementation, these success messages require an accessible boolean-true native setter result, safe immediate observations and a matching later read. That is a **source-guided inference** from the known success paths; the log does not directly expose every native API return, restriction check or call count. The restoration preview and final diagnostic provide the explicit current-value observations. The full suite still verifies non-45 originals only through mocks.

## Earlier command-entry failures

Earlier attempts produced unknown-command/refusal output and `NO_PENDING_VERIFICATION`; one intended confirmation was visibly sent as ordinary chat without its leading slash and with a number different from the displayed card. These preceded the successful card-2/card-3 sequence and are not native setter or compensation failures. The subsequent fresh preview, actual confirmation and verification succeeded.

The handoff now directs the user to enter the exact printed confirmation command, including `/` and its current number, instead of substituting `N`/`M` placeholders. No runtime parser or confirmation policy changed. Token numbers 2 and 3 are evidence for this session only, not commands to reuse in another test.

## What remains unverified

- Measured settling time, repeatability, arbitrary original values, canonicalized raw formats and other renderers/machines/builds.
- Native clamping, rejected/errored/secret setter results, compensation failure, explicit recovery after an external conflict, the no-setter release path and native combat transitions. These remain simulated coverage.
- Journal persistence across reload/logout/restart, crash recovery and restoration after uncertain state. `SavedVariables: VALIDATED_COPY` shows accepted stored data at load; it does not establish immediate durability or persistence of this operation's recovery journal.
- A complete Lua-error audit, exact alias attribution, continuous Contrast monitoring, same-value external writes or ABA races, and instrumentation proving zero startup writes. Successful logs and unchanged endpoint values are narrower evidence.
- General public-release suitability, licensing, CurseForge packaging/tagging/moderation and the remaining release QA.

The dev.2 report's static `Unverified: native writes, settling, persistence and restoration` wording and `FOREVER_CANDIDATE_UNVERIFIED` compatibility string do not update automatically after a test. They do not negate this newly recorded round trip. The production catalog remains unadmitted and runtime writes still require a fresh explicit confirmation; no broad admission or automatic restore/reapply was enabled.

## Repository follow-up

This is a documentation-only evidence update on the existing Phase 01B branch and PR #4. Runtime modules, TOC, schema, test harness and checker are unchanged from `7138245`. The previously executed **64/64 Lua 5.1 mock pass**, syntax and structural results remain applicable to that unchanged code; no redundant test rerun or additional native test is claimed.

The first controlled round trip is complete; there is no outstanding owned setting in the final report. Next is review of PRs #2/#3/#4 and separately approved additional acceptance work, following [the merge sequence](17-MERGE-SEQUENCE.md). No merge, Phase 02, further live test, release or CurseForge publication is authorized by this result. Issue #1 remains open for the remaining validation work.
