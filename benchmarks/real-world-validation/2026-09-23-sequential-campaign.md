# Real-world validation — sequential campaign (5 rounds), 2026-09-23

First run of
[`SEQUENTIAL-CAMPAIGN-INSTRUCTIONS.md`](SEQUENTIAL-CAMPAIGN-INSTRUCTIONS.md):
5 extractions on the **same** real codebase, in sequence. Each round's
with-skill result was reviewed and merged before the next round
started. Rounds 1, 3 and 5 are checkpoints (A baseline / B with-skill /
C trigger check). Rounds 2 and 4 are with-skill only.

**Project**: the same legacy Struts app that rounds 1–2 targeted (a
travel-document generation app). It is not the modern rewrite used in
round 7.

**Stack**: Java 7, Struts 1.x, Ant, JUnit 4 + H2 in-memory DB, ISO-8859-1
sources with CRLF line endings. It differs from rounds 1–2 in one way
that matters: a full local `ant` build + test suite now runs in about 75 s
(539 tests at the campaign's base commit). Every arm could run the real
suite, and the orchestrator reran every suite from outside after each
arm finished.

**Where the merges went**: the target project's own remote allows no
commits from this environment. So "merged" means a **local-only
integration branch**. It was created off the project's current tip, has
no upstream, and was never pushed. Each round's worktrees branched off
that integration branch's current tip, verified with `git merge-base`
before each dispatch (5/5 rounds matched). Each B was reviewed, then
merged fast-forward into it. The integration branch ends with 8
commits: 5 flows extracted, ~830 lines removed from the god class,
+77 tests (539 → 616).

**Target**: one god class, the app's ~14.5k-line static utility class.
It was round 2's target too, but round 2 extracted a flow that was never
merged, and this campaign did not reuse it. Five distinct flows, each
with at least 2 real external callers, all found by `grep -a` before
writing any task sentence. They were picked so that later rounds
*depend* on earlier rounds' choices:

| Round | Type | Flow | External callers |
|---|---|---|---|
| 1 | Checkpoint | gift-section texts (5 methods, one of them a text lookup also used by 3 other flows still in the god class) | 5 files |
| 2 | Sequence | insurance-booklet lookup (6 methods; a sales-channel helper shared with round 1's callers stays behind) | 2 files |
| 3 | Checkpoint | consent (token check + consent status, 6 methods; shares an "initiatives of this booking" helper with round 5) | 4 files |
| 4 | Sequence | request access control (IP whitelist, password token, URL encrypt/decrypt) | 10 form classes |
| 5 | Checkpoint | honeymoon section (3 methods; calls round 1's text lookup *and* round 3's shared initiatives helper) | 4 files |

Every task sentence used the round-3 template: an exact method list, an
explicit "do NOT move" list of shared helpers, a mandatory `grep -a`
before deleting anything, and "update every real external caller".
Every arm also got the same environment note (ISO-8859-1 + CRLF, edit
through a latin-1-safe path, run `check-encoding.sh`).

## Preflight notes

- **Plugin sync**: `check-plugin-sync.sh` reported **stale** (installed
  `gitCommitSha` 59 commits behind), even after a `/plugin` marketplace
  update. The plugin's version number (1.5.0) hadn't changed, so the
  installed copy was never refreshed. I diffed the installed
  `skills/` and `hooks/` against the repo tip with `diff -rq
  --strip-trailing-cr`: **byte-identical**. So the with-skill arms read
  current content, and the campaign is valid. The script checks the SHA
  in the install record, not the files, so it reports stale even when
  the content matches. That's a small follow-up (see Verdict).
- **Every arm, baseline included, had the operator's auto-memory index
  in context.** Round 1's baseline reported it unprompted. That index
  holds a project-specific "flow extraction convention" note: flat
  service package, Service + package-private Repository, reuse the
  shared connection provider, and "keep the original, add a REFACTOR
  NOTE". The note came from earlier, skill-guided work on this same
  project. So "baseline" in this campaign means "no skill, but with the
  project's accumulated skill-derived conventions". That is the
  condition the campaign set out to measure, but it also means round 1
  was not a clean no-conventions starting point.
- The codebase was already partly mature before round 1. Its service
  package held ~30 previously extracted classes, and the god class
  itself carried `REFACTOR NOTE`s pointing new flows at a shared
  connection provider. Several arms quoted those notes as the thing
  that shaped their design.
- Two other always-on plugins were active in every arm (a
  terse-output style and a minimal-code style). One round-1 arm left
  that second plugin's marker comments in production code.

## Round 1 — checkpoint (gift-section texts)

**A — baseline**: Service + package-private Repository, reusing the
shared connection provider. It **duplicated** the shared text lookup:
it kept the original in the god class, unchanged, with a `REFACTOR
NOTE` naming its 3 remaining internal callers, and put a copy in the new
service. All 5 external callers were rewired. 10 new tests, 549/0. It
found a dead DB query (a looked-up value that is never used), the
missing `ORDER BY` in the text lookup, and kept both. It deliberately
kept the original brand-context parameter
so that "a null value still fails inside the method's own catch" (see
B). It named the memory note and three existing classes/notes as its
design sources.

**B — with-skill**: 3 commits: an as-is move plus rewiring, then
hardening, then trimming. It **moved** the shared text lookup and
rewired the god class's 3 internal callers to the new service too, so no
duplicate and no REFACTOR NOTE were needed. 24 tests. It ran them
against the as-is commit before any hardening (557 green), which made
them real characterization tests. Final count 563/0. It removed the dead
query and two unused parameters from public signatures, which touched
8 call sites. That was beyond the task, but behaviour-neutral. Steps
cited: 0–5, 7–10, a light 13. Steps 11–12 were skipped. In its own
words, "the existing codebase shaped the design more than the playbook
did".

**C — trigger check**: **self-invoked the skill**. Like B, it moved the
shared lookup and rewired the internal callers. 21 tests, 560/0. It
switched to bind parameters and typed dates, which carries a DB2-side
risk that was only verified on H2.

**External review, before merging B**: all 3 suites were rerun from
outside (549 / 563 / 560, 0 failures, encoding clean). B had two edge
regressions that A had explicitly guarded against:
- B's service reads `context.getSchema()` at the top, outside any
  catch. The original swallowed a null context. It can't happen in
  practice, because all 4 callers already dereference the context
  earlier.
- B narrowed the catch to `SQLException`, so a null column would now
  throw a `NullPointerException` out of `.trim()`.

B also bound a booking number with `setString` against a `DECIMAL`
column. That relies on DB2 casting it implicitly, and was only verified
on H2. A kept the concatenation. C kept it too, and said why. B merged
with those three notes.

## Round 2 — sequence only (insurance booklet)

One commit. It went straight to the hardened form, where round 1 used
3 commits. Service + Repository + two pure, DB-free helpers. It left
the shared sales-channel helper in the god class and **called back**
into it. That was an explicit decision against Step 5
(duplicate + REFACTOR NOTE): "a business rule would drift if copied".
12 tests, 575/0. It found a probable legacy bug: a fixed-width field is
trimmed before it is parsed, so a short last entry is silently dropped.
The orchestrator confirmed the bug is present in the original.

**Built on round 1?** Yes, explicitly: "I copied their pattern
directly" (round 1's three commits). That included round 1's
questionable part: "the practice number is now bound with `setString`
against DECIMAL columns, **the same way the gift refactor already does
it**". The campaign's convention propagated as a whole, flagged risk
included.

## Round 3 — checkpoint (consent)

All three arms converged on the same shape:
- Service + package-private Repository, with bind parameters.
- All 6 methods deleted from the god class.
- Shared public helpers called back into the god class, each with a
  one-line comment modelled word-for-word on round 2's.
- Tests on H2 through the same harness.

- **A**: 12 tests, 587/0. It "copied the pattern of the previous commit"
  (round 2). It explicitly named a pre-existing security issue in the
  original flow (details deliberately omitted from this public report),
  plus a second, smaller one it chose to leave as it was.
- **B**: 14 tests, 589/0. It covered one case A skipped (the
  direct-sales + initiative path). It was the only arm to put a
  `REFACTOR NOTE` on the private schema list it had to copy; A and C
  copied the same list without one. Its hardening happened to close the
  same security issue, but it reported **"No bug fix included"**. It
  never recognised the issue as a finding.
- **C**: **self-invoked the skill again**. It used the checklist but
  didn't open the playbook. 15 tests, 590/0. It named the same security
  issue explicitly. It also read the memory convention file directly, and
  deviated from it deliberately, because the task and the recent commits
  both delete the original.

**Methodology incident**: A, B and C all wrote build logs to the same
shared temp directory under the same filename. C's first suite log was
overwritten by a sibling's, and showed another arm's test names. C
noticed, and reran with a unique log; I confirmed its final numbers
from outside. From round 4 on, each arm got its own scratch directory
in the prompt. This is folded into the runbook fixes below.

**External review**: suites rerun (587 / 589 / 590, 0 failures). B's
logic was compared line by line with the original: it matches. The
change in exception type can't be seen by callers: both declare
`throws Exception`, and the action catches `Exception`. Merged.

## Round 4 — sequence only (request access control)

One commit. It split the flow into two services because "they change
for different reasons" (DB whitelist vs URL building). 14 tests. They
include a *real* `SQLException`, forced by a missing table, and runs
through the real form classes. 603/0. **Built on earlier rounds?**
"Mirrored [round 3's commit] nearly one-to-one", and copied the commit
message style too.

It found the most serious pre-existing issues of the campaign: one
functional bug that makes a code path always fail, and several
access-control weaknesses. The orchestrator confirmed all of them in
the original. Details are deliberately omitted from this public report
and were reported to the project owner. It kept all of them as they
were, as instructed, and left comments and tests that pin them.

## Round 5 — checkpoint (honeymoon section)

**Near-total convergence.** All three arms independently produced:
- the **same class name**;
- no Repository, because the flow has no SQL of its own;
- the 3 methods deleted;
- the **same 8 rewired call sites, at identical line numbers**;
- both shared helpers called back into the god class;
- round 1's extracted text lookup **reused** rather than re-read from
  the god class.

All three found the same case-sensitivity inconsistency in the
company-code check, and pinned it.

- **A**: 9 tests, 612/0. It mirrored round 1's service directly, and
  flagged a pre-existing weakness in the shared helper that stayed
  behind (B flagged it too). It was also the cheapest arm of the whole
  campaign (see table).
- **B**: two commits, as the playbook's Step 1 prescribes: service and
  tests *alongside* the old code, tests green against the old code
  (13/13), then rewire and delete. 616/0. The only arm to do Step 1 as
  a separate commit, like round 1's B. It said the biggest influence was
  round 3's commit, and that it "followed that precedent **instead of
  the playbook's step 5**".
- **C**: **did not invoke the skill.** In its words: "The branch's
  recent commits already set the pattern, so I followed those
  directly." 9 tests, 612/0. It also called the memory convention note
  "out of date for this branch".

**External review**: suites rerun (612 / 616 / 612, 0 failures). B's one
code change, `replaceAll` → `replace`, is safe: the replacement values
are fixed brand names and URLs with no `$` or `\`. Merged.

## Cost trend

Tokens / tool calls / wall time, as reported by each subagent run:

| Round | A (baseline) | B (with-skill) | C (trigger) | C invoked skill? |
|---|---|---|---|---|
| 1 | 119k / 24 / 381 s | 186k / 47 / 847 s | 150k / 33 / 604 s | yes |
| 2 | — | 105k / 25 / 420 s | — | — |
| 3 | 92k / 28 / 445 s | 115k / 25 / 473 s | 114k / 34 / 654 s | yes |
| 4 | — | 112k / 31 / 508 s | — | — |
| 5 | 81k / 17 / 312 s | 107k / 28 / 396 s | 91k / 20 / 332 s | **no** |

The targets differ in size, so this is a trend, not a measurement.
Every arm got cheaper as the codebase gained a template to copy.
B's premium over A fell from 1.56× tokens at round 1 to 1.25× at
round 3 and 1.32× at round 5. Its tool-call ratio went 2.0× → 0.9× →
1.6×, with no clean trend. B's cost dropped most between rounds 1 and 2 (186k → 105k).
After that it stayed flat, while A kept falling.

## Does the gap shrink?

**Yes, on structure, clearly. Partly on process. Not on bug-finding,
where the skill had no edge to begin with.**

- **Structure (shared-dependency handling, class shape, what gets
  deleted)**:
  - **Round 1:** the only real structural divergence of the campaign. A
    duplicated the shared lookup with a REFACTOR NOTE, following the
    memory convention. B and C moved it and rewired the internal
    callers.
  - **Round 3:** all three had converged on the pattern rounds 1–2 had
    just merged.
  - **Round 5:** all three produced essentially the same diff.

  The gap on this axis went from "different design" to "none". The
  campaign's own merged commits did that, not the skill: every arm,
  baseline included, named a specific earlier commit as its template.
- **Process discipline**: this is where B still differed at round 5.
  B did the Step 1 faithful copy with tests run against the *old* code
  before deleting, in both round 1 and round 5; no A or C did that in
  any round. B also wrote a few more tests in every checkpoint (24 vs
  10/21, 14 vs 12/15, 13 vs 9/9). The edge is real, but it is smaller
  than at round 1, and it isn't consistent: B skipped the separate
  Step 1 commit in rounds 2, 3 and 4.
- **Bug and security finding**: no with-skill advantage at any
  checkpoint. At round 3 the baseline and the trigger arm both named a
  real pre-existing security issue. B closed it incidentally through
  its hardening, but reported "no bug fix". At round 1, B's extra
  hardening introduced two edge regressions that the baseline had
  explicitly guarded against.
- **The playbook's own Step 5 lost to project precedent.** In rounds 2
  and 5, B *explicitly* overrode "duplicate shared code with a REFACTOR
  NOTE" in favour of "call back into the god class", because an
  earlier merged commit did so. The one place B still added a REFACTOR
  NOTE (round 3's copied private list) is exactly the case where
  calling back wasn't possible.
- **Conventions propagate as a whole, bad parts included.** Round 1's
  B made a questionable choice (binding a string against a `DECIMAL`
  column), flagged in review. Round 2 copied it, citing round 1. Round 3
  used it again. Review notes that stay out of the code don't travel
  with the convention.

**Trigger check across 3 checkpoints on the same codebase: yes, yes,
no.** This is the first time this benchmark has 3 data points on one
codebase. The "no" came at the most mature point, with a stated reason:
the codebase itself was already the guide. That fits round 7's C, which
also skipped the skill on a codebase with strong local convention. Here
we watched the switch happen within one codebase.

## Verdict

The central hypothesis holds on this codebase: **the skill's marginal
value shrinks as the codebase accumulates its own conventions.** By
round 5, baseline, with-skill and the uninstructed arm produced nearly
identical extractions, at a small cost premium for with-skill. The
uninstructed arm stopped reaching for the skill on its own. What the
skill still bought at round 5 was process: the Step 1 extract-alongside
commit and tests proven against the old code before deleting. That is
the "legible discipline" finding from every round since round 3, now
seen at the late end of a maturing codebase too. The skill did most of
its work early, by setting the pattern the later rounds copied. On
this project much of that pattern predates the campaign: it was already
in memory and in the code at round 1. That early influence is also why
a flaw in the first merged extraction spread to the next two rounds.

Worth carrying forward:
1. **Isolate each arm's scratch/log paths in the prompt.** A shared
   temp directory let one arm see another's output (round 3). Folded
   into this campaign from round 4 onward.
2. **State in the report whether arms inherited project memory.** Here
   the baseline was never convention-free. A future campaign that wants
   a clean round-1 baseline has to run without project memory.
3. **`check-plugin-sync.sh` should compare content, not the install
   record's SHA.** It reported stale on a byte-identical install.
4. **Review findings that stay in the review don't propagate, but the
   code they were about does.** When a checkpoint merge carries a known
   caveat, put it in the code (a comment, or a failing-on-DB2 test
   note) so the next round inherits the caveat together with the
   pattern.
5. **A shorter campaign would have lost the headline.** The trigger
   flip and the full structural convergence only showed up at round 5.
