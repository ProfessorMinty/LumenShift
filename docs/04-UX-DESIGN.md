# UX concept — radial wheel and visual studio
**Status:** proposed direction, not approved artwork or implementation.

## Inspiration
The user's video shows a small compact menu of icons opening beside the character/cursor and disappearing quickly. LumenShift should capture the *instant action* and small footprint without copying assets or code. Two pathways: quick wheel for frequent switches, advanced studio for deliberate tuning.

## Quick wheel (MVP)
- A draggable small orb can open the wheel. Also provide a keybind and slash command.
- Six selectable actions, initially: Natural, Night Vision, Cinema, Lantern, Clarity, Moonlight. Show name + distinct icon + current-selection indication; hue alone is insufficient.
- Wheel placement near cursor with edge-clamping; don't let parts render offscreen. No screen-covering dimmer or large modal background.
- Click-to-select is the safe initial behavior. Investigate hold-to-open, hover-to-select, release-to-commit only after testing input APIs and combat behavior.
- Clear close/cancel action, Escape support, click-away behavior if allowed, consistent hover feedback and contextual tooltips.
- Optional compact status label/orb with active mode indication and quick access to advanced settings (e.g. right click).
- Respect other mouse cursor UI, action bars, accessibility scaling and common HUD addons such as EllesmereUI.
- No strobe/flash, rapidly flickering overlays or loud unsolicited sound.

## Mode design intentions
| Mode | Primary purpose | Suggested visual delta | Optional visual effect | Sound |
|---|---|---|---|---|
| Natural | Return to user's baseline | Restore LumenShift visual-layer keys | None | Gentle optional off cue |
| Night Vision | Read dark interiors | Target brightness 75 vs user's 45 | Tunable green screen tint, restrained vignette, subtle scanlines | Original goggles on/off chirps |
| Cinema | Atmospheric screenshots and exploration | Mood-tuned brightness/contrast after validation | Letterbox and subtle color-wash only; clarify not real LUT | Optional unobtrusive cue |
| Lantern | Warm readable interiors | Raise brightness modestly from baseline | Warm amber overlay, optional soft vignette | Optional warm click |
| Clarity | Most readable gameplay | Neutral brightness/contrast, no obscuring effects | Usually none | None by default |
| Moonlight | Cool low-light fantasy mood | Measured cooler atmosphere with readability warning | Blue-tinted UI overlay (not engine moonlight) | Optional quiet cue |

Modes must not change vegetation/LOD quality profile implicitly. Future extension: user-created modes, location-specific recommendations (manual opt-in), presets import/export.

## Quality profile intentions
- Current Baseline: **exact current user's preferences**, not reset engine defaults.
- Balanced: approved performance/quality middle ground, only validated CVars.
- Ultra/Vista: maximum visual richness with explicit FPS warning and benchmarking.
- Performance: reduce approved performance-heavy effects for busy areas.
Quality profile selected separately from mode. A quality preset change must be previewable and reversible.

## Advanced window
- Header: current mode, current quality profile, client build, restore baseline shortcut, danger/pending marker.
- Modes: gallery of editable mode cards with enable/disable and per-mode deltas.
- Color & Effects: brightness/contrast targets, overlay tint RGB+opacity, edge darkening, scanline visibility; avoid inaccessible green-only labels.
- Graphics Quality: foliage/terrain/detail/shadows/water groupings with measured performance costs.
- Sound: master toggle, activation/deactivation choices, individual volume if API permits and tested.
- Accessibility: reduce motion, high contrast interface, UI scale, keyboard/gamepad testing, optional audio mute.
- Diagnostics: CVar effective vs desired vs baseline, unsupported values, conflicts, pending reload, last failure, copy sanitized report.
- Saved Profiles: future phase for user presets and import/export with validation.

## Responsive behavior and safety
- Multiple aspect ratios and UI scale values, including ultrawide. Avoid action bar, unit frame and chat coverage.
- If Cinema letterbox would cover essential HUD, default to screenshot-only behavior or add in-game warning; never hide combat warnings.
- Sound opt-in and adjustable. No copyrighted game or film audio reused; original synthesized samples acceptable if user approves.
- Describe tint honestly: GUI overlay, not actual world shader and not true low-light intensification.
- Graphics changes show optional restart/relog notices and do not quietly modify user preferences.

## Acceptance walkthrough proposal
1. User opens and closes quick wheel repeatedly with no accidental selection.
2. User toggles Night Vision on/off through its own keybind.
3. User edits green tint independently of brightness.
4. User switches Night Vision -> Cinema while keeping Ultra quality profile.
5. User can Restore My Settings and verify readback.
6. User chooses silence and reduced motion, and preferences persist.
7. User can still reach all vital UI, and wheel works in different resolutions.
8. User opens Diagnostics and sees unsupported CVar clearly described rather than silent failure.

## Visual identity ideas (not assets)
Dark moon-glass / obsidian surfaces, soft emerald/amber/cobalt accents, restrained holographic radial segmentation, original iconography. Accessibility and low GPU/UI overhead outrank ornamental animation.
