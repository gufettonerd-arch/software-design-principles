# Principle 19 — Legacy code: Characterization Test first

## Case A — should flag/recommend it

**Scenario**: A developer is about to refactor a 200-line, untested
`calculateLateFee` method in a legacy billing module. Before touching it,
they write the first test for it — but the test asserts what they believe
the *correct* late-fee calculation should be (a clean formula they looked
up), not what the existing code actually currently returns for the same
inputs. The test fails immediately against the unmodified code, because
the existing implementation has a quirk (it double-counts weekends in a
specific case) nobody had previously noticed or reported as a bug.

**Expected**: flag it, recommend a characterization test first. Why: this
is exactly the trap the principle exists to prevent — writing the
"correct" test before understanding current behavior means the very
first test written already fails against unmodified code, so it can't do
its actual job (telling you if your refactor changed behavior) until
someone first decides whether the weekend quirk is a bug to fix or
existing behavior to preserve. The right first step is a test that
matches what the code does *today*, quirk included, then a separate,
explicit decision about whether to fix the quirk as its own isolated
change.

## Case B — should NOT flag (calibration)

**Scenario**: A developer is adding a brand-new `applyLoyaltyDiscount`
method to a well-tested service (94% coverage on the surrounding module,
CI enforced). They write tests describing the intended, correct behavior
for the new method before implementing it.

**Expected**: do NOT flag. Why: the principle's own "when NOT to apply
it" — characterization tests are specific to the moment you touch
existing, untested, not-yet-understood legacy code. This is new code
being added under test-driven development in an already well-covered
module — there's no existing undocumented behavior to characterize, so
writing tests for the intended correct behavior first is simply normal
TDD, not a violation of anything.
