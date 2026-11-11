# Photo Studio interface

Beta.22 • November 11, 2026

The owner's screenshot showed a 360-pixel-wide inspector with two mode selectors, six tool tabs, six preset buttons and two history actions above the first slider. The first two slider rows filled the remaining viewport. The new inspector keeps that width. World Photo and Portrait Stage share a mode switch in the title bar. The six editing tools use a vertical rail with icons and persistent labels. Capture screenshot is the primary action in the bottom bar.

| Observed design | LumenShift implementation |
|---|---|
| Lightroom lets photographers browse visual profile previews and adjust intensity. [Adobe profile controls](https://helpx.adobe.com/lightroom/web/edit-photos/apply-effects/use-profiles.html) | Color shows six illustrated versions of the same landscape together. Each has a caption. The current match has an underline and a name. Manual adjustments can produce a Custom look. Intensity and the two color balances sit directly below the gallery. |
| Photos groups vignette darkness, size and softness under one adjustment. [Apple vignette controls](https://support.apple.com/guide/photos/phtafbdcae9d/mac) | Vignette has three shape controls and a placement map. Glow has separate shape and color controls. Film holds light leak and grain. Each page fits without wheel scrolling in the tested standard and compact layouts. |
| The Lightroom radial gradient has a spatial editing gesture. [Adobe radial gradient](https://helpx.adobe.com/lightroom/web/edit-photos/apply-masks/create-mask-with-radial-gradient.html) | Click a point on the placement map to move both axes and see the effect in the scene. Type X/Y percentages for precision. The glow handle also appears on the game scene while editing its shape. |
| Visible choices reduce the need to recall how to find an action. [Nielsen Norman Group](https://www.nngroup.com/articles/ten-usability-heuristics/) | The rail keeps tool names visible. Subpage labels stay pinned. Undo and Redo sit beside the Look heading, with availability drawn from the actual history. Cool/warm and green/rose tracks show the direction of the adjustment and mark neutral. |

Capture separates the timer, output settings, combat preferences and the staged compositing pair. Saved separates world looks, compositions and sharing, or staged scenes and lights. The scrollbar appears when content exceeds its viewport. Long collections and detailed output settings can still scroll.

The swatches are original palette illustrations. The world itself supplies the live preview. Selecting a page only changes which controls are displayed. Presets, restoration, appearance sources and camera movement continue through their existing controllers. SavedVariables retain schema 20. The artwork source and licensing are in [asset provenance](../assets/PROVENANCE.md).

All 711 simulated Lua 5.1 tests and 10 packaging tests passed. Seven interface cases exercise gallery selection, scroll-free Look pages at both densities, live percentages, scaled placement and numeric entry, history, combat and navigation across both modes. Standalone layout renders were inspected at 360 UI units wide. Actual client fonts, pointer targets and usability still need owner testing.

## Owner test

1. Extract the test ZIP and replace the installed LumenShift addon folder. Keep SavedVariables.
2. Open Camera Mode, choose **Look → Color**, click Warm Ember, then drag Cool / warm. Try Undo, Redo and Show Before.
3. Open Vignette, raise Darkness, then click near one corner of the small image. Confirm that the clear center moves. Try Glow → Shape with Amount above zero and move the glow. Change its color under Color mix.
4. Open Film and adjust grain. Check the settings in Portrait Stage as well. Use Hide controls or H, take a screenshot, and check the file. Confirm the labels and pointer targets feel comfortable at your usual UI scale.

## Camera and actors in beta.23

**World Photo.** Open Camera → Position. Hold Orbit left/right or Tilt up/down and release at the angle you want. Closer and Farther adjust distance. Precision movement slows the pad. The field-of-view track also accepts a typed value. Framing has separate Guides, Offset and Quality pages.

**Portrait Stage.** Camera → Position opens a two-axis orbit map. Moving horizontally changes the viewing angle around the cast. Moving up raises the viewpoint. Front, Three-quarter and Profile jump to a view and preserve the lens distance and horizon roll. Lens holds distance, aim height and field of view. The stage lens needs the native ModelScene renderer.

**Actors.** The selected cast member is shown above the controls. Pick Stand, Sit, Kneel, Wave, Cast spell or Run and press Play pose to see the motion. Browse searches 56 animations and shows six per page. Playback adjusts the variation and, on the ModelScene renderer, time and speed. Scrubbing pauses the actor. Individual models can support different animations.

**Placement.** Choose Transform → Place and click the front-view map. The crosshair marks the selected actor's horizontal and vertical stage coordinates. Type X and Y for precision or adjust depth and scale. Turn changes facing, tilt and roll where supported. Use Cast to add a target or pet. Staged lighting has separate Rig, Direction and Color pages.

### In-game check

1. Disable Narcissus for the test. Open the LumenShift wheel and select Camera. Hold Orbit left, release, then try Tilt up with Precision movement enabled. Check that motion stops on release.
2. Switch to Portrait Stage. Try Three-quarter, then click the orbit map and adjust Horizon roll. Confirm that Level horizon keeps the viewing angle.
3. Select Actors → Poses → Wave and press Play pose. Open Playback and scrub to freeze a frame. In Browse, search for Dance and try it on the player.
4. With a unit targeted, use Cast → Add target. Select the target in Transform → Place and click Right. Check that only the target moves. Hide controls, inspect the frame and press Escape to exit.

All 717 Lua 5.1 mock tests and 10 packaging tests passed. The six new interface tests cover compact layouts, scaled map clicks, rejected edits, cast selection, animation browsing and the fallback model renderer. Layouts were inspected off-client at 360 UI units wide. Verify the native render, game fonts, pose playback and pointer feel at your usual UI scale.

## World Photo Light in beta.24

Tone pairs Brightness and Contrast. Detail pairs Sharpness and World bloom. Drag anywhere along an illustrated track or type a value and press Enter. The four samples show the direction of adjustment. The live world is the preview, and native bloom depends on the current renderer and scene. Sharpness uses the existing 0–100 scale, which the controller converts to WoW's inverse sharpening value.

Originals shows each captured game value alongside its current reading. A dash marks an original that has yet to be captured. Show Before and Show After compare the whole photo. Restore lighting returns only the native lighting edits, keeping the selected photo look. The existing preview queue combines rapid inputs, verifies each native transaction and drains the final requested value before comparison, restoration or capture.

**In-game check.** Open Camera → World Photo → Light. Drag Brightness slowly, hold the pointer down, and move it again. Check that the world changes before release and settles at the displayed value. Try Contrast, then any available Detail controls. Open Originals, compare Show Before and Show After, and choose Restore lighting. Verify your original values and look at the scene before exiting Camera Mode.

All 724 simulated Lua 5.1 tests and 10 packaging tests passed. Seven Light tests cover live changes before release, both layout sizes, queued page changes, exact restoration, restricted settings, numeric input and an external-change conflict. Off-client renders were inspected at 360 UI units wide. Actual renderer response and drag feel await in-game testing.

## World Photo Pose in beta.25

**Find an emote.** Open World Photo → Pose. Type part of a name or paste an emote such as `/salute` in the search field. Results update as you type. All emotes shows six cards per page. Select a card and click Pin to keep it in Favorites. Searching, paging and pinning only change the picker.

**Try it on your character.** Choose Try followed by the emote's name. This requests a world emote that nearby players may see or hear. Animation depends on the character and client. Stop pose uses WoW's cancel action or requests Stand on clients with the legacy API.

**Take one shot.** With Pose timer off, Take shot captures your current frame through the clean screenshot path. With the timer on, choose a delay of 0–10 seconds and press Pose & shoot to replay the selected emote and take one shot. Try always previews, including when the timer is on. The timer uses the saved after-pose preference and delay. The Capture tab retains its separate burst count. Cancel during the countdown stops the pending shot. WoW's screenshot event supplies the completion message.

**In-game check.** With Narcissus disabled, search for Dance, click Try Dance, and click Take shot during the animation. Confirm that WoW's Screenshots folder contains one image with the controls hidden. Pin Dance, open Favorites and turn on Pose timer. Try a short delay, then start a second countdown and cancel it. Check that the cancelled shot adds no file.

All 732 simulated Lua 5.1 tests and 10 packaging tests passed. Eight picker tests cover search and focus, page bounds, favorites, preview-only emotes, immediate and timed single shots, cancellation, missing APIs and separation from Portrait Stage. The 360-unit layouts were inspected off-client. Native animation timing and the resulting screenshot files still need an in-game check.

## World Photo Capture in beta.26

Choose **World Photo → Capture → Timer**. Single shot uses a 0–10 second delay. Choose Burst for 2–5 shots with 1–5 seconds between them. Both the panel action and the bottom shutter follow these choices while Timer is open. The current count, delay and spacing use the existing saved preferences. Switching to Single shot remembers the previous burst count for the current session.

The countdown shows seconds to the next shot. Each confirmed screenshot fills one segment. The inter-shot countdown begins when WoW confirms the preceding capture. If WoW rejects a screenshot or sends no result, the burst stops and the panel reports the confirmed count. Cancel capture stops the initial countdown. Stop burst cancels the remaining shots between captures. Escape exits Camera Mode. A screenshot already requested from WoW can still finish.

The existing event-driven sequence handles the shutter, clean frame and screenshot events. Adjusting the timer and switching capture pages only edit preferences or navigation. Under Output, JPEG, Antialiasing and Shadows expose their own controls. Their existing Apply and Restore actions remain explicit.

**In-game check.** With Narcissus disabled, try Single shot with a three-second delay. Check the countdown, wait for WoW's confirmation and inspect the new file in Screenshots. Then try a three-shot burst with two seconds between shots. After the first confirmation, click Stop burst before the next shot. Verify the confirmed count against the new files and check that the capture controls are absent from the images.

The Lua 5.1 suite has 740 passing simulated tests, including eight World Capture cases. All 10 packaging tests passed. An additional timing check covered the 11 first-shot delays at each of the five shot counts, yielding the expected 165 simulated screenshots. Timer, Output and Combat fit without scrolling in the tested standard and compact layouts. Actual frame timing, game fonts and saved files need the in-game check above.

## World Photo Saved in beta.27

In **Saved → Looks**, choose **Save current** to store color and screen effects such as vignette, glow and grain. Native lighting stays separate. In **Compositions**, the same action captures the framing guides, zoom and camera settings available on the current client. The existing banks hold 12 looks and eight compositions. Older entries use the same format.

Enter a name and save. The library selects the saved card and opens its page. To update an entry, select its card, choose **Save current → Use selected name**, then click **Replace look** or **Replace composition**. The two libraries can contain the same name.

Search by part of a name or use Previous and Next. Each page holds three cards. Stock looks use their palette illustrations. Custom looks show their effect details; composition thumbnails draw the saved aspect and thirds guides on a reference landscape. Browsing reads the library without changing the shot. **Apply look** loads screen styling. **Apply composition** recalls guides and the captured camera settings and reports the result. **Delete** removes the selected entry from that library. **Share** still imports and exports look codes.

**In-game check.** With Narcissus disabled, save a warm look, change to a cool look, then search for the saved name and apply it. Save a different composition with a square guide, move the camera, and apply that composition. Check the framing, available zoom and field of view, and confirm the warm look is still active. Reload the UI and find both entries again.

Nine simulated library tests cover existing full banks after reload, literal search and keyboard focus, replacement at capacity, deletion, asynchronous camera failures, guide-only clients, look sharing and Before/After. A separate sweep saved, searched and applied all 20 entries through the visible controls. The library and save forms fit both tested panel sizes. Native rendering and persistence on the installed client remain part of the in-game check.
