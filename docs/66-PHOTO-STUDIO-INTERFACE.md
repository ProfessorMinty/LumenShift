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
