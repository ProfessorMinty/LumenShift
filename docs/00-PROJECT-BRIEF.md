# LumenShift product brief
**Stage:** Phase 00 (research only) | **Maintainer:** Northern Lights Labs | **Primary game:** World of Warcraft: Forever

## Mission
Give players one intuitive control for atmosphere, low-light readability and advanced graphical looks, without forcing them into multiple graphics menus. The original use case is brightness around **45** for a moody aesthetic, but **75** when the character enters dark buildings, optionally accompanied by a playful green night-goggle overlay and activation sound.

## Audience
- Players who want to see clearly indoors without giving up their aesthetic outdoors.
- Landscape explorers, screenshot takers, video creators and fantasy-atmosphere enthusiasts.
- Players who want advanced CVar tuning without memorizing console commands.
- Dungeon/raid players who need a dependable readability-first fallback.

## Central distinction: two independent layers
1. **Visual mode** modifies only relevant atmosphere/presentation keys and effects. Initial concepts: Natural, Night Vision, Cinema, Lantern, Clarity, Moonlight.
2. **Graphics quality profile** changes only approved renderer detail settings. Proposed profiles: Current Baseline, Balanced, Ultra/Vista, Performance. Neither layer silently overwrites the other.

## Quick interaction
A small draggable orb and configurable keybind open a radial wheel with memorable icons. The supplied reference video shows a compact icon cluster opening near the cursor; treat it as ergonomic inspiration, not reusable code or art. Phase 01 can begin with click-to-select; investigate hold-to-open and release-to-select separately. Separate one-key Night Vision toggle remains essential.

## Advanced interaction
An expandable configuration panel offers Modes, Appearance/Effects, Quality, Sounds, Accessibility, Diagnostics and Preset Library (latter may ship later). Every CVar entry should show: effective value, baseline, user-tuned target, verified range, client default if known, performance cost and whether reload is required.

## Functional requirements
- F01. Identify live client/build and fail safely on unsupported APIs/CVars.
- F02. Record before-state of every CVar that LumenShift intends to change.
- F03. Apply only declared delta keys, not an entire guessed graphics profile.
- F04. Verify readback and report rejection/clamping, mismatches and pending reload.
- F05. Offer explicit Restore My Settings, with behavior defined for logout/reload/crash.
- F06. Never confuse Restore My Settings with Reset Engine Defaults.
- F07. Allow per-mode tint/sound/vignette toggles and safe opacity limits.
- F08. Respect combat, UI visibility, Edit Mode, other addons and gamepad/keyboard choices.
- F09. Provide a diagnostics/status panel without account identifiers.
- F10. Make all performance-heavy settings opt-in and display risk warnings.
- F11. Saved custom mode variants after core presets and restoration are proven.

## Non-goals for initial release
Real GPU shaders; injector/Reshade integration; overriding the OS monitor color profile; automated combat/camera/player input; automatic environmental light detection; guaranteed color grading of the world; PvP reactive visibility; full Retail compatibility.

## Success criteria (to validate, not yet attained)
- Night Vision cycles **45 → 75 → 45** without losing a baseline.
- Switching mood does not change foliage, draw distance, shadows or other quality settings unless explicit.
- Unsupported or conflicting settings are reported, not silently 'successfully applied'.
- Normal restore returns exact captured values where the client permits.
- Readable wheel and menu never obscure vital combat UI or cause Lua errors.
- No forced addon-generated sound, green cast or letterbox; each is independently adjustable.

## Approval decisions
- Confirm proposed mode names and quality profile naming.
- Approve restoration semantics when users manually alter settings while a preset is active.
- Decide if Vista/Performance are first-release quality profiles or later enhancements.
- Select eventual license and distribution platforms. Repo currently public, license not yet chosen.
