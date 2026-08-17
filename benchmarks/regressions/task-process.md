# Process-adherence benchmark — task

Same fixture and flow as `task.md` (`calculateLoyaltyBonus`, fully tested,
`requireCustomer` shared with four other flows). Different instruction: this
variant asks for **incremental commits**, so the resulting git history can be
replayed and checked for the playbook's actual guiding rule — every step
leaves the build green — not just the final state.

## Instructions given to both arms, verbatim

> In `src/main/java/bench/GodClass.java`, `calculateLoyaltyBonus` and
> `calculateShippingFee` are two unrelated flows that happen to live in the
> same class (there are other methods too — leave anything not mentioned
> here alone). Extract `calculateLoyaltyBonus` into its own class called
> `LoyaltyBonusService` in the same package (`bench`). `calculateShippingFee`
> must keep working exactly as before — don't touch its behavior. Keep the
> existing test suite green throughout; you may add new tests for the new
> class if you want.
>
> **Commit your work incrementally, at natural checkpoints, instead of one
> big commit at the end** — for example: after creating the new class
> without removing anything from the old one, after updating the call site,
> after adding tests, after removing now-dead code. Run `mvn test` before
> each commit. There's no fixed number of commits expected; use your own
> judgment about what counts as a checkpoint.

This instruction is deliberately identical for both arms — it doesn't
mention the playbook or its step numbers, so an incremental-commit habit
that shows up in the baseline arm is a general good practice, not
skill-specific. What's expected to differ is *what the checkpoints turn out
to be*, not whether checkpoints exist at all.

## What differs between arms

Same as the other variants: baseline told not to consult any skill;
with-skill arm told to use `software-design-principles` and its playbook.

## Scoring — see `score-process.sh`

1. **Build-green-at-every-commit** — for each commit (oldest to newest,
   excluding the baseline commit), check out that commit's tree and run
   `mvn test`. A commit is GREEN if all 18 tests pass, or RED-EXPECTED if
   the only failure is `processRefund_smallOrder_shouldNotChargeFee_KNOWN_BUG`
   (present from the very first commit, so it's expected to still be there
   at every checkpoint). Anything else failing at any intermediate commit is
   a genuine process violation — the playbook's core guiding rule broken,
   not just the final regressions check.
2. **Extract-before-delete evidence** — is there a commit, before the last
   one, where `LoyaltyBonusService.java` already exists *and*
   `GodClass.calculateLoyaltyBonus` still contains real logic (not yet
   reduced to a one-line delegate)? That's Step 1's "copy before you
   delete" made visible in the history, not just claimed in a report.
3. **REFACTOR NOTE with removal criterion** (reused from the other
   variants) — present in the final state if `requireCustomer` was
   duplicated.

Fully automatic: run `score-process.sh <run-dir>`.
