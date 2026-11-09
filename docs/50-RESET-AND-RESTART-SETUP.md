# Reset LumenShift and restart setup — beta.6

**2026-11-09 · Northern Lights Labs**

The owner requested an in-addon reset after learning that deleting the addon folder does not remove WoW's separately stored SavedVariables. This is an explicit, optional factory reset of **LumenShift's account-wide data only**. Ordinary updates continue to preserve saved settings.

## Player flow

1. Right-click the LumenShift logo to open Studio, then choose **Accessibility**.
2. Click **Reset LumenShift & Restart Setup**. The confirmation explains what will be removed. **Cancel** or Escape leaves the data unchanged.
3. Click **Reset & Restart Setup** to clear LumenShift's settings and reload the UI. The fresh setup wizard opens after world entry.
4. Choose Original or Game Defaults and your preferences. Keeping the current graphics selection does not apply a quality recipe. Finish setup normally.

The same action is in **WoW Settings > AddOns > LumenShift**. The diagnostic report has **Reset LumenShift...**, available even if the saved data cannot be loaded and Studio is unavailable. No slash command, confirmation token, report export or recovery action is required.

Reset deletes LumenShift preferences, mode edits, personal presets, launcher position, baseline selection, completion state, experiment records and all saved recovery originals. It does **not** restore those originals or change current Brightness, Contrast, sharpening, quality banks, camera/name CVars, sound settings or key bindings. Other addons' SavedVariables are not accessed. Account-wide means LumenShift starts fresh for every character using this WoW account.

If the player resets while a mode's graphics values are still active, those values remain current. Selecting Original in fresh setup will capture those current values. Reset is not a graphics-restoration action, and there is no in-addon undo for the intentionally deleted data. The confirmation states this before the final click. WoW manages its own SavedVariables files and backups; the addon does not erase files or promise secure deletion.

## Implementation

- `UI/Reset.lua` provides the confirmation and explicit reset/reload lifecycle using existing Widgets and keyboard navigation. Cancel is first in keyboard navigation; opening the dialog never confirms it.
- `Core/Bootstrap.lua` owns the only callback that replaces the `LumenShiftDB` global. Confirmation obtains fresh schema-12 defaults through `Store.Open(nil)`, including incomplete onboarding and independent Keep Current graphics choices.
- Existing controllers close over their original database. Reset replaces the save target without rebinding those controllers. During the explicit reload, a transient `reader.resetPending` fence prevents owned guarded input/events and the private native CVar call from acting. The new Lua runtime starts normally with no such flag.
- Missing reload, an exception, or an unexpected return preserves/restores the previous save target and allows retry/cancel. An actual in-progress operation or combat defers the final action without clearing data. There is no delayed automatic retry. Historical conflicts, owned/pending/failed recovery records, an unavailable CVar API or a different build do not block the reset.
- There is no reset-on-load, schema change, additional SavedVariable, native graphics call, generic reset API or file-system operation. All installed features and existing recovery behavior remain intact until the player explicitly confirms this action.
- `ReloadUI` follows the existing user-clicked setup path in [24](24-GUIDED-SETUP.md) and [36](36-DEV11-RELOAD-AND-UI-FIXES.md). Reload is the persistence boundary requested by the player; this does not claim immediate disk durability or crash-proof saving.

## Verification

`tests/reset.lua` adds ten simulated regressions: visible-button confirmation/cancel/Escape; replacement of only our save target; startup into fresh setup and later completion; deliberate removal of historical recovery without restoration; combat/in-progress deferral; missing/throwing/unexpected reload with retry; reload reentry and late handlers; reset access with quarantined data; absent graphics APIs/new build; and a full 24-preset library with visual, normal/raid, names, FOV and photo recovery records.

Final validation: **421/421 Lua 5.1 tests passed**, including all ten reset regressions; **64 Lua files and four binding bodies** passed syntax checks; **45 runtime modules** passed structural/TOC/version checks with one native CVar call site; **10/10 Python packaging tests** and **98 current local documentation links** passed. Whitespace checks passed. The first full run exposed an RST10 fixture that had not activated names before asserting a names record; that fixture was corrected and the entire suite rerun successfully. The initial package-link check ran before this document existed and passed after it was added.

These tests simulate native reload and setting APIs. **The reset has not yet been tested in the live client.** Existing owner-confirmed graphics evidence remains scoped to its recorded builds and operations. The local ZIP is built from the clean committed source with per-file hashes and two byte-identical builds; its commit/hash receipt is delivered separately.

## Focused owner check

Install the complete beta.6 `LumenShift` folder from the local ZIP. No manual SavedVariables deletion is needed.

1. Open the reset dialog and Cancel. Confirm current preferences remain.
2. Open it again and confirm. Expect a UI reload followed by fresh setup, with the scene and current game graphics values unchanged.
3. Check a known other addon's preference still matches. LumenShift does not write its data; as with any normal reload, all addons run their own loading code.
4. In fresh setup, choose Original and Keep Current graphics, save the preferences and finish. Reopen Studio to confirm your choices. Old personal presets/recovery records should be gone. A later ordinary reload should keep the new completion state.

This task does not install/operate the owner's game, merge PR #5, close Issue #1 or publish to CurseForge.
