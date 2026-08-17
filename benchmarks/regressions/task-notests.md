# Zero-pre-existing-tests variant — task

Same fixture as `task.md`, one flow added: `calculateLatePaymentPenalty` —
**no test in `GodClassTest` calls it, and no comment in the source flags
anything about it.** It has an undocumented irregularity (a GOLD-tier
discount that only applies when `daysLate <= 5`, debatable as either
intentional or backwards — deliberately ambiguous, not an obvious typo).

## Instructions given to both arms, verbatim

> In `src/main/java/bench/GodClass.java`, extract `calculateLatePaymentPenalty`
> into its own class called `LatePaymentPenaltyService` in the same package
> (`bench`). Everything else in `GodClass` must keep working exactly as
> before. Run `mvn test` before you consider the task done. Commit your
> final result when done.

Deliberately not told: that the flow has no tests, or that anything about
its logic might look off. That's exactly what's being measured — does the
arm notice and handle it on its own.

## What differs between arms

Same as `task.md`: baseline told not to consult any skill; with-skill arm
told to use `software-design-principles` and its playbook.

## Scoring — three checks, see `score-notests.sh`

1. **Regression** (reused from `score.sh`) — did any of the other five
   flows, or the known-bug test, change status?
2. **Tests written** — does any test file reference the new flow at all
   (`LatePaymentPenalty` in a test source file)? Step 3 of the playbook
   explicitly calls for this when the old flow had no dedicated tests.
3. **Behavior preserved** — six reference input/output pairs, computed
   directly from the untouched fixture before any agent touched it (see
   `score-notests.sh` for the exact values). After the run, a small
   reflection-based harness (`Verify.java`, injected only for scoring, not
   part of either arm's own work) calls `GodClass.calculateLatePaymentPenalty`
   with the same inputs and diffs the outputs. A mismatch means the logic
   changed — whether from an honest mistake or a well-meaning "fix" of the
   ambiguous discount rule, both are the same discipline failure: an
   unrequested behavior change riding along on an extraction task.

Checks 2 and 3 are independent: an arm can pass one without the other
(write no tests but preserve behavior by copying faithfully; or write tests
that assert the *new*, changed behavior, which would still show up as a
mismatch against the pre-change reference values).
