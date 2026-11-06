# LumenShift 0.2.0-beta.1 — local candidate guide

Northern Lights Labs · Forever 1.60.1.70790, interface 16001.

This is a development candidate for owner acceptance, not a published release or an accepted feature-complete beta. The prior Brightness 45 → 75 → 45 test passed visually and by readback. The integrated Studio, wheel, effects, audio and other targets have automated mock coverage but have not passed native acceptance yet. Contrast and graphics-quality writes are unavailable pending evidence. Nothing changes graphics at startup, even if setup was enabled in a previous session.

## Install the complete folder

1. In the currently installed build, finish restoring Brightness and verify that `/ls` reports `BASELINE` with zero recovery records. If it does not, keep the current addon and recovery card; resolve that before updating.
2. Exit WoW completely. Keep a backup of the current `LumenShift` addon folder and, if present, its account-level `LumenShift.lua` and `LumenShift.lua.bak` SavedVariables files. Do not delete or overwrite the whole `WTF` or `Interface` directory.
3. Extract the supplied `LumenShift-0.2.0-beta.1-<commit>.zip` outside the game. It contains one `LumenShift` folder. The ZIP's `BUILD.json` identifies the exact source commit and file hashes.
4. Replace just the old addon folder with that **entire extracted `LumenShift` folder** in your existing Forever `Interface/AddOns` directory. The final path must be `World of Warcraft/_forever_/Interface/AddOns/LumenShift/LumenShift.toc`. Beside the TOC you must see `Core`, `UI`, `Media` and `Bindings.xml`. Do not install only the TOC, the ZIP itself, or an extra nested `LumenShift/LumenShift` wrapper.
5. Start WoW, enable LumenShift in the character-selection AddOns list, and log in. No launcher-version reconfirmation is needed. If the client has since patched, the native writer refuses a different identity until reviewed.

Schema 1 is migrated to schema 2 without replacing recovery originals. Saved setup/preset preferences do not reactivate a mode. Corrupt or newer schemas are preserved and quarantined. Older builds do not understand schema 2; do not downgrade over it or discard recovery data to suppress an error.

## First pass: no graphics changes

Run `/ls`, then `/lumenshift`. Both should display version `0.2.0-beta.1`, readable Brightness/Contrast and state `BASELINE` with no recovery records. The values should still match your pre-install readings; the prior 45/60 values are evidence from that earlier session, not mandatory defaults.

Run `/ls studio`. Inspect all seven pages. Open the wheel with `/ls wheel` or left-click the crescent launcher; Escape or right-click cancels. Right-click the launcher opens Studio; dragging moves it. Check text, icons, scrolling, scale, keyboard cancellation and the Diagnostics report. Keep initial setup disabled during this first pass. Slider edits only save configuration. Keep audio muted if you want a silent pass. Print the read-only quality scan from Graphics Quality if collecting evidence; it never applies a profile.

Record any Lua error, missing icon, unreadable text, blocked input or unexpected graphics change. Close the panel/wheel and stop acceptance on errors. The browser/mock preview is not a game screenshot.

## First owner-controlled activation

Perform this section only when you choose to authorize a live Brightness test. Use an out-of-combat, stationary scene. No developer/agent should execute these steps for you.

1. Run `/ls` and save the **current Brightness value** outside the game. This is the value that must return; never assume 45. Confirm no unresolved recovery records.
2. Open `/ls studio` → Visual Modes. Read and turn on the recovery acknowledgement, then click **Enable visual switching**. This alone makes no graphics change. Save the printed recovery note. Leave **Experimental Brightness targets beyond 75 OFF** and the Night Vision target at **75**.
3. Run `/ls toggle` once. The engine captures the then-current original, prints a recovery card, applies Brightness 75 and schedules a separate read-only verification. Wait for `Brightness target verified by readback`; inspect the scene. You do **not** need `/ls confirm` or `/ls verify` for this ordinary Studio switch.
4. Run `/ls`. Expect `ACTIVE`, Brightness 75, the exact captured original retained, and unchanged Contrast. If Brightness was already 75, no ownership/write is needed and the state may remain `BASELINE`; the optional presentation can still be active.
5. Run `/ls toggle` again, or select **Natural** on the wheel. Wait for `Original Brightness verified by exact readback; ownership released.` Run `/ls` and confirm the exact original value, `BASELINE` and zero recovery records. The scene should return and presentation effects disappear. An already-75 unowned toggle simply removes effects.
6. If any failure/conflict appears, stop switching and use the recovery procedure below. Do not keep retrying a failed operation.

The existing per-operation confirmation commands remain for deliberate manual experiments/recovery. Ordinary mode changes after setup use the same planner and sole Brightness writer, with fresh preflight and readback checks. Every new ownership captures the actual current value.

## Modes, effects and shortcuts

- `/ls studio`: configuration and recovery. `/ls wheel`: mouse/keyboard selection. `/ls toggle`: Night Vision/Natural. `/ls mode natural` is an explicit return to the trusted current-session original.
- Set your own bindings in the game's Key Bindings → LumenShift: Toggle Night Vision, Open / close visual wheel, Open Visual Studio. No keys are assigned automatically. On the wheel, 1–6 select, arrows/Tab navigate, Enter selects and Escape cancels. Hold-to-select is unavailable pending native input validation.
- Natural clears effects and restores owned Brightness. Night Vision uses 75 and optional green tint. Cinematic proposes 42/warm treatment, Lantern 65/amber, Clarity 70/neutral, Moonlight 55/blue. These additional numbers are authored aesthetic starting points, not Blizzard defaults, native-safe maxima or measured performance settings. Applying non-75 targets requires the separately labeled experimental option and owner acceptance. Each mode can instead be edited to 75 while testing presentation alone.
- Brightness sliders update saved settings; **Apply** is separate. The 0–100 editor domain comes from the named-build UI source; only the earlier 45/75/45 path has live evidence. Contrast is displayed as unavailable, and no other graphics setting is written.
- Colors and Effects provides per-mode tint RGB, opacity, vignette and letterbox height. Apply saved effects deliberately. Letterbox requires both a positive per-mode height and the global screenshot toggle. These are UI textures, not shaders. They sit below ordinary HUD frames, are noninteractive and clear in combat. They do not automatically return when combat ends; explicitly reapply effects if wanted. Custom-UI layering remains a test gate.
- Audio starts muted. Enable it on Audio and choose soft/normal original cues. Previews play only when enabled. The addon never changes global game audio volumes; unavailable/muted SFX can prevent playback.
- Personal Presets saves up to 24 variations of the edited visual mode. Apply loads that variation and performs an explicit mode selection. Rename in the name field with Enter; delete removes only that saved variation. No arbitrary CVar imports or executable profiles are supported.
- Accessibility includes reduced motion, animation off, high-contrast panel, scale and launcher visibility/position reset. The slash interface remains available when the launcher is hidden.
- Quality profiles are independent. Current Baseline leaves the existing quality unchanged. Balanced/Vista/Performance clearly refuse activation until their complete native target sets and restoration behavior are validated. The read-only catalog is evidence collection, not an operational graphics panel.

## Recovery, updates and removal

On reload, crash uncertainty or external changes, LumenShift does not automatically restore or reapply anything. SavedVariables may not have reached disk; they are not crash-proof storage. A matching value cannot identify which addon last wrote it. Keep the externally saved recovery note.

For an unresolved original, use `/ls restore` or **Restore My Brightness — preview only** in Diagnostics and Recovery. Read the displayed original/current/target carefully. It intentionally replaces the current value with the captured original, which may override an external manual change; proceed only if that is now what you want. Save the card, then enter the **exact numbered `/ls confirm ...` command printed in chat** or click the matching confirmation button. Afterward use `/ls verify` / **Verify pending recovery (read only)**. Never type a placeholder letter in place of the number. `/ls cancel` cancels permission, not graphics state. Failed recovery retains information and makes no automatic retry or uncertain reapply.

Normal synchronous on/off failure can make one bounded compensation attempt to its known before-value, followed by readback. Late drift, conflict, reload and explicit recovery failure never automatically fight the current setting. If the saved original is missing or unreadable, retain the external note and request support; do not use reset-all or delete the journal as a shortcut.

Before disabling, updating or uninstalling: select Natural (or finish explicit recovery), verify the original and zero records, then disable controls. Exit normally before replacing/removing just the addon folder. Graphics settings can persist independently of the addon; deleting files or SavedVariables does not restore them. Keep backup data and the recovery note until a subsequent startup still shows the intended values.

For support, report addon version/source commit, action, engine state, Brightness original/current and any error code. Avoid sharing chat logs with other players' messages, account paths, names or credentials. Native addon coexistence, performance, media and migration acceptance remain open; do not represent simulated tests as game tests.

## License and distribution

Original code and technical documentation: MIT, copyright 2026 Northern Lights Labs (`LICENSE`). Original artwork, icons, textures, sounds, logo and branding: All Rights Reserved (`ASSET-LICENSE.md`); permitted for installation/use as part of LumenShift, not independent reuse/redistribution in other projects without permission. Third-party components retain their own terms. None are bundled here. This ZIP has not been uploaded to CurseForge, and public publication requires final owner approval.
