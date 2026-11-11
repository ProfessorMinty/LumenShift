# LumenShift

**Northern Lights Labs · Visual modes for World of Warcraft: Forever**

**0.2.0-beta.25** provides six editable visual modes, an icon wheel, Studio, optional screen effects and original Night Vision sounds, personal presets, independent graphics profiles and diagnostics. This is a local beta candidate for owner acceptance, not an approved public release.

World Photo → Pose now lets you search 12 illustrated character emotes, pin favorites, try an emote, and take a clean shot. The optional pose timer replays the emote for one timed screenshot. [Pose controls](docs/66-PHOTO-STUDIO-INTERFACE.md#world-photo-pose-in-beta25).

World Photo → Light now has illustrated, draggable Tone and Detail controls. Open Originals to compare the game values or use Restore lighting to return to your pre-edit lighting. [Photo Studio controls](docs/66-PHOTO-STUDIO-INTERFACE.md#world-photo-light-in-beta24).

Beta.23 adds a compact world camera pad, a clickable portrait orbit map and illustrated pose picks. Open **Portrait Stage → Actors** to pose the selected character. **Transform → Place** moves an actor on the stage. [Camera and actor controls](docs/66-PHOTO-STUDIO-INTERFACE.md#camera-and-actors-in-beta23).

Beta.22 redesigns Photo Studio with an illustrated filter gallery, a labeled tool rail, click-to-place vignette and glow controls, and separate pages for common editing tasks. [Interface and controls](docs/66-PHOTO-STUDIO-INTERFACE.md).

Beta.21 corrects camera failure handling in World Photo and Portrait Stage. [Camera verification and remaining photo work](docs/65-PHOTO-CAMERA-CONTROLS.md#beta21-verification-and-remaining-work).

Beta.20 puts **Camera** first in Photo Studio. World Photo adds held vertical tilt and precision movement. Portrait Stage adds live yaw, pitch and horizon roll with numeric entry and saved angles. Choose Position, Framing or Visibility in either mode. [Design research, controls and test guide](docs/65-PHOTO-CAMERA-CONTROLS.md).

Beta.19 audits collection loading and repairs photo name-control feedback: explicit immediate Hide switches, Hide all / Restore names, focused-unit coverage, and readable NPC values. Collection interruption, failed scheduling and partial source lists are handled honestly. Schema 19 preserves settings and recovery; no reset or Narcissus is needed. The remaining quest-giver label is still a native acceptance question. [Audit and exact test](docs/64-COLLECTION-AND-NAME-AUDIT.md).

Beta.18 adds **native transmog collection browsing** under **Camera → Portrait Stage → Actors → Outfits → Collection**: categories, search, collection-status/favorite/source filters, class selection, exact-source previews and native sets/variants. Selected appearance sources survive outfit/scene saving; older settings migrate without a reset. Works without Narcissus. Entries depend on the client’s native collection data; uncollected availability is not assumed. [Controls, source decisions and test steps](docs/63-TRANSMOG-COLLECTION.md).

Beta.17 audits the expanded photo tools: combat filter changes now clear inherited mode effects, compositing pairs consistently omit both treatment layers, and unavailable inventory sources are reported locally. All photo deliveries and requested library extensions are implemented; native rendering, combat/input and actual screenshot acceptance remain. [Audit and completion checklist](docs/62-PHOTO-LIBRARIES-AUDIT.md).

Beta.16 adds **56 grouped/searchable model poses**, variations, **12 model spell effects**, an equipped/bag/equipment-set browser and **eight saved base-item outfits**. Under Actors, choose Transform, Poses, Outfits or Effects. Filters and existing Photo Studio stay active during combat by default; Capture and Accessibility provide independent combat choices. Native graphics/name writes and camera movement remain locally restricted. Schema 17 keeps earlier settings and scenes; no Narcissus or reset is needed. [Controls, limits, sources and test procedure](docs/61-PORTRAIT-LIBRARIES-AND-COMBAT.md).

Beta.15 audits Phase 3: changing targets no longer swaps a staged actor during appearance edits; absent optional model APIs no longer prevent scene loading; fallback poses retain saved advanced choices; letterbox/capture-result behavior is corrected. **589 Lua 5.1 mocks and 10 package tests pass.** All three photo deliveries are implemented; native rendering, input and actual screenshot acceptance remain. [Audit, limits and remaining work](docs/60-PHOTO-AUDIT-AND-COMPLETION.md). No Narcissus or settings reset is needed.

Beta.14 adds **Portrait Stage** beside World Photo: player/target/pet model copies, live transforms, curated pose playback/scrubbing, model lighting, neutral/chroma backgrounds, saved scenes/lights and a two-image compositing capture. Existing filters and capture controls remain available. Phase 2 audit fixes a pending zoom exit interrupted by combat/world leave. No Narcissus or settings reset is needed. [Architecture, source decisions and exact test](docs/59-PORTRAIT-STAGE.md).

Beta.13 adds **camera composition and output controls**: zoom, held orbit, shoulder/dynamic framing, native-supported antialiasing and ray shadows, JPEG quality, edge light and separate saved compositions. The Phase 1 audit fixes tab-switch undo and late screenshot visibility after leaving the world. No Narcissus or settings reset is needed. [Controls and test guide](docs/58-PHOTO-COMPOSITION-AND-OUTPUT.md).

Beta.12 adds **Pose and Capture** tabs: twelve world emotes, favorites, Stop pose, optional pose capture, countdowns and short bursts with Cancel. Frame gains separate player/pet/NPC/bubble controls; Look gains Undo/Redo. **Every photo tool works without Narcissus.** Optional coexistence handles its known passive toolbar without borrowing its features. Keep your saved settings. [Controls, architecture and test steps](docs/57-STANDALONE-PHOTO-WORKFLOW.md).

Beta.11 makes native photo lighting and FOV sliders **preview while dragging**, with paced verified updates and the latest endpoint retained. Capture and Hide controls finish the pending edit first; Escape cancels unissued edits and uses normal restoration. [Details and owner test](docs/55-LIVE-PHOTO-SLIDERS.md). No settings reset is needed.

The [Narcissus source investigation and photo expansion plan](docs/56-NARCISSUS-PHOTO-ARCHITECTURE.md) explains the overlapping toolbar, world-photo versus model-stage techniques, and the phased posing, capture and composition work. Deliveries A, B and C are implemented in beta.12/beta.13/beta.14. **LumenShift is standalone and must work with Narcissus uninstalled.** The research itself added no dependency or copied source/artwork.

Beta.10 adds a complete **in-scene Photo Studio**: live filters, soft vignette, draggable glow, grain, native lighting sliders, comparison, framing and saved photo looks. Camera keeps Hide controls/H and Escape. [Implementation and testing](docs/54-IN-SCENE-PHOTO-EDITOR.md). The later beta.14 update adds the optional model stage; native visual acceptance is pending.

Beta.8 corrects Camera Mode rejecting server-stored friendly-name preferences as if they were write-protected. The existing camera controls now use the corrected policy through activation and restoration; diagnostic exports include the full flags and precise preflight result. No settings reset is needed. [Failure evidence, fix and checks](docs/52-CAMERA-NAME-STORAGE-FIX.md).

Beta.7 shows **one launcher at a time**, cleans up wheel spacing and puts **Camera** directly on the wheel. Minimap and floating are alternative entry points; existing preferences are preserved. [Changes and checks](docs/51-LAUNCHER-AND-WHEEL.md).

Beta.6 adds **Reset LumenShift & Restart Setup** in Studio > Accessibility and WoW's LumenShift settings panel. It clears only addon data, reloads, and opens fresh setup while leaving current game settings unchanged. [Reset behavior and checks](docs/50-RESET-AND-RESTART-SETUP.md).

Beta.5 fixes a reported recovery refusal after the owner’s fallback macro returned Brightness to its captured original. [Failure evidence, fix and clean setup](docs/49-RETURNED-ORIGINAL-AND-CLEAN-SETUP.md).

Beta.4 fixes five findings from the whole-addon forensic audit: cross-controller reentry, effects Apply, wheel input, unnecessary graphics ownership and incomplete Camera recovery exports. [Full audit, fresh sources and remaining limits](docs/48-FORENSIC-AUDIT.md). The earlier [Phase 5 audit](docs/47-PHASE5-AUDIT-AND-COMPLETION.md) remains historical evidence.

Beta.2 completes Delivery 5: editable saved presets, Delete/Undo, retained drafts, scrolling setup, keyboard focus/navigation, display fitting, reduced-motion fixes and readable status. Its Delivery 4 audit fixes independent Camera/name restoration and capture cancellation across sessions. [Current changes, support matrix and test steps](docs/46-BETA2-POLISH-AND-AUDIT.md).

Dev.16 adds Camera composition guides, guide-free capture, manual native field of view, optional temporary photo quality, and a user-started FPS comparison with practical graphics guidance. [Implementation, limits and testing steps](docs/45-DEV16-CAMERA-AND-PERFORMANCE.md).

Dev.15 audits Delivery 2 and adds two distinct starting looks per mode, independent light/style intensity, optional sharpening/bloom capture for Original or Game Defaults, and a separate bounded contact-depth trial. Existing saved looks are retained. [Changes, evidence and button-based testing](docs/44-DEV15-DISTINCT-MODES.md).

Dev.14 adds shared mode/quality optics, Inherit / Off (extra) / Custom sharpening, Clear/Goggles Night Vision, neutral fresh Clarity with optional bloom, real sequential Before/After and data-only preset import/export. Existing customizations are preserved. [Implementation, tests and button-based steps](docs/43-DEV14-SHARED-OPTICS.md).

Dev.13 completed the first reliability delivery: coordinated Brightness/Contrast switching and recovery, a saved Camera effects preference, cosmetic resume after combat, viewport-aware edges and a local bloom capability check. [Changes, validation and button-based test](docs/42-DEV13-RELIABILITY.md).

Dev.12 added native **1–10 graphics levels**, **WoW recommendation**, **Keep current**, separate **raid/battleground settings**, previews and per-bank Restore controls in Setup and Studio. Recommendations come from the game's defaults, not a hardware benchmark. Native recipes now control shadows, lighting, water, textures, particles and other source-defined components where available. [Implementation and limits](docs/37-NATIVE-GRAPHICS-BANKS.md).

The dev.11 reload/mode-continuation, movable-window and wheel-spacing fixes remain included. [Regression details](docs/36-DEV11-RELOAD-AND-UI-FIXES.md).

Version/build/interface differences now show one warning instead of locking controls. Actual APIs, values and ownership are still checked. Schema 17 preserves preferences, completion, graphics banks, photo looks and exact originals; Camera-session names intent remains separate from manual names choices. Preset exports use LSMODE3; older LSMODE2 imports remain supported. Dev.7 added Camera Mode, built-in quality recipes and native tier trials. Dev.8 redesigns Studio with grouped navigation, mode/profile cards, aligned settings, a fixed primary action and the approved aurora logo. [UI architecture and validation](docs/31-STUDIO-REDESIGN.md). Dev.9 integrates the supplied Core icons, mesh panels and Lumen Loops accents, with a fitted wheel and bundled third-party credits. [Asset integration](docs/32-ASSET-INTEGRATION.md).

Setup offers **Original** (your captured Brightness/Contrast) or **Game Defaults** (the values reported by WoW). Setup can also explicitly include sharpening/bloom in the return reference. Mode optics take precedence over quality, which takes precedence over that reference. The selected name replaces Natural in the interface; graphics quality stays independent. This is a visual baseline choice, not a reset of all game settings. [Baseline behavior](docs/34-BASELINE-CHOICE.md).

The [Forever graphics investigation](docs/33-FOREVER-GRAPHICS-DEEP-DIVE.md) covers native/hidden image-quality, lighting, water and detail controls, their evidence and the plan for more substantial modes. Dev.10 also fixes built-in sharpening recipes and adds read-only research observations; the proposed rendering features are not all implemented yet.

The [mode and optics audit](docs/38-MODE-AUDIT-AND-OPTICS.md) records what every mode actually does, the owner's existing sharpening/AO observations, stronger Night Vision options, real night-vision design context and the remaining implementation work. It distinguishes native sharpening/contact depth from unsupported world-outline shaders and identifies Camera presentation and composite-mode gaps. Delivery 1 reliability fixes and Delivery 2 shared sharpening/bloom controls are implemented in dev.13/dev.14. Delivery 3 starting looks, intensity and the isolated contact-depth trial are included in dev.15. Delivery 4 Camera/graphics comparison is implemented in dev.16. Delivery 5 polish is implemented in beta.2; integrated native optical, Camera and UI acceptance remains pending.

The broader [graphics control research](docs/39-GRAPHICS-CONTROL-LANDSCAPE.md) covers native settings, hidden CVars, Lua/console APIs, camera/viewport tools, HDR, drivers and external shaders/client modifications. It includes a searchable historical inventory of 701 graphics/related CVars and 25 graphics console commands, with source/default/security provenance. External dark-edge and monochrome shaders are technically real; their existence does not make them Lua-addon features or establish Forever compatibility.

The [community visual research](docs/40-COMMUNITY-VISUAL-RESEARCH.md) compares firsthand Forever experiments and creator approaches to sharpening, atmosphere, camera composition and sustainable performance. It checks popular recipes against native metadata and proposes concrete improvements and comparisons for each mode. Community preferences and proposed effects remain separate from verified client behavior.

The [implementation plan](docs/41-IMPLEMENTATION-PLAN.md) turns that research into five usable deliveries: reliability fixes, shared optics and sharper modes, distinct mode treatments, Camera/graphics selection, and beta polish. Routine development proceeds under existing authorization; unavailable optional features affect their own controls, without adding global locks or repeated setup approvals.

Setup separates Appearance from Graphics. Save & Close saves choices without applying them; Apply & Reload explicitly applies selected graphics banks before reload. Ordinary mode use remains enabled; it cannot silently leave controls disabled because graphics were still loading. The previous completed-but-disabled setup also works with a direct mode click. No acknowledgement checkbox, non-75 Brightness unlock or repeated calibration requirement stands between a normal click and its action.

## Install and use

Install the **whole extracted LumenShift folder**, not the ZIP or TOC alone, under Forever's `Interface/AddOns`. Follow the [installation and testing guide](docs/21-BETA-USER-GUIDE.md).

1. Choose **Original** or **Game Defaults** on Appearance, then **Next: Graphics**. Keep current is the initial default. Choose a recommendation or level only if desired. **Save & Close** saves without applying; **Apply & Reload UI** applies the selected banks. With both kept, **Finish & Reload UI** saves/reloads only.
2. Left-click the LumenShift launcher or minimap button for modes; right-click for Studio.
3. Select **Night Vision** to try it. Select **Original** or **Game Defaults** to return to the baseline chosen in setup.
4. Use Studio's Visual Modes editor to customize Brightness and optional Contrast. Edit preferences freely, then click **Apply**.
5. In **Graphics Quality**, use native normal/raid choices or **Detail profiles** for Balanced/Vista/Performance. Scroll to per-bank Restore controls when originals exist. In **Advanced Graphics**, select a named setting and value, then **Test & Restore** for a temporary trial. Balanced/Vista/Performance have built-in bounded recipes; saved custom values take precedence; **Current Baseline** restores quality independently.
6. In **Camera**, hide/show the interface using the native Alt+Z API, optionally hide friendly player/pet names, or toggle names separately. The optional Camera keybind exits and restores Camera changes while preserving independent manual names choices; native Alt+Z only brings the HUD back. **Keep visual effects in Camera** controls whether the selected effects stay visible while the HUD is hidden.

Normal use requires no commands. Settings → AddOns → LumenShift also opens setup, Studio and diagnostics. Opening setup, startup and reload do not activate graphics or play sounds. The explicit **Apply & Reload UI** action applies selected graphics before reloading. Saved choices remain available without automatically reapplying a mode on login.

## What works and what is unfinished

Night Vision starts at Brightness 75; other modes have editable authored settings. Every activation captures the actual original before writing, verifies readback and preserves external changes instead of fighting them. The return mode uses the chosen visual snapshot. Diagnostic recovery restores exact pre-change visual/optical originals, which can differ from Game Defaults; it also clears optical quality requests while retaining other quality settings and saved edits. Effects are optional UI textures, not world shaders. Audio begins muted and can be enabled in setup or Studio.

Optional Contrast and named sharpening, foliage, distance, LOD, bloom and weather controls are **experimental**. Apply checks the current client, values, bounds and flags. Test & Restore is optional, not an unlock. Saved quality profiles remain usable after reload without repeating tests. Balanced/Vista/Performance now have bounded built-ins with explicit unavailable-member reporting; existing nonempty custom profiles keep exactly their own keys. Shadow/light/water tiers have real temporary native trials which restore the tier and check captured named settings. Dev.12 also includes supported tiers in persistent native normal/raid recipes with captured known-value restoration. Complete native dependencies and live acceptance remain unverified. HDR/renderer controls remain in the game settings.

The single native graphics call remains in WriteBoundary. Planner, per-key originals, ownership, conflict detection and readback remain internal requirements. An interrupted session or unresolved conflict needs an explicit recovery decision; startup never guesses a restore. SavedVariables is not immediately durable or crash-proof. Restore before updating or removing the addon.

The owner supplied successful **dev.6 Brightness 45 → 75 → 45** native readbacks on **Forever 1.60.1:70862:16001**, with no report warnings/errors. [Evidence and compatibility policy](docs/28-DEV6-ACCEPTANCE-AND-WARNING-POLICY.md) distinguish that success from dev.7's new simulated paths. See the [quality feature/evidence matrix](docs/29-QUALITY-PROFILES-AND-NATIVE-TRIALS.md) and [Camera architecture](docs/30-CAMERA-MODE.md). **The current beta.18 is an integrated candidate awaiting owner acceptance.** New native graphics controls have mock coverage; full dependency restoration and owner in-game acceptance remain unverified.

## Diagnostics

Studio → Diagnostic Center → Export Complete Diagnostic Report produces one copyable report of current capabilities, values, operations, originals and recent errors. It excludes names, chat, accounts, local paths and raw native exception text. Nothing uploads automatically. Reports are useful when something fails; exporting one is not a prerequisite for ordinary use.

## Development

Authoritative repository: [ProfessorMinty/LumenShift](https://github.com/ProfessorMinty/LumenShift). Existing branch `feat/beta-integration`, draft PR #5. Main and prior PRs are not merged automatically; [Issue #1](https://github.com/ProfessorMinty/LumenShift/issues/1) remains open.

```text
python tools/check.py --mocks --lua-runtime PATH_TO_ISOLATED_LUPA
python -m unittest discover -s tests -p test_package.py -v
python tools/package.py --output PATH_OUTSIDE_REPOSITORY
```

The optional Lupa 2.6 runner uses actual Lua 5.1 and is not shipped. System Lua 5.1 can run `lua tests/run.lua`. The builder reads clean committed source, stamps its commit into Core/Build.lua, hashes the payload and compares two archives byte-for-byte. It cannot install or upload.

## Licensing

Original source/technical documentation: [MIT](LICENSE), copyright 2026 Northern Lights Labs. Original creative assets: [All Rights Reserved](ASSET-LICENSE.md), permitted for installation/use as part of LumenShift; no independent reuse/redistribution in other projects without permission. Third-party terms remain independent. See [provenance](assets/PROVENANCE.md). The complete distribution is not MIT-only.

No CurseForge project, upload or publication is authorized. Publication requires native QA and final owner approval.
