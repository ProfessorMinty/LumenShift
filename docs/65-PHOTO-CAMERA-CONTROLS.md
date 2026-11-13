# Photo camera controls

Beta.20 • 10 November 2026

World Photo now opens its first session on **Camera → Position**. Hold **Orbit left/right** to turn around your character or **Tilt up/down** to change the viewing angle. Release to stop. **Precision movement** slows all four directions for fine adjustments. World camera angles stay where you leave them on exit. The distance and field-of-view controls still use their existing restoration paths.

In **Portrait Stage → Camera → Position**, drag a slider or type an angle in degrees. Yaw orbits the cast horizontally. Pitch raises or lowers the camera around its aim point. Roll rotates the staged image around the viewing axis. **Level horizon** sets only roll to zero. **Reset stage camera** returns all six lens and position settings to their defaults. Scene saves include the angles. A world backdrop stays level behind the models.

The pinned **Position**, **Framing** and **Visibility** buttons remain accessible while scrolling. Framing holds guides, bars and the backdrop or advanced world settings. Visibility holds name and bubble controls in both modes. Capture, Hide controls and Exit remain at the bottom of the screen. Filters are under **Look**, and individual actor rotation is under **Actors → Transform**.

## Design research

The following observations describe each developer's published interface. The last column records LumenShift's design choices.

| Reference | How the controls appear | LumenShift decision |
|---|---|---|
| Remedy, *Control* | A Camera tab groups roll and field of view with lens settings. Filters and character visibility have a separate tab. Reset and Hide UI have dedicated inputs. | Give camera movement its own first page and put name visibility behind a plainly labeled button. [Remedy’s guide](https://blog.playstation.com/2019/10/15/acclaimed-sci-fi-shooter-control-gets-a-photo-mode-tomorrow/) |
| Insomniac, *Marvel’s Spider-Man 2* | Photo Mode starts on Camera. Shoulder buttons navigate four tabs. Precision lowers input sensitivity so players can finish lining up the subject. | Open on Position and let players switch the held controls to a slower speed. [Photo Mode guide](https://blog.playstation.com/2023/10/19/marvels-spider-man-2-photo-mode-features-detailed-tips-to-get-started/) |
| NVIDIA Ansel | The published interface shows collapsible groups in a narrow side panel, with numeric FOV and roll in Camera & Capture. Snap and Done are available beneath the settings. | Keep most of the screen available for composition. Show degrees beside staged camera sliders and keep capture and exit reachable. [Ansel interface, slide 19](https://developer.download.nvidia.com/assets/gameworks/downloads/regular/GDC17/TakeAdvantageOfNVIDIAAnselPhotoModeAndGeForcePlatformFeatures_GDC17_FINAL.pdf#page=19) |
| DynamicCam and LibCamera for WoW | DynamicCam exposes separate zoom, shoulder-offset and pitch groups. LibCamera documents native yaw and pitch motion, with explicit stop behavior. | Put direct movement on Position. Keep dynamic framing under Framing and stop only the movement LumenShift started. [DynamicCam options](https://github.com/mpstark/DynamicCam/blob/master/Options.lua) · [LibCamera](https://github.com/mpstark/LibCamera) |

## Forever capabilities and implementation

- **World camera.** The captured Forever 70532 global API lists native view start/stop pairs for up, down, left and right. The client must expose both halves of a direction for the associated button to work. The normal and precision speeds are native movement multipliers of 0.08 and 0.025. The resulting degrees per second depend on the client. Release, leaving the button or page, clean view, capture, combat, exit and the existing five-second timeout stop the active direction. Reduced motion disables held movement. [Forever global API inventory](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/GlobalAPI.lua)
- **World horizon roll.** The reviewed global API, CVar inventory and generated Forever 70862 camera API did not establish a supported independent roll setter for the live world. World Photo exposes yaw and pitch as relative movement. Horizon roll is available on the staged model camera. [Captured CVars](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/CVars.lua) · [Forever camera API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/CameraDocumentation.lua)
- **Stage camera.** ModelScene exposes camera position, yaw/pitch/roll orientation and FOV. LumenShift computes a position on a sphere around the cast's aim height, then converts the visible degrees into native radians. Positive elevation puts the lens above that point. Roll changes orientation while preserving the aim point and distance. UI limits are ±180° yaw, ±80° pitch and ±90° roll. The actor-only renderer retains saved angles. [ModelScene methods](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameDocumentation.lua) · [Native orbit model](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXML/Shared/ModelSceneCameras/OrbitCameraMixin.lua) · [Pitch sign convention](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXML/Vector3D.lua)
- **Saved scenes.** Database schema 20 and portrait schema 4 initialize previous active and saved scenes to zero camera angles. This reconstructs their previous front-facing view with their existing distance, height, FOV and actor transforms. The camera writes new lens values to the active scene after the backend accepts them. A failed edit attempts to return the previous lens and reports a failed return if needed.

## Owner test

1. Exit Camera Mode, close WoW and extract the beta.20 ZIP. Replace the complete installed LumenShift folder. Keep SavedVariables. For a standalone test, leave Narcissus disabled.
2. Open **World Photo → Camera → Position**. Hold Tilt up, then Tilt down. Check Orbit left/right and Precision movement. Check release, moving the pointer off the button and changing pages. Verify H gives a clean view and Escape exits with the camera stopped.
3. Open **Portrait Stage → Camera → Position**. With a solid backdrop, set yaw to 30°, pitch to 15° and roll to −12°. Check that the cast stays in frame and the roll updates while dragging. Level horizon should keep the orbit. Reset stage camera should keep the cast, outfit and backdrop.
4. Save an angled scene on **Saved**, re-enter and load it. Check an older saved scene still has its earlier front view. Try a world backdrop and confirm that only staged models follow the stage camera. Inspect one actual screenshot with the controls hidden.
5. Open **Camera → Visibility** for the outstanding quest-giver name check. The four name readbacks and the Hide all names action are available here.

The automated suite covers native-call routing, release and interruption, degree/radian conversion, orbit geometry, live and typed edits, reset, failed edits, save/load, migration, fallback rendering and page navigation with Narcissus absent. Native movement direction and speed, model framing, world-backdrop compositing, comfort and screenshot output still need the owner test.

All 695 Lua 5.1 mock tests and 10 packaging tests passed, including 14 new camera regressions. Syntax checks covered 100 Lua files and four binding bodies. Structural checks covered 67 runtime modules and the existing single CVar writer. Off-client previews covered both position pages and scrolling the smaller viewport with the page buttons pinned.

## Beta.21 verification and remaining work

The standalone fixture exercised all four World Photo buttons and their matching native stop functions. In Portrait Stage, a known pose with yaw −90°, pitch 60° and roll −90° places the camera at approximately (0, −3, 6.29615) at the default distance and aim height. The independent expected orientation is (π/2, π/3, −π/2) radians. The simulated renderer received those coordinates and angles from the visible sliders. The earlier tests also cover live dragging, numeric entry, precision movement, saved scenes, level/reset and the actor-only renderer. The numerical check follows the published [Forever orbit convention](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXML/Shared/ModelSceneCameras/OrbitCameraMixin.lua) and [vector math](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXML/Vector3D.lua).

- If a stage angle is rejected, its thumb and numeric field return to the accepted value together. Updating the thumb does not issue another camera request. Loading a saved angle that fails now preserves the current lighting as well as the cast.
- If WoW rejects a movement stop, clean view keeps its controls accessible and shows the failure. Exit returns the normal HUD, runs the other restorations and reports any outstanding stop failure. A rejected start followed by a rejected stop preserves the stop error so the player can see the outstanding problem.
- If a timer queues a callback and then reports a scheduling error, the abandoned callback cannot later refresh the controls.

All **704 Lua 5.1 mock tests** passed, including **23 camera-axis cases**, along with **10 packaging tests**. Syntax checks covered 100 Lua files and four binding bodies. Structural checks verified 67 runtime modules, the TOC and the single graphics writer. The camera tests ran with Narcissus absent. No new in-game rendering or movement result was recorded for beta.21.

**Owner acceptance checklist.** All three planned photo deliveries are implemented. The remaining work is in-client acceptance and repairs for discrepancies found there.

1. With Narcissus disabled, try the four world directions at both speeds, release, switch pages and exit. Check yaw, pitch and roll on a staged subject against a solid backdrop, then level, save and reload it. A world backdrop should stay level. Confirm the actual shot matches the preview.
2. Recheck Marshal Dughan in **Camera → Visibility → Hide all names**. If his label persists, record the NPC, Special, Interactive and Focused readbacks and compare while untargeted with the pointer away. Check original names return afterward.
3. On representative player, pet and NPC models, verify poses, spell effects, exact transmog sources, both weapon hands and saved outfits. Inspect the actual single, timed, burst and compositing images plus an external screenshot made with controls hidden.
4. Exercise combat preferences, H/Escape, cancellation, world transitions, reload and restoration after another addon changes an owned setting. Check input, responsiveness and clipping in a three-actor scene at the player's usual UI scale.
