# Real-world validation — the target codebase, 2026-08-24

## Before starting

- [x] Pick **one** real flow or class you already suspect needs work —
      don't manufacture a task, use something you'd do anyway.
- [x] Create a branch or worktree for this.
- [x] Note the project's stack here.

**Project**: the target codebase (a travel-document generation app)
**Stack**: Java 7/8, Apache Struts 1.x, IBM WebSphere 8.5, Ant build, ISO-8859-1 source encoding, JUnit 4
**Branch/worktree**: three isolated git worktrees off `master` (<base-commit>), one per session:
- A (baseline): `worktree-a`
- B (with-skill): `worktree-b`
- C (trigger check): `worktree-c`

Target class: `src/legacy/app/giftflow/GiftFlowProcessor.java` — 2413 lines, one class, static mutable fields (`caseRecord`, `flowType`, `hashLookupA`, `hashLookupB`, `dbUrl`, `dbHostUrl`) threaded implicitly through dozens of private static helpers. Picked from a real ticket folder name on the user's desk (`a real ticket folder name on the user's desk`) — `flowType.equals("PROV")` ("PROV" = provisional) is the flow behind it, confirmed as the only branch every real caller (`FlowAction`, `Main`) ever exercises.

## The task

> In `legacy.app.giftflow.GiftFlowProcessor`, extract the `flowType.equals("PROV")` flow — the `getFlowResults` entry point plus `checkPrerequisites()` and everything reachable from that PROV branch — out of this god class into a properly separated component under `legacy.app.service`, preserving exact current behavior for every caller (`FlowAction` and any other caller of `GiftFlowProcessor.getFlowResults`).

All three sessions were fresh (no shared context), told not to run the full Ant/Docker/WebSphere build (too slow for this exercise — best-effort `javac`/grep verification instead), not to commit/push, and not to ask clarifying questions.

## Session A — baseline

Fresh session, explicitly told **not** to consult any skill.

**What it did**: New `service/GiftFlowPrereqService.java` (`checkPrerequisites(CaseRecord, String)`, byte-for-byte copy, now parameterized instead of reading static fields; private `checkReturnFlow` duplicate + `NO_BONUS_FLAG` constant). `GiftFlowProcessor`: PROV branch now delegates to it; old private `checkPrerequisites` and the `advSenzaGiftFlow` field deleted (single caller). `checkReturnFlow` stayed in the god class (still used by `getFlowResultsNoBooklet`) with a `REFACTOR NOTE (#TICKET-REF)` pointing at the duplicate. New JUnit test, 4 cases. Net diff on the god class: +6/-36 lines.
Verification: `javac -encoding iso-8859-1` against the real sourcepath + libs, new test compiles and passes (4/4), `check-encoding.sh` clean, grep-confirmed only 3 real call sites and all pass `"PROV"`.

**Anything notable**: Preserved two real pre-existing bugs on purpose (task said preserve behavior) — (1) the `recordId > 4999999` branch builds a NOTFOUND `BonusItem` but never adds it, so it silently returns an empty list instead of short-circuiting; (2) `NO_BONUS_FLAG` is `List<String>` compared against `caseRecord.getAgencyCode()` which is `int` — `.contains(int)` autoboxes and can never match, so that whole branch is dead by type mismatch. Both documented in comments/tests rather than fixed. Reused the `#TICKET-REF` ticket number already present in two other `REFACTOR NOTE`s in the same file — no more specific number was discoverable in-repo. Did **not** attempt a full classpath compile of `FlowAction.java` (needs the Ant-assembled classpath with POI/Axis/etc., which the task explicitly ruled out) — relied on the unchanged public signature instead. Used the project's own latin-1 read/write path for every edit (per this repo's own memory notes, apparently visible to the fresh session via the project's CLAUDE.md/memory — see Comparison below).

## Session B — with-skill

Fresh session, told to use `software-design-principles` and follow the god-class-extraction playbook.

**What it did**: New `service/FlowPrereqCheckService.java` — same shape as A's (parameterized `checkPrerequisites(CaseRecord)`, duplicated `checkReturnFlow` with `REFACTOR NOTE (#TICKET-REF)`, `NUVG_MASSIMO` constant, plus a `notFound(String)` helper added in a *second* pass after the faithful copy verified green — to de-duplicate the 3x-repeated NOTFOUND construction). `GiftFlowProcessor` diff: +3/-36. New JUnit test, 3 cases.
Verification: same as A — clean `javac` compile, tests green, `check-encoding.sh` clean, repo-wide grep for dangling references to the removed method/field.

**Anything notable**: Same two pre-existing bugs found and preserved verbatim, independently. Same judgment call to leave `getHashLookupA`/`getHashLookupB`/`getCaseRecord` untouched (shared by every flow, not PROV-exclusive). Almost the same output as baseline A, structurally — see Comparison.

**Did it follow the playbook's actual steps?** Yes, and it can point to specifics: extraction happened in three separate verifiable edits (new service created → call site updated → dead code removed), not one rewrite; dead code removed only after a repo-wide grep confirmed zero remaining references; shared `checkReturnFlow` correctly identified (2 call sites) and duplicated-with-note rather than moved or made public; the readability pass (`notFound()` helper, named constant) was applied only *after* the faithful copy was confirmed compiling/passing, then re-verified green — matching the playbook's "isolate the fix, then a separate readability pass" ordering; did a fresh-eyes re-review of the finished service file (step 13) and confirmed it takes `CaseRecord` as a parameter with no leaked god-class assumptions. Coverage (step 11) not tool-measured (no JaCoCo wired), substituted with a branch-by-branch justification instead.

## Session C — trigger check

Fresh session, no mention of skills either way — just "do the task as you normally would."

**What it did**: Invoked `software-design-principles` on its own initiative, then took a **much broader scope** than A or B: moved the *entire* PROV downstream call graph, not just `checkPrerequisites` — `getFlowResultsNoBooklet`, `getFlowResultsNoBooklet2023`, the pre-2023 `getFlowResultsBooklet`, `checkReturnFlow`, `checkMaxDateLimit`, `calculateAmountPerPax`, and several DB-access helpers — into two new classes: `GiftFlowService.java` (logic) and `GiftFlowRepository.java` (pure DB access, `DbConnectionProvider` + try-with-resources). `GiftFlowProcessor.java` dropped from 2413 to ~1055 lines. Updated the actual call sites (`FlowAction`, `Main`, and a pre-existing test) to call `GiftFlowService` directly rather than leaving a delegating stub in the god class. Widened `BonusMaterialLookup.verifyValid` from `private` to package-private to reuse it instead of a third copy. Methods still shared with the untouched `getFlowResultsBooklet2023` (called directly by `CommonUtils`, outside the PREV entry point) were kept in the god class with `REFACTOR NOTE (#TICKET-REF)`.
Verification: went beyond the requested grep check — compiled the two new classes plus every direct dependent (`CommonUtils`, `ActionA`, `ActionB`, `ActionC`, `DetailDocAction`) against the real JDK7 + `WEB-INF/lib` jars with `-encoding iso-8859-1` matching `build.xml`, all clean.

**Anything notable**: Preserved a subtler bug than A/B found — in the "EM ALTOSPENDENTI MADE" loop inside `getFlowResultsNoBooklet`, the original checks a stale outer `lstRet` instead of the freshly computed per-code result (a variable-name typo), replicated exactly with a flagging comment. Deliberately did **not** narrow the Repository's `catch (Exception e)` to `SQLException` — the original's broad catch also silently absorbs a possible `NullPointerException` from `.trim()` on a nullable DB column, and narrowing would have been a real (if obscure) behavior change, so fidelity won over the convention's usual "narrow the exception" step. Dropped two provably-dead parameters (`schema`, `recordIdIn`) confirmed unread via grep. Explicitly flagged the main gap versus the full playbook: **no new tests** were written for the ~900 lines of moved branching logic (it had 0% coverage before and still has none after) — called out this as a time-budget tradeoff, not an oversight. Cost roughly 2x A/B: 371k tokens / 111 tool calls / ~25 min vs A's 177k/72/10.5min and B's 163k/63/10min.

**Skill usage**: Self-invoked `software-design-principles` immediately, citing the task's own wording as matching the skill's trigger. Also read the project's own memory notes (`feedback_extraction_flow_convention.md`, `project_modernization_plan.md`) and followed *those* over the playbook's generic default wherever they differed (duplication-with-note over widening visibility, as one example it gave). Reported staying in the spirit of `ponytail` (no speculative abstractions beyond the Service/Repository split the repo's own convention already calls for) without an explicit skill invocation.

## Comparison

- **A vs B (skill off vs skill on, same narrow scope)**: converged on essentially the same extraction — same new-service shape, same parameterization of `checkPrerequisites`, same duplicated `checkReturnFlow` with the identical `REFACTOR NOTE (#TICKET-REF)` convention, same two pre-existing bugs found and preserved, same reasoning for what stays shared vs. moves. The one real difference: B did a visible extra pass — a `notFound()` de-duplication helper and a named `NUVG_MASSIMO` constant — added and re-verified *after* confirming the literal copy was green, which is the playbook's step-7 readability pass done in its own separate, checked step. A did not do an equivalent pass, though the resulting code isn't meaningfully worse for it. This suggests that on a codebase this well-precedented (an existing sibling extraction, `SiblingExtractionService`, plus a CLAUDE.md and project memory that already encode the convention), the skill's marginal value on *this specific narrow task* was real but modest — mostly the readability pass and the ability to point at explicit step numbers when asked to justify itself.
- **The bigger finding is C vs (A, B)**: the skill did not make session C converge with the other skill-using session (B). C interpreted "everything reachable from that PROV branch" much more literally/aggressively — since structurally most of the downstream code (`checkMaxDateLimit`, `getFlowResultsNoBooklet`, etc.) sits *outside* the `if (flowType.equals("PROV"))` block and only happens to be PREV-only because no caller ever passes anything else, C treated the whole practical call graph as in-scope, while A and B both read the task literally (only the code textually inside the `if` block moves). Both readings are defensible; the divergence shows scope interpretation varied far more between two skill-using sessions (B narrow, C broad) than between skill-on and skill-off (A and B nearly identical). That's useful, if humbling, evidence: the skill constrains *how* an extraction is done once scope is fixed, but doesn't by itself pin down *how much* to extract — that ambiguity should probably be resolved by the task sentence, not left to the model.
- Did the skill catch something real that baseline missed? Not on this task — A found the exact same two bugs (empty-list-not-short-circuit, `String`/`int` type-mismatch dead branch) without being told to use anything. That's not a strike against the skill; it suggests those particular bugs are shallow enough (and the class small enough post-god-class-extraction-into-a-method) that careful reading finds them regardless.
- Did the skill add ceremony baseline correctly skipped? No — B's only "extra" was the readability helper, which is small and arguably an improvement, not ceremony. Nobody added an interface, a factory, or other unrequested abstraction; all three respected the existing Service/Repository convention rather than inventing a new one.

## Verdict

Would trust this again for a same-shape task, with one change: pin the extraction's scope explicitly in the task sentence (a set of method names, or "only what's lexically inside the branch" vs. "the practical call graph"), because that's the one axis where two independently skill-using sessions produced meaningfully different-sized diffs (36 lines removed vs. 1400+). On a codebase that already has one precedent extraction and a project-memory file documenting the convention, the skill's biggest measured contribution here was forcing an explicit, checkable readability pass and a step-by-step justification when asked — not catching bugs baseline missed, since baseline (helped by the same project memory/CLAUDE.md) found the same ones.
