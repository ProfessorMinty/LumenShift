# LumenShift 0.2.0-dev.9 — install and explore

Northern Lights Labs · World of Warcraft: Forever. The owner's dev.6 report confirms working Night Vision/restoration on 1.60.1:70862:16001. Version differences now warn once instead of locking controls. No version reconfirmation or command-based setup is needed.

## Install the whole folder

1. In the old build, select **Natural** and **Current Baseline** if settings are active. Keep unresolved recovery records.
2. Exit WoW and back up the old LumenShift folder. Keep SavedVariables so preferences and originals carry forward.
3. Extract `LumenShift-0.2.0-dev.9-<commit>.zip`. Copy its entire **LumenShift** folder into Forever's `_forever_/Interface/AddOns`, replacing the previous addon folder.
4. The result must be `.../_forever_/Interface/AddOns/LumenShift/LumenShift.toc`, with **Core**, **UI**, **Media** and **Bindings.xml** beside it. Install neither the ZIP nor the TOC alone; avoid nested `LumenShift/LumenShift` folders.
5. Start WoW and enable LumenShift in AddOns. If the game itself marks the interface tag out of date after a patch, its **Load out of date AddOns** option is separate from the addon's warning policy.

Completed dev.6 setup stays completed; it should not pop up again. First-time users see setup automatically. Older dev.1–dev.5 setups reopen once with saved choices preselected. Setup saves before **Finish & Reload UI**; **Save & Close** avoids reloading. Setup/startup never applies graphics or hides the HUD. Reopen preferences through Settings → AddOns → LumenShift → Setup wizard if desired.

## Open and use LumenShift

- **Left-click** the launcher/minimap icon for the six-mode wheel. **Right-click** for Studio.
- Select **Night Vision**, then **Natural** to restore the actual captured originals. Other modes have editable Brightness, optional Contrast, tint and effects.
- **Visual Modes**: select a mode card, edit its sliders/toggles, then click the teal **Apply** button at bottom right. Selecting a card alone does not change the scene. Natural restores owned visual settings; it leaves quality alone.
- **Colors & Effects**, **Audio**, **Personal Presets** and **Accessibility** contain optional presentation, sounds, saved variations, reduced motion and scale controls.
- Optional bindings are under Key Bindings → LumenShift. No keys are assigned automatically. Commands remain shortcuts only.

## Check the new layout

Right-click the launcher to open Studio. Check that the grouped sidebar, page title and bottom-right action fit your screen. In Visual Modes, selecting another card should only change the editor; Apply performs the switch. Visit Graphics Quality and Camera, then try Accessibility → Studio scale and High-contrast panel. Longer Advanced Graphics and Diagnostic Center content scrolls while the main action stays visible. Existing preferences and completed setup are retained.

The six smaller mode icons remain placeholders pending the owner’s new artwork. The approved metal-ring/aurora logo is included. Dev.9 adds silver Core utility icons, Steel/Midnight mesh panels, teal Lumen Loops accents and a fitted segmented wheel. High contrast hides the decorative panels and glow. Studio → Accessibility → Art & Credits lists the artists; complete third-party notices ship with the addon.

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

For sharpening, foliage, distance/LOD, Contrast, bloom or weather: choose a setting and value, then **Test & Restore**. It tries the value for about two seconds and checks restoration. Start with Natural and Current Baseline. A prior trial is optional for direct named-control Apply.

For **Shadows, lighting & water**: choose a supported native level, then **Try selected level & restore**. It captures the tier and readable named settings, applies the tier, waits two seconds, restores it and checks the captured values. These are experimental temporary trials, not persistent tier profiles. If a related setting fails to return, the report retains its original and no guessed repair is attempted. Use **Restore interrupted quality trial** deliberately after reviewing an interrupted/failed trial. HDR/renderer changes remain in the game's settings.

## One consolidated check

Outside combat, use a stationary scene:

1. Night Vision → Natural; Lantern → Natural. Check the effects and optional sounds you chose.
2. Apply Vista, switch Night Vision/Natural, then Current Baseline. Quality and modes should stay independent.
3. Toggle friendly names twice. Enter Camera Mode, then exit using its keybind or Alt+Z plus Exit. Check that original player/pet name visibility returns.
4. Optionally try a supported shadow/light/water tier and let restoration finish. If it reports recovery, stop that trial and export; do not repeatedly retry it.
5. Open **Diagnostic Center → Export Complete Diagnostic Report → Select All → Ctrl+C**. Paste the report with a short description of what looked right or wrong. It collects the technical details; no chat transcript or extra commands are needed.

Reports exclude names, chat, accounts, local paths and raw native exception text. They include only name-setting CVar identifiers and numeric states, not actual player/pet names. Nothing uploads automatically. Run Diagnostics is read-only; test/apply/camera buttons perform their named actions.

## Recovery and removal

External edits are preserved instead of repeatedly overwritten. Ordinary Natural/Current Baseline/name toggle respects conflicts. Explicit recovery can replace a newer value with the captured original; use the appropriate Diagnostic Center, Advanced Graphics or Camera restore control deliberately.

Restore before updating, disabling, downgrading or removing the addon. SavedVariables is not immediately durable or crash-proof. Deleting files or saved data does not undo graphics/name changes. Keep unresolved originals and export instead of deleting a journal.

## What is verified

Native dev.6 Night Vision/readback/restoration is recorded in [28](https://github.com/ProfessorMinty/LumenShift/blob/feat/beta-integration/docs/28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md). The dev.9 textured UI was reviewed through an off-client layout model and automated Lua tests; native font metrics, input, scrolling and addon coexistence still need an in-game check. New dev.7 camera, profile and tier behavior has automated mock coverage and still needs in-game evaluation. Persistent shadow/light/water profiles remain incomplete because complete native dependencies/restoration are not established. See the [feature/evidence matrix](https://github.com/ProfessorMinty/LumenShift/blob/feat/beta-integration/docs/29-QUALITY-PROFILES-AND-NATIVE-TRIALS.md). This is an expanded interactive development build, not accepted feature-complete beta or a CurseForge release.

Original code/technical documentation: MIT, copyright 2026 Northern Lights Labs. Original creative assets: All Rights Reserved with permission to install/use as part of LumenShift. Both notices ship in the addon. No new third-party assets are included.
