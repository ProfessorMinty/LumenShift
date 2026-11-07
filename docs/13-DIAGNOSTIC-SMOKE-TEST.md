# Arctic's diagnostic-only smoke test

**Target:** World of Warcraft: Forever **1.60.1.70790**, already confirmed through the owner's Battle.net launcher. **Build:** source version 0.1.0-dev.1 on `feat/phase-01a-foundation`, including the review-fix commit linked on [PR #3](https://github.com/ProfessorMinty/LumenShift/pull/3). **Native test status:** owner-observed load/readback/repeated-output PASS; [results and limits](14-CLIENT-SMOKE-RESULTS.md). The agent did not run the game. This document preserves the protocol for later reproduction; no launcher-version reconfirmation or immediate rerun is requested.

This checks loading, both slash commands and Brightness/Contrast reporting. It does not activate a visual mode or write graphics settings. The addon may create/update its own LumenShiftDB when the game normally saves; this is separate from graphics CVars.

## Install the diagnostic source

1. Close World of Warcraft completely.
2. Use the updated checkout on `feat/phase-01a-foundation`, or download that branch's repository source with GitHub's **Code -> Download ZIP** and extract it outside the game. Record the PR's review-fix commit so the test identifies the exact source. This is repository source, not a published release package.
3. Copy **only the `LumenShift` folder inside `addon/`** into the existing Forever installation's `_forever_/Interface/AddOns/` directory. If an older LumenShift folder is present, move that folder to a private backup outside AddOns first so files from different builds cannot mix. Leave SavedVariables and other addons untouched.
4. Confirm this layout, with no extra wrapper directory:

```text
World of Warcraft/
  _forever_/
    Interface/
      AddOns/
        LumenShift/
          LumenShift.toc
          Core/                 (13 Lua files)
```

5. Launch Forever. At character selection, open **AddOns** and enable **LumenShift** for the test character. If it is absent, check the folder nesting. If it is marked incompatible/out of date, stop and record that result; do not override the compatibility warning. Interface 16001 loaded in Arctic's observed 70790 test; other builds require their own validation.

## Run the smoke test

1. Enter the world and wait for loading to finish. Keep the Graphics settings and any other addon preset controls untouched throughout the test.
2. Enter `/ls` in chat. Capture the report, especially the header, client/interface line, API availability, Brightness/Contrast values/defaults/flags, state and recovery count.
3. Enter `/lumenshift`. It should produce the same diagnostic report format and the same current Brightness/Contrast readings while settings remain unchanged.
4. Enter `/ls` once more. Confirm the readings remain stable, no effect/sound activates and no Lua error or diagnostic error is reported. If another addon changes a setting, record the difference; do not adjust the setting to make the test pass.

Expected report contents:

- `LumenShift 0.1.0-dev.1 | diagnostic only; graphics writes disabled`.
- Client version `1.60.1`, build `70790`, and the actual interface. For interface 16001, `FOREVER_CANDIDATE_UNVERIFIED` is expected: a tuple match does not automatically certify native behavior or enable writes.
- Availability lines for AreCVarsLoaded, GetCVar, GetCVarDefault, GetCVarInfo and the secret/access guards.
- Brightness and Contrast current/default numeric strings with `(OK)` when readable, plus secure, readOnly, locked, serverAccount and serverCharacter flags. **Use the actual observed numbers; 45, 60 and 75 are not required test values or assumed defaults.**
- On a fresh diagnostic install: state BASELINE and zero recovery records. Pre-existing saved recovery data may instead produce RECOVERY/quarantine; preserve and report it, without resetting or attempting restoration.
- No write-admitted CVars and no preset activation, regardless of the flag values.

If CVars report `CVARS_NOT_LOADED`, wait for loading to settle and retry one diagnostic command. If getters or accessibility checks are absent/restricted, explicit unavailable/`ACCESS_UNVERIFIED` output is the expected safe behavior; report the numeric-value check as BLOCKED, not passed. Do not inject replacement APIs, disable guards or alter settings to obtain a pass. Missing-guard handling is already covered by mocks; do not deliberately remove live functions.

If either command is unknown, prints another addon's output, reports an error, or yields different values unexpectedly, record the exact behavior and stop. The full `/lumenshift` command helps distinguish a possible `/ls` alias collision. Do not change an error-display CVar or any graphics CVar as part of this test.

## Return the result

Send the source commit, date, whether LumenShift appeared/enabled, the diagnostic client/interface line, and sanitized outputs from both commands. Mark each item PASS, FAIL or BLOCKED: addon load, `/ls`, `/lumenshift`, Brightness display, Contrast display, stable repeated readings, and any observed Lua/diagnostic error or visual/audio change. Include other enabled addons if a conflict appears; omit account names, character identifiers and full private installation paths.

Stable readings are an observed smoke-test result, not proof of every possible writer/race or persistence behavior. Arctic's supplied results are recorded in doc 14. Do not proceed to graphics writes, reload/persistence experiments, Phase 01B, merges or publication from this checklist. Issue #1 remains open.
