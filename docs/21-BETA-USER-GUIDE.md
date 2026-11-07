# LumenShift 0.2.0-dev.11 — install and explore

Northern Lights Labs · World of Warcraft: Forever. The owner's dev.6 report confirms working Night Vision/restoration on 1.60.1:70862:16001. Version differences now warn once instead of locking controls. No version reconfirmation or command-based setup is needed.

## Install the whole folder

1. Keep your SavedVariables and recovery originals. For this fix, you do not need to clear an active mode or resolve the old reload lock before updating. Do not delete saved data to work around it. Restoring originals is still appropriate before uninstalling.
2. Exit WoW and back up the old LumenShift folder. Keep SavedVariables so preferences and originals carry forward.
3. Extract `LumenShift-0.2.0-dev.11-<commit>.zip`. Copy its entire **LumenShift** folder into Forever's `_forever_/Interface/AddOns`, replacing the previous addon folder.
4. The result must be `.../_forever_/Interface/AddOns/LumenShift/LumenShift.toc`, with **Core**, **UI**, **Media** and **Bindings.xml** beside it. Install neither the ZIP nor the TOC alone; avoid nested `LumenShift/LumenShift` folders.
5. Start WoW and enable LumenShift in AddOns. If the game itself marks the interface tag out of date after a patch, its **Load out of date AddOns** option is separate from the addon's warning policy.

Dev.10 opens setup once to ask for the new return-mode choice while preserving your other preferences. **Original** captures your current Brightness/Contrast; **Game Defaults** reads the defaults reported by WoW. The numbers appear below the cards. This choice covers visual settings; graphics quality remains independent. After saving, setup should not repeat on later logins. Setup saves before **Finish & Reload UI**; **Save & Close** avoids reloading. Setup/startup never applies graphics or hides the HUD. Reopen preferences through Settings → AddOns → LumenShift → Setup wizard if desired.

## Open and use LumenShift

**Retest this fix:** login should leave graphics unchanged. From the reported Cinematic 42 state, click Night Vision (75), then Original (captured 45). Reopen setup through native Settings → AddOns → LumenShift → Setup wizard, click Finish & Reload UI, and check that it reloads and stays completed. Drag setup/Studio/report by the title bar and check the wheel's longer Game Defaults label. Recovery records no longer block reload or a new mode click when a completed record still matches. A pending/failed write or actual external change retains its original and needs explicit recovery. These are requested native checks, not already verified results.

- **Left-click** the launcher/minimap icon for the six-mode wheel. **Right-click** for Studio.
- Select **Night Vision**, then **Original** or **Game Defaults** to apply your chosen return look. Other modes have editable Brightness, optional Contrast, tint and effects.
- **Visual Modes**: select a mode card, edit its sliders/toggles, then click the teal **Apply** button at bottom right. Selecting a card alone does not change the scene. The return mode uses the saved visual baseline and leaves quality alone. Diagnostic recovery restores the separate pre-change originals.
- **Colors & Effects**, **Audio**, **Personal Presets** and **Accessibility** contain optional presentation, sounds, saved variations, reduced motion and scale controls.
- Optional bindings are under Key Bindings → LumenShift. No keys are assigned automatically. Commands remain shortcuts only.

## Check the new layout

Right-click the launcher to open Studio. Check that the grouped sidebar, page title and bottom-right action fit your screen. In Visual Modes, selecting another card should only change the editor; Apply performs the switch. Visit Graphics Quality and Camera, then try Accessibility → Studio scale and High-contrast panel. Longer Advanced Graphics and Diagnostic Center content scrolls while the main action stays visible. Existing preferences are retained; the new baseline choice is requested once.

The six smaller mode icons remain placeholders pending the owner’s new artwork. The approved metal-ring/aurora logo is included. Dev.9 adds silver Core utility icons, Steel/Midnight mesh panels, teal Lumen Loops accents and a fitted segmented wheel. High contrast hides the decorative panels and glow. Studio → Accessibility → Art & Credits lists the artists; complete third-party notices ship with the addon.

## Check the new return mode

1. Choose **Original** in setup. Check the displayed Brightness/Contrast against your intended current look, then **Finish & Reload UI**. After reload, setup should stay closed and graphics should be unchanged.
2. Select Night Vision, then Original. Check that your captured look returns; no assumption is made that your Brightness was 45.
3. To try the alternate choice, reopen Setup wizard through native Settings, select **Game Defaults**, inspect the reported values and **Save & Close**. Saving should not change the scene. Apply Game Defaults from the wheel or Studio when you want to see it.
4. If the defaults differ from your prior settings, **Diagnostic Center → Restore My Brightness — preview only → Confirm displayed recovery card → Verify pending recovery** restores pre-change Brightness. **Advanced Graphics → Preview recovery of experimental visual settings → Confirm displayed operation** restores pre-change Contrast. This is separate from applying the selected Game Defaults look.
5. Reopen setup to choose Original again if desired. **Capture again** deliberately replaces the preferred visual snapshot; ordinary preference saves do not recapture it. Capturing while a mode is active uses retained pre-mode originals.
6. Export one report if needed. It now includes the chosen baseline and an extra graphics-research section. That extra section only reads candidate settings; it does not disable existing controls or apply new console tweaks.

A missing default is displayed as unavailable, never guessed. If Contrast is missing from a snapshot it is left alone; if Brightness is missing the return mode cannot apply until a later explicit click can read it. Other modes remain available when their own inputs are valid. Native dev.10 testing has not been performed by development tools.

## Camera Mode and names

1. Open **Studio → Camera**. Leave **Hide friendly player and pet names in Camera Mode** checked to hide those names with the interface; uncheck it for HUD-only behavior.
2. Click **Enter Camera Mode — hide interface**. It uses the same native visibility API as Alt+Z. Your visual mode and graphics profile stay active.
3. Return using your optional **Enter / exit Camera Mode** keybind. Alternatively, press **Alt+Z**, then click **Exit Camera Mode** in Studio. Alt+Z itself reveals the HUD; it does not restore names.
4. **Toggle friendly player and pet names** works independently of HUD visibility. Toggling back restores the individual original settings, including a mixed on/off pair.
5. **Restore original name settings** explicitly recovers saved originals after an interruption or conflict. Enemy names, nameplates, camera zoom and camera movement are unchanged.

If name restoration fails, the interface is shown first and originals stay in the report. No name or HUD setting is automatically reapplied on login/reload.

## Independent quality profiles

Studio → **Graphics Quality** offers usable experimental profiles:

- **Balanced:** sharpening while keeping/restoring original scene detail.
- **Vista:** modest increases in foliage, distance and object detail from your originals.
- **Performance:** modest reductions in scene detail. No FPS improvement is guaranteed.
- **Current Baseline:** restore captured quality originals without switching off your visual mode.

Select a profile card to preview it, then click **Apply** at bottom right. Targets and the number of unavailable built-in controls are shown before Apply; the report contains individual capability details. Existing custom profiles keep exactly their saved values; built-in keys are not silently added. Edit named settings in **Advanced Graphics**, save values into a profile, then Apply. Removing all custom keys returns that slot to its built-in recipe. These are experimental recipes within bounded test ranges, not native defaults or measured safe maxima.

## Advanced controls and temporary trials

For sharpening, foliage, distance/LOD, Contrast, bloom or weather: choose a setting and value, then **Test & Restore**. It tries the value for about two seconds and checks restoration. First restore pre-change visuals using Diagnostic Center and choose Current Baseline for quality. Applying Game Defaults may still own visual settings, so it is not a substitute for releasing them. A prior trial is optional for direct named-control Apply.

Sharpness uses WoW's reversed raw scale: **lower is sharper**. Built-in profiles now preserve your current strength instead of forcing 1.

For **Shadows, lighting & water**: choose a supported native level, then **Try selected level & restore**. It captures the tier and readable named settings, applies the tier, waits two seconds, restores it and checks the captured values. These are experimental temporary trials, not persistent tier profiles. If a related setting fails to return, the report retains its original and no guessed repair is attempted. Use **Restore interrupted quality trial** deliberately after reviewing an interrupted/failed trial. HDR/renderer changes remain in the game's settings.

## One consolidated check

Outside combat, use a stationary scene:

1. Night Vision → your chosen Original/Game Defaults; Lantern → that same return mode. Check the effects and optional sounds you chose.
2. Apply Vista, switch Night Vision/your return mode, then Current Baseline. Quality and modes should stay independent.
3. Toggle friendly names twice. Enter Camera Mode, then exit using its keybind or Alt+Z plus Exit. Check that original player/pet name visibility returns.
4. Optionally try a supported shadow/light/water tier and let restoration finish. If it reports recovery, stop that trial and export; do not repeatedly retry it.
5. Open **Diagnostic Center → Export Complete Diagnostic Report → Select All → Ctrl+C**. Paste the report with a short description of what looked right or wrong. It collects the technical details; no chat transcript or extra commands are needed.

Reports exclude names, chat, accounts, local paths and raw native exception text. They include only name-setting CVar identifiers and numeric states, not actual player/pet names. Nothing uploads automatically. Run Diagnostics is read-only; test/apply/camera buttons perform their named actions.

## Recovery and removal

External edits are preserved instead of repeatedly overwritten. Ordinary return-mode/Current Baseline/name toggle respects conflicts. Explicit recovery can replace a newer value with the captured original; use the appropriate Diagnostic Center, Advanced Graphics or Camera restore control deliberately.

Restore before updating, disabling, downgrading or removing the addon. SavedVariables is not immediately durable or crash-proof. Deleting files or saved data does not undo graphics/name changes. Keep unresolved originals and export instead of deleting a journal.

## What is verified

Native dev.6 Night Vision/readback/restoration is recorded in [28](https://github.com/ProfessorMinty/LumenShift/blob/feat/beta-integration/docs/28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md). The dev.10 baseline behavior has simulated coverage only. The textured UI was reviewed through an off-client layout model and automated Lua tests; native font metrics, input, scrolling and addon coexistence still need an in-game check. New dev.7 camera, profile and tier behavior has automated mock coverage and still needs in-game evaluation. Persistent shadow/light/water profiles remain incomplete because complete native dependencies/restoration are not established. See the [feature/evidence matrix](https://github.com/ProfessorMinty/LumenShift/blob/feat/beta-integration/docs/29-QUALITY-PROFILES-AND-NATIVE-TRIALS.md). This is an expanded interactive development build, not accepted feature-complete beta or a CurseForge release.

Original code/technical documentation: MIT, copyright 2026 Northern Lights Labs. Original creative assets: All Rights Reserved with permission to install/use as part of LumenShift. Both notices and THIRD-PARTY-NOTICES.md ship in the addon; dev.9 supplied-art licenses remain unchanged.
