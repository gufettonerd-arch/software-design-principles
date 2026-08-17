# Process-adherence benchmark — GodClass fixture, N=4 (2026-08-17)

## What this measures

The third axis of the three planned for the playbook (after regressions and zero-pre-existing-tests, both run the same day). Those two only ever checked the *final* state of a run. This one checks the playbook's actual guiding rule — "every step must leave the build green" — literally, by replaying each run's own commit history and running `mvn test` at every checkpoint, not just at the end. A single big commit that happens to be green at the finish line can still represent a risky, non-incremental process; this axis is built to catch that difference, which the other two structurally can't see.

## Fixture and task

Same fixture as the first regressions run (`calculateLoyaltyBonus`, fully tested, `requireCustomer` shared with five other flows). Different instruction (`task-process.md`): both arms are told to **commit incrementally, at natural checkpoints**, instead of one commit at the end — creating and adding to the new class before touching the old one, updating the call site, adding tests, removing dead code — with `mvn test` run before each commit. The instruction is identical for both arms and never mentions the playbook or step numbers, so any incremental-commit habit in the baseline arm reflects a general good practice, not something skill-specific.

## Method and a scorer bug found before trusting it

`score-process.sh` lists a run's commits (excluding the baseline commit), checks each one out in turn, and runs `mvn test` at that exact point in history. A commit is GREEN if all tests pass, RED-EXPECTED if the only failure is the fixture's known pre-existing bug (present since before any agent touched anything, so expected at every checkpoint), or a genuine failure otherwise. Two more checks: whether an early commit shows the new class coexisting with the still-intact old method (Step 1's "copy before you delete" made visible in the history, not just claimed in a report), and whether a `REFACTOR NOTE` with a removal criterion is present in the final state (reused from the other two variants).

Self-testing against a hand-built synthetic commit history caught a real bug before any real run was scored: when a checkpoint's build fails to *compile*, Maven produces no surefire reports at all, and the original scoring loop read "zero failures found in zero report files" as GREEN — a compile error was being silently reported as a clean pass. Fixed to treat a missing/empty reports directory as a hard failure, and re-verified against three synthetic histories: a genuine compile error at an intermediate commit (now correctly caught), a clean multi-commit history (all four checks correct), and an existing single-commit run from an earlier axis (correctly reported as `NOT_INCREMENTAL` rather than a false pass or fail).

## Results

N=1 pilot:

| Arm | Commits | Checkpoints clean | REFACTOR NOTE | Result |
|---|---|---|---|---|
| Baseline | 4 | yes | no | PASS |
| With-skill | 4 | yes | yes | PASS |

N=4:

| Arm | Seed | Checkpoints clean | Extract-before-delete | REFACTOR NOTE | Result |
|---|---|---|---|---|---|
| Baseline | 1 | yes | yes | no | PASS |
| Baseline | 2 | yes | yes | no | PASS |
| Baseline | 3 | yes | yes | no | PASS |
| Baseline | 4 | yes | yes | no | PASS |
| With-skill | 1 | yes | yes | no* | PASS |
| With-skill | 2 | yes | yes | yes | PASS |
| With-skill | 3 | yes | yes | yes | PASS |
| With-skill | 4 | yes | yes | yes | PASS |

*Seed 1 chose the "push resolution to the caller" design instead of duplicating the shared helper — see below.

8/8 clean checkpoints and 8/8 extract-before-delete evidence, in both arms. `REFACTOR_NOTE_PRESENT`: 0/4 baseline, 3/4 with-skill.

## Interpretation

This is the third independent benchmark design run this day, and the third time the same shape of result shows up: **raw process safety is not where the two arms differ.** A capable baseline, simply told to commit incrementally, produces a sequence that closely mirrors the playbook's own step order (add class → delegate → tests → dead-code removal) without being told to. Every intermediate commit in every one of the 16 runs across this axis was independently verified buildable — the "big-bang risk" this whole playbook is written against doesn't actually show up here, in either arm, at this task's difficulty.

What differs, consistently, across three differently-designed benchmarks now (a fixture with full test coverage, one with zero coverage on the target flow, and this one checking the commit history itself): whether a deliberate, transitional duplication of shared code gets **documented** — what's duplicated, why, and when to remove it — versus made silently. That's not a safety property in the sense this axis measures; it's a maintainability property for whoever reads the code after the extraction is done and doesn't have the run's transcript to explain it.

## The recurring Step-5 divergence

One with-skill run in four (this axis's seed 1, matching the same ~1-in-4 rate seen in the zero-tests variant) chose "push resolution to the caller" instead of duplicating `requireCustomer`, reasoning explicitly that "this is the only flow being extracted from this god class per the task" — reading the literal scope of the task prompt as satisfying the sharpened Step 5's first condition. The other three read the fixture's own leftover comment (still flagging `calculateLatePaymentPenalty` as a future extraction target) as evidence that condition wasn't met, and duplicated with a note. Both are defensible; the split is stable across two separate variants now, not a one-off. Not something to "fix" — a real illustration of how far an explicit rule can reduce judgment calls without eliminating them when two signals in the same fixture point different directions.

## What this run led to

No new playbook or skill changes this time — the finding confirms and strengthens the Step 5 correction already made after the previous variant, rather than surfacing a new gap.

## Limitations

- Same single-task-shape caveat as the other two variants.
- The build-green-at-every-commit check assumes the agent's chosen checkpoints are meaningful; an agent could game this metric with many trivial green commits that don't actually correspond to safe intermediate states. Not observed in any of the 16 runs here, but the scorer doesn't rule it out structurally.
- Checking out and testing every commit is the slowest scorer of the three axes (N tests instead of 1 per run) — fine at N=4, would need to be smarter about caching/parallelizing before scaling much further.
