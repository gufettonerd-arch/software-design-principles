# Quality benchmark — task

Same fixture, seventh flow: `chkShipElig` — deliberately written like real
legacy code, not like the other flows in this fixture. Eight levels of
brace nesting, no guard clauses, four magic number literals (`0`, `30`,
`20`, `5`), three magic string literals (`"IT"`, `"FR"`, `"DE"`), abbreviated
names (`c`, `o`, `w`, `cc`, `ok`), and redundant null checks on `c`/`o` left
over from before `requireCustomer`/`requireOrder` existed (those helpers
already throw on not-found, so the checks can never be false). This is
exactly the kind of code the playbook's Step 7 exists for.

## Instructions given to both arms, verbatim

> In `src/main/java/bench/GodClass.java`, extract `chkShipElig` into its own
> class called `ShippingEligibilityService` in the same package (`bench`).
> Keep the method named `chkShipElig` on the new class. Everything else in
> `GodClass` must keep working exactly as before.
>
> You may clean up the extracted method as part of this — naming, nesting,
> magic numbers — if you think it's warranted. Whatever you do, the method
> must return the exact same result for the same inputs as it does today;
> a cleanup is not license to change behavior. Run `mvn test` before you
> consider the task done.

Deliberately open-ended on whether to clean up — neither arm is told to,
neither is told not to. That's what this axis measures.

## What differs between arms

Same as the other variants: baseline told not to consult any skill;
with-skill arm told to use `software-design-principles` and its playbook.

## Scoring — three checks, see `score-quality.sh`

1. **Regression** (reused) — did any of the other flows, or the known-bug
   test, change status?
2. **Behavior preserved** — eight reference input/output pairs computed from
   the untouched method, checked via reflection against
   `GodClass.chkShipElig` after the run (`VerifyQuality.java`, injected only
   for scoring, removed after).
3. **Readability delta** — `measure-quality.js` computes max brace-nesting
   depth and magic-literal count on `chkShipElig`'s body in
   `ShippingEligibilityService.java`, compared against the fixture's own
   baseline (depth 8, 4 magic numbers, 3 magic strings). Purely mechanical,
   no judgment call — a proxy for Step 7, not a full reading of it. A future
   iteration should add an independent LLM-judge pass grading the more
   qualitative parts of Step 7 (do the names say what they hold, do the
   comments survive "if I delete it, does it still make sense") using the
   step's own wording as the rubric — not built yet, this run only measures
   what a script can measure without opinion.
