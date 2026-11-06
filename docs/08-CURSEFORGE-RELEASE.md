# CurseForge publication and release engineering

**Project:** LumenShift — World of Warcraft: Forever visual modes and advanced graphic settings.
**Target distributor:** CurseForge (intended, not yet submitted).
**Authorization:** Planning and documentation only. Do not create a CurseForge project, configure upload tokens/webhooks, upload files or announce releases without Arctic's approval.

## Authoritative publication references (checked 2026-11-06)
- CurseForge project creation/submission: https://support.curseforge.com/support/solutions/articles/9000197241
- CurseForge author project guide: https://support.curseforge.com/support/solutions/articles/9000199552
- CurseForge moderation policies (updated 2026-10-22): https://support.curseforge.com/support/solutions/articles/9000197279
- CurseForge multi-TOC/flavor tagging: https://support.curseforge.com/support/solutions/articles/9000209856
- CurseForge automatic packaging/.pkgmeta: https://support.curseforge.com/support/solutions/articles/9000197281
- CurseForge upload API: https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api
- CurseForge Forever live migration announcement: https://blog.curseforge.com/wow-forever-migrate-addons-beta-to-live/
- Blizzard UI Add-On Development Policy, posted by Blizzard staff: https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642/1

**Important evidence caveat:** CurseForge's official Forever blog confirms live _forever_ folder and game version support context, but specific *submission form* identifiers and exact current "Forever" flavor options MUST be validated in the live author dashboard. Third-party October/November 2026 guides report Forever 1.60.1 and interface 16001; never hardcode the identifier without confirming the installed game build.

## Blizzard policy requirements
- Addon free to download and use; no premium functionality or mandatory paid services.
- Lua/source remains publicly viewable and unobfuscated, including distributed files.
- No advertisements or in-game requests for donations.
- No unauthorized executable hooks, injections or game automation; follow current Blizzard EULA and add-on policy.
- No negative impact on gameplay/servers/other players; no abusive polling or performance-heavy on-frame loops.
- Third-party source and assets may only be copied under a suitable license with required attribution. Looking at an addon for inspiration is not permission to reuse it.

## CurseForge project metadata (draft, not published)
- **Name:** LumenShift. Verify name uniqueness in CurseForge's live project creation UI before registration. No ownership implied by an unclaimed name.
- **Owner/creator:** Northern Lights Labs (confirm actual CurseForge user identity; don't invent or claim a linked account).
- **Summary proposal:** Switch between immersive visual modes and accessible lighting presets in World of Warcraft: Forever.
- **Categories:** Select an available and relevant World of Warcraft addon category in the author form; don't invent a category ID.
- **Description:** Explain what each mode does, limitations (no shader injection), controls, compatibility, screenshots, CVar persistence, restoration and uninstall instructions.
- **Logo:** original high-quality square PNG, at least 400x400 per author guidance. No Blizzard game logo or unlicensed images.
- **Screenshots:** authentic game captures of tested features; do not pass concept renders off as real game screenshots.
- **License:** MUST be decided and applied consistently to GitHub repository and CurseForge project. **Not selected.** Public repository is not itself an open-source license.
- **Issues:** link to https://github.com/ProfessorMinty/LumenShift/issues after publication.
- **Source:** https://github.com/ProfessorMinty/LumenShift
- **Dependencies:** none unless introduced and confirmed, then declare correctly.

## Build/package acceptance rules
1. Packaging starts only after implementation is authorized. Proposed canonical addon directory is **LumenShift/** and must contain the matching LumenShift.toc, or a verified Forever flavor-specific TOC, plus all referenced Lua/XML, textures and audio.
2. TOC title, version, author, notes, interface number, SavedVariables and file load order must be correct for the target **live** WoW build. No stale beta-only TOC assumptions.
3. The downloadable ZIP must contain **one top-level LumenShift folder**, not the repo's documentation, local paths, VCS history, screenshots, or extra nested wrappers.
4. The ZIP must include all runtime assets and licenses/attributions required to legally distribute those assets, and no unlicensed or obfuscated third-party code.
5. Build scripts must be repeatable and deterministic: from a recorded Git commit/tag, produce the same list of expected runtime files. Verify ZIP structure before upload, including exact paths/case sensitivity.
6. No personal Config.wtf, WTF, cache, logs, account information, API keys, CurseForge token or local system paths in any artifact.
7. Automated checks should validate Lua syntax using a parser appropriate to the game Lua dialect, TOC content and referenced files, archive structure, manifest/version alignment, assets and legal attribution. Mock tests are not equal to live game tests.
8. Choose between manual ZIP creation and CurseForge's packaging/webhook workflow only after comparing options. Their packaging system supports **.pkgmeta** for naming, exclusions, moving files, externals, changelog/license inclusion. Do not add placeholder .pkgmeta that could accidentally package documentation before release architecture exists.
9. If automating publication, credentials MUST be stored in protected secrets, never in source code, comments, issue bodies or logs; separate validation/build from publishing and require an explicit human-controlled release gate.
10. Don't automatically publish on every push to main. A release needs a reviewed tag, changelog, manual approval and file-by-file compatibility check.
11. Multi-flavor builds are not a launch requirement. Do not tag Retail/Classic as compatible unless tested. CurseForge says TOC base names must match the addon directory, and supported flavors must be tagged correctly.

## Release channels and lifecycle
- Internal dev: local testing; never upload unfinished/untested code to CurseForge.
- Alpha: exploratory client-tested releases for opted-in testers only when approved; alpha is not the normal end-user app default.
- Beta: broader user acceptance when major bugs are controlled; still opt-in.
- Release: stable, verified target build, changelog, meaningful screenshots, setup/restore instructions, license, correct file version tags. CurseForge requires at least one **Release** file to sync in the app by default.
- Versioning: propose SemVer-style tags (v0.x.y-alpha, v0.x.y-beta, v1.0.0), but verify actual packaging tag behavior. Note source tags and CurseForge uploaded display names need not be identical.
- Maintain a simple CHANGELOG.md once code development begins; no fabricated launch date.

## Pre-publication review checklist
- [ ] Unique project name and visual identity confirmed
- [ ] User approves public description, logo and branding
- [ ] Author account/ownership verified by user
- [ ] License decided, added to repository and consistent with third-party license obligations
- [ ] Blizzard addon policy and CurseForge moderation rules current and checked
- [ ] Correct Forever version/flavor and interface number confirmed in live game and CurseForge author dashboard
- [ ] Clean fresh-game installation from release ZIP succeeds
- [ ] No Lua errors with only LumenShift enabled, then common addons installed
- [ ] Night Vision, Cinema, Lantern, Clarity etc. operate honestly within API restrictions
- [ ] Baseline capture/restore and persistence/readback tested (including unusual crashes/uninstall documentation)
- [ ] Keybinds, radial wheel, full settings, sounds, tint and accessibility tested
- [ ] UI compatibility and different display resolutions tested
- [ ] No unsafe CVar writes, severe FPS regressions or critical UI obstructions
- [ ] Privacy, source visibility, licenses and asset provenance reviewed
- [ ] Human approval of release notes and distribution ZIP
- [ ] CurseForge project created and file submitted manually or via explicitly approved secure automation
- [ ] Moderation result checked; do not claim published before approval

## Critical installation support and uninstall reality
CurseForge's own live migration guidance identifies World of Warcraft/_forever_/Interface/AddOns. Keep source checkout outside the game. Provide a fresh-install guide and explain how to verify correct folder nesting and game version. Graphics CVars can persist independently of addon installation; warn users to choose Restore My Settings **before disabling/uninstalling**, and do not promise a deleted addon can restore settings after removal.

## Decision queue for Arctic
1. Confirm eventual public CurseForge project display name and author credit.
2. Select license compatible with distributing visible Lua and any third-party assets.
3. Choose initial Forever-only support vs future tested flavors.
4. Decide whether GitHub releases should mirror CurseForge releases.
5. Approve a distribution/publishing workflow after prototype has passed client QA.
