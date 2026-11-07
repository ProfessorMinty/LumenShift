# Supplied artwork integration — 0.2.0-dev.9

Date: 2026-11-07. Scope: the existing Studio design, setup, reports, launcher and mode wheel on `feat/beta-integration`, draft PR #5. The owner's downloaded source packs are read-only inputs. No installed-game changes, native graphics tests, merge or publication.

## Visual direction

The interface combines dark steel surfaces, silver utility icons and restrained teal light. Large page titles, grouped navigation, aligned controls and the fixed primary action from dev.8 remain. Decorative art stays behind controls and does not replace their text labels. The approved LumenShift logo remains the central brand asset.

| Supplied artwork | Selected exports | Placement |
|---|---|---|
| Core Essential UI Icons — Streamline | Eleven Line icons and one Solid close icon, 64×64 | Studio navigation, primary actions, setup close, report heading and wheel Studio button |
| Mesh Gradients — Craftwork Studio | Steel and Midnight, 512×512 | Steel for Studio/setup/report panels; Midnight for the sidebar |
| Lumen Loops — Jon Lehman | Teal accents 6 and 8, 512×512 | Restrained header/selected-card sweep and wheel center halo |
| Fractal Haze — Kroba Store | None: not found among supplied files | Pending; current headers use the selected Lumen Loops artwork |

The six existing mode icons are unchanged pending the owner's custom fantasy family. Utility symbols are not replacements for that family. Existing original audio and vignette remain. No video assets, new animation loop, shader or sound pack was added.

The wheel base and six selected sectors use original fitted geometry; the switch track and knob are also original shapes. The wheel keeps its existing labeled mode buttons and keyboard controls, adds a central logo, and accepts clicks across its visible ring sectors. Pure `Radial.Hit` geometry excludes the center, the outer area and the gaps. The existing Product controller still handles every activation. Edit fields receive a teal focus outline.

## Implementation and source records

`tools/export_theme.py` performs mechanical raster/format exports using isolated Pillow 13.0.0 and resvg-py 0.5.0. These are build tools, not addon dependencies. It recolors Core SVG paths white for native UI tinting, preserves source aspect ratios in raster exports, and renders the original functional geometry. Source packs are not sent to an image generator.

`assets/theme-sources.json` maps all 16 selected third-party inputs to their runtime files, source SHA-256, creator, modifications and license URL. `assets/manifest.json` records every committed output hash. `THIRD-PARTY-NOTICES.md` records checked official sources and credits; both the notices and source mapping ship inside the ZIP. Studio → Accessibility → Art & Credits includes visible attribution. The exact source filename, rather than a local owner path, identifies each input.

Original code stays MIT; original creative assets retain the owner's reserved-rights terms. Streamline Core exports retain CC BY 4.0, and the identified Craftwork exports retain the applicable Craftwork Commercial License. `ASSET-LICENSE.md` explicitly excludes these third-party files from its original-art ownership claim. Only the selected, integrated runtime textures ship: no source packs, editable SVG/Figma files, videos or full-resolution downloaded masters. Final public-release review retains the existing license/acquisition and owner-publication checks.

The complete Media directory has 37 files totaling 6,991,746 bytes. Textures use power-of-two dimensions and uncompressed 32-bit BGRA TGA with alpha. Packaging consumes committed exports deterministically; it does not regenerate source art. Native texture caching and actual GPU allocation have not been measured.

Shared widget pools reset texture alpha, tint, crop and draw layer before reuse. Persistent icons are allocated once; page art reuses existing pools. No polling or per-frame layout handler was added. High contrast hides decorative mesh/light textures while retaining controls, labels and selection indicators. Existing reduced-motion preferences remain in effect; the added artwork is static.

No planner, native writer, ownership/recovery model, mode/quality relationship or SavedVariables schema changed. Schema remains 5, completed setup stays completed, and startup does not change graphics settings.

## Verification

**Simulated / off-client:**

- `python tools/check.py --mocks --lua-runtime ../lua-test-runtime`: 209 passed, 0 failed under Lua 5.1. Syntax checks compile 40 Lua files and 4 binding bodies; structural checks verify 32 runtime modules, exact TOC paths, matching versions, asset hashes and the single native CVar call site.
- U07–U10 cover labeled icon navigation, high-contrast decoration suppression, pooled texture state reset, edit focus, bounded keyboard sector selection, matching ring/gap hit geometry and controller routing. Earlier zero-startup-write, restoration, conflict, setup persistence, camera and quality cases remain passing.
- `python -m unittest discover -s tests -p test_package.py -v`: 9 passed. Added checks require the third-party notices/source mapping and bound packaged texture size while excluding source editing packs.
- The optional UI model uses actual Lua widget positions and texture paths, including opacity, tint, crop and draw layer. Browser inspection checks Studio, effects, setup, wheel, high contrast and the report window. These are off-client previews with mock values, approximate native font metrics and slider placement.

**Not verified in-client:** dev.9 texture decoding, native font/texture layering, wheel hit targets at the owner's UI scale, and the complete UI interaction pass. The earlier owner Brightness result is unchanged in [28](28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md). Mock screenshots are not owner diagnostics or new live evidence. Remaining native camera/profile/tier/effects/audio gates are unchanged.

## Owner check when the game is available

1. Close WoW and replace the complete `Interface/AddOns/LumenShift` folder with the extracted dev.9 folder. Keep SavedVariables. See [21](21-BETA-USER-GUIDE.md) for the full installation guide.
2. Log in and right-click the LumenShift launcher/minimap icon to open Studio. Confirm the new utility icons, steel panels, teal selection and readable page hierarchy at your normal UI scale. Startup should not alter the scene or repeat completed setup.
3. Visit Accessibility, toggle High-contrast panel, and check that decoration disappears while text and controls remain. Revert it if preferred. Check numeric-field focus and saved switch preferences.
4. Open the mode wheel. Check visible segments, labels, hover/keyboard selection, Escape/right-click close and the central Studio button. Selecting a mode retains the existing real mode-switch behavior; use Natural to restore your captured original afterward.
5. Open Diagnostic Center → Export report. Confirm the report text and select/copy controls are readable. Reopen setup from Accessibility only if you want to inspect it; closing without Save keeps your existing settings.

An ordinary diagnostic export and a screenshot of any overlap or missing texture are sufficient feedback. This change adds no extra approval dialogs or calibration ceremony.
