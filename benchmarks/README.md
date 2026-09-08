# Benchmarks — index

Two synthetic benchmarks, testing the two documents this skill ships
(`references/god-class-extraction-playbook.md` and `references/principles.md`)
on different axes, plus a non-synthetic one:
[`real-world-validation/`](real-world-validation/) — a template for
running baseline-vs-with-skill on one real flow in a real project, filled
in as people actually run it (see `TEMPLATE.md`), not scored
automatically like the two below. Five rounds filled in as of 2026-09-08,
on three different real codebases — see the dedicated section near the
bottom of this file. Everything here is real infrastructure
— fixtures that compile and run, scorers that were self-tested against
synthetic pass/fail cases before being trusted on real agent output — not
a plan.

**Status as of 2026-08-19**: all four god-class axes (regressions,
zero-pre-existing-tests, process adherence, quality) have been run clean
at N=4 against the decontaminated fixture, and the principles benchmark
has run once across all 56 cases (14 principles × 2 cases × 2 arms). See
[`regressions/results/2026-08-19-principles-and-rerun.md`](regressions/results/2026-08-19-principles-and-rerun.md)
for both — it's the current source of truth; the three 2026-08-17 reports
are kept for history but each now links forward to the clean rerun.

**Before trusting a with-skill run**: run `benchmarks/check-plugin-sync.sh`
first — it compares the installed plugin's `gitCommitSha` (in
`~/.claude/plugins/installed_plugins.json`) against the repo's latest
commit and warns if it's stale. The plugin doesn't auto-update silently —
a run found this the hard way after every principles-benchmark with-skill
run that day had read a version pinned to install time, missing two
same-day fixes (see the correction note at the top of the 2026-08-19
report); round 5 found the same problem again, the orchestrating
session's own installed copy 18 commits stale while it was writing round
5's own fix. This was a manual check from 2026-08-19 to 2026-09-08; it's
a script now.

## `regressions/` — god-class extraction playbook

One fixture (`fixture/`, a small Maven project shaped like a real god
class — several unrelated flows, a helper shared by most of them, one
deliberately preserved bug), examined four ways:

| Task/scorer | What it checks | Status |
|---|---|---|
| `task.md` / `score.sh` | Regressions: did the extraction break anything untouched? | Clean N=4: 8/8 PASS, zero regressions. [2026-08-17 report](regressions/results/2026-08-17-godclass-n4.md) (see correction note) → [2026-08-19 clean rerun](regressions/results/2026-08-19-principles-and-rerun.md) |
| `task-notests.md` / `score-notests.sh` | Extracting a flow with zero tests and an undocumented bug: does it get tested, does behavior stay identical? | Clean N=4: 4/4 with-skill PASS, 0/4 baseline wrote a test. [2026-08-17 report](regressions/results/2026-08-17-godclass-notests-n4.md) → [2026-08-19 clean rerun](regressions/results/2026-08-19-principles-and-rerun.md) |
| `task-process.md` / `score-process.sh` | Does the build stay green at *every* commit, replayed from git history, not just the end state? | Clean N=4: 8/8 checkpoints clean both arms; REFACTOR NOTE 0/4 baseline vs 3/4 with-skill. [2026-08-17 report](regressions/results/2026-08-17-godclass-process-n4.md) → [2026-08-19 clean rerun](regressions/results/2026-08-19-principles-and-rerun.md) |
| `task-quality.md` / `score-quality.sh` + `grade-quality.md` | Extracting a genuinely messy flow (deep nesting, magic numbers): does a real Step 7 readability pass happen? | First clean N=4 run (prior pilot was contaminated and discarded): 8/8 behavior preserved, with-skill far more consistent on the readability delta than baseline. [2026-08-19 report](regressions/results/2026-08-19-principles-and-rerun.md) |

`aggregate.sh` scores a batch of run directories with any of the four
scorers above and prints a summary table — use it instead of scoring runs
one at a time.

**The 2026-08-17 contamination, in one paragraph**: `fixture/`'s source
comments named the playbook by step number for part of what these axes
measure, visible to both the baseline and with-skill arms. Confirmed via
git history and fixed in commits `8d46545` and `ffe8fd9`. The mechanical
checks (did anything break, did the build stay green at every commit,
does the readability delta hold) were unaffected — they're computed from
the resulting code, not from what an agent read. The "discipline"
findings (REFACTOR NOTE presence, test-writing habit) needed a clean
rerun before being trusted as originally stated — that rerun is done, see
above, and the findings held.

**Recurring finding across all four axes, now confirmed clean**: the
playbook's measurable effect isn't preventing breakage (regressions stays
saturated at 0/8 everywhere, in every run) — it's discipline that has no
built-in penalty for skipping: writing a test for previously-untested
code, documenting a duplicate's removal criterion (REFACTOR NOTE),
cleaning up consistently instead of some-seeds-yes-some-seeds-no. A
capable baseline gets the underlying engineering right; what it skips is
making that reasoning legible to whoever reads the code next.

## `principles/` — the 20 principles

14 principles, each with a should-flag and a should-not-flag snippet (see
`principles/README.md` for which principles are in scope for this
single-snippet methodology and which aren't). First full run: 56/56 cases
complete, see
[the 2026-08-19 report](regressions/results/2026-08-19-principles-and-rerun.md).

**Headline result, now at N=2** (56 cases × 2 seeds, 112 runs): recall
(catching the real issue) held at 28/28 on both arms across both seeds —
no difference there. Precision (correctly *not* flagging a calibration
case), combined across both seeds: **15/28 (54%) baseline vs 23/28 (82%)
with-skill**. Two of the three with-skill misses found on the first seed
turned out to be a haiku-specific limitation (clean on the default model
the second time); the third (`14-fail-fast`) missed on **both** seeds, on
the default model both times — a real, repeatable gap, not noise or a
weaker model. See the report for the full case-by-case breakdown.

**Partial N=4 on the 3 highest-signal principles** (DRY, CQS, Fail Fast —
the ones with real N=2 misses): see
[the 2026-08-22 report](regressions/results/2026-08-22-n4-partial.md).
Confirms the Fail Fast case-file fix generalizes for the most part — but
a same-day [blind grading pass](regressions/results/2026-08-22-blind-grading.md)
(the first time this project ran one for real, on newly-saved raw
transcripts) caught a genuine factual error in Case B's premise that
same-session grading had passed cleanly: the case claimed a validation
rule "isn't expressible" via bean-validation annotations, and that's
simply wrong — 2 independent with-skill responses correctly noticed.
Fixed the case file same day, **reverified with 4 fresh with-skill runs:
4/4 clean**. First real evidence this project's own same-session grading
has a blind spot, exactly the kind `grade-principles.md` warned about —
and, unlike DRY's fix attempts below, proof that when the underlying
issue really is a wording/factual defect (not a judgment call the model
keeps landing on differently), one fix genuinely closes it. See the
blind-grading report for the full story. Also investigates a CQS Case A
baseline recall wobble that looked repeatable at 2 seeds but turned out
to be ~50% variance across 6 (3/6 baseline vs. 4/4 with-skill) — read as
a real, not-yet-proven hypothesis about semantic vs. syntactic smells,
not a settled finding (see the report). Also finds and fixes the same
case-file confound in CQS Case B that Fail Fast had, verified with one
run per arm. One more finding, different in kind, investigated three
times over that day: the DRY Case B with-skill hit/miss tally (4/6, then
6/6 after a same-day wording fix) turned out to be measuring the wrong
thing — nearly every run reasons via rule-of-three timing, not
recognizing coincidental similarity, which happens to give the right
surface answer only because the snippet shows exactly 2 instances.
Confirmed with a 4-run check adding a third, still-unrelated variant
(4/4 reasoned about instance count, none about meaning), then tried two
different fixes in `principles.md` and reverified both against that same
3-instance scene: restructuring the section (0/4 improved) and adding a
concrete worked counter-example — a numeric threshold, in a different
domain (2/4, no better than the unedited baseline). **Two distinct fix
approaches, two clean failures**, read at the time as a pattern-match
instinct that resists in-context correction, not a wording gap — see
**2026-09-08 update** below, which found a third approach that
broke the streak. A worthwhile checklist audit came out of the original
session too — reread the other 17 case files for the same confound shape
Fail Fast/CQS had; found none serious enough to fix at the time.

Extended same day to 2 more principles, SOLID and Readability, picked in
order rather than for cause. SOLID came back clean (7/8). Readability
Case A was strong (4/4); Case B turned out to be a **fourth case with the
same confound shape** — fixed the two dominant distractions, reverified
1 run per arm: both confirmed closed by name in the responses, but two
different, previously-secondary issues took their place. Reported as
"measurably improved, not clean" rather than rounded up — see the report.

Extended once more to Value Object, Tell Don't Ask, and Law of Demeter —
now full N=4 (seed3, then seed4). Case A recall 8/12 clean, all 4
baseline misses concentrated on 2 principles (Tell Don't Ask, Law of
Demeter), with-skill 6/6 clean. The result that matters isn't about any
one of these: the "finds real secondary issues, stays silent on the
calibration point" Case B pattern has now shown up on **7 principles
today**. Past the point of hand-fixing each case file — read as a
question about the grading methodology itself (score the specific point
and unrelated findings separately, not folded into one MATCH/MISS) —
see the report for the full reasoning. The `04-law-of-demeter.md`
formatting bug found in passing is fixed and reverified same day — first
attempt introduced a new bug (broken on negative cents), caught by the
first verification run and corrected before moving on; seed4's baseline
then caught a real but out-of-scope gap in the fix (fixed 2-decimal
formatting is wrong for non-2-decimal currencies) — not chased further,
same treatment as other far-edge cases noted today.

The Case B rubric fix (two axes instead of one) was validated blind on
5 principles same day — not just proposed, tested: a clean arm-correlated
split on 2 clean case files, no correlation on 2 known-confounded ones,
and a genuinely different (less flattering) result on the fifth —
see [the blind-grading report](regressions/results/2026-08-22-blind-grading.md).

Extended once more to Strategy and Specific Exceptions, seed3 only
(N=3). Strategy Case A baseline missed and explicitly dismissed the
real issue as fine; Specific Exceptions Case A went 2/2 clean. Brought
both to full N=4 the next day (2026-08-23): Specific Exceptions held
clean (Case A 4/4, Case B with-skill 2/2 explicit). **Strategy did
not** — seed4's with-skill response missed Case A, explicitly invoking
the checklist's own "when NOT to apply it" clause to argue *against*
Strategy for a 5-branch, already-growing snippet, the same clause it
used correctly to pass Case B in the same batch. First with-skill
Case A regression this session on a principle a single earlier seed
had called clean — direct evidence a one-seed read shouldn't be
trusted as settled, on either arm.

Extended to the last 4 untouched snippet principles — DDD tactical,
Hexagonal, Composition over Inheritance, Shared state, seed3 only —
completing all 14 snippet-based principles with data beyond N=2 (8 at
full N=4, 6 at N=3 — now 10 at N=4, 4 at N=3 after Strategy/Specific
Exceptions reached seed4 on 2026-08-23). Composition over Inheritance
came back cleanest of the day. One finding worth flagging: **DDD tactical Case B with-skill
actively contradicted its own calibration point**, reframing a
deliberately-anemic JPA entity as a Tell Don't Ask violation. Second
contradiction of this shape today, after Law of Demeter. **Investigated
further on 2026-08-23** — see
[the contradiction-pattern report](regressions/results/2026-08-23-contradiction-pattern-investigation.md):
Case A and Case B are independent runs with no shared context, so
"over-applied in the same review" was the wrong framing. What's actually
happening: 4 separate with-skill Case B responses across 3 principles
(Law of Demeter ×2, DDD tactical, Hexagonal) all reach for **Tell Don't
Ask by name** on a snippet shape it doesn't own — 3 of 4 land wrong,
because the correct exemption for each case is written under a
*different* principle's own "when NOT to apply it" heading (Law of
Demeter's Value-Object-navigation carve-out, DDD tactical's
persistence-entity carve-out), not under Tell Don't Ask's. **Fixed the
same day**: added both exemptions directly to Tell Don't Ask's own
clause (plugin 1.2.4 → 1.2.5), reverified against exactly the two named
case files — 1 with-skill run each, both clean EXPLICIT passes on the
first attempt. **N=3 reverification on 2026-08-24 found the fix is real
but not fully closed**: 2 more Law of Demeter Case B with-skill reruns
found 1 CONTRADICTED via a new route — the response correctly recalls
the exception exists, then argues this specific snippet's formatting is
"generic money-printing, not receipt-specific" and therefore outside it,
recommending the exact `Money.format()` extraction the case says is
unnecessary. Post-fix tally on that case: 2 clean, 1 contradicted out of
3. The original bug (not knowing the exemption existed) is closed; a
subtler one (litigating the exemption's boundary once the model knows
it) is not. **Closed with a second, targeted fix on 2026-08-26**: the
clause now explicitly names "generic vs. specific formatting" as the
wrong axis and points at the right one (does a second real caller
exist — a DRY/rule-of-three question, not a Tell Don't Ask one).
Reverified with 3 fresh runs against the identical snippet: **3/3
clean**, all three explicitly using the new reasoning ("one caller,"
"rule of three") rather than reaching for the generic-vs-specific
framing that caused the original miss. See
[the report](regressions/results/2026-08-23-contradiction-pattern-investigation.md)
for the full reasoning and all transcripts.

Also on 2026-08-24: DDD tactical and Hexagonal brought to full N=4. Both
principles' Case A baseline flipped from a seed3 miss/soft-miss to a
clean seed4 hit — the second and third instance of real single-seed Case
A variance this week (after Strategy's with-skill flip the other way).
On 2026-08-26, the last 2 principles — Composition over Inheritance and
Shared state — reached full N=4 too. Composition over Inheritance's
Case A stayed clean 4/4 across both seeds, including baseline; its
with-skill Case B response used Composition's own "is-a" reasoning
directly at seed4, unlike seed3's pass which borrowed Specific
Exceptions' framing — direct evidence the "borrows a neighboring
principle" pattern isn't universal. Shared state's Case A also stayed
clean 4/4; its with-skill Case B flipped from SILENT (seed3) to clean
EXPLICIT (seed4) — a third principle this week (after Strategy and
Composition) where Case B with-skill engagement varied seed to seed on
the same case file.

**All 14 snippet-based principles are now at full N=4** (DRY, CQS, Fail
Fast, SOLID, Readability, Value Object, Tell Don't Ask, Law of Demeter,
Strategy, Specific Exceptions, DDD tactical, Hexagonal, Composition over
Inheritance, Shared state) — the scale-up that started 2026-08-22 as
"3 principles with the most N=2 signal" is complete. The 6 scenario-based
principles remain untouched at N=2.

**The 6 scenario-based principles** (structural/process decisions, not
single-file smells — see `principles/scenario-cases/`): first run, 46/48
clean matches at N=2. 5 of 6 principles went 8/8 on both arms; the one
exception (`16-modular-monolith`) had baseline land on the right general
direction without naming the case's specific point twice, still logged as
partial rather than a clean miss. Notably cleaner than the snippet
benchmark's headline number — see the 2026-08-19 report's Part 3 for why
that's a hypothesis (scenario prompts spell out the situation; snippet
prompts require noticing what to look for first) rather than a settled
conclusion.

**First scenario-principle data beyond N=2** (2026-08-26): DDD strategic
(Bounded Context), picked arbitrarily, brought to N=3. Clean 4/4 — both
arms correctly recommend the 3-team merge-conflict case and correctly
decline the single-team no-friction one, with-skill explicitly checking
the exemption clause both times rather than pattern-matching the shape
alone. Consistent with the hypothesis above, still just one principle —
the other 5 remain at N=2.

Extended the same day to the remaining 5 scenario principles (Package by
feature, Anti-Corruption Layer, Strangler Fig, Modular Monolith,
Characterization Test) — **all 6 scenario-based principles now have
data beyond N=2.** Case A recall stayed perfect: 10/10 across all 5,
both arms. Case B: with-skill 5/5 EXPLICIT correct; baseline split 3/5
correct, 1 silent, and **1 CONTRADICTED** — Anti-Corruption Layer's
baseline recommended adding a translation layer for a vendor API the
case explicitly says is already aligned and needs no isolating,
reasoning that schema-drift risk justified it despite today's alignment
("the YAGNI instinct says skip it, but the boundary here is real, not
speculative"). With-skill correctly declined via the checklist's own
exemption on the identical scenario. This is a new shape for this
benchmark: not with-skill over-flagging or baseline staying silent, but
**baseline over-recommending** via generically sound defensive-
engineering instinct that the calibration case specifically tests
against.

**Brought all 6 to full N=4 the same day.** Case A stayed perfect —
12/12 this seed, 22/22 combined, no misses anywhere. Case B with-skill:
6/6 EXPLICIT correct. Case B baseline gave two corrections to the seed3
read, not confirmations: the Anti-Corruption Layer CONTRADICTED result
above **doesn't repeat** at seed4 — baseline recommends a contract test
and call-site consolidation, not the DTO/mapper layer, so that finding
is downgraded from "a real pattern" to "one data point that didn't
generalize," an honest correction rather than a confirmation. Package by
feature's sidestep (baseline answers "how to onboard" instead of
"should we restructure") **does repeat both seeds** — the more durable
of the two findings, and a candidate for rewording that case's Case B
scenario in a future session, the same way `07-cqs.md`/`14-fail-fast.md`
were reworded once a case-file shape was shown to consistently pull
attention away from what's being tested. See
[the report](regressions/results/2026-08-22-n4-partial.md) for the full
breakdown and all transcripts. **All 20 principles in this benchmark
(14 snippet-based, 6 scenario-based) are now at full N=4.**

**Trigger accuracy** (does the skill actually fire on the right requests,
unprompted): first test, 8/8 correct — 4 prompts designed to plausibly
need it (god-class extraction, a pre-PR review, a generic-catch call, an
interface-or-not question) all triggered it with substantively correct
content; 4 designed not to (JS syntax, a bash one-liner, timezone trivia,
a CSS fix) all correctly didn't. Small, clear-cut sample — see the
2026-08-19 report for the caveat about boundary cases not yet tested.

**Boundary-case trigger test (2026-09-08)**: the first test's own caveat
said boundary cases weren't tried. 6 deliberately ambiguous prompts this
time — plain chat questions, no repo attached, no hint of a test — each
run as a fresh, blind session: a method that's grown to 80 lines with 4
nested ifs but "not causing bugs"; two classes with the exact same
1000/500 discount thresholds duplicated; a "return null, Optional, or
throw?" style question; a `static HashMap` used as a cache in a normal
concurrent Spring app; mocking a final class in a JUnit test; and a
small, read-only, 3-repository CRUD controller someone said "needs a
service layer." **Triggered 3/6, correct every time it fired**: the
long-method and duplicated-threshold questions got calibrated,
YAGNI-aware advice; the CRUD-controller question got a correct
**decline**, citing the tactical-DDD/Hexagonal "when NOT to apply it"
exemption by name — direct evidence the skill isn't just flag-everything,
it can talk itself out of firing on a case its own documentation says to
skip. Of the 3 non-triggers, 2 were genuinely out of scope (a style
convention, a pure Mockito/tooling question) — correctly silent. **The
third is the real finding**: a static `HashMap` cache in a concurrent web
app is exactly principle 18's own documented scenario (a non-thread-safe
structure shared across concurrent requests) by name, and the skill
didn't fire on it — the response still caught and fixed the thread-safety
problem on baseline reasoning alone, so nothing broke, but this is the
first concrete instance of the skill staying silent on a prompt that
matches one of its own 20 principles' textbook example almost verbatim.
Consistent with the standing finding across all five real-world rounds
(baseline judgment is often already sound, so a missed trigger doesn't
always cost anything) — but a small sample, and the first real crack in
an otherwise clean trigger record. Worth a larger boundary sample before
treating 3/6 as a stable rate rather than one data point.

**DRY Case C, revisited (2026-09-08)**: the "three clean failures" above
weren't the end of the story. A third fix attempt targeted the actual gap
the first two shared without either of them naming it — both prior
attempts (the restructure, and the worked counter-example) reasoned about
a *numeric threshold* shape; Case C's snippet has no numbers in it at all
(three one-line string-concatenation methods). Added a new worked example
to `principles.md`'s DRY section matching Case C's exact surface shape —
same signature, string-building, nothing to point at as "obviously
different data." Tested blind, N=4, fresh sessions given only the
candidate guidance text and the bare snippet (no answer key, no skill
invocation — just the excerpt pasted in): **4/4 explicit correct
non-flags**, every response naming the knowledge question and explicitly
rejecting "no numbers = generic" reasoning rather than falling back to
instance counting. First clean result on this case after two prior clean
failures — see `principles/cases/05-dry.md`'s own "Update, 2026-09-08"
note for the exact wording and test setup. Held to the same bar as every
other N=4 result here: real, not yet reverified against a second seed —
a second seed clean would move this from "a real result" to "closed,"
the same way other findings in this project have needed two seeds before
being called settled.

**Before running it again**: the case files under `principles/cases/`
contain the snippet *and* the answer key ("Expected: ...") in the same
file. Only the code block gets shown to a reviewing agent — never the
file as a whole. Getting this backwards would repeat the exact mistake
the fixture contamination above describes, at a more direct level
(handing over the answer, not just a structural hint toward it).

## `real-world-validation/` — real legacy codebases, starting 2026-08-24

First real (non-synthetic) runs, on a real codebase — a real Java 7/8
Struts 1.x legacy travel-document app, not a fixture. Each round is
baseline (A) vs with-skill (B) vs a trigger check (C, told nothing about
skills either way) extracting one real flow out of a god class, in
isolated git worktrees. See
[round 1](real-world-validation/2026-08-24-real-world-round1.md) and
[round 2](real-world-validation/2026-08-24-real-world-round2.md) for the
full write-ups.

**Round 1** (a ticket-picked mid-size class, ~2400 lines): A and B converged almost exactly — same service shape, same
duplicated-with-note handling of shared code, same two real pre-existing
bugs found and preserved by both independently. B's one visible edge was
a separate, playbook-step-7 readability pass (a `notFound()` helper, a
named constant) done and reverified *after* the faithful copy was
confirmed green. The bigger finding was C, not B: C self-invoked the
skill but read "everything reachable from the branch" far more
aggressively than A/B did (1400+ lines moved vs. 36), a scope reading
neither wrong — the divergence between two skill-using sessions (B vs C)
was bigger than the divergence between skill-on and skill-off (A vs B).

**Round 2** (the single biggest class in
the repo, ~14700 lines) deliberately pinned the exact method list up front
to close round 1's scope ambiguity — it worked, all three sessions agreed
on scope. A **new** ambiguity took its place instead: how many of the
flow's real external callers actually get rewired to the extraction. C
rewired all 3, A rewired 1 of 2, B rewired 0 — despite identical scope
and all three satisfying "preserve exact behavior" (nothing broke,
because the old methods were also left in place). B's one clear edge:
catching a second real shared caller that A/C's
reports don't mention checking for. The headline finding is C: this
round it did **not** self-invoke the skill (opposite of round 1's C on a
similar task) — read the project's own memory/precedent files instead —
and still produced the most complete extraction of the three (full
caller rewiring, new characterization tests, a false-positive shared-name
catch neither A nor B found). Read together with round 1: the skill's
marginal value looks smaller on a codebase that has already accumulated
its own concrete, discoverable conventions, and the trigger check itself
isn't yet consistent run-to-run on near-identical tasks — both flagged as
open questions, not conclusions, pending more rounds.

**Neither round found the skill catching a bug baseline missed**, and
neither found it adding ceremony baseline correctly skipped — its
measured effect so far is entirely about process (an explicit, checkable
readability pass; documenting shared-dependency decisions via REFACTOR
NOTE) and about scope/integration completeness varying more between
sessions than expected, not about catching or avoiding anything baseline
got wrong. Both rounds' own verdicts recommend pinning task-sentence
ambiguity tighter next time (round 1: how much code moves; round 2: how
many callers get switched over) rather than treating either round as
closing the question.

**Round 3 ran on a second, unrelated real codebase** (2026-09-04) — see
[the report](real-world-validation/2026-09-04-real-world-round3.md).
Not the same system as rounds 1–2: a legacy booking system whose Java was
auto-generated from COBOL years ago, COBOL source now gone, one giant
class (~43,700 lines) where every method shares one mutable
working-storage object instead of using parameters, and cross-program
calls happen by name string (CICS-style) rather than Java method calls.
That last point broke the round's planned test — round 2's "how many
real callers get rewired" axis doesn't exist on this codebase, since
there's no such thing as a Java-level external caller to rewire. The
round adapted on the fly: same duplication-removal shape (two paragraph
methods sharing a byte-for-byte-identical 30-line block), but the
question became whether the playbook's Service/Repository extraction
pattern survives contact with globally-coupled generated code, not
hand-written OO code. All three sessions (A/B/C) converged on the same
answer independently — a plain, unregistered private helper method, no
new class, no Service/Repository split — which on this data point reads
as "a careful baseline and a skill-guided session agree once the code
itself makes the over-engineered option obviously wrong," rather than
evidence the skill doesn't matter. The real differences were smaller:
2 of 3 sessions added an explanatory comment unprompted (one with the
skill, one without), and only one session (C, the trigger-check, skill
not invoked) went and found a real dependency-complete compile path
instead of settling for a syntax-only check — confirmed after the fact
by re-running that same compile against all three sessions' code: all
three compiled clean, so the gap was about verification thoroughness,
not code correctness. Full writeup, including why the intended axis
didn't transfer and what a future round on this kind of codebase should
test instead, is in the report.

[`ROUND-3-INSTRUCTIONS.md`](real-world-validation/ROUND-3-INSTRUCTIONS.md)
is the original runbook this round started from, written for a
hand-written-app shape like rounds 1–2 — worth keeping for that case,
but note it doesn't anticipate the generated-code, name-based-calling
architecture round 3 actually ran into. Kept up to date since as a
living runbook (worktree base-commit verification and the plugin-sync
script were both folded into it after round 5), not a one-time snapshot.

**Round 4 stayed on the same second codebase** (2026-09-04) but picked a
bigger, more self-contained flow — see
[the report](real-world-validation/2026-09-04-real-world-round4.md).
Round 3's target was too small and too globally-coupled to show much
variance; this round found a real, ~570-line date-arithmetic subsystem
that (unusually for this codebase) reads and writes only its own narrow
corner of the shared working-storage object, making a genuinely
parameterized extraction possible for once. On the way to picking it,
the round hit a second, subtler version of round 3's false-positive-caller
trap: a literal, syntactically valid Java `import` statement that turned
out to be dead code, shadowed in every one of its 9 apparent call sites
by a locally-redeclared class of the same name — harder to catch than a
bad grep, since an `import` looks like real evidence until you check
whether anything actually resolves to it. On the task that did run, all
three sessions (A/B/C) independently converged on the same real
extraction shape — a small dependency-free class, no shared mutable
state, an explicit typed result — which round 3's target structurally
couldn't support. The orchestrating session didn't just take the three
reports at face value: it independently re-read the original source for
the error-handling behavior and independently re-compiled all three
sessions' code against the real dependency classpath, catching two bugs
in its own verification script along the way (a too-broad file glob, then
a classpath-construction mistake) before confirming all three were
genuinely clean — a reminder that a failed *reproduction* of a
verification claim isn't the same as a *refuted* one. No correctness
differences were found between the three on close inspection; the real
differences were in thoroughness — one session flagged a genuine,
unresolved technical question (a possible overflow/truncation risk)
instead of guessing, another did a real behavior-preserving
consolidation pass beyond a 1:1 port, a third had the most complete test
coverage — matching this project's standing finding across all four
real-world rounds now: the skill's most consistent effect is making
already-good judgment legible and checkable, not correcting judgment a
careful baseline gets wrong.

**Round 5 shifted to a third, unrelated real codebase and a different
task shape entirely** (2026-09-08) — see
[the report](real-world-validation/2026-09-08-real-world-round5.md). Not
an extraction: a real implementation/migration request (port a legacy
flow into a modern sibling project, matching an already-migrated
neighboring flow's async/parallel architecture). The headline finding
isn't about the skill at all: all three sessions, in an initial pass,
independently accepted the same false premise — that a deep integration
step was unreachable/unverifiable in this environment — and none of
them, skill-guided or not, challenged it before building a stub around
it. The correction came only from the orchestrating session directly
verifying that claim instead of trusting it, not from any of A/B/C. Fed
the same correction, all three then replaced the stub with a real,
working implementation and verified it against a live endpoint — two of
the three independently hit and fixed the identical underlying technical
bug with zero visibility into each other's work, a strong repeated
signal that the bug is a property of the real legacy code, not one
session's approach. The skill's measured effect, once again, was
legibility (naming the pattern, citing steps) rather than catching the
wrong premise itself — extending, not complicating, the standing finding
above. Also reconfirms an open methodology gap from this round's own
first pass (stale worktree base commits, not yet fixed) and the
trigger-check session's skill self-invocation rate, still 1-for-3 across
rounds. Both process gaps (worktree base-commit verification, the
unreachable-claim check) were folded into `TEMPLATE.md` and
`ROUND-3-INSTRUCTIONS.md` the same day, alongside the skill's own new
"verify before you build around it" checklist item — a round 6 is the
next test of whether that actually changes a pass-1 outcome.
