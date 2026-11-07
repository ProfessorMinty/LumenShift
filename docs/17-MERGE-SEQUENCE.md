# Review and merge sequence — owner approval required

**Checked:** 2026-11-06. Origin is `https://github.com/ProfessorMinty/LumenShift.git`. No merges, retargets or `main` mutations were performed while preparing Phase 01B. Issue #1 remains open.

## Reviewed bases

| PR | Current base and exact reviewed head | Readiness evidence |
|---|---|---|
| [#2: Phase 00 research](https://github.com/ProfessorMinty/LumenShift/pull/2) | `main` → `docs/phase-00-research` at `99e86236683764603d86b579e56b7dfb76a20287` | Open, unmerged, 10 Markdown files, +702/−189; research/findings/client-validation/release requirements, no runtime implementation. No submitted review/comments returned. |
| [#3: Phase 01A foundation](https://github.com/ProfessorMinty/LumenShift/pull/3) | `docs/phase-00-research` → `feat/phase-01a-foundation` at `ddf04c91c72dec80468c9a41cf07cd0d7dad7407` | Open, unmerged, 26 files, +1856/−10; source, tests and documentation. Both Aurora recommendations implemented in `60ce4e3`; owner smoke evidence in `ddf04c9`. Existing complete 38-test Lua 5.1 suite rerun successfully before Phase 01B changes. |

Aurora's [source review](https://github.com/ProfessorMinty/LumenShift/pull/3#pullrequestreview-5806213704) is `COMMENTED`, not `APPROVED`, and explicitly excludes live/release sign-off. The [fix report](https://github.com/ProfessorMinty/LumenShift/pull/3#issuecomment-6694603947) and [native smoke report](https://github.com/ProfessorMinty/LumenShift/pull/3#issuecomment-6695906338) were read. The latter establishes diagnostic loading and getters, not native writing/restoration. Research documents remain intact on the Phase 01B branch.

GitHub reported both PRs mergeable and no auto-merge configuration. No requested reviewers were listed. Each checked head's check-runs endpoint returned zero runs; local test results are not GitHub CI checks. The integration received **HTTP 403, Resource not accessible by integration**, when reading `main` branch protection. Thus required-review/status/ruleset requirements remain **unknown**, not absent. A maintainer must inspect the actual merge requirements in GitHub before approving a merge; mergeability alone is insufficient.

## Sequence to execute only after approval

1. Review PR #2's exact head/diff and GitHub's actual approval/check requirements. Obtain explicit owner approval for that merge; satisfy required reviews/checks. Recheck the head has not moved, then merge #2. Do not delete its branch while dependent PRs still target it.
2. After #2 is merged, retarget #3 to `main`. Refresh its diff: research should no longer appear as newly introduced work, and the Phase 01A source/review fixes/smoke documentation must remain. If the merge strategy changes ancestry, inspect carefully instead of assuming GitHub recalculates the intended diff. Preserve prior commits/unrelated changes.
3. Rerun the complete Phase 01A Lua 5.1 suite and structural checks on the actual updated PR #3 head/base combination, resolve any real conflicts, and satisfy current review requirements. Obtain explicit owner approval for #3's merge. **This updated-base check is pending because #2 has not been merged.** The pre-implementation 38/38 result is not presented as a retargeted result.
4. Review Phase 01B separately. Its branch starts at PR #3's exact head and its PR initially targets `feat/phase-01a-foundation`, so only Phase 01B changes appear. After an approved #3 merge, retarget Phase 01B to `main`, inspect the new diff and rerun its complete suite before considering a separately approved merge.
5. Keep Issue #1 open through the remaining native write/restoration/persistence and release gates. Neither a source merge nor a mock pass grants live-test or CurseForge publishing permission.

Implementation review can proceed on the stacked branches without prematurely merging research or foundation changes. No owner approval is inferred from the Phase 01B implementation assignment.
