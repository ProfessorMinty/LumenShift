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

## Phase 00 feasibility findings — 2026-11-06

These findings refine the concepts above; none is a live-client pass. Sources are pinned in [07](07-EVIDENCE-AND-DECISIONS.md).

| Feature | Evidence and limitation | Proposed behavior / acceptance |
|---|---|---|
| Tint / gradient | S70790 texture methods include SetColorTexture, SetGradient and SetBlendMode (SRC-15); native world-buffer access is not established | Plain alpha overlay first; blend-mode enumerations and ADD/MOD behavior remain unverified. A texture's desaturation affects that texture, not the world. No monochrome/LUT claim |
| Vignette / scanlines / letterbox | H composition from original UI textures/frames | Off initially; no strobe. Provisional tint cap 0.12, vignette cap 0.15 require readability review, not claimed safe thresholds. Letterbox remains manual screenshot use only |
| HUD layering | UI strata exist, but a single layer cannot guarantee all third-party frames remain untouched | Noninteractive overlay below ordinary HUD where verified; test Blizzard UI, EllesmereUI, tooltips and warnings. Disable the effect if it obscures critical UI. No reparenting/hiding action bars or world viewport resizing |
| Animation | S70790 animation groups/templates (SRC-16) | Short UI-only fade, cancel/cleanup on close; reduced-motion bypass. No per-frame CVar interpolation |
| Original sounds | Beta capture includes PlaySoundFile/StopSound; 70790 source uses StopSound and documents C_Sound sound-kit calls (SRC-01/17) | Custom-file signature, codecs and permissions remain U on 70790. Trial OGG first, WAV fallback after testing. Channel/mute/handle checked in V1; never change global audio CVars |
| Per-cue volume | C_Sound.PlaySound documents volumeOverride for sound kits, not proof for custom PlaySoundFile | Do not advertise arbitrary per-file gain. Prefer mute and pre-rendered quieter original samples until the actual file API is verified |
| Click wheel / orb | H on public frame/button APIs; source has bindings and UI infrastructure | Cursor coordinates converted by effective UI scale, clamped at screen edges; click-to-commit, Escape/cancel. No mouse capture outside wheel bounds; never auto-assign a conflicting key |
| Hold/release | S70790 Camelot bindings use runOnUp and keystate (SRC-18), but Blizzard bindings have different trust context | Deferred feature. Test lost key-up, focus change, chat focus, combat and cancellation; no protected-action bypass or synthetic input |
| Keyboard/gamepad | Source has input infrastructure; actual LumenShift navigation U | Dedicated toggle + numbered/directional selection proposal. No dynamic protected rebinding in combat. Controller support stays unclaimed until tested |
| Advanced Settings | S70790 RegisterCanvasLayoutCategory/RegisterAddOnCategory (SRC-19) | Native discoverability with a custom canvas later; diagnostics distinguish actual CVar string from observed rendering effect |

## Explicit mode delta sets (proposal, all untested)

`b_mode` / `c_mode` mean an owner-reviewed finite value within the admitted range, **not a default to invent**. A mode with unset required values is disabled. Effects are presentation fields, never hidden quality writes. Recommend display name **Cinematic** with internal ID `cinematic`; `Cinema` in the earlier concept remains a naming decision.

| Mode | Exact CVar delta schema | Presentation delta | Current disposition |
|---|---|---|---|
| Natural | `{}`; release visual ownership | all effects off | First core restore action |
| Night Vision | `{Brightness: 75}` | optional green tint and original on/off cue | First target after approval; Contrast/Gamma untouched |
| Cinematic | `{Brightness: b_cinematic, Contrast: c_cinematic}` | optional restrained wash; manual bars off by default | Values unset; later visual review |
| Lantern | `{Brightness: b_lantern}` | optional amber tint | Value unset; later review |
| Clarity | `{Brightness: b_clarity, Contrast: c_clarity}` | no obscuring effects, sound off | Values unset; no sharpen/quality changes |
| Moonlight | `{Brightness: b_moonlight}` | optional blue tint | Value unset; no fog/lighting-quality writes |

The original contrast preference 60 is not forced by Natural. Restoring a visual mode uses the captured actual originals. Optional tint/audio failure must not make diagnostics claim the brightness operation failed or succeeded incorrectly.

## Explicit quality delta sets (Phase 04 proposal)

Recommended first study domain `Q`: `{textureFilteringMode, ResampleAlwaysSharpen, ResampleSharpness, groundEffectDensity, groundEffectDist, groundEffectFade, lodObjectCullSize, lodObjectFadeScale, terrainLodDist, farclip, reflectionMode}`. Each key starts disabled. No brightness/contrast/gamma, camera, colorblind, audio, HDR, backend, overall graphics or raid-bank key belongs to Q.

| Profile | Declared delta | Selection rule |
|---|---|---|
| Current Baseline | `{}` | Release quality ownership only |
| Balanced | `{textureFilteringMode: b_filter, ResampleAlwaysSharpen: b_sharpen, ResampleSharpness: b_strength}` | Proposed modest image-detail scope. Targets unset; disabled pending evidence and visual review |
| Vista (preferred over “Ultra”) | A value for each explicitly named key in Q above | Full detail-study scope. No universal maxima; seed values in 02 are experiments only; targets unset and profile disabled |
| Performance | `{groundEffectDensity: p_density, groundEffectDist: p_dist, groundEffectFade: p_fade, lodObjectCullSize: p_cull, lodObjectFadeScale: p_lod, terrainLodDist: p_terrain, farclip: p_far, reflectionMode: p_reflection}` | Reduce measured workload where proven, preserving visibility. Targets unset; disabled until benchmarked and reviewed |

An alternative uses native menu-tier keys (`graphicsViewDistance`, `graphicsGroundClutter`, `graphicsEnvironmentDetail`, lighting/shadow/water tiers). It is easier to explain but can change underlying keys. Do not mix tier writers with low-level writers for the same domain. Admit a tier only after its entire side-effect closure and restoration order are known; otherwise leave it to Blizzard's menu. Reject profiles with unapproved required keys instead of silently applying a subset under the same name.

These symbolic values are explicit authoring slots, not executable profile data. On a profile change, removed keys release ownership through the normal conflict-aware restore path. A smaller tested key set may be proposed later as a newly reviewed profile revision; do not silently redefine an existing profile after skipping unsupported keys.

Acceptance: switching any visual mode produces zero quality-key writes; selecting Quality Baseline leaves the visual mode active; Restore All reports every restored, externally changed, failed and pending key. Labels/icons remain distinguishable without color, effects can be disabled independently, keyboard actions are reachable, and diagnostics remain usable when advanced features are unavailable.
