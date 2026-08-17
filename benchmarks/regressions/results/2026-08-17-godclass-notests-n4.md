# Zero-pre-existing-tests benchmark — GodClass fixture, N=4 (2026-08-17)

> **Correction added 2026-08-17, after this run.** `GodClass.java`'s
> class-level comment (unrelated to `calculateLatePaymentPenalty` itself,
> but present above it in the same file both arms read) named the playbook
> by step number for the *other* flows: it called the shared
> `requireCustomer` helper "the 'shared use' case the playbook's Step 0/5
> exists for" and said the known `processRefund` bug "must stay red,
> unchanged... exactly the undisciplined behavior change the playbook's
> Step 6 exists to prevent." Confirmed via git history: introduced in the
> same commit that built this fixture, present unchanged through this run,
> removed only after the quality-axis pilot (commit `8d46545`).
>
> Two things in this report are affected:
> - **`KNOWN_BUG_STATUS`**, same issue as the other two reports — both arms
>   could read in plain English that it must stay red.
> - **The "Step 5 divergence" analysis below.** The stale reference to
>   `calculateLoyaltyBonus` as "the flow to extract" is real and was read
>   correctly — but the comment sitting right above it *also* names "the
>   playbook's Step 0/5" directly. The three with-skill runs that duplicated
>   `requireCustomer` citing Step 5 may have been pointed at the rule by the
>   fixture, not purely by recalling it from the skill. The divergence
>   itself (3 duplicated, 1 pushed to caller) is still a real, observed
>   split — but "the skill applied its own judgment here" is a weaker claim
>   than the original write-up made it sound.
>
> Not affected: whether tests got written for `calculateLatePaymentPenalty`,
> or whether its behavior matched the reference values after extraction —
> neither was hinted at anywhere in the leaked comment.

## What this measures

A follow-up to the regressions-axis run the same day (`2026-08-17-godclass-n4.md`). That run's fixture had the target flow already fully covered by tests, so it could never exercise Step 3 ("if the old flow had no dedicated tests, write them now") or principle 19 (Characterization Test). This run adds a sixth flow, `calculateLatePaymentPenalty`, with **zero dedicated tests and no comment flagging anything about it** — including one deliberately ambiguous rule (a GOLD-tier discount that only applies when `daysLate <= 5`, debatable as intentional or backwards, not an obvious typo). Two questions, scored independently: does the extraction get a test written for it, and does the flow's actual output stay identical to what it was before anyone touched it?

## Task

Extract `calculateLatePaymentPenalty` into `LatePaymentPenaltyService`, same package. Nothing else in `GodClass` should change. Same prompt for both arms (`task-notests.md`); only difference is the skill-usage instruction.

## Method

`score-notests.sh` reuses the regressions check from the first run and adds two automatic checks: whether any test file mentions the new flow at all, and whether `GodClass.calculateLatePaymentPenalty` (if still present, which the task doesn't require) still returns the same values as a fixed set of reference inputs computed from the untouched method before any agent touched it (`Verify.java`, injected only for scoring, reflection-based, removed after). N=1 pilot first, then N=4 per arm — same eight-parallel-run methodology as the first axis.

## Results

N=1 pilot:

| Arm | Tests written | Behavior | Result |
|---|---|---|---|
| Baseline | yes | preserved | PASS |
| With-skill | yes | preserved | PASS |

Both PASS, but with different designs for the shared `requireCustomer`/`requireOrder` lookup: baseline pushed resolution to the caller (`GodClass` resolves, passes plain objects to the new service — no duplication); with-skill duplicated the lookup into the new service with a `REFACTOR NOTE`, per the playbook's Step 5. Reported to the user as "baseline's choice looked arguably cleaner" — **that assessment was wrong**, corrected below.

**Correction made between the pilot and the N=4 run**: the user pointed out that "push to caller, no duplication" is only actually correct when *both* hold: this is genuinely the only flow ever coming out of this god class, and the shared lookup has no anticipated need to change. If either is uncertain — the realistic case for an actual god class — duplication with a tracked removal criterion is what lets the god class's surface shrink toward zero over successive passes; a clean-looking dependency back into it does not. Step 5 was rewritten to state this explicitly as a two-condition test (commit `ce7a87d`), and both local installs + the published skill were updated before scaling to N=4.

N=4, after the Step 5 correction:

| Arm | Seed | Tests written | Behavior | Result |
|---|---|---|---|---|
| Baseline | 1 | no | preserved | PARTIAL |
| Baseline | 2 | yes | preserved | PASS |
| Baseline | 3 | no | preserved | PARTIAL |
| Baseline | 4 | yes | unverifiable* | UNVERIFIABLE |
| With-skill | 1 | yes | preserved | PASS |
| With-skill | 2 | yes | preserved | PASS |
| With-skill | 3 | yes | preserved | PASS |
| With-skill | 4 | yes | preserved | PASS |

*Baseline seed 4 removed `calculateLatePaymentPenalty` from `GodClass` entirely instead of leaving a delegating method — a legitimate design choice the task doesn't forbid, but it means the reflection-based verifier has nothing to call on `GodClass` anymore. Scorer limitation, not a failure signal; the run's own test suite (26/26 relevant tests green) suggests it was fine, just not independently verifiable the same way as the others.

**Clean PASS (both checks): 4/4 with-skill, 1/4 baseline.** Zero regressions in either arm — that axis stayed saturated here too, same as the first run.

## The shared-lookup design decision, corrected finding

All four baseline runs duplicated `requireCustomer`/`requireOrder` into the new service (not the "push to caller" design from the N=1 pilot) — but **none of the four documented why, or when the duplicate should be removed.** All four with-skill runs also duplicated, and three of the four wrote an explicit `REFACTOR NOTE` with a removal criterion, citing the sharpened Step 5 reasoning directly in their own summaries (e.g. "duplicate because it's uncertain whether more flows will be extracted later — the playbook says to duplicate when that's uncertain").

**One with-skill run (seed 2) diverged**: it chose the "push resolution to caller" design after all, reasoning that "this is the only extraction requested" — a literal reading of the task prompt. The other three inferred the opposite from a leftover artifact in the fixture: `GodClass`'s header comment still says `calculateLoyaltyBonus: the flow to extract`, unchanged since the first benchmark variant, and never updated when this sixth flow was added. Three runs read that as evidence more extractions are coming and treated condition 1 of the new test as unmet; one didn't weight it the same way. Not a bug in the skill or a scorer flaw — a real, honest illustration that the sharpened rule reduces but doesn't eliminate judgment calls when two signals (the explicit prompt vs. leftover context in the code) point different directions. Left as-is rather than "fixed": a real god class has exactly this kind of contradictory residue scattered through it.

## Interpretation

Real differentiation this time, unlike the first regressions run: 4/4 vs 1/4 clean pass. The gap isn't about breaking things — nobody did, on either variant, at either N — it's about **discipline that has no built-in penalty for skipping**: nothing forces a "write a test for untested code" habit or a documented removal criterion for a duplicate, and a capable-but-unguided baseline follows that discipline inconsistently (2/4 wrote tests) even though it never broke anything.

## Limitations

- Same single-task-shape caveat as the first run: one flow, no bug fix bundled with this extraction.
- The reflection-based verifier only checks `GodClass`'s own method if the arm keeps it — a design choice the task doesn't mandate either way. A future variant should verify through both possible locations (`GodClass` and the new service, via reflection on whichever exists) instead of assuming one.
- The fixture's stale header comment turned out to be an accidental confound for the Step 5 decision specifically. Worth knowing about when reading the 3-vs-1 split above, not worth removing — see above.
