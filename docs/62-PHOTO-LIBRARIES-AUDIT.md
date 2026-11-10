# Photo libraries and combat audit — beta.17

2026-11-10 · Northern Lights Labs. The owner requested verification of the expanded poses, spell effects, outfit browser and combat choices, plus an honest photo completion checklist. This audits [beta.16](61-PORTRAIT-LIBRARIES-AND-COMBAT.md) against the [photo plan](56-NARCISSUS-PHOTO-ARCHITECTURE.md). Repository/remote verified as ProfessorMinty/LumenShift; same `feat/beta-integration` branch and PR #5. Schema **17**, portrait schema **2**, existing settings and recovery originals are preserved.

**Outcome:** three reproduced defects corrected. All three planned photo deliveries and the requested library extensions have implementations. The beta remains usable without Narcissus; no reset, new unlock, activation approval or prerequisite addon was added. Complete in-game rendering/input/output acceptance has not yet been established.

**Follow-up:** [Beta.18](63-TRANSMOG-COLLECTION.md) implements the subsequently requested native transmog collection browser and exact selected appearance-source saving. The beta.17 evidence and completion scope below remain historical.

## Findings and corrections

| Reproduced behavior | Correction and regression evidence |
|---|---|
| With a neutral photo look inheriting Night Vision's tint, switching Keep filters during combat off hid only the photo-effect layer. The inherited mode treatment remained visible. | Photo rendering now clears the inherited layer too when the active photo session opts out of combat effects. Switching the option back on restores the selected treatment without a graphics write. PXA05. |
| The background/chroma compositing pair hid photo effects but could retain the inherited visual-mode treatment. Refreshes during capture could reapply it. | Route both layers through the same layer-capture exclusion before the first image and on subsequent render refreshes. Completion, cancellation and failure restore the selected treatment. Combat entry/exit and direct refresh are covered. PXA06/PXA12. |
| Missing inventory, bag or equipment-set reader APIs produced an apparently empty browser without explaining the missing source. | Report unavailable sources locally, keep items from working sources and distinguish genuinely empty inventories. Invalid/fractional bag counts and reader failures are rejected without requesting unknown items or disabling the stage. PXA04/PXA09/PXA10. |

The unchanged beta.16 baseline passed **621/621 Lua 5.1 tests**. The initial new reproduction produced **five passing and three failing cases**. After corrections and four additional cases, the focused portrait suite passes **86/86** (PC, PCA, PX and PXA groups). One new two-image test needed its mock timer sequence corrected: an inert timeout from the first image precedes the second request in the fixture queue. It did not require changing native screenshot scheduling.

## What the audit verifies

- All **56** unique pose IDs and all **12** effect IDs plus Clear route to the selected owned actor; another actor stays unchanged. Unsupported-animation rejection and a spell setter throwing after mutation retain/restore the prior selection in the simulated cases. These tests verify routing/state, not visible rendering of the game assets.
- Saved outfits preserve explicit empty slots and use independent copies. A complete scene containing pose, variation, selected time offset, spell effect, off-hand outfit and light survives a standalone reload and explicit scene load.
- Accessible equipped items remain previewable when bag/set readers fail. Unavailable APIs are not inferred to mean an empty wardrobe. Real equipment, spells and world units are never mutated by these browsers.
- All four combinations of Studio/filter combat choices preserve the saved look, respect HUD behavior and issue no deferred native writes. Clean capture stays clean through combat; H and Escape use the existing paths. Default settings retain both the stage and filters.
- Prior migrations, full saved-bank capacity, missing optional backend capabilities, failed item preview buffering, target identity checks, timeout/cancellation, keyboard failure, preset independence and one-writer tests remain in the full suite.

The fixtures provide native API mocks with **no Narcissus environment**, and the addon has no Narcissus TOC/library/art dependency. Optional coexistence code remains separate from rendering and pose/outfit functionality. The runtime writer remains `Core/WriteBoundary.lua`; the new corrections add no native graphics calls.

## Validation record

- **633/633 Lua 5.1 mock tests pass**, retaining all 621 earlier cases and adding PXA01–PXA12.
- **10/10 Python packaging tests pass**. Syntax: **95 Lua files plus four binding bodies**. Structure: **65 runtime modules**, exact TOC/version/assets and one native CVar call site.
- **154 relative documentation links**, whitespace, standalone dependency and portrait writer scans pass. The dependency scan distinguishes explanatory UI text from runtime APIs; foreign symbols are confined to the existing optional compatibility adapter.
- The expanded inventory-status layout was rendered and inspected using the off-client geometry model. Its approximate fonts/textures do not verify native actor appearance or game input.

These are simulated/off-client checks. No actual game session, installed addon folder, WTF file, real equipment or graphics setting was operated. No PR was merged or CurseForge release published.

The candidate ZIP is generated from clean committed source, built twice and compared byte-for-byte, with CRC/content/manifest hashes verified. Its filename and receipt identify the source commit. Original MIT source and separately licensed assets retain their existing notices.

## Source checks

Revisited the pinned Forever 70862 source declarations on 2026-11-10:

- [ModelScene actor base](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorBaseDocumentation.lua): animation variation/speed/offset, `SetSpellVisualKit`/`GetSpellVisualKit`, and `TryOn` signatures. A successful call or kit-ID readback does not certify pixels or universal animation/kit support.
- [Equipment-set readers](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/EquipmentManagerDocumentation.lua): table/nullable reader results, distinct set/ignored-slot APIs and separate equipment-changing functions. LumenShift uses item readers only and previews the returned positive item entries; omitted/unknown entries are not treated as instructions to remove gear. Explicit empty slots in LumenShift's own saved outfits are preserved.
- [Native bag readers](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua#L175): `GetContainerItemID` may return no values for an empty slot. The audit specifically tests that form, so an empty slot does not produce a false unavailable-source warning.
- [Forever character-panel source](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PaperDollFrame.lua#L1559) illustrates the separate ignored-slot representation. This audit does not infer item emptiness or transmog variants from absent item IDs.

These are source-confirmed declarations/examples, not new owner-native observations. The identifier provenance and native-clear example remain in [61](61-PORTRAIT-LIBRARIES-AND-COMBAT.md#source-evidence-and-limits).

## What remains before photo mode is complete

There is **no unstarted mandatory implementation phase** in the agreed photo plan. Remaining work is acceptance and any resulting fixes:

1. **Native model and outfit acceptance without Narcissus.** Test player/target/pet copies and representative race/form/NPC models. Visually check the pose groups, variation/offset controls, each spell kit, replacement/Clear, head/cloak/weapons and equipped/bag/set/saved outfit previews. Mark model-specific missing or wrong visuals and adjust the catalogue/UI where needed. Verify real gear is unchanged. API/mocked success cannot establish this.
2. **Combat and lifecycle acceptance.** Exercise both default-on choices and both opt-outs; check continuous filters, usable sliders/model controls, clean view, H/Escape and visible mouse Exit. Verify no native graphics/name/orbit action runs later because combat ended. Test cancel, re-entry, target changes, loading/world departure and normal reload. Check native input/taint errors and exact return of previously changed graphics/framing/names where supported.
3. **Actual screenshot acceptance.** Inspect the files from ordinary, delayed/burst and background/chroma-pair capture. Check framing, intended filters, clean controls and that both compositing images omit treatments. Also use an external screenshot tool with controls hidden. A mock Screenshot call does not prove a correct output file.
4. **Visual, performance and coexistence polish.** Check common resolutions/UI scales, long item names, scrolling, full three-actor scenes, particles and rapid slider use. Measure actual frame cost and fix clipping/input/appearance issues found. Separately test common UI/camera addons; Narcissus coexistence is optional and must never become a core dependency.

These tasks do not lock the beta or require another version confirmation. Public distribution separately needs the [release QA and final owner publication approval](08-CURSEFORGE-RELEASE.md).

## Scope limits, not missing enablement steps

- Outfit browsing covers equipped/bag items, native sets and saved base-item outfits. At beta.17, transmog-collection browsing was optional; it is now implemented in [beta.18](63-TRANSMOG-COLLECTION.md). Exact snapshots of every worn enchant/bonus/transmog component and richer item comparison remain separate extensions.
- A model kit may not render on every model/client. Skeletal pause does not guarantee frozen particles. Saved scenes retain a chosen offset rather than a read-back instantaneous playhead.
- Compositing pairs produce ordinary background/chroma screenshots. Transparent PNGs, true silhouette/depth masks and layered files are not implemented or promised.
- UI filters/glow/vignette and native model lights do not provide world-buffer LUT grading, depth-aware bokeh, time freeze or real campfire relighting. Native graphics/name writes and native orbit remain subject to combat restrictions; cosmetic controls stay available under the Studio preference.

## Quick owner test of this correction

1. Exit WoW. Extract beta.17 and replace only the complete `LumenShift` addon folder; keep SavedVariables. Disable Narcissus for the standalone check. No reset/setup is needed.
2. Apply a visibly styled visual mode (for example Night Vision), enter Camera and use a neutral photo look so its inherited treatment is visible. In Capture, leave Stay in Photo Studio on. During combat, switch Keep filters off/on and check that the inherited treatment hides/returns immediately.
3. In Portrait Stage, stage an actor with a pose, spell kit and outfit. Capture a background/chroma pair; inspect both files for absence of screen tints/vignette/glow. After completion or Cancel, the chosen look should return. Normal single captures should retain that look.
4. Try Poses, Effects and Outfits, save a scene, exit, reload normally and load it explicitly. Use the broader [beta.16 test](61-PORTRAIT-LIBRARIES-AND-COMBAT.md#exact-local-test) for per-actor effects/outfits and combat combinations. Report the control and visible result for any failure; no launcher-version reconfirmation is required.
