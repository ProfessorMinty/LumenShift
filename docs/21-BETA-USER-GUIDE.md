# LumenShift 0.2.0-dev.4 — install, explore, report

Northern Lights Labs · World of Warcraft: Forever 1.60.1.70840 / interface 16001 (70790 also retained for experimental testing).

This update fixes the build rejection found in Arctic's dev.3 report and reworks the wizard. The report already confirms client 70840, Brightness 45 and Contrast 60; no launcher-version reconfirmation is needed. Dev.3 loaded/exported successfully but Finish stopped before reload. **Dev.4 has offline tests, not native acceptance.** The earlier verified Brightness round trip belongs to 70790 and an older addon.

Included: six editable modes, wheel, Studio, optional effects/sounds, presets and diagnostics. Contrast/selected quality controls are experimental. Balanced/Vista/Performance start empty, and advanced shadow/light/water controls remain read-only. This is not yet the finished product; see [scope and evidence](https://github.com/ProfessorMinty/LumenShift/blob/feat/beta-integration/docs/25-BUILD-70840-AND-SETUP-REVIEW.md).

## Install the whole folder

1. If the currently installed older addon still owns a brightness change, finish its restore/verification first. Keep any recovery card. Do not discard unresolved originals to update.
2. Exit WoW. Back up the old LumenShift addon folder and its SavedVariables if present. Leave other addons and the rest of WTF/Interface alone.
3. Extract `LumenShift-0.2.0-dev.4-<commit>.zip` outside the game. Replace only the old addon folder with the **entire extracted LumenShift folder** in your existing Forever AddOns directory.
4. The resulting layout must be `World of Warcraft/_forever_/Interface/AddOns/LumenShift/LumenShift.toc`, with `Core`, `UI`, `Media` and `Bindings.xml` beside the TOC. **Do not put the ZIP itself in AddOns or install just the TOC.** Avoid an extra nested `LumenShift/LumenShift` folder.
5. Start WoW, enable LumenShift in the AddOns list and log in. Startup runs read-only checks and never changes graphics or plays sounds. Schemas 1/2/3 migrate to 4 while preserving originals; corrupt/newer data is quarantined. Do not downgrade over schema 4 or delete recovery data to silence an error.

## Complete the setup wizard

The wizard appears after your first login, outside combat.

1. **Welcome:** check the displayed compatibility and development scope, then click **Choose preferences**.
2. **Preferences:** use the labeled ON/OFF cards for screen effects, sounds, animations, reduced motion, high contrast and launcher visibility. Click **Review choices**.
3. **Review:** check the summary, choose whether to enable visual switching, read/check the restore reminder, then click **Finish & Reload UI**.

 The addon saves your choices and requests a UI reload from that button. It does not restart the whole game, apply a graphics mode or play a sound during setup/reload.

Closing the wizard with Set up later/Close leaves your preferences unchanged; it can reopen from the launcher or Settings. Completed setup stays completed on later logins; reopen it with **Settings → AddOns → LumenShift → Setup wizard** if needed. Do not delete SavedVariables to force it. An unreviewed build shows the reason on Welcome and starts with switching off; read-only preferences can still be saved. Existing unresolved graphics ownership opens Recovery first instead of reloading over it. If reload is unavailable or fails, the wizard explains what happened; it does not loop or repeatedly reload.

## Check this update without changing graphics

Complete setup and allow its user-clicked reload. Confirm that your scene and Brightness/Contrast stay unchanged, the wizard stays completed, and the launcher opens the wheel/Studio. Open **Diagnostic Center → Export Complete Diagnostic Report → Select All → Ctrl+C**. Export automatically refreshes read-only checks. Early CVARS_NOT_LOADED events may remain in history; the current-check section should reflect current availability. No mode selection or calibration is needed for this check.

## Explore with buttons

After reload, **left-click the labeled LumenShift launcher or minimap button** for the wheel; **right-click** for Studio. The native **Settings → AddOns → LumenShift** page also opens Studio, the setup wizard, diagnostics and export. If the minimap is unavailable, a labeled screen button takes its place. Hiding the movable launcher does not remove that separate entry point.

Choose **Night Vision** on the wheel to try Brightness 75 after enabling controls in setup. The addon captures the actual original and performs immediate plus scheduled verification. Select **Natural** to restore the exact original. Never assume it was 45. If already at 75, no ownership/write is needed. Use a stationary scene outside combat for your first visual test.

The wheel supports labeled mouse selection, 1–6, arrows/Tab, Enter and Escape. You can assign optional keys in Key Bindings → LumenShift. No commands or automatic key assignments are required.

Explore the six editors, Colors and Effects, Audio, Personal Presets and Accessibility. Slider edits save configuration; Apply is separate. Non-75 brightness targets require the clearly labeled experimental opt-in. Those targets are authored starting points, not proven safe maxima or measured performance settings. Audio begins muted: enable it and use the explicit previews. Effects, animation, sound and screenshot bars can be disabled; bars need a positive mode height and global screenshot option. Effects are UI textures below ordinary HUD, not world shaders, and clear in combat without automatic return. Custom-UI layering still needs your visual judgment.

Personal presets save up to 24 mode variations; Apply loads/selects one, while rename/delete affect only saved data. Quality is independent of modes. You can explore all UI/media without choosing a calibration target or turning on Contrast.

## Optional Contrast and quality experiments

In Studio, click **Calibration Lab**. Return to Natural and restore existing experimental ownership before starting a new calibration.

1. Select a named setting and read its current value/capability and explicit test-policy bounds. Enter the exact target you want to try. No target is applied just by opening/editing.
2. Click **Preview exact modification (read only)**. It shows original/current/target and watch coverage. Click **Export Complete Diagnostic Report**, Select All, Ctrl+C, and save this preview outside the game before writing; SavedVariables is not immediately durable.
3. Only when you choose to authorize that displayed live experiment, click **Confirm displayed operation**. It applies once, checks the value, waits about two seconds for a fresh read, then restores the captured original and verifies again if observations remain trustworthy. Watch the scene; numerical success cannot judge its appearance.
4. On a successful round trip, the exact target becomes available for experimental use during this login. For Contrast, set that target on the desired Visual Modes editor and enable **Use experimental calibrated Contrast for this mode**. For quality, save tested targets into Balanced/Vista/Performance and apply that configured set. Empty/uncalibrated profiles refuse as a whole; no guessed settings are assigned.

Natural restores owned visual settings; **Current Baseline — restore quality** restores owned quality separately. Calibration permissions expire on reload, although numeric profile preferences remain. Sharpening values are raw CVar units and have reversed source UI mapping. Relative quality bounds are addon test-size limits, not native safe ranges. Tier shadows/light/water, HDR/renderer and other unmapped controls remain observation-only with explanations.

Do not deliberately induce crashes or adverse conflicts during initial exploration. A failed second Contrast leg can leave Brightness active with its original retained; MODE_PARTIAL identifies this. Stop and export the report rather than repeatedly applying.

## One report instead of manual probes

In Studio, click **Diagnostic Center → Run Diagnostics**. This performs safe reads only: no settings changes, audio playback, synthetic UI input or reload. PASS, FAIL, BLOCKED and NOT TESTED are distinct. Visual effects/audio/persistence cannot be certified by reads.

Click **Export Complete Diagnostic Report** to refresh checks and export them together (also available from Settings or Studio’s persistent Export report button). In its dedicated scrollable window, click **Select All**, press **Ctrl+C**, then paste directly into Codex/ChatGPT. The report has build/commit, client/UI/API observations, current/default/security values, requests/readbacks/originals, recovery, watched changes, recent warnings/errors and bounded event history. You do not need to paste unrelated chat or manually collect separate values/screenshots. Add one sentence describing what looked or sounded wrong; the addon cannot measure your visual judgment.

The default export excludes character/preset names, chat, account identifiers, installation paths, credentials and raw native error text. Nothing uploads automatically. A guarded addon error produces one notice pointing to the report. A separate minimap/Settings entry can still open the report if Studio initialization fails. A failure before the addon can create any UI lies outside its own reporting ability; report that loading error without unrelated chat/account data.

## Recovery and stopping

Conflicts, late drift or uncertain reload state never automatically restore/reapply. **Cancel** cancels permission/callbacks, not the current graphics value. Save the report while still in that login; event history is memory-only and bounded.

For Brightness, click **Restore My Brightness — preview only** in Diagnostic Center. Review the original, current and proposed target displayed in the window, click **Confirm displayed recovery card**, then **Verify pending recovery (read only)**. No numbered command needs to be typed. For Contrast/quality, use the corresponding **Preview recovery** button in Calibration Lab, export the preview and click its confirmation button. Recovery intentionally replaces the displayed current value with the captured original, so confirm only if that is what you want. Failed recovery retains its record without an uncertain retry/reapply.

Unexpected watched-setting changes are reported as dependency **or external change**, with readable before/after values. The addon does not guess which changed them or overwrite unrelated settings. Such records remain unresolved for review even after the primary value is restored. Send the report before further experiments if they appear.

Before disabling/updating/removing, select Natural, restore owned quality, resolve recovery and export a final report. Exit normally before replacing/removing only the addon folder. Deleting files/SavedVariables does not restore graphics settings. Keep the external original-value report and backups; disk persistence and crash-proof restoration are not guaranteed.

## Terms

Code/technical documentation: MIT, copyright 2026 Northern Lights Labs. Original artwork/icons/textures/sounds/logo/branding: All Rights Reserved; install/use with LumenShift is permitted, independent reuse/redistribution in other projects needs permission. See both included licenses. Third-party terms remain independent. No CurseForge upload or publication has occurred.

## Optional shortcuts

Slash commands remain available for convenience or troubleshooting; they are not required for setup, modes, configuration, diagnostics, export or recovery. The normal entry points are the automatic wizard, launcher/minimap buttons and Settings page.
