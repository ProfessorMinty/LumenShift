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

## Reconciled Phase 00 test specification — 2026-11-06

**All tests are NOT RUN.** [10](10-CLIENT-VALIDATION.md) supplies the read-only R1–R4 commands and separately gated W1–W4/V1/B1 protocols. A source inspection is not an executed mock or live test. The future implementation must preserve these test IDs in its evidence records.

### Required off-client cases

| ID | Injected scenario | Required observable result |
|---|---|---|
| M01 | First load, fresh DB, reconnect, valid DB | Zero setters and zero unsolicited sound; diagnostics available |
| M02 | Actual baseline 45 and separately 52; NV -> Natural | Restore 45 and 52 respectively; original never replaced by 75 |
| M03 | Target already equals current, key unowned | No write, no restore claim/ownership acquired |
| M04 | Visual transition with quality profile active, then reverse | Exact writer-call set restricted to selected layer; other selection unchanged |
| M05 | Missing API/CVar, false/nil/error return, secure/read-only flags, inaccessible value | Refusal before mutation; clear specific status; no fallback ConsoleExec/RegisterCVar |
| M06 | NaN/infinity, string payload, unknown key, wrong type, out-of-domain target | Rejected before any write; imports never execute code |
| M07 | Setter returns success but no-op/clamps; setter errors after changing | Detect mismatch; inspect attempted key; compensate only defensible changes |
| M08 | Failure at each operation in a multikey switch | Reverse compensation to transaction before-values; previous active mode retained only if recovered |
| M09 | Restore fails or becomes restricted midway | PARTIAL/ERROR with unresolved journal preserved; no “fully restored” status |
| M10 | External value drift before preflight, before setter, after readback and before restore | External value preserved; ownership suspended, bounded diagnostics, no write fight |
| M11 | Synchronous/reentrant CVAR_UPDATE, duplicate/missing events | No recursive apply; immediate reads still authoritative; bounded event queue |
| M12 | Late readback drift, stale timer, rapid repeated toggles/cancel | Transaction IDs reject stale callbacks; one transaction at a time; latest explicit request handled once |
| M13 | Combat enters between preflight and operation | Stop/defer; no automatic retry after combat; recover only when allowed |
| M14 | Reload with unresolved journal; character switch; missing/stale journal after simulated crash | Read-only recovery; never adopt an active preset as fresh baseline |
| M15 | Corrupt/older/newer schema or invalid profile | Preserve recovery data, disable writes, transactional migration or explicit refusal |
| M16 | Profile tries visual/quality overlap or tier plus low-level writer | Reject ambiguity before writes, including indirect dependency conflicts |
| M17 | Unknown client build/interface or unsupported renderer | Read-only mode, no stale catalog writes |
| M18 | Optional missing sound/texture, hidden UI, reduced motion | Core result accurately reported; no global audio changes; effects clean up |

Model the unavoidable same-value/ABA race separately: the mock should demonstrate the limitation, not claim to solve writer attribution. Property checks over generated valid plans should enforce disjoint writer sets, no write without a captured original, and preservation of unresolved records. A stock Lua pass cannot certify WoW's security/taint behavior; use a parser/runtime matched to the game's accepted dialect when implementation begins.

### Live acceptance record

For each R/W/V/B case record build tuple, date, catalog version, approved scope, API/flags, exact before/target/immediate/settled/restore strings, visual effect, unrelated-key comparison, expected vs actual, tester and sanitized evidence. Use PASS, FAIL, BLOCKED or NOT RUN; a skipped key cannot count as a successful whole-profile restore. Keep setter acceptance, readback, rendering effect and persistence as separate result fields.

W2 must cover direct Graphics sliders, overall preset fan-out, raid bank activation, another brightness writer, and late updates after closing Graphics. W3 must cover account/per-character save load, clean reload/logout/cold start, disable after restore, upgrade and schema migration. A hard-crash recovery test stays simulated until separately approved on a disposable setup. Do not install the historical alpha as a test shortcut.

### B1 benchmark protocol proposal

Approval must name hardware, keys/targets, acceptable frame-budget change and recovery values. Use dark interior, dense forest, busy city and long vista; add water/weather scenes for relevant keys. Record resolution, render scale, HDR, backend, driver, frame cap **and its enable state**, graphics tiers, addons, zone/weather/time and camera alignment. Do not publish private hardware identifiers.

Proposed repeatable run: 30-second warmup, then 60-second A baseline / B single change / A restored blocks, at least three matched triplets. Keep the camera fixed and record scene variation; if weather/crowds differ materially, invalidate the comparison. This is a protocol choice, not measured data. Stop on serious stutter or instability; restore immediately where permitted.

Use a permitted, separately approved frame-time capture method for p50/p95/p99 and stutter counts. If only `GetFramerate()` snapshots are available, report FPS samples as such; do not relabel them as true frame times or 1% lows. No external injector or overlay is required. Report effect size, variability and missing evidence; do not claim an improvement smaller than run-to-run noise. A Vista candidate with no visible gain and a measurable cost is rejected for that tested setup.

### UI and packaging acceptance additions

- V1: 16:9 and ultrawide, low/high UI scale, edge-clamped wheel, chat/menus focused, lost key-up, Escape, keyboard-only use, color-independent labels, muted audio, repeated toggles, hidden UI, combat warnings and EllesmereUI. Any covered critical UI fails the effect. Reduced-motion mode must remove nonessential motion.
- P1: install from the exact prospective ZIP into a clean Forever test setup after approval; confirm TOC/interface/load order, asset paths/case and no wrapper nesting. Do not rely on “load out of date addons” to claim compatibility.
- P2: upgrade from the last supported schema, preserve baselines/presets, reject downgrade to unsupported schema with a recovery path. Uninstall after verified restore; document residual SavedVariables and CVar state accurately.
- P3: compare ZIP contents against an allowlist and hashes; check versions, changelog, license/provenance, forbidden files, no placeholders/secrets, and no release credential required for validation.

Phase 00 document validation is limited to link/scope/evidence/consistency checks. No addon or game tests are represented as having passed.
