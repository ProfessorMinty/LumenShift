# Portrait libraries and combat continuity — beta.16

2026-11-10 · Northern Lights Labs. The owner authorized the formerly optional larger pose library, model spell effects and outfit browsing, plus configurable combat continuity. Builds on the [Phase 3 audit](60-PHOTO-AUDIT-AND-COMPLETION.md) on the existing implementation branch/PR #5. LumenShift remains standalone; Narcissus is neither a dependency nor a source of runtime functionality or bundled art.

**Follow-up:** [Beta.17 audit and completion checklist](62-PHOTO-LIBRARIES-AUDIT.md) corrects inherited treatment visibility during combat choices/compositing and labels unavailable inventory readers. The beta.16 results below remain historical evidence; schema 17 and the delivered controls are preserved.

## Delivered controls

Open **Camera → Portrait Stage → Actors**, select an actor, then choose a tool. Choosing a browser scrolls directly to it; its top button returns to actor selection/tools. Transform retains positioning, scale, sheathe, transmog-preview and helmet/cloak controls.

| Tool | Behavior |
|---|---|
| Poses | **56** native model animation identifiers, grouped as Everyday, Social, Action, Casting and Movement. Plain-text search and eight-entry pages. Includes social emotes, weapon-ready/attack poses, casting/channeling, sitting/sleeping and movement. Six variation choices (0–5), Play/Pause, and ModelScene speed/offset controls. These do not perform a world emote. |
| Effects | **12** curated native visual-kit choices plus No effect. One replaceable kit per actor, saved with that actor/scene. Clearing, replacing or leaving the stage clears the owned kit. These never cast a spell or apply an aura to a world unit. |
| Outfits → Items | Browse wearable items read from equipped gear, bags 0–4 and native equipment sets. Select a slot, search by name/ID, page through entries, and preview an item. Native item icons are used when returned. A pasted item link or numeric item ID can request a separate preview; no script text is executed. Hide selected slot and Clear item overrides are explicit actions. |
| Outfits → Sets | Preview the player's equipped base-item outfit or available native equipment sets. Omitted/ignored set slots retain the staged unit's base appearance. Equipment-set API absence does not disable the other browsers. |
| Outfits → Saved | Save/replace, preview and delete up to **eight** outfits. Saves base item IDs and explicit empty slots, combining accessible equipped items with the staged overrides. This is not an unlock catalogue or a snapshot of transmog collection ownership. |

Existing scene/light banks, live sliders, Look filters, vignette, glow, grain, edge light, background choices, capture/H/Escape and World Photo remain. Native unit identity is checked before an outfit reload or capture of equipped items for a saved outfit. Changing targets cannot silently replace the existing actor. Clothing previews use its hidden back buffer; a failed item request keeps the visible actor and prior saved selection. Outfit overrides respect hide-head/cloak/weapon choices.

Item information is read only on browser refresh or an explicit preview/save action. The list caps at 256 unique wearable items, 32 native sets, and 64 cache requests per refresh. Missing native item data requires another explicit Refresh/preview, never a delayed outfit mutation. Non-wearable cached bag items are skipped. Banks, money, real gear, action bars and world spell casting are untouched.

## Combat choices

The previous unconditional combat handlers hid photo effects, destroyed the stage, cancelled captures and disabled all photo input. The new behavior separates cosmetic composition from native graphics operations.

Both options default **on**, including migration of prior settings. Find them in **Photo Studio → Capture → Combat behavior**, or **Studio → Accessibility → Combat**.

| Choice | On | Off |
|---|---|---|
| Stay in Photo Studio in combat | An existing stage, selected look, owned models, controls and single/timed captures continue. Cosmetic sliders and supported model controls remain available. | Combat returns the game HUD, closes the stage/controls and cancels unissued captures. The photo look stays if the separate filter option is on. |
| Keep filters during combat | Both visual-mode cosmetics and the active photo look remain visible at their selected values. | Temporarily hides cosmetics during combat, retaining their settings. Validated visual-mode cosmetics and the active photo look can return after combat without native CVar writes or sound replay. |

Entering Camera during combat deliberately uses **current native settings**: it does not apply names, temporary quality or a deferred preset. Explicit exit still shows the game HUD and cleans up owned models/captures. Native originals that cannot be restored during combat remain available for an explicit later restore. Ending combat never silently retries graphics operations or re-hides the HUD after the user chose the gameplay-UI option.

Native graphics/name writes, native camera movement and world-emote actions retain their existing combat checks. Entering combat cancels unissued slider writes and stops owned orbit/movement. Already applied graphics values are not intentionally reset. An issued transaction still performs its verification/failure handling; it is not declared successful merely to preserve a look. The addon cannot prevent WoW itself, a renderer, another addon, or an actual external CVar change from changing the image.

Camera's own keyboard handler may participate during combat, but it still respects text focus and native API rejection. If WoW rejects keyboard propagation, LumenShift disables that handler and leaves visible mouse controls, Capture and Exit available; it does not bypass the restriction. New native unit/appearance calls similarly retain identity/access checks. These limitations affect the relevant action rather than switching the entire addon into read-only mode.

## Implementation and saved data

- `Core/PortraitLibrary.lua` contains original organization of native identifiers, slot labels and equipment-location mappings. `Core/PortraitWardrobe.lua` reads native inventory/item/set data; `UI/PortraitLibrary.lua` provides pooled browser controls. The existing controller and backend own all model changes.
- ModelScene uses `SetSpellVisualKit(id, false)` and zero to clear. When a native getter exists, its selected-ID readback must match. This verifies the requested identifier, not visible pixels or asset availability. The reduced DressUpModel backend retains outfit and pose browsing but does not pretend to support ModelScene's replaceable-kit interface.
- Item previews use owned-model `UndressSlot`/`TryOn`, with the documented main/off-hand arguments and native result reasons. Wrong-race, non-equippable, pending data, exceptions and inaccessible results cannot replace a previously successful actor. Model appearance flags are applied before item overrides, with hidden slots and weapon state honored afterwards.
- **Schema 17 / portrait schema 2** adds per-actor variation, kit and outfit maps, an eight-entry outfit bank, and two camera/combat booleans. Older scene banks retain their values; only absent new fields receive defaults. No setup reset or automatic scene loading occurs. Invalid data remains preserved for diagnosis rather than replaced.
- Full supported scene/outfit/look/preset banks exceeded the previous copy budget in a reproduced test. The shared data-only copy limit rises from **4,096 to 8,192 visited nodes**, with the same depth limit of 12, 256-byte strings, finite numbers, no metatables/cycles/executable values, and explicit bank/slot limits. Oversized data still fails closed. SavedVariables is not immediately durable storage.
- Diagnostics add saved-outfit count and the combat options. Item names, outfit names, equipment-set names and unit identities are not exported. No new asset pack, library, CVar writer, model database or Narcissus code is bundled.

## Source evidence and limits

Primary API/client sources were accessed 2026-11-10 and are pinned to the researched Forever 70862 UI-source mirror. They establish declarations and client examples, not a new live rendering pass on the owner's installation.

- [Actor base API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorBaseDocumentation.lua): animation variation/speed/offset, TryOn item-link string and hand argument, spell-kit setter/getter. [Native party-pose UI](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_GlueXML/WoWLabs/GluePartyPoseUI.lua) explicitly clears owned actor kits with zero; this is a usage example, not proof every kit exists on Forever.
- [Actor dressing and local pause](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorDocumentation.lua), [DressUpModel](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPIDressUpModelDocumentation.lua), and [ItemTryOnReason](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/UIModelInfoSharedDocumentation.lua): success 0, wrong race 1, not equippable 2, pending data 3. No equipment-changing API is used.
- [Native item information/cache requests](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua), [container reads](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua), and [equipment-set reads](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/EquipmentManagerDocumentation.lua). Equipment sets are read, never activated or edited.
- The reference author's [animation identifiers](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/PhotoMode/AnimationCatalogue.lua) and [spell visual identifiers](https://github.com/Peterodox/Narcissus/blob/0a6d5985f6604fdb39190f284def6864f3622a8b/Narcissus/Modules/PhotoMode/SpellVisualCatalogue.lua) corroborate the selected native IDs. LumenShift uses a small independently organized selection with original controls/labels; it does not copy the reference implementation, artwork, thumbnails or complete database. Code/asset licensing stays as recorded in the repository.

Some models lack poses or variations; some kits may not exist/render on this client. Native API acceptance is not proof of a visible effect. Particle simulation may continue when a model's skeletal pose is paused; a compositing pair cannot promise identical particle frames. Outfit saves use base items, not exact transmog illusions/bonus variants or the entire game's appearance catalogue. Native model framing, racial/form differences, special-item compatibility, combat input/taint, frame cost and actual screenshots remain in-game acceptance. No previous Brightness success is relabelled as a pass for these new features.

## Validation

Final automated validation: **621/621 Lua 5.1 mock tests pass**, including 32 new portrait/combat regressions; **10/10 Python packaging tests pass**. Syntax checks cover **94 Lua files and four binding bodies**, and structural checks cover all **65 runtime Lua modules**. The full-bank storage, hidden-slot, keyboard-failure, browser-navigation and non-wearable-item cases are included. Historical combat-suspension tests now explicitly choose the off preferences; their interruption/restore assertions remain in place. Migration expectations advance to schema 17 rather than dropping old-version coverage.

Four off-client geometry previews were reviewed for Poses, Effects, Outfits and Combat options. These use approximate fonts/textures and validate layout only; they do not establish native model appearance, spell-kit rendering or in-game input behavior.

No game session, installed addon folder, WTF/SavedVariables file, real equipment or graphics setting was operated by development tools. Nothing was merged or published. The ZIP builder uses clean committed source, hashes its payload and compares two generated archives.

## Exact local test

1. Exit WoW. Extract the **beta.16 ZIP** and replace only the complete installed **LumenShift** folder. Keep SavedVariables. The path ends in `_forever_/Interface/AddOns/LumenShift/LumenShift.toc`, with Core, UI and Media beside it. No reset or new setup is needed.
2. Disable Narcissus for this standalone test. Open the LumenShift wheel → **Camera → Portrait Stage → Actors**. Choose Poses, try a category/search, Play/Pause and variations. Keep a screenshot of any pose that renders differently from its label.
3. Choose **Effects**, select a kit, replace it, then select **No effect**. Add another actor and check each kit is independent. Some models/kits may have no visible result; report that kit and model type without assuming it is supported merely because no error appeared.
4. Choose **Outfits → Items**, select a slot and preview an equipped/bag item. Try **Sets**, then **Saved** to save and reapply a combination. Check real gear is unchanged. Retarget while a target actor is staged: outfit edits should preserve that actor and ask for its original unit to be selected again. If item data is uncached, use Refresh and deliberately try again.
5. In **Look**, choose a noticeable filter. Under **Capture → Combat behavior**, leave both options on and, during ordinary gameplay combat, verify the look/stage stay present. Use H or Hide controls, capture, then Escape/Exit. Do not expect native graphics sliders, names or orbit to execute while in combat. If native keyboard input is unavailable, use the visible mouse controls.
6. Try the alternatives: turn off Stay in Photo Studio but leave Keep filters on; combat should show the game HUD and preserve the look. Turning Keep filters off should temporarily hide cosmetics without changing saved values. After combat, explicitly exit/restore any pending native changes; none should automatically reapply.
7. Reopen and save a scene with a pose/outfit/effect. After a normal reload, no stage should open itself; loading the saved scene should retain its settings. Inspect actual screenshot files, including a clean view without controls. Report any native visual/input issue; launcher-version reconfirmation is unnecessary.
