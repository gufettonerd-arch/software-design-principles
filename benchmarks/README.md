# Benchmarks — index

Two separate benchmarks, testing the two documents this skill ships
(`references/god-class-extraction-playbook.md` and `references/principles.md`)
on different axes. Everything here is real infrastructure — fixtures that
compile and run, scorers that were self-tested against synthetic pass/fail
cases before being trusted on real agent output — not a plan.

**Status as of 2026-08-17**: the god-class benchmark has three published
rounds (regressions, zero-pre-existing-tests, process adherence — 24 runs),
plus one built-but-discarded round (quality — the pilot was contaminated,
see below) and infrastructure for a fourth (quality, LLM-judge grading) that
hasn't been run. The principles benchmark has 14 cases written and zero
runs. Next session reruns the three published rounds against the cleaned
fixture and runs the principles benchmark for the first time.

## `regressions/` — god-class extraction playbook

One fixture (`fixture/`, a small Maven project shaped like a real god
class — several unrelated flows, a helper shared by most of them, one
deliberately preserved bug), examined four ways:

| Task/scorer | What it checks | Status |
|---|---|---|
| `task.md` / `score.sh` | Regressions: did the extraction break anything untouched? | Published, [report](regressions/results/2026-08-17-godclass-n4.md) — **read the correction note at the top before trusting the numbers** |
| `task-notests.md` / `score-notests.sh` | Extracting a flow with zero tests and an undocumented bug: does it get tested, does behavior stay identical? | Published, [report](regressions/results/2026-08-17-godclass-notests-n4.md) — same correction applies |
| `task-process.md` / `score-process.sh` | Does the build stay green at *every* commit, replayed from git history, not just the end state? | Published, [report](regressions/results/2026-08-17-godclass-process-n4.md) — same correction applies |
| `task-quality.md` / `score-quality.sh` + `grade-quality.md` | Extracting a genuinely messy flow (deep nesting, magic numbers): does a real Step 7 readability pass happen? | Built, mechanical scorer self-tested, LLM-judge rubric written — **no valid run yet**, the only pilot run was against the contaminated fixture and was discarded |

`aggregate.sh` scores a batch of run directories with any of the four
scorers above and prints a summary table — use it instead of scoring runs
one at a time.

**The correction, in one paragraph**: `fixture/`'s source comments named the
playbook by step number for part of what these axes measure, visible to
both the baseline and with-skill arms. Confirmed via git history and fixed
in commits `8d46545` and `ffe8fd9` (a second, milder leak found by
auditing the rest of the fixture after the first one). The published
reports' mechanical checks (did anything break, did the build stay green
at every commit, does the readability delta hold) are unaffected — they're
computed from the resulting code, not from what an agent read. The
"discipline" findings (known-bug handling, REFACTOR NOTE presence) need a
clean rerun before being trusted as originally stated.

## `principles/` — the 20 principles

14 principles, each with a should-flag and a should-not-flag snippet (see
`principles/README.md` for which principles are in scope for this
single-snippet methodology and which aren't). Not run yet.

**Before running it**: the case files under `principles/cases/` contain the
snippet *and* the answer key ("Expected: ...") in the same file. Only the
code block gets shown to a reviewing agent — never the file as a whole.
Getting this backwards would repeat the exact mistake the correction above
describes, at a more direct level (handing over the answer, not just a
structural hint toward it).
