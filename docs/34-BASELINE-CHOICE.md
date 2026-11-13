# Dev.10 — Original and Game Defaults

The setup now asks which **visual return mode** to use. **Original** captures the player's Brightness and Contrast. **Game Defaults** captures their `C_CVar.GetCVarDefault` values. The selected name replaces Natural in Studio and the wheel. The internal `natural` identifier remains stable for saved modes, presets and artwork; existing settings are not discarded.

This is deliberately precise: the choice covers the visual mode's Brightness/Contrast, **not every game option**. Graphics Quality stays independent. A comprehensive quality-default/snapshot feature needs a supported-key list and tier dependency handling; [33](33-FOREVER-GRAPHICS-DEEP-DIVE.md) describes that next work. Never call a broad reset API or a Classic/Enhanced experience preset to implement this choice.

## User behavior

- Setup previews both captured numbers or marks a missing one unavailable. Saving preferences does not apply them. The first explicit mode click uses the selected baseline. Game Defaults is allowed to look different from the player's previous configuration.
- Other modes keep their authored Brightness. Their optional explicit Contrast takes precedence; otherwise they use the selected baseline Contrast when available. Returning to Original/Game Defaults uses the chosen Brightness and Contrast with no overlay effects.
- Reopening setup does not silently recapture. **Capture again**, changing the choice, or selecting its card requests a fresh read on save. Closing without save discards the draft.
- Capturing Original while a mode is active uses the stored pre-mode originals for owned/recovery keys. It does not save temporary Night Vision brightness as the player's baseline.
- If settings were unavailable during setup, the next explicit mode click attempts to fill only missing snapshot keys before writing. Existing values are never refreshed implicitly. Failed native defaults are never replaced with current values or hardcoded 50/45. Missing Brightness prevents applying that baseline; other modes can still work. Missing Contrast is shown as unavailable and is not invented.
- Existing schema-5 users see this new choice once; prior preferences and completion remain in the migrated data. After saving, ordinary subsequent logins do not repeat setup. There are no startup/reload graphics writes or automatic reapplications.

## Architecture and restoration

`Core/Baseline.lua` owns a schema-6 record: source (`current` or `gameDefaults`), chosen boolean, a bounded Brightness/Contrast raw-string map, and capture identity. Validation rejects unknown fields/keys, nonnumeric/nonfinite values and values outside the existing 0–100 domains. `ReadOnly` checks accessibility and reports absent, secret, drifted or malformed API results. A snapshot is a sequence of reads, not an atomic engine snapshot.

`Store` explicitly migrates schemas 1–5 to 6 using validated copies. Preferences, completion, custom quality profiles, experimental journals, camera records and recovery originals are preserved. Invalid input remains quarantined rather than overwritten.

The snapshot is a **preferred look**, not ownership. Only the existing write boundary can change a setting. Before every write it captures the real current value in the relevant journal and uses planner/conflict/readback checks. Example with mock values: Original 52/60, Game Defaults 48/53. Applying Game Defaults changes to 48/53 but retains recovery originals 52/60. Explicit recovery returns to 52/60; it does not rewrite that record to the chosen default. Choosing a matching Original uses the exact raw restoration path, including a captured string such as `052.00`.

Brightness and Contrast remain separate sequential legs, not a falsely advertised all-or-nothing transaction. Contrast is preflighted before Brightness. A later Contrast failure can leave Brightness applied and is reported as partial; the existing boundary compensates where safe and retains unresolved originals. No automatic retries or uncertain restore on startup were added. For external drift, the existing explicit recovery workflow still applies, even if the external value happens to equal the original.

The selected baseline is not shown as active merely because it is configured. The session marker becomes active after verification and is cleared on a new choice, uncertain readback or differing current values. Quality profile selection and camera state are independent.

“Restore My Brightness” and experimental visual recovery mean **pre-change originals**, whereas **Apply Original/Game Defaults** means the selected saved look. These can intentionally differ. Restore originals before updating/removing; selecting Game Defaults is not equivalent to releasing ownership. SavedVariables remains normally persisted by the game, not immediately durable or crash-proof.

## Verification

The Lua 5.1 suite adds H01–H18 and Q00: read-only captures, arbitrary native defaults, exact raw restoration, active-mode capture, explicit recapture/cancel, schema migration, invalid data, absent/secret/error/drifted defaults, delayed capture, partial availability, Contrast preflight, external conflicts, partial failure, zero startup writes, no-setter explicit release, independent quality, research-observation admission boundaries, unchanged fractional Contrast, and preserving sharpness 0.2 through all three built-in profiles. An owned custom sharpness also restores exactly to a fractional original such as `0.250`.

**Results:** 228 Lua 5.1 mock tests passed / 0 failed; 9 Python packaging tests passed; syntax passed for 33 runtime modules, 9 test files and 4 binding bodies; structural and whitespace checks passed. Original-selected setup, Game Defaults-selected setup and the baseline Studio editor were inspected in an HTML rendering of actual Lua mock geometry. Spacing and footer actions fit; native font metrics remain unverified. These are simulated/off-client results; native behavior of dev.10 is untested.

Follow [21](21-BETA-USER-GUIDE.md) for the owner-operated check: choose Original first, save/reload, Night Vision → Original; then choose Game Defaults and deliberately apply it, inspect the difference, restore pre-change Brightness/Contrast through the existing recovery UI, and confirm quality remained unchanged. Existing dev.6 native evidence is accepted without another launcher-version check. Native font metrics and the enlarged setup layout still need in-game confirmation even after off-client layout review.
