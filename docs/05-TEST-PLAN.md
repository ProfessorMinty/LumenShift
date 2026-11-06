# Test plan — safety, graphics and usability
**Phase 00:** define tests only; no unapproved writes. **Phase 01+:** execute approved mock and game tests and attach evidence.

## Test evidence metadata
Record game title, build/TOC interface, OS, GPU and driver (non-sensitive summary), display resolution, render scale, graphics preset, addons enabled, zone, weather/time, screenshots, exact steps, pre-values, post-values, frame metrics (where relevant), result and rollback success. Never commit account identifiers or machine-local private paths.

## 1. Read-only compatibility probe
- Record /dump GetBuildInfo(), supported CVar API function existence and return types.
- Read user supplied CVar keys, without modifying settings. Verify exact spelling and absent handling.
- Inspect addon API/Blizzard UI source for security annotations and textures/audio/settings.
- Check whether the game graphics menu and third-party addons already control these keys.

## 2. Write-capable tests ONLY with approval
- For each permitted CVar: snapshot value -> write low-risk proposed value -> read back -> return exact captured value -> read back.
- Test multiple writes across mode changes and rejected/out-of-range values; confirm no unrelated changes.
- Test dependent settings that graphics-menu sliders may overwrite. Try relog/reload only when approved.
- Maintain an emergency recovery card for user to restore original values manually.

## 3. Logic unit/mocks
- Initial Baseline with no mutation.
- Natural -> Night Vision -> Natural: 45 -> 75 -> 45 (only if baseline really 45).
- Baseline 52 -> Night Vision -> Natural returns 52, never hardcodes 45.
- Enable Cinema while Ultra quality stays active, and vice versa.
- CVar missing: report unsupported and skip, other preset parts continue if safe.
- SetCVar rejected, clamped or readback stale: detectable partial failure.
- Manual external CVar change: conflict policy does not destroy user's new value.
- Different addon writes a CVar after LumenShift: do not fight in an endless update loop.
- Combat restricted: no protected call, deferred/failed state and no false success cue.
- Reload/logout/disabled/addon removed state: documented deterministic behavior where possible.
- SavedVariables schema migration, corruption/missing keys, fresh install and profile reset.
- Fail if a mode writes a quality-owned key without explicit approved intent.

## 4. Visual/UI tests
- World tint overlay visible at multiple UI scales and resolutions; verify whether HUD elements are tinted.
- Green tint 0, subtle, medium and maximum allowed: readability and headache/eye-fatigue check.
- Vignette/letterbox enabled/disabled, including ultrawide; check chat, tooltips, quest tracker, raid warnings and action bars.
- Correct mode labels, icons, selection, cancellation, cursor placement, drag persistence and keyboard navigation.
- Animation on/off, sound on/off, repeated rapid toggles, missing audio assets and audio master disabled.
- No flicker/strobe, excessive OnUpdate CPU use or frame leakage from repeatedly opening the wheel.
- Conflicts with EllesmereUI, common UI frames and a second brightness addon.

## 5. Quality/performance benchmarking
Use matched camera position and viewing direction in (a) dark interior, (b) densely vegetated forest, (c) city with players/NPCs and (d) long-distance vista.
- Record frame time distribution and FPS under baseline.
- Change ONE quality CVar per run, not an entire unknown stack.
- Capture screenshots and effect observations; revert exact original immediately.
- Repeat to reduce effects of weather, time, assets loaded, player movement and caching.
- Rate performance impact: negligible / low / moderate / high / unknown, with numbers only if actually observed.
- Reject an 'Ultra' default that is visually indistinguishable but measurably worse on tested conditions.

## 6. Packaging/release tests
- TOC interface/version and client-flavor validation.
- Install directory nesting and expected saved variable files.
- Full restart for new textures/sounds, /reload for Lua tweaks where supported.
- Slash command, binding registration and Settings panel.
- Clear uninstall instructions explaining that persisted CVars cannot be reset by a deleted addon.
- No license-unknown third-party assets in releases.

## Stop conditions
Crash, repeated Lua errors, non-revertible values, unexpectedly large FPS regression, protected action errors, covered combat UI, unexplained setting mutations, unresponsive wheel, or significant eye-discomfort effects. Stop experiment, restore baseline if possible, log results, do not continue to next CVar.

## Verification scorecard
PASS only after reproduction on the target client with steps and expected/actual behavior. SIMULATED PASS is distinct from IN-GAME PASS. NOT TESTED is not PASS. Problems have severity and reproducible evidence.
