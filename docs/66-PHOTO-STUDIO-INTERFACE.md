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

## Portrait Stage Saved in beta.28

Choose **Portrait Stage → Saved → Scenes** to save the cast, poses, outfits, stage camera, backdrop and model light together. **Lights** stores the direction, color and intensity of the model light. Applying a light changes the rig while preserving the current cast and camera. Each library holds eight entries and reads earlier saves in place.

Click **Save current**, type a name and save. Search by part of the name or page through three cards at a time. Select a card and click **Apply scene** or **Apply lighting setup**. To replace an entry, select it and choose **Save current → Use selected name**. The action displays **Replace** when the typed name already exists in the current library. Delete acts on the selected entry. Each library keeps its own search and selection.

Scene cards diagram the saved cast positions from the front. Light cards illustrate key color and direction on an ambient swatch. Selecting a card only changes the library selection. On Apply, scene slots resolve the current player, target or pet. The status reports completion after the actors finish loading. A partial result identifies cast, light or lens issues. **Actors → Cast** shows per-slot failures.

**In-game check.** With Narcissus disabled, pose your character, add a target, choose a backdrop and save a scene. Save a different light under the same name in Lights. Move an actor, then search for and apply the light. Check that the rig changes and your actor stays put. Apply the scene and check the original placement, poses, backdrop and lighting. Reload the UI and find both names again.

Nine simulated portrait library tests cover full banks after reload, search focus, replacement, deletion, cast and light previews, pending model loads, missing units, renderer limits and switching modes. A separate check saved, found and applied all 16 entries using the visible controls. Both libraries and their naming forms fit the standard and compact test layouts. Native model appearance, lighting and installed-client persistence still need the in-game check.

## Portrait Stage Capture in beta.29

Open **Portrait Stage → Capture → Timer**. Choose the output from the row above Single shot and Burst.

| Output | What WoW captures |
|---|---|
| Full scene | Staged cast and current backdrop with the active photo look. |
| Background | Current backdrop with the staged models hidden. A world backdrop still includes objects and units in the live world. |
| Cast | Staged models against solid chroma green. |
| Pair | A background screenshot followed by a cast screenshot on green, with the same staged pose held across both passes. |

Select a first-shot delay of 0–10 seconds. Burst takes 2–5 shots, or 2–5 pairs, with 1–5 seconds between shots or pairs. A three-pair burst produces six ordinary screenshot files when all six captures succeed. WoW writes them to its Screenshots folder. The layer passes omit the photo filters and mode overlays. For an external editor, key the green cast over the corresponding backdrop.

Either shutter on Timer starts the displayed sequence. The counter advances on WoW's screenshot event. The second pass follows confirmation of the background. Between pairs LumenShift returns the backdrop, filters and each actor’s previous playback setting. Cancel capture stops the initial countdown and Stop burst cancels remaining work between captures. A native request already issued can still finish. If a pass fails or times out, the panel shows how many files were confirmed.

**In-game check.** Disable Narcissus, stage a playing character, choose a distinctive backdrop and add a photo look. Try a single Background shot and a Cast shot. Then select Pair, choose a three-second timer and start a two-pair burst. Check that the four files alternate between the backdrop and green cast, omit controls and filters, and that the original stage and playback return afterward. Repeat and stop between pairs to check cancellation.

Eight simulated stage tests cover both renderers, framing, paired poses, timing, cancellation, partial captures and restoration errors. A separate UI sweep exercised all 20 output and shot-count combinations, checking the contents of 75 simulated captures. The timer and burst controls fit both tested panel sizes. Native screenshot rendering and file output still need the in-game check.

## Portrait Stage Light in beta.30

Open **Portrait Stage → Light → Rig**. Drag the dot horizontally to move the key light around the cast, and vertically to raise or lower it. The center is the front of the stage and both outer edges are the back. These directions are relative to the stage, including when its camera is turned. The angle readout follows the gesture. Clicking a named gel changes the key color. **Key intensity** (0–200%) controls directional illumination, and **Shadow fill** (0–100%) adds neutral ambient light.

For fine control, **Direction** offers four compass points and typed azimuth and elevation. **Color** has live red, green and blue tracks with percentage entry. **Presets** shows four illustrated complete rigs. Use **Saved → Lights** to keep a custom rig. The existing lighting format works on both native stage renderers.

**In-game check.** Open Portrait Stage with a character posed and Narcissus disabled. Watch the character’s face while you drag from Left to Right and then upward. Click Amber, lower Shadow fill and drag Key intensity. Check the lighting changes before you release. Try a custom blue mix under Color, save it under Saved → Lights, apply Softbox, then recall your saved light. Take a Full scene screenshot to check the result. World Photo lighting and camera settings should stay as you left them.

Eight standalone mock tests exercise live input, both renderers, rejected edits, saved rigs and gesture cleanup. An additional sweep compared the direction, color and intensity received by the renderer for 108 combinations. All four pages fit at both tested panel sizes. The native rendering and input feel still need the in-game check.

## Portrait Stage Outfits in beta.31

Open **Portrait Stage → Actors → Outfits** and choose the actor in the top row. **Collection** opens first with the local **Collected** filter. Click the slot name to browse another category or **Collection sets**. Type part of a name or a numeric appearance, item or source ID. Category results update as you type. Click a card to preview the appearance on the selected actor. **Sources** lets you choose a specific variant. For weapons that support multiple slots, click the current hand to choose the destination.

**All slots** searches the categories WoW exposes. Enter a name or ID and press **Search** or Enter. Changing the query or leaving the browser cancels unfinished reads. The browser keeps up to 1,000 matches per cross-slot search and flags incomplete reads or capped results. Narrow the query or browse a specific slot for more. The Collected filter describes ownership of the appearance; the source picker shows ownership of each variant. Use **Filters → All** to see uncollected results supplied by the client. Changing a local filter does not change WoW’s wardrobe filters. The explicitly labeled WoW class and reset controls affect the shared wardrobe.

**Items** browses equipment and bags, with item ID/link entry under its own button. **Gear sets** previews equipment sets. **Saved outfits** saves or recalls staged outfits. These views, source variants, categories and filters all use finite pages. None of the preview actions equips gear or applies transmog to the live character.

**In-game check.** With Narcissus disabled, choose a staged actor and open Outfits. Search for a collected appearance and click its card. Check the actor changes and your equipped gear stays the same. Choose All slots, search for a known item in another slot, then try an exact variant from Sources. For a one-handed weapon, switch the destination to Off hand. If a second actor is present, preview on that actor and check the first one keeps its outfit. Actual collection coverage, native item icons and rendering depend on the installed client.

Ten standalone UI tests cover compact layouts, exact-source and off-hand previews, both renderers, interrupted search, partial results, rejected previews and wardrobe controls. A separate eight-page sweep previewed 24 appearances on each simulated renderer and checked the source on the selected model after every click. Native model rendering and available collection entries still need the in-game check.

## Portrait Stage actor effects in beta.32

Open **Portrait Stage → Actors → Effects** and choose the player, target or pet in the actor row. Browse the twelve curated effects six at a time, narrow the library with **Elemental**, **Lighting** or **Magic**, or type a name, family or exact visual-kit ID. Search, paging and hovering leave the actor as posed. Click a card to preview the effect on that actor, click another to swap, or click **Clear effect** to remove it. **Clear search** only resets the text filter. The top row continues to show the actor’s current choice even when it falls outside the filter.

The cards use bundled family symbols. The selected staged character supplies the live preview. ModelScene actors use their native replaceable visual kit. The fallback renderer can browse the catalog and retains the scene’s saved choice. Actual particle appearance and duration depend on the client, model and kit.

**In-game check.** With Narcissus disabled, open Effects on a posed character. Search for Frost and click **Frost sparkle**. Clear the search, click **Fire surge**, and check that it replaces the frost. Type an unmatched name and use **Clear effect**. If there is a second actor, give it a different effect and check that clearing the first actor leaves the second one alone. Save a scene with an effect, clear it and recall the scene to check playback on your client.

Eight standalone UI tests cover browsing, live search, both layouts, native rejection and readback, failed restoration, actor isolation, scene recall, capture, combat and unsupported renderers. A separate sweep exercised 36 previews across the three staged actors. Native particle rendering remains an in-game check.

## World camera framing in beta.33

Beta.32 used the same message for either of two account camera preferences. The screenshot establishes that at least one reported an enabled value. It does not identify which one. In the pinned Forever UI, the Motion Sickness checkbox sets the centering flag to the inverse of its value and the movement-reduction flag to its value. Neither checkbox position turns both off. The older Forever CVar capture identifies both preferences as account-stored. Native flag eligibility and scene behavior are evaluated separately. [Forever settings definition](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/Accessibility.lua#L49-L65) · [Forever preference metadata](https://github.com/Ketho/BlizzardInterfaceResources/blob/d1ee569878094270c0ad8d8b00de0762158fd578/Resources/CVars.lua#L198-L206).

Open **World Photo → Camera → Framing → Offset**. If the page lists an active preference, **Enable photo framing** temporarily pauses it. **Shoulder offset** moves the world camera sideways relative to your character. **Dynamic framing** enables dynamic camera pitch. **Footroom** adjusts vertical composition with dynamic framing enabled. If you prefer to keep your accessibility choice active, leave it enabled and use the other photo tools.

Only the explicit button opts into the override. Opening Photo Studio, editing ordinary sliders and loading saved compositions cannot request it. The existing writer captures exact originals before a write and verifies readback. **Restore all framing** or normal Camera Mode exit returns owned values. A subsequent native checkbox choice supersedes the verified preference override as a pair. If a session is interrupted, the diagnostic report includes the available framing originals. Manual Restore can reconcile an interrupted preference-only transaction at an identifiable endpoint. Ambiguous changes retain recovery data. SavedVariables persistence on a crash is not guaranteed.

**In-game check.** Note the listed preference, enable photo framing, drag Shoulder offset, turn on Dynamic framing and try Footroom. Choose Restore all framing and check both the scene and the listed preference. Repeat using normal Camera Mode exit. The sidebar is 20 UI units wider so Camera and Capture have room in the game font. Check readability at your usual UI scale.

Nine simulated regression cases cover the four preference combinations, no-write browsing, account-stored flags, native restrictions, exact restoration, external checkbox changes, rejected writes, reload recovery and exit during verification. Native movement, restoration and client-font appearance still need in-game acceptance.

## Saved framing preference in beta.34

**Enable photo framing on entry** is available in **Studio → Camera** and **World Photo → Camera → Framing → Offset**. In Studio before entry, the switch saves the choice immediately. Turning it on in an eligible active World Photo session also starts that session’s override. Turning it off changes future entries. To end the current override now, click **Restore all framing**.

Each normal entry reads WoW’s current camera preferences. The existing writer captures the values it changes and restores those originals on exit. A newer external camera choice takes precedence. Manual shoulder offset, footroom, dynamic pitch and field-of-view adjustments still use their own captured originals. The switch does not save or reapply their numeric values. When name hiding or temporary quality is enabled, entry framing waits for those operations to finish.

Schema 21 stores one boolean, off for fresh installs and upgrades. A reload loads the preference without changing game settings. An interrupted preference journal keeps its earlier originals for recovery. Entering during combat uses current native settings for that visit. Ending combat does not trigger a delayed override.

**In-game check.** Turn on the preference in Studio, enter Camera Mode twice and check the Offset controls on each visit. Between visits, change WoW’s motion preference and confirm the second exit returns to the newer value. Try **Restore all framing** during a visit and confirm framing enables again next time. Turn the switch off, exit, then check the one-session enable button is available when a comfort preference is on.

Ten simulated regression cases cover migration, persistence, exact originals across visits, manual restoration and opt-out, combined name and quality settings, stale entry callbacks, combat, native restrictions, external changes, interrupted recovery and rapid exit. Native entry timing and restoration remain part of the in-game check.
