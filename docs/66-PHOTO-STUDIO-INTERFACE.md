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
