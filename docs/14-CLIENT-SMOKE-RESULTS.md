# Forever diagnostic smoke-test results

**Recorded:** 2026-11-06. **Tester/source:** Arctic's user-supplied in-game text after installing the diagnostic folder and following the slash-command handoff. **Classification:** Verified in-client, owner-observed/reported; the agent compared the supplied reports, not a directly controlled game session.

The supplied folder was verified locally against source commit `60ce4e3f989a1864b1bb344f46368b97a26d35a9`. The report identifies addon version `0.1.0-dev.1`; that version string alone does not prove the installed file hashes. Only the addon diagnostics are summarized here. Unrelated game chat, player names, account data and private paths are excluded.

## Observed results

The first submission contained one LumenShift report. The follow-up contained that report and two further reports after Arctic was asked to run `/lumenshift` and `/ls` again. All three diagnostic blocks in the follow-up are identical.

| Check | Observed result |
|---|---|
| Addon loading / diagnostic output | PASS: LumenShift produced complete diagnostic reports in-game |
| Version / build / interface | `1.60.1` / `70790` / `16001` |
| Repeated command output | PASS: three identical diagnostic reports; no diagnostic error line present |
| Read API availability | AreCVarsLoaded, GetCVar, GetCVarDefault and GetCVarInfo all available |
| Access guard availability | canaccessvalue and issecretvalue both available |
| Brightness current / default | `45` (OK) / `50.000000` (OK) |
| Contrast current / default | `60` (OK) / `50.000000` (OK) |
| Flags, both keys | secure=no, readOnly=no, locked=no, serverAccount=no, serverCharacter=no |
| Addon state / recovery | BASELINE / 0 records |
| SavedVariables status | NEW; in-memory initialization observed, persistence not tested |
| Write capabilities | Diagnostic reports unavailable; source boundary remains unconditionally disabled |

The follow-up is accepted as owner-operated evidence for the requested command smoke sequence. Typed slash commands are not echoed in the pasted output, so individual blocks cannot be independently attributed to a particular alias. No alias failure was reported. There is no need to ask for the launcher version again: the launcher confirmation and the native version/build/interface report now agree.

## What this establishes

The diagnostic addon loaded in the owner's Forever session, interface 16001 was reported, the present getter/access APIs were usable for Brightness and Contrast, their result shapes passed the adapter's checks, and repeated displayed values stayed stable. This closes the initial read-only load/readback uncertainty for this observed setup. It does not certify other builds, renderers or machines.

The literal `FOREVER_CANDIDATE_UNVERIFIED` and `Unverified: native loading, persistence, restoration` lines are static wording in this development build. They do not invalidate the newly recorded loading evidence and do not change themselves after a successful test. No runtime strings or compatibility permissions are changed by this documentation update.

## Still untested

- SavedVariables reload/logout/cold-start persistence and recovery durability. Repeating a slash command leaves the initial `NEW` load status unchanged and is not a persistence test.
- Native writes, accepted target ranges, settling, rendering effects, exact restoration, external-writer conflicts and combat behavior. False security/read-only flags are observations, not write authorization.
- Native unavailable/secret/error branches: guards were present and values readable during this test; adverse paths remain simulated.
- Exact command attribution, a complete native Lua-error audit and independent visual/audio observations. No diagnostic error appears in the reports; that alone does not prove the absence of every hidden error or side effect.
- Before-startup versus after-startup values, same-value writes and ABA races. Stable repeated values are readback evidence, not a native setter trace.

## Next review gates

1. Review the Phase 00 PR #2 and Phase 01A PR #3, including Aurora's fixes and this evidence. Neither is automatically merged. After an owner-authorized merge of #2, retarget #3 to main and inspect its new diff before any merge of #3.
2. Separately approve a read-only reload/persistence check with the current writer-disabled build. Do not infer permission for it from this results record.
3. Separately authorize Phase 01B implementation and its controlled Brightness experiment, with a recovery card, a freshly captured original and explicit verification/restore criteria. The proposed 75 target is still a future experiment; 45 is this session's observation, not a hardcoded restore value.

Issue #1 remains open for the outstanding live-client work. No graphics-write capability, preset, effect, release or CurseForge action is authorized by this smoke-test result.
