# Owner-reported fallback recovery — beta.5

**2026-11-09 · Northern Lights Labs**

The owner reported that beta.4 did not reopen setup and mode clicks produced an earlier-change/recovery message. A read-only inspection confirmed that the installed **0.2.0-beta.4 / a722e003** matched every file in its packaged manifest. This was not an old or partial addon-folder installation.

The saved addon data retained a completed Brightness record: **original 45, last verified/intended 42**, from Cinematic. The game's saved configuration showed **Brightness 45 / Contrast 60**. Disk configuration is not a fresh live API observation, but the owner then supplied the fallback macro used to restore those values. That combination reproduces the refusal in mocks. The owner also requested a clean LumenShift setup.

## Cause and correction

The old continuation rule required the current value to equal the last value written by LumenShift. Returning to the exact captured original through the owner's macro was treated as unresolved recovery, even though the user had already returned that setting. Both the Brightness-only path and composite mode planner could refuse the next explicit click.

Beta.5 adds a pure exact-original predicate. A **new explicit request** may continue when the record is completed/owned without a failure, or is marked conflicted solely by `EXTERNAL_CONFLICT`, and the fresh safe observation exactly equals the captured original with the same client signature. The planner still validates the descriptor, numeric domain and requested target, and the native boundary rechecks before writing.

- Selecting Night Vision from original 45 can now write 75 while retaining original 45 for restoration.
- Selecting Original when it is already 45 releases the stale record through the existing no-setter verification path.
- Pending writes, failed operations, another external value such as 55, changed signatures/descriptors, unavailable/restricted observations and intervening drift remain preserved. No reset-all, guessed default or automatic replay was introduced.
- Startup remains read-only. Saved state is not rewritten merely because the addon loaded. Schema 12 and existing presets, artwork and the single native writer remain unchanged.

The earlier 403-test suite missed this combination of a completed saved mode and an external return to its original. The owner's report supplies new native failure evidence; the correction is automated-test evidence until exercised in the game.

## Setup and the two visible controls

The saved setup-completed flag and chosen baseline explain the absence of an automatic wizard. Updates intentionally preserve completion. Setup remains reopenable through Studio/native Settings; a fresh SavedVariables state opens it on world entry.

The small logo beside the minimap is the launcher; the large radial wheel is its menu. They are not two copies of the addon. A separate movable launcher is also optional in Setup. This patch does not remove visible entry points or alter the owner's choice.

## Owner-authorized clean setup

The owner explicitly requested a clean setup after using a fallback macro. The authorized reset concerns **LumenShift SavedVariables only**, with WoW fully closed first. Back up and hash-verify `LumenShift.lua` and `LumenShift.lua.bak` before removing them from the applicable account's SavedVariables directory. Keep the backup outside the public repository.

Do not remove the entire WTF/Interface folders, `Config.wtf`, macros, other addon settings or graphics values. The owner's macro and its selected values remain unchanged. Its values are personal preferences, not universal Blizzard defaults. Replacing only the addon folder does not reset SavedVariables.

The local reset procedure checks the actual WoW process outside the development sandbox, refuses while it is running, verifies every backup, rechecks process/source state and removes only the two specifically named addon data files. Native graphics operations and addon installation are separate actions; the reset performs neither. Actual reset completion and backup location are reported in the chat, not assumed by this document.

After the reset and whole-folder beta.5 update:

1. Start Forever normally. The fresh setup wizard should open.
2. Choose **Original** to capture the current visual settings restored by the owner's macro. Keep current graphics choices unless deliberately testing a new recipe.
3. Save preferences and finish setup. Use the launcher/wheel to select Night Vision, then Original; no tokens or slash-command setup are needed.
4. If the fallback macro is used after a completed mode, the next explicit mode click should work when the values exactly match captured originals. Export a report if it still refuses; do not discard an uncertain recovery record merely to hide an error.

## Verification

`tests/returned_original.lua` covers the 45 → 42 → external 45 sequence after reload and during the same login, no-setter Original selection, composite Contrast release, retained unrelated quality, fresh/completed setup, unsafe record variants and a changing observation before the setter.

- **411 Lua 5.1 tests passed, 0 failed**: 403 retained plus eight new regressions. The four initially failing fallback cases now pass.
- **62 Lua files and four binding bodies** passed syntax checks; structure remains 44 modules and one native CVar call site.
- **10 Python packaging tests passed**. Current local documentation links and whitespace checks passed.
- These are off-client results. The owner's beta.4 refusal is native evidence; beta.5's actual gameplay success remains to be observed.

The beta.5 archive is built from a clean recorded commit with an exact manifest/checksum and contains the complete addon folder. No new in-game success, automatic merge or CurseForge publication is claimed.
