# Delivery 4 — Camera composition and practical graphics comparison

**2026-11-08 · 0.2.0-dev.16 · schema 11 · Northern Lights Labs**

This implements Delivery 4 of [the agreed plan](41-IMPLEMENTATION-PLAN.md) on `feat/beta-integration`, continuing PR #5 from dev.15 commit `ed2f1562b15b59365de5688694a96387714e1175`. Prior visual modes, shared optics, authored variations, normal/raid graphics choices, assets and licensing remain intact. No installed-game operation, merge or publication was performed. Delivery 5 polish and native beta acceptance remain separate work.

## What the player gets

- **Camera composition:** optional thirds and 16:9, 2.39:1 or square frame guides. These are guides, not viewport remapping or cropping. A capture/exit bar remains visible when Camera hides the HUD. Native mouse and wheel framing remain unchanged.
- **Guide-free screenshot:** Capture screenshot hides LumenShift's composition guides and bar, waits for a frame opportunity, then calls the native screenshot function. It reports native success/failure when observed; a timeout is explicitly unobserved. Ordinary Print Screen is not intercepted and may include the guides. Selected visual effects remain governed by the existing Camera effects preference.
- **Manual field of view:** reads the current `cameraFov` and the native API's dynamic range. Editing the slider saves an editor choice; Apply field of view makes the deliberate change. Exact pre-change raw values are captured before writing and restored on explicit Restore framing or Camera exit. No zoom automation, camera tracking, rotations or continuous correction is added.
- **Optional temporary photo quality:** off by default. Choose a native 1–10 level, then enter Camera. It applies to everyday graphics and, if separate raid settings are enabled, the raid bank as well. The enable flag and saved everyday/raid choices remain unchanged. Exit restores captured pre-photo values, including known dependent leaves. Unknown renderer dependencies remain an acknowledged limitation.
- **Practical graphics comparison:** Graphics Quality now offers Smooth gameplay, Richer scenery and Quieter operation guidance. These choices explain what to compare; they do not assign a hardware tier. Observe FPS for 10 seconds records ten native readings after two seconds of settling, the actual elapsed time, selected scene label, requested bank choices and observed settings. The latest two observations remain in memory and diagnostic export for the current session. No graphics settings change during sampling.

## Architecture and restoration

`Core/Framing.lua` defines the narrow FOV policy. `Core/Camera.lua` coordinates names, framing, HUD and temporary quality. `UI/Camera.lua` builds the Studio page; `UI/Composition.lua` owns the unprotected composition root. `Core/Performance.lua` owns bounded read-only observations. The native CVar call still exists exactly once, in `Core/WriteBoundary.lua`.

Schema 11 adds Camera guide/photo preferences, an independent framing journal and a temporary photo bank container. Migration retains onboarding completion, modes, presets, baseline references, optical requests and all earlier originals. No setter or HUD change occurs on startup. SavedVariables are not immediately durable storage, and this is not crash-proof restoration. The new photo preference is off for existing installations. LSMODE3/legacy LSMODE2 preset behavior is unchanged.

The photo engine reuses the existing native bank planner, support checks, snapshot/order logic, immediate/delayed readbacks and bounded compensation. Its pre-photo snapshots differ deliberately from the everyday engine's earlier pre-addon originals. Everyday ownership is suspended, not overwritten, while photo records exist; ordinary bank changes wait for explicit photo restoration. The photo engine never writes sharpening/bloom, Brightness, Contrast, Gamma or RenderScale as recipe targets. Shared optical ownership remains canonical and independent. Foreign bank/optical changes detected during a recipe stop the operation and retain evidence.

Exit first shows the HUD, then restores independent names, FOV and photo banks. Matching saved records can be restored after reload through the same explicit button; startup never replays them. Names/framing completion leaves the preceding controller's callback before starting another operation. Multi-bank photo restoration stays inside one boundary sequence. An error in one independent part does not prevent attempting other matching restorations. External changes are preserved, without automatic retries; originals stay available in the report. Missing setters, restrictions or changed native FOV bounds affect the relevant operation.

Combat entry exposes the HUD and hides Camera guides without restoring graphics. A pending Camera entry cannot hide the HUD after combat interrupts it. The player exits/restores deliberately afterward. FPS observation is read-only and may run during combat when explicitly started; the report counts combat observations. This makes an owner-run raid observation possible without enabling graphics writes in combat.

DynamicCam/Narcissus coexistence is based on ownership checks rather than addon-name locks: LumenShift does not modify foreign frames, views, movement controls or tracking settings. If another addon changes owned FOV, restoration stops instead of overwriting it. Actual interaction with those addons remains untested.

## FPS interpretation

The reported mean/min/max are summaries of ten `GetFramerate()` observations. They are **not** per-frame measurements, 1% lows, GPU/CPU timing, thermal/power measurements, a hardware benchmark or automatic quality recommendations. Timers can run late; actual elapsed time is reported. No permanent sampler, render loop, automatic tier selection or repeated quality hunting runs in the background.

The scene label is chosen by the player; no location, character, instance name or chat is recorded. Matching the label does not prove the viewpoint, weather, movement, population or combat load matched. Current known settings are checked each tick. A changed setting, unavailable/invalid reading, world transition, timer failure or Cancel ends the observation without adding a misleading completed result. Between-tick activity cannot be reconstructed. Reload discards session samples. Short outdoor results cannot predict raid performance. Quieter operation still requires the player's noise/heat judgment and native FPS-cap choices.

WoW recommendation retains the earlier meaning: per-key native defaults, not an addon-callable hardware benchmark. No new auto-detect function or fabricated RAID variants are introduced.

## Evidence and decisions

Inspected 2026-11-08. Sources establish interface declarations and source behavior, not successful native testing of this implementation.

- **Source-confirmed, mirrored Forever 70862:** [native Graphics.lua FOV setting, lines 1181–1195](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua#L1181-L1195) reads `cameraFov` and API-provided limits. [Camera API declaration](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/CameraDocumentation.lua) specifies the default/min/max return tuple. LumenShift's finer 0.1-degree editor step is an authored experimental choice, not a native visual acceptance claim. It has no guessed fallback range.
- **Captured API inventory, Forever 70532:** [GlobalAPI.lua](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/GlobalAPI.lua) lists `GetFramerate`, `GetTime` and `Screenshot`; [Events.lua](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/Events.lua) lists screenshot success/failure. Each function's current availability/accessibility is checked at runtime. An API name alone does not prove its live result.
- **Existing bank/leaf evidence:** [37](37-NATIVE-GRAPHICS-BANKS.md) and [39](39-GRAPHICS-CONTROL-LANDSCAPE.md) retain the native recipe mappings, known dependencies, FPS/research limitations and external-camera precedent. No third-party addon code or assets were copied for this delivery.
- **Verified earlier in client:** the owner's recorded Brightness round trip remains accepted in [28](28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md). This is not evidence that the new FOV/photo/screenshot/FPS integration passed in game. No launcher version reconfirmation is requested.

## Automated and layout validation

- **366 Lua 5.1 mock tests passed, 0 failed**, including CAM01–CAM26 for migration, bounds/restrictions, exact and partial restoration, cross-controller read/setter reentry, other-addon changes, reload, combat, guide/capture events, invalid/late FPS observations, cancellation and bounded lifetime.
- **9 packaging tests passed**: deterministic bytes, single install root, source identity and hashes, licensing/provenance and unsafe-path rejection.
- **42 runtime modules**, exact TOC/version checks and one native CVar call; **56 Lua files + four binding bodies** passed Lua 5.1 syntax checks.
- Whitespace checks and **100 local documentation links** passed. Offline geometry inspection covered the Camera page, photo options, composition guides/bar and graphics comparison; approximate fonts/textures/strata and the mocked native Settings host are not native UI proof.

All automated cases are simulated, including camera visibility, screenshot events, FPS values, native recipes and renderer side effects. Offline geometry models are not game screenshots. The final complete run followed the callback-serialization fixes and unknown-combat/timer regressions. Intermediate failures were corrected before this result; no in-game pass was inferred.

During development, tests caught the missing FOV read-catalog entry and restoration attempting to enter the second photo bank through a still-held public callback guard. Both were corrected. Combined names/framing/photo entry and exit coverage also exercises deferred transitions between controllers. Final review corrected the overall photo status to Recovery when one bank restores but another conflicts; CAM19 asserts that result. The failed runs remain development history, not passing native results.

## Install and try it

1. Exit WoW. Keep SavedVariables; do not delete your preferences or recovery records. Back up the old addon folder.
2. Extract the development ZIP. Copy the **entire LumenShift folder** into Forever's `_forever_/Interface/AddOns`, replacing the old addon folder. The result is `.../_forever_/Interface/AddOns/LumenShift/LumenShift.toc`, with Core, UI, Media and Bindings.xml beside it. Install neither the ZIP nor the TOC alone.
3. Start WoW. Right-click the LumenShift launcher/minimap button for Studio. Completed setup should stay completed. Opening pages should change no graphics settings.
4. Open **Camera**. Leave temporary photo quality off initially. Choose thirds/frame guides and whether to hide names. Enter Camera. Confirm the HUD hides, selected screen effects behave as chosen, and the capture/exit bar remains usable.
5. Click **Capture screenshot**. Check the saved screenshot for absence of LumenShift's guides and bar. Confirm controls return after completion. Click **Exit Camera Mode**; confirm the HUD and captured name values return. Alt+Z is still a native HUD shortcut, not complete Camera restoration.
6. Try a small **Field of view** edit, then **Apply field of view**. Restore framing and confirm the previous framing returns. If the API is unavailable, the page explains that locally; HUD/guides remain usable. Try your camera addon normally and confirm LumenShift does not keep forcing its value.
7. For photo quality, first restore any overlapping detail profile/contact-depth trial using its existing controls. Enable **Use a photo quality level on Camera entry**, choose a modest level, and enter. Exit. Check everyday and enabled raid settings against their pre-photo values; confirm saved bank choices and the active visual mode were retained. Export diagnostics if restoration reports a conflict/failure; do not clear saved data.
8. Open **Graphics Quality**, scroll to **Find your balance**, choose a goal and scene, then **Observe FPS for 10 seconds**. Keep the same viewpoint and workload. After it completes, deliberately change a native level using the existing Apply button and sample again. Compare observations with appearance/motion and your desired experience. Restore the bank if desired. Sampling never applies a level for you.
9. Check Camera exit, window scaling/dragging, reload with matching owned changes, failed capture recovery, and interaction with other addons. Studio → Diagnostic Center → **Export Complete Diagnostic Report** includes FOV/photo originals and FPS observations. Export is optional during normal use.

**Still requiring native observation:** FOV effective readback/appearance, screenshot timing and guide exclusion, HUD/strata/input at varied scale/aspect, DynamicCam/Narcissus conflicts, normal/raid dependency closure and photo exit, actual FPS sampling/timer behavior, and the prior dev.13–15 visual effects/looks. Native image-quality improvement, complete renderer restoration and feature-complete beta acceptance are not claimed.
