# Regressions benchmark — task

Fixture: `fixture/` — a Maven project with `bench.GodClass`, a small but
structurally realistic god-class: 5 unrelated flows, a `requireCustomer`
helper shared by 4 of them (including the one to extract — this is the
playbook's Step 0/5 "shared use" case), and one deliberately failing test
(`processRefund_smallOrder_shouldNotChargeFee_KNOWN_BUG`) documenting a
pre-existing, out-of-scope bug. Baseline: 18 tests, 17 green, 1 red.

## Instructions given to both arms, verbatim

> In `src/main/java/bench/GodClass.java`, `calculateLoyaltyBonus` and
> `calculateShippingFee` are two unrelated flows that happen to live in the
> same class. Extract `calculateLoyaltyBonus` into its own class called
> `LoyaltyBonusService` in the same package. `calculateShippingFee` must
> keep working exactly as before — don't touch its behavior. Keep the
> existing test suite green throughout; add new tests for the new class if
> you want. Run `mvn test` before you consider the task done.

Neither arm is told about `applyDiscountCode`, `generateInvoiceSummary`,
`processRefund`, or the known bug — those exist purely as tripwires the
prompt doesn't call attention to, on purpose.

## What differs between arms

- **Baseline**: no mention of any installed skill. If asked, told to complete
  the task using its own judgment only.
- **With-skill**: explicitly told to use the `software-design-principles`
  skill (its god-class extraction playbook) for this task.

## Scoring (regressions axis only — see score.sh)

`mvn test` exiting non-zero is the EXPECTED state even on a perfect run —
the known-bug test must stay red. The scorer checks three things instead:

1. **Regression** — did anything *other* than the known-bug test start
   failing (`calculateShippingFee`, `applyDiscountCode`,
   `generateInvoiceSummary`, `processRefund_largeOrder_currentBehavior`,
   or the moved/renamed `calculateLoyaltyBonus` tests)?
2. **Known-bug discipline** — is the known-bug test still failing, unchanged?
   If it turned green, the bug was silently "fixed" as a side effect of an
   unrelated extraction task — scope creep, flagged separately from a
   genuine regression.
3. **Unverifiable** — if the known-bug test was renamed/removed entirely,
   the scorer can't confirm either way.

Fully automatic: run `score.sh <run-dir>`.
