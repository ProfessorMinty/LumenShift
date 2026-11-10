# LumenShift 0.2.0-beta.17 — install and explore

Northern Lights Labs · World of Warcraft: Forever. The owner's dev.6 report confirms working Night Vision/restoration on 1.60.1:70862:16001. Version differences now warn once instead of locking controls. No version reconfirmation or command-based setup is needed.

Beta.17 fixes inherited-mode effects remaining visible after switching combat filters off, keeps compositing pairs free of both treatment layers, and labels unavailable inventory readers. All beta.16 controls remain. Keep SavedVariables; no setup reset. [Audit, exact checks and remaining work](62-PHOTO-LIBRARIES-AUDIT.md).

Beta.16: **Camera → Portrait Stage → Actors** now has **Poses**, **Outfits** and **Effects** browsers. Choose a pose category/search, preview equipped/bag/set items, save outfits, and select or clear a model spell effect. **Capture → Combat behavior** controls whether Photo Studio and filters remain active during combat (both on by default). Native graphics/name writes and orbit remain unavailable during combat; the selected look remains unchanged. Keep SavedVariables. [Exact controls and test steps](61-PORTRAIT-LIBRARIES-AND-COMBAT.md).

Beta.15 fixes Phase 3 target refresh and optional model capabilities, keeps saved layouts working on the fallback renderer, and corrects letterbox/capture feedback. Use **Camera → Portrait Stage** as before. Keep SavedVariables; no reset or new setup. [Audit and remaining photo work](60-PHOTO-AUDIT-AND-COMPLETION.md).

Beta.14: Open **Camera → Portrait Stage** near the top of Photo Studio. **Actors** adds player/target/pet copies and live transforms, poses and appearance previews. **Light** relights those models; **Scene** offers backgrounds/lens; **Saved** stores scenes and independent lights. **Look** filters still apply. Capture freezes staged models only; H hides controls, Escape exits. Scroll Capture past timers for a two-image background/green-screen cast pair. **World Photo** returns to the existing world tools. Schema 16 keeps your settings; no new setup or reset. [Exact Phase 3 test and backend limitations](59-PORTRAIT-STAGE.md#installation-and-owner-test).

Beta.13: **Frame** adds native zoom, held orbit and shoulder/dynamic framing. Scroll down **Capture** for supported AA, ray-shadow and JPEG-quality controls. **Look** adds Sun Flare/Blue Hour and edge light; **Saved** keeps compositions separate from looks. Phase 1 pose/capture/history tools remain included. Schema 15 preserves your settings. No Narcissus or new setup is required. [Exact Phase 2 test](58-PHOTO-COMPOSITION-AND-OUTPUT.md#installation-and-owner-test).

Beta.12: **Photo Studio works with Narcissus disabled or uninstalled.** Pose offers twelve world emotes, Pin, Stop and optional one-shot capture after posing. Capture offers a 0–10 second delay, 1–5 shots, 1–5 second interval, Start and Cancel. Frame has separate name/bubble groups plus Apply name choices now. Look has Undo/Redo. Keep SavedVariables; schema 14 preserves your settings without repeating setup. [Standalone test and controls](57-STANDALONE-PHOTO-WORKFLOW.md#installation-and-owner-test).

Beta.11: native lighting and FOV now **preview as you drag**, with paced updates and the last pointer value retained. Capture/Hide controls/Before-After finish the pending edit first. Escape cancels queued input and restores through the existing Camera path. No reset is needed. [Live-slider test](55-LIVE-PHOTO-SLIDERS.md).

Beta.10 adds **Photo Studio directly inside Camera Mode**. Open the launcher → Camera. Look contains filters, vignette, draggable glow and grain; Light contains native brightness/contrast/sharpness/bloom sliders; Frame contains guides/FOV/letterbox; Saved stores and shares photo styles. Native sliders now preview during dragging; typing a number and pressing Enter also applies. Show Before/After compares the scene; Exit/Escape returns temporary native edits. Hide controls/H gives a clean external screenshot. Keep SavedVariables; no setup reset is needed. [Full controls and campfire test](54-IN-SCENE-PHOTO-EDITOR.md). The later beta.14 update adds the optional model stage.

Beta.9: in Camera Mode, click **Hide controls** (or press **H**) before using Snagit, Alt+Print Screen or another capture tool. This hides the toolbar and guides, retaining selected effects. **H** shows the controls again. **Escape** exits Camera and uses its normal restoration. [Details and photo-editor research](53-PHOTO-MODE-RESEARCH-AND-CONTROLS.md). Keep SavedVariables; no setup reset is needed.

Beta.8 fixes a Camera name-preflight refusal caused by treating server-storage metadata as a restriction. Keep your saved settings. Open the wheel, click **Camera**, then use **Exit Camera Mode** to return the HUD and prior friendly names. No reset or command is needed. [Evidence and focused check](52-CAMERA-NAME-STORAGE-FIX.md).

Beta.7 shows only one launcher: minimap by default, or the floating button if previously selected. Change this in **Studio > Accessibility > Floating launcher instead of minimap**. The wheel now has separate **Camera** and **Studio** icon buttons. Use **1–6** for modes, **7** for Camera, **8** for Studio, or arrows/Tab then Enter. **Exit Camera Mode** returns the interface. No settings reset is needed. [Layout and acceptance checks](51-LAUNCHER-AND-WHEEL.md).

Beta.6 adds **Reset LumenShift & Restart Setup**. Right-click the LumenShift logo, open **Accessibility**, click the reset button, then confirm **Reset & Restart Setup**. WoW reloads into fresh setup. This deletes only LumenShift preferences, presets, saved originals and recovery history for this WoW account; current graphics settings and other addons' saved data stay unchanged. It does not restore old graphics values. Also available in WoW Settings > AddOns > LumenShift, or **Reset LumenShift...** in the diagnostic report. [Details and test steps](50-RESET-AND-RESTART-SETUP.md).

Beta.5 allows an ordinary mode click after a completed change returns to its exact captured original, including the owner’s fallback macro. Choosing Original in that situation releases the stale record without a setter. [Details and optional clean setup](49-RETURNED-ORIGINAL-AND-CLEAN-SETUP.md).

Beta.4 includes the [whole-addon forensic audit fixes](48-FORENSIC-AUDIT.md): Effects Apply uses your edited appearance, wheel input respects chat and held keys, overlapping writes are rejected, unchanged native recipes take no new ownership, and exports retain Camera recovery details. No SavedVariables reset is needed. The prior setup/accessibility fixes remain included.

## Install the whole folder

1. Keep your SavedVariables and recovery originals. For this fix, you do not need to clear an active mode or resolve the old reload lock before updating. A routine update does not need a reset. Use the explicit reset button only when you want to start fresh. Restoring originals is still appropriate before uninstalling.
2. Exit WoW and back up the old LumenShift folder. Keep SavedVariables so preferences and originals carry forward.
3. Extract `LumenShift-0.2.0-beta.17-<commit>.zip`. Copy its entire **LumenShift** folder into Forever's `_forever_/Interface/AddOns`, replacing the previous addon folder.
4. The result must be `.../_forever_/Interface/AddOns/LumenShift/LumenShift.toc`, with **Core**, **UI**, **Media** and **Bindings.xml** beside it. Install neither the ZIP nor the TOC alone; avoid nested `LumenShift/LumenShift` folders.
5. Start WoW and enable LumenShift in AddOns. If the game itself marks the interface tag out of date after a patch, its **Load out of date AddOns** option is separate from the addon's warning policy.

Dev.10 opens setup once to ask for the new return-mode choice while preserving your other preferences. **Original** captures your current Brightness/Contrast; **Game Defaults** reads the defaults reported by WoW. The numbers appear below the cards. This choice covers visual settings; graphics quality remains independent. After saving, setup should not repeat on later logins. Setup saves before **Finish & Reload UI**; **Save & Close** avoids reloading. Opening setup and startup never apply graphics or hide the HUD. The new Graphics page applies only through its explicitly labelled Apply & Reload UI action. Reopen preferences through Settings → AddOns → LumenShift → Setup wizard if desired.

## Presets and keyboard access

In **Personal Presets**, Save variation stores a copy of the selected mode's editor settings. **Edit** copies a saved preset to Visual Modes without applying. Change its light/detail there, then return to Personal Presets and choose **Update from mode editor**. **Reset editor** discards those edits in favor of the saved snapshot; the current scene stays unchanged. **Apply** is the separate scene-changing action.

Rename a card with Enter. Export copies a complete data-only LSMODE code into the transfer field for Ctrl+C; import saves it without applying. Delete has **Undo last deletion** for this session. Names/transfer drafts survive page rebuilding. Presets keep visual settings only; graphics quality remains independent. Up to 24 looks are supported. Original/Game Defaults remains the setup reference rather than a personal variation.

Studio and Setup support **Tab / Shift+Tab** focus, **Enter / Space** buttons and native text entry; Enter commits a numeric/name edit. Focused controls scroll into view. Existing chat/text focus wins. **Escape** clears a keyboard selection or closes the window through the game's window handling. Wheel: 1–6 for modes, 7 for Camera, 8 for Studio; arrows/Tab to select, Enter to activate, Escape to close. Use title bars to move windows. Accessibility includes Studio scale, high contrast, reduced motion, effects and minimap/floating launcher choice. No commands are required.

Setup's expanded Graphics page scrolls while Save & Close and Finish/Apply & Reload remain fixed. Only an in-progress Apply temporarily prevents setup edits. Successful preference saving survives an apply failure; recovery originals stay available. Completed setup is not reopened merely because the addon version changed.

See the [beta.2 audit, current support matrix and test steps](46-BETA2-POLISH-AND-AUDIT.md). This candidate includes all five implementation deliveries. In-game acceptance of the combined build is pending; the older confirmed Brightness tests do not establish every effect or graphics recipe.

## Delivery 4 Camera and graphics comparison

Studio → **Camera** now offers thirds and aspect guides, manual **Field of view**, and optional **Temporary photo quality**. **Enter Camera Mode** hides the HUD and leaves a small capture/exit bar available. **Capture screenshot** hides LumenShift's guides/bar for the native capture; ordinary Print Screen is unchanged. **Exit Camera Mode** shows the HUD and restores matching Camera names intent, framing and photo-quality values. It preserves names hidden/shown separately before Camera entry. **Restore original name settings** deliberately restores all captured names. **Restore Camera changes** also works after reload. External edits remain preserved, with originals retained for recovery. Photo quality starts off and never replaces saved everyday/raid choices. See [the dev.16 test steps and limits](45-DEV16-CAMERA-AND-PERFORMANCE.md#install-and-try-it).

Studio → **Graphics Quality** → **Find your balance** offers Smooth gameplay, Richer scenery and Quieter operation guidance. Choose the scene, then **Observe FPS for 10 seconds**. After the observation, apply a graphics choice yourself and observe again from the same viewpoint/load. Sampling is read-only, finite, and allowed during combat; graphics changes remain outside combat. The last two observations are session-only and included in diagnostic export. Mean/min/max FPS readings are not frame-time percentiles, hardware recommendations or predictions of future raid performance. Settings changes, world transitions, invalid readings or Cancel stop the sample. No background autotuning runs.

## Delivery 3 starting looks, intensity and optional depth

Use the [dev.15 installation and button-based checks](44-DEV15-DISTINCT-MODES.md#install-and-use-the-new-build). Visual Modes → Starting Look now offers two authored variations per active mode. Selecting a variation replaces that mode's saved edits; Apply changes the scene. Save a personal preset first to keep your current edits. Hover a variation for its purpose.

Light & style intensity blends custom Brightness/Contrast toward your return look and scales tint/edges. Detail, bloom and screenshot framing stay independent. Setup → Appearance can explicitly include sharpening and bloom in the return reference; saving makes no graphics changes. Effective priority is mode, then quality, then opted-in reference. Full captured-visual recovery still restores separate exact originals.

Unavailable unowned sharpening/bloom is disclosed before Apply and after success, allowing available controls to work. An owned setting is retained for recovery; an actual write failure is never silently skipped. The optional contact-depth control is a separate Advanced Graphics Test & Restore experiment, not an automatic mode/profile effect. It requires readable enabled AO context, uses a narrow displayed trial range and reports that visible effect/motion stability remain unverified.

Existing looks and setup completion are preserved. New preset exports include intensity; old exports still import. No new calibration unlock or version-confirmation step is required.

## Delivery 2 detail and comparison

Follow the [dev.14 button-based steps](43-DEV14-SHARED-OPTICS.md#install-and-try-it-with-buttons). In Visual Modes, scroll to Detail: choose Inherit quality, Off (extra), or Custom weak-to-strong detail. Apply changes the scene. Clear removes styling while retaining native changes; Goggles uses optional Night Vision styling. Before/After compares the actual scene, and Finish comparison returns to After without overwriting intervening external changes. No commands or unlock are needed.

New/reset Clarity inherits return-look brightness and uses Clear styling. Upgrades preserve old Clarity customizations; enable Use return-look brightness and select Clear to adopt the neutral look deliberately. Custom bloom/glare is optional and checked only when requested. New detail settings default to inheritance, so updating does not silently strengthen a saved mode.

Personal Presets → Export highlights a copyable data-only string. Paste it into the transfer field, supply a name, and Import preset. Import saves without applying; a preset's Apply uses the same mode/quality resolver.

Diagnostic Center → Restore captured visuals restores captured Brightness, Contrast and optical originals, including optical quality overrides. Other quality settings and saved edits remain. Normal Original/Game Defaults mode instead reveals the latest underlying quality preference. This distinction also applies to the older recovery instructions below.

## Delivery 1 reliability test

Follow the short [dev.13 button-based checks](42-DEV13-RELIABILITY.md#install-and-check-with-buttons) for combined Brightness/Contrast changes, exact restoration, Camera effects, combat and reload. Diagnostic Center now shows both visual settings and offers **Restore captured visuals** directly. The saved **Keep visual effects in Camera** preference controls hidden-HUD presentation. These fixes have mock coverage; their new native behavior still needs observation.

## Native graphics setup and first test

1. Open **Settings → AddOns → LumenShift → Setup wizard**. Your existing completed setup is not forcibly repeated. Appearance keeps the Original/Game Defaults choice and effects preferences. Click **Next: Graphics**.
2. Start with **Keep current**. Check that the everyday graphics level or Custom label and the raid checkbox match your game settings. **Save & Close** saves choices without changing the scene. Reopen setup and verify those choices remain.
3. If unsure which quality to choose, **WoW recommendation** uses the game's current per-option defaults. It is not an FPS benchmark. **Choose a level** exposes the native 1–10 scale; higher favors detail, lower favors performance. Raid/battlegrounds have a separate choice when enabled. Shared options such as resolution and renderer are not included.
4. **Review changes** lists what the chosen recipe would directly change. Opening it makes no changes. Projected textures and particles stay enabled; native lower presets/defaults may be adjusted for those combat cues.
5. For the first controlled test, use **Studio → Graphics Quality** instead of reloading. Leave raid on Keep current. Choose one level away from Everyday's current level, review, then **Apply graphics**. Wait for the operation to finish; inspect the scene and the native graphics page. This is an experimental user-triggered graphics change.
6. Scroll down and click **Restore everyday graphics**. This deliberately replaces current everyday settings with their captured originals. Verify the scene and export if needed; the report shows original/expected/current values for all captured settings. No confirmation card is required.
7. Test the raid bank separately, including its checkbox, and use **Restore raid graphics**. Check actual automatic bank activation in the relevant content when available; this has not been certified from source alone. Then test a two-bank Apply if desired.
8. When satisfied, select your intended choices and **Apply graphics**, or use Setup → **Apply & Reload UI**. Setup saves first, applies/verifies selected banks, and reloads only after success. **Save & Close** is always available without applying. With both banks kept, the last button is **Finish & Reload UI**.

Only available known parent/leaf originals are captured. Missing leaves are disclosed in the report; complete renderer dependencies and exact whole-game restoration are unverified. If an Apply or Restore reports failure, keep its originals and export the report. There is no automatic retry or uncertain restore on startup. A failed raid operation can follow a successful everyday operation; each bank retains its own recovery data.

**Detail profiles** on Graphics Quality contains Balanced/Vista/Performance and Current Baseline. Restore an overlapping detail profile before applying native everyday levels, or restore everyday graphics before applying overlapping detail changes. Non-optical bank captures remain separate. Shared sharpening/bloom keys have one canonical original; mode overrides temporarily take precedence over the detail-profile request. Returning from a mode reveals the latest underlying quality request.

## Open and use LumenShift

**Retest this fix:** login should leave graphics unchanged. From the reported Cinematic 42 state, click Night Vision (75), then Original (captured 45). Reopen setup through native Settings → AddOns → LumenShift → Setup wizard, choose Next: Graphics, keep both banks unchanged, click Finish & Reload UI, and check that it reloads and stays completed. Drag setup/Studio/report by the title bar and check the wheel's longer Game Defaults label. Recovery records no longer block reload or a new mode click when a completed record still matches. A pending/failed write or actual external change retains its original and needs explicit recovery. These are requested native checks, not already verified results.

- **Left-click** the launcher/minimap icon for the mode wheel, including its Camera and Studio buttons. **Right-click** for Studio.
- Select **Night Vision**, then **Original** or **Game Defaults** to apply your chosen return look. Other modes have editable Brightness, optional Contrast, tint and effects.
- **Visual Modes**: select a mode card, edit its sliders/toggles, then click the teal **Apply** button at bottom right. Selecting a card alone does not change the scene. The return mode uses the saved visual baseline and leaves quality alone. Diagnostic recovery restores the separate pre-change originals.
- **Colors & Effects**, **Audio**, **Personal Presets** and **Accessibility** contain optional presentation, sounds, saved variations, reduced motion and scale controls.
- Optional bindings are under Key Bindings → LumenShift. No keys are assigned automatically. Commands remain shortcuts only.

## Check the new layout

Right-click the launcher to open Studio. Check that the grouped sidebar, page title and bottom-right action fit your screen. In Visual Modes, selecting another card should only change the editor; Apply performs the switch. Visit Graphics Quality and Camera, then try Accessibility → Studio scale and High-contrast panel. Longer Advanced Graphics and Diagnostic Center content scrolls while the main action stays visible. Existing preferences are retained; the new baseline choice is requested once.

The six smaller mode icons remain placeholders pending the owner’s new artwork. The approved metal-ring/aurora logo is included. Dev.9 adds silver Core utility icons, Steel/Midnight mesh panels, teal Lumen Loops accents and a fitted segmented wheel. High contrast hides the decorative panels and glow. Studio → Accessibility → Art & Credits lists the artists; complete third-party notices ship with the addon.

## Check the new return mode

1. Choose **Original** in setup. Check the displayed Brightness/Contrast against your intended current look, then **Next: Graphics**, leave Keep current selected, and **Finish & Reload UI**. After reload, setup should stay closed and graphics should be unchanged.
2. Select Night Vision, then Original. Check that your captured look returns; no assumption is made that your Brightness was 45.
3. To try the alternate choice, reopen Setup wizard through native Settings, select **Game Defaults**, inspect the reported values and **Save & Close**. Saving should not change the scene. Apply Game Defaults from the wheel or Studio when you want to see it.
4. If the defaults differ from your prior settings, **Diagnostic Center → Restore My Brightness — preview only → Confirm displayed recovery card → Verify pending recovery** restores pre-change Brightness. **Advanced Graphics → Preview recovery of experimental visual settings → Confirm displayed operation** restores pre-change Contrast. This is separate from applying the selected Game Defaults look.
5. Reopen setup to choose Original again if desired. **Capture again** deliberately replaces the preferred visual snapshot; ordinary preference saves do not recapture it. Capturing while a mode is active uses retained pre-mode originals.
6. Export one report if needed. It now includes the chosen baseline and an extra graphics-research section. That extra section only reads candidate settings; it does not disable existing controls or apply new console tweaks.

A missing default is displayed as unavailable, never guessed. If Contrast is missing from a snapshot it is left alone; if Brightness is missing the return mode cannot apply until a later explicit click can read it. Other modes remain available when their own inputs are valid. Native dev.10 testing has not been performed by development tools.

## Camera Mode and names

1. Open **Studio → Camera**. Leave **Hide friendly player and pet names in Camera Mode** checked to hide those names with the interface; uncheck it for HUD-only behavior.
2. Click **Camera** on the wheel, or **Enter Camera Mode — hide interface** in Studio. It uses the same native visibility API as Alt+Z. Your visual mode and graphics profile stay active.
3. Click the visible **Exit Camera Mode** button to return, or use the optional **Enter / exit Camera Mode** keybind. If needed, **Alt+Z** reveals the HUD so you can reach Studio or the wheel; Alt+Z alone does not restore names.
4. **Toggle friendly player and pet names** works independently of HUD visibility. Toggling back restores the individual original settings, including a mixed on/off pair.
5. **Restore original name settings** explicitly recovers saved originals after an interruption or conflict. Enemy names, nameplates, camera zoom and camera movement are unchanged.

If name restoration fails, the interface is shown first and originals stay in the report. No name or HUD setting is automatically reapplied on login/reload.

## Independent quality profiles

Studio → **Graphics Quality** offers usable experimental profiles:

- **Balanced:** sharpening while keeping/restoring original scene detail.
- **Vista:** modest increases in foliage, distance and object detail from your originals.
- **Performance:** modest reductions in scene detail. No FPS improvement is guaranteed.
- **Current Baseline:** release quality requests without switching off the visual mode; active mode optical overrides remain until the mode releases them.

Select a profile card to preview it, then click **Apply** at bottom right. Targets and the number of unavailable built-in controls are shown before Apply; the report contains individual capability details. Existing custom profiles keep exactly their saved values; built-in keys are not silently added. Edit named settings in **Advanced Graphics**, save values into a profile, then Apply. Removing all custom keys returns that slot to its built-in recipe. These are experimental recipes within bounded test ranges, not native defaults or measured safe maxima.

## Advanced controls and temporary trials

For sharpening, foliage, distance/LOD, Contrast, bloom or weather: choose a setting and value, then **Test & Restore**. It tries the value for about two seconds and checks restoration. First restore pre-change visuals using Diagnostic Center and choose Current Baseline for quality. Applying Game Defaults may still own visual settings, so it is not a substitute for releasing them. A prior trial is optional for direct named-control Apply.

Sharpness uses WoW's reversed raw scale: **lower is sharper**. Built-in profiles now preserve your current strength instead of forcing 1.

For **Shadows, lighting & water**: choose a supported native level, then **Try selected level & restore**. It captures the tier and readable named settings, applies the tier, waits two seconds, restores it and checks the captured values. These are experimental temporary trials, not persistent tier profiles. If a related setting fails to return, the report retains its original and no guessed repair is attempted. Use **Restore interrupted quality trial** deliberately after reviewing an interrupted/failed trial. HDR/renderer changes remain in the game's settings.

## One consolidated check

Outside combat, use a stationary scene:

1. Night Vision → your chosen Original/Game Defaults; Lantern → that same return mode. Check the effects and optional sounds you chose.
2. In Graphics Quality → Detail profiles, apply Vista, switch Night Vision/your return mode, then Current Baseline. Quality and modes should stay independent.
3. Toggle friendly names twice. Enter Camera Mode, then exit using its keybind or Alt+Z plus Exit. Check that original player/pet name visibility returns.
4. Optionally try a supported shadow/light/water tier and let restoration finish. If it reports recovery, stop that trial and export; do not repeatedly retry it.
5. Open **Diagnostic Center → Export Complete Diagnostic Report → Select All → Ctrl+C**. Paste the report with a short description of what looked right or wrong. It collects the technical details; no chat transcript or extra commands are needed.

Reports exclude names, chat, accounts, local paths and raw native exception text. They include only name-setting CVar identifiers and numeric states, not actual player/pet names. Nothing uploads automatically. Run Diagnostics is read-only; test/apply/camera buttons perform their named actions.

## Recovery and removal

External edits are preserved instead of repeatedly overwritten. Ordinary return-mode/Current Baseline/name toggle respects conflicts. Explicit recovery can replace a newer value with the captured original; use the appropriate Diagnostic Center, Advanced Graphics or Camera restore control deliberately.

Restore before updating, disabling, downgrading or removing the addon. SavedVariables is not immediately durable or crash-proof. Deleting files or saved data does not undo graphics/name changes. Keep unresolved originals and export instead of deleting a journal.

## What is verified

Native dev.6 Night Vision/readback/restoration is recorded in [28](https://github.com/ProfessorMinty/LumenShift/blob/feat/beta-integration/docs/28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md). The dev.10 baseline behavior has simulated coverage only. The textured UI was reviewed through an off-client layout model and automated Lua tests; native font metrics, input, scrolling and addon coexistence still need an in-game check. New dev.7 camera, profile and tier behavior has automated mock coverage and still needs in-game evaluation. Dev.12 adds explicit persistent native normal/raid recipes, including supported shadow/light/water settings, with captured known-value restoration. Complete native dependencies/restoration and owner acceptance are not established. See the [feature/evidence matrix](https://github.com/ProfessorMinty/LumenShift/blob/feat/beta-integration/docs/29-QUALITY-PROFILES-AND-NATIVE-TRIALS.md). This is an expanded interactive development build, not accepted feature-complete beta or a CurseForge release.

Original code/technical documentation: MIT, copyright 2026 Northern Lights Labs. Original creative assets: All Rights Reserved with permission to install/use as part of LumenShift. Both notices and THIRD-PARTY-NOTICES.md ship in the addon; dev.9 supplied-art licenses remain unchanged.
