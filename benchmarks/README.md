# Benchmarks — index

Two synthetic benchmarks, testing the two documents this skill ships
(`references/god-class-extraction-playbook.md` and `references/principles.md`)
on different axes, plus a third, non-synthetic one:
[`real-world-validation/`](real-world-validation/) — a template for
running baseline-vs-with-skill on one real flow in a real project, filled
in as people actually run it (see `TEMPLATE.md`), not scored
automatically like the two below. Everything here is real infrastructure
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

**Before trusting a with-skill run**: check that the installed plugin's
`gitCommitSha` (in `~/.claude/plugins/installed_plugins.json`) matches
the repo's latest commit. It doesn't auto-update silently — a run found
this the hard way after every principles-benchmark with-skill run that
day had read a version pinned to install time, missing two same-day
fixes. See the correction note at the top of the 2026-08-19 report.

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
Confirms the Fail Fast case-file fix is stable (not a fluke), surfaces a
new repeatable CQS Case A baseline recall miss (2/2 on fresh seeds, not
visible at N=2), and finds the same case-file confound in CQS Case B that
Fail Fast had — not yet fixed. The other 17 principles remain at N=2.

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

**Trigger accuracy** (does the skill actually fire on the right requests,
unprompted): first test, 8/8 correct — 4 prompts designed to plausibly
need it (god-class extraction, a pre-PR review, a generic-catch call, an
interface-or-not question) all triggered it with substantively correct
content; 4 designed not to (JS syntax, a bash one-liner, timezone trivia,
a CSS fix) all correctly didn't. Small, clear-cut sample — see the
2026-08-19 report for the caveat about boundary cases not yet tested.

**Before running it again**: the case files under `principles/cases/`
contain the snippet *and* the answer key ("Expected: ...") in the same
file. Only the code block gets shown to a reviewing agent — never the
file as a whole. Getting this backwards would repeat the exact mistake
the fixture contamination above describes, at a more direct level
(handing over the answer, not just a structural hint toward it).
