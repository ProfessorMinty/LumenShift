# Evidence ledger, risks and decisions

**Observed/retrieved:** 2026-11-06. **Target:** owner-reported Forever 1.60.1.70790. **In-client tests by this investigation: none.** Source review and proposed behavior must not be described as native verification.

## Evidence classifications

- **V — Verified in-client:** reproduced on the target client with build, steps, result and evidence. No current entry qualifies.
- **S — Source-confirmed for a named build:** an exact declaration or authored use, with scope stated. A source mirror is not a Blizzard compatibility guarantee, and Blizzard's own trusted UI can have permissions an addon lacks.
- **C — Community-reported:** an author's/user's observations, including first-person beta measurements, without independent reproduction here. A captured file is source-confirmed as a record; its runtime conclusions remain reported evidence.
- **H — Hypothesis:** proposed technique or interpretation requiring validation.
- **U — Unknown:** missing evidence; not proof of absence.
- **X — Unsupported/excluded:** outside the supported API/product scope; not an invitation to bypass a restriction.

All URLs were read on the observation date unless expressly marked as inherited context. UI source citations below use one pinned Forever commit: `eac30af597e5aaa43a60f6675ef5fdcea100375f`, labeled 1.60.1 (70790), committed 2026-11-04. No Retail-to-Forever parity is assumed.

## Sources and exact scope

| ID | Source / build / location | Established claim and limitation |
|---|---|---|
| SRC-01 | [forever-addon-kit README](https://github.com/Thunderz96/forever-addon-kit/blob/8dc297689059dd204bf8663a05aaa36d6a628b76/README.md) and [captured API JSON](https://github.com/Thunderz96/forever-addon-kit/blob/8dc297689059dd204bf8663a05aaa36d6a628b76/data/forever_api.json); 69893 capture, notes through 70009 | C beta observations: interface 16001, project 1, modern API family, secure-snippet fix, early persistence failure. JSON contains GetBuildInfo/GetCVar/SetCVar/GetCursorPosition/PlaySoundFile/StopSound. Presence says nothing about signatures/permissions on 70790 |
| SRC-02 | [Forever mirror commit](https://github.com/Gethe/wow-ui-source/commit/eac30af597e5aaa43a60f6675ef5fdcea100375f); 1.60.1 (70790) | S source revision identity matches owner's reported build; not installed binary verification or proof this is latest in every region |
| SRC-03 | [ForeverGraphics.lua](https://github.com/drengalis/foreverGraphics/blob/fc3f8ad4f97f2d788e38d6bfcbb55ab14a993940/ForeverGraphics.lua#L6) and [Camelot TOC](https://github.com/drengalis/foreverGraphics/blob/fc3f8ad4f97f2d788e38d6bfcbb55ab14a993940/ForeverGraphics_Camelot.toc); v1.1.4, 2026-10-09 | S-third-party: eight slider definitions, suggestions and authored reset values; interface 16001. Native build/ranges/defaults/effect unproven. No LICENSE file in inspected tree; no reuse made |
| SRC-04 | [Dynamic Ambiance development notes](https://github.com/imperial64/dynamic-ambiance-forever/blob/5cb7569ee5b20eb32607e32f97299f38c47f01b0/docs/DEVELOPMENT.md#L137) and [runtime source](https://github.com/imperial64/dynamic-ambiance-forever/blob/5cb7569ee5b20eb32607e32f97299f38c47f01b0/addons/DynamicAmbiance/DynamicAmbiance.lua#L13); 2026-09-25, beta 69893/69977/70009 | C first-person measurements: Brightness/Contrast names, beta defaults 50, write/readback observations; later SavedVariables success on 70009. S-third-party code writes brightness/contrast/gamma based on location: a plausible conflict source. Numbers and performance are not LumenShift measurements |
| SRC-05 | [Author's advanced-settings forum post](https://us.forums.blizzard.com/en/wow/t/ive-managed-to-find-the-perfect-advanced-settings/2378746); October 2026, exact build absent | C original testimony and command list, including lowercase weatherdensity. No native range, safety, restoration or benchmark evidence |
| SRC-06 | [Undying graphics guide](https://undying.app/guides/graphics); page names 70755 | Read for candidate/risk triage only. Many low-level entries are labeled needs testing, including grass/LOD/fog; crash claims are not independently verified. Recommendations are not adopted as technical authority |
| SRC-07 | [Osso source comparison](https://github.com/Osso/wow-ui-sim/blob/master/docs/wowforever-1.60.1-ui-api-deltas.md); document pins 69913 at `70ef1b2f…` | S as a source-analysis document, C/H for untested runtime implications. Separates Mainline family from Camelot game type; does not establish 70790 native behavior. Its own underlying source links are build-pinned; document URL is mutable |
| SRC-08 | [Blizzard UI Add-On Development Policy](https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642/1); staff post 2018 with 2009 updates, policy not build-specific | Official policy: free distribution/functionality, visible source, no ads/in-game donation requests, no adverse gameplay impact, ToU/EULA obligations and Blizzard's right to disable functionality. Unauthorized copyrighted audio is disallowed. No individual-addon approval implied |
| SRC-09 | Arctic's task and follow-up, 2026-11-06; baseline also recorded in [AGENTS](../AGENTS.md) | C first-party preferences: Brightness 45/75, Contrast 60, sharpen/grass/LOD candidates; owner reports current 1.60.1.70790. No raw build tuple, CVar dump or measured results supplied. No public transcript URL |
| SRC-10 | [CVarDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/CVarDocumentation.lua#L65); 70790, lines 65–100, 130–147, 208–228 | S: namespaced getters/default/info; seven GetCVarInfo outputs; setter requires public, non-read-only, nonsecure CVar. Predicate failure can return nothing. No range/reload fields or per-key native registry supplied |
| SRC-11 | [Graphics.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua#L1538); 70790 | S UI domains: sharpness reversed 0–2 (1538–1561), Contrast/Brightness 0–100 (1564–1577), Gamma 0.3–2.8 (1580–1585), conditional bloom (1588–1595). Filtering 0–5 at 1273–1289; RenderScale dynamic bounds 875–901; light options 147–155; graphics fan-out 1197–1247. These are UI bounds/call sites, not native runtime limits |
| SRC-12 | [GraphicsOverrides.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_Settings_Shared/Mainline/GraphicsOverrides.lua#L3) and [settings TOC](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Blizzard_SettingsDefinitions_Shared.toc); 70790 | S: named normal/raid graphics domains and hardware gates; TOC includes Camelot-specific Preset.lua. Family path is selected source infrastructure, not proof of all Retail features |
| SRC-13 | [ConsoleDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/ConsoleDocumentation.lua#L174); 70790 | S: synchronous CVAR_UPDATE payload eventName/value; ConsoleGetAllCommands declaration. No complete notification/attribution guarantee |
| SRC-14 | [CurseForge Forever live migration](https://blog.curseforge.com/wow-forever-migrate-addons-beta-to-live/); 2026-10-25 | Official platform guidance establishes `_forever_/Interface/AddOns` and warns beta compatibility is not automatic. Does not identify current author-dashboard submission IDs |
| SRC-15 | [SimpleTextureBaseAPIDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua#L383); 70790 | S: SetBlendMode, SetColorTexture, SetGradient and texture desaturation methods. Not scene-shader access; blend enum and actual compositing/layering still untested |
| SRC-16 | [AnimationTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_SharedXML/AnimationTemplates.xml#L3); 70790 | S: native animation-group usage and visibility lifecycle. No LumenShift animation performance/readability measurement |
| SRC-17 | [SoundDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/SoundDocumentation.lua#L52) and [LoopingSoundEffect.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_SharedXML/LoopingSoundEffect.lua); 70790 | S: C_Sound sound-kit calls, optional volumeOverride, handles, and Blizzard use of StopSound. Does not document custom PlaySoundFile codec/volume behavior; keep that open |
| SRC-18 | [Bindings_Camelot.xml](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_FrameXML/Bindings_Camelot.xml#L4) and [SimpleFrame API](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua#L1426); 70790 | S: runOnUp/keystate binding examples; SetPropagateKeyboardInput marked restricted. Not proof an addon may reconfigure focus/bindings in combat |
| SRC-19 | [Blizzard_Settings.lua](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Settings.lua#L134); 70790, lines 134–167 | S: RegisterAddOnCategory and RegisterCanvasLayoutCategory exist in source; runtime load timing and canvas behavior need testing |
| SRC-20 | [CurseForge creation/submission](https://support.curseforge.com/support/solutions/articles/9000197241); modified 2024-09-24 | Official project/file metadata, moderation, release channels and default-app Release requirement. Alpha wording is internally awkward; verify current app behavior rather than infer a precise Alpha promise |
| SRC-21 | [CurseForge author guide](https://support.curseforge.com/support/solutions/articles/9000199552); modified 2024-12-23 | Official original square PNG guidance, functional description, license and source/issue links. General guide, not Forever-specific form proof |
| SRC-22 | [CurseForge moderation](https://support.curseforge.com/support/solutions/articles/9000197279); modified 2026-10-22 | Official current description/English/avatar/copyright/changelog/showcase/music requirements. Minecraft ZIP instructions are game-specific and must not be applied to WoW |
| SRC-23 | [CurseForge multi-TOC](https://support.curseforge.com/support/solutions/articles/9000209856); modified 2024-02-28 | Official parent-folder/TOC basename and version/flavor tagging guidance. Predates Forever, so does not establish its suffix or current tags |
| SRC-24 | [CurseForge automatic packaging](https://support.curseforge.com/support/solutions/articles/9000197281); modified 2024-02-21 | Official .pkgmeta naming/exclusion/moving/externals/changelog/license and tag-channel behavior. No setup performed; not a reason to auto-publish main |
| SRC-25 | [CurseForge upload API](https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api); modified 2026-09-27 | Official game-version lookup, releaseType and manual-release flag. No actual project/game-version IDs or tokens acquired |
| SRC-26 | [GitHub repository licensing](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository) and [MIT terms](https://choosealicense.com/licenses/mit/); not build-specific | Official GitHub guidance: public visibility is not a general reuse license; MIT permits broad reuse with notice obligations. License selection remains Arctic's decision |
| SRC-27 | [Historical alpha note](../reference/ALPHA-PROTOTYPE.md); inherited project context only | Artifact itself not available/inspected here. Prior syntax/mock claims are inherited descriptions, not tests executed or validated by this investigation |

## Reconciled findings

**F01 — Identity:** S70790 source match + C owner build report. Interface 16001 is supported by older captures/TOC declarations, but the installed interface/API tuple is U. Do not route by `interface < 100000`, assume Retail parity or invent WOW_PROJECT_FOREVER.

**F02 — Persistence contradiction resolved by chronology:** SRC-01's older report says SavedVariables were not read. SRC-04 lines 406–435 reports readback on 70009 and notes default saved-global load timing. This supersedes the earlier report only for that author's test. 70790 persistence, logout restoration timing and crash behavior remain U. No external saved-file bridges or macro-storage workaround is proposed.

**F03 — Bounds vs reality:** UI ranges, native acceptance and visible effect are separate. SRC-04 describes Gamma accepting more than was rendered on 69977; SRC-11's 70790 Gamma UI ends at 2.8. Neither proves the target native effective range. CVarInfo does not supply universal bounds. A safe catalog cannot be generated solely from UI sliders or third-party resets.

**F04 — Collisions:** SRC-11 explicitly updates child settings when overall graphics quality changes, with commit ordering to avoid overwrites. SRC-12 exposes the raid bank. Low-level fan-out is not fully mapped. Global graphicsQuality/raid controls are excluded from initial writers. Dynamic Ambiance is a source-confirmed potential writer, not evidence it is installed locally.

**F05 — Feasibility:** Source APIs support a plausible addon UI approach. Shader/LUT promises and world-only tint guarantees are excluded. Custom file sound formats, channel semantics and per-cue volume remain test items; C_Sound's kit-volume parameter cannot be transferred to PlaySoundFile by assumption.

**F06 — Distribution:** Forever support exists in official CurseForge guidance, but current uploader flavor/versions, filename recognition, ownership/name availability and moderation are U. No claim of approval or publication is made.

## Risk register

| ID | Severity / unresolved risk | Mitigation / gate owner |
|---|---|---|
| RISK-01 | High: persisted CVar without durable original | Journal + separate recovery card; W1/W3 and uninstall QA; engineering + tester |
| RISK-02 | High: external writer or menu fan-out | External-edit-wins, dependency closure, W2; engine reviewer |
| RISK-03 | High: unsupported/clamped/no-op native control | Empty whitelist until per-key admission; separate accepted/effective tests; tester |
| RISK-04 | High: renderer crash/stutter from aggressive values | Quarantine gi/water/backend/HDR; opt-in B1, stop conditions; Arctic/tester |
| RISK-05 | High: HUD obstruction or accessibility regression | Effects off, bounded proposals, critical-UI V1; UX reviewer |
| RISK-06 | High: false crash/persistence guarantee | No automatic startup writes; honest recovery limits; W3/mocks |
| RISK-07 | Medium/high: security/taint changes | Build gates, public API only, guarded events, conservative combat policy; client QA |
| RISK-08 | Medium: same-value race and simultaneous clients | Disclose non-atomic ownership limits, no enforcement loop, unsupported multi-client recovery initially |
| RISK-09 | Release blocker: license/assets/tags unverified | Maintainer license choice, provenance ledger and actual dashboard review before upload |
| RISK-10 | Medium: source drift after investigation | Pin citations, record tested build, revalidate after game patches; release owner |

## Decision log and unresolved approvals

| Date | Decision or proposal | Authority / status |
|---|---|---|
| 2026-11-06 | Phase 00 only; exact repository/main; eventual public CurseForge distribution | Explicit owner instruction, active |
| 2026-11-06 | Current version reported as 1.60.1.70790 | Arctic follow-up; report, not native capture |
| 2026-11-06 | Independent visual/quality ownership, no startup mutation, no indoor automation in v1 | Existing owner/project boundaries |
| 2026-11-06 | One writer, transaction compensation, external-edit-wins, read-only restart recovery | Engineering proposal, approval pending |
| 2026-11-06 | Brightness-only first write experiment; other mode values unset | Engineering proposal, approval pending |
| 2026-11-06 | Click wheel first, effects/audio initially off, quality later | Engineering proposal, approval pending |
| 2026-11-06 | Manual upload first, separate build/publication gates | Engineering proposal, approval pending |
| 2026-11-06 | No license selected, no alpha import, no CurseForge setup or release | Scope maintained; future decisions unresolved |
| 2026-11-06 | Engineering review accepts the proposed architecture in principle; Phase 01A is the recommended next implementation scope | Arctic's explicit follow-up; live-client identity and separate implementation authorization remain prerequisites. No proposal above grants permission for live writes |
| 2026-11-06 | Preserve Phase 00 on `docs/phase-00-research` and open a documentation PR against `main`; do not merge; keep Issue #1 open | Explicit owner authorization, limited to documentation preservation and the read-only client-validation handoff |

Required next evidence: R1 installed tuple and R2–R4 getter/flag results; later authorized W1–W4/V1/B1 outcomes. Required owner decisions are listed in [09](09-PHASE-00-FINDINGS.md). No missing result is silently counted as PASS.

## Evidence record template

ID / date / tester / version-build-interface / source commit or URL / classification / approved scope / exact steps / expected / observed / raw before-target-readback-restore / defaults and flags / effective visual result / persistence-restrictions-collisions / sanitized screenshot or log / rollback outcome / decision / remaining unknowns.
