# Real-world validation — round 7, 2026-09-15

**Project**: a fourth, unrelated real codebase — the modern Spring Boot
rewrite of the legacy Struts app rounds 1-2 targeted. Seventh real-world
round, first one on this codebase; only prior contact with it this
session was exploratory (reading a SOAP client as a reference pattern
for round 5's work), never as a round's own target.

**Stack**: Java, Spring Boot, Maven multi-module — a fourth distinct
stack for this benchmark (after rounds 1-2's Struts 1.x/WebSphere,
rounds 3-4's COBOL-generated CICS-style code, rounds 5-6's back-office
backend). Target module: the application's main module.

**Branch/worktrees**: 3 isolated `git worktree`s off the same verified
base commit — verified via `git merge-base` against the tip before
dispatching any session.

**Target, and why it was picked**: a legacy response-converter class
(688 lines, ~40 methods) — a classic multi-method god class (unlike
round 6's single-method god method), doing dozens of unrelated
field-mapping conversions (travel services, accommodation, transports,
passengers, references, agency, brand...) in one class. 2 real callers,
and — unlike rounds 5-6's zero-test targets — a real, substantial
existing test file already covers it (968 lines). Scope was pinned up
front to the accommodation/hotel-mapping sub-flow (the main entry method
plus 14 private helpers used only by it, confirmed via grep before
writing the task sentence that none of them are shared with other flows
except one money-formatting helper, which is — deliberately left out of
the helper list, and how each session chose to handle that became the
round's main finding).

## The task

> In the legacy response-converter class (~688 lines), extract the
> accommodation/hotel-mapping flow — the toAccommodation method and the
> private helper methods it alone uses (14 named helpers) — into a
> properly separated component, preserving exact current behavior for
> the converter's real callers. Verify your extraction against the
> module's real existing tests (there's an existing test file for this
> converter) before calling it done — don't settle for a syntax-only
> check.

All three sessions: work only inside their own worktree, no visibility
into the others, best-effort module-scoped build instead of a full
build, commit locally when done, don't push, don't ask clarifying
questions.

## Session A — baseline

No skill. New class for the extracted flow, main method renamed per the
package's own existing `*Converter`/`new XConverter().x(...)`
convention (already used by several sibling classes in the same
package). All 14 listed helpers moved verbatim.

**The shared-helper question**: found the money-formatting helper is
also used by a different, not-yet-extracted flow, so kept it on the god
class, changed its visibility to package-private static (it touches no
instance state), called directly from the new class — no duplication,
smallest diff.

**Verification**: found the existing test file (968 lines) is
class-level disabled. Didn't accept that as "no test exists" —
temporarily re-enabled it, ran it against the refactored code, then
`git stash`'d back to the *original* pre-extraction code and ran the
identical (locally-patched-for-missing-fixture-data) test file again:
**byte-identical pass/fail/error outcome both times**, repeated across
3 rounds of progressive fixture patches. Restored everything to the
original committed state afterward (confirmed via `git status`/
`git diff --stat`, zero test-file changes kept). Full module suite
after: 890 tests, 0 failures, 0 errors.

## Session B — with-skill

Used `software-design-principles`, cited playbook steps 0, 1, 2, 3, 4,
5, 7, 8, 9-10 (n/a, noted why), 12 (skipped, noted why), 13. New class
for the extracted flow, same rename/convention choice as A.

**The shared-helper question — the real divergence**: per the
playbook's own Step 5 (shared code), **duplicated** the money-formatting
helper into the new class with a `REFACTOR NOTE` documenting the
removal criterion (remove once the other flow is also extracted),
rather than A/C's shared-static approach. Both are legitimate; this is
the "conformance vs. improvement tension" axis this project has tracked
since round 5 — B followed the playbook's prescribed pattern for a
shared dependency literally, A and C independently found a different,
equally valid solution neither one was told to use.

**Also unique to B**: wrote a **new, permanent test file** (11 tests,
committed) exercising the extracted class directly, reusing the
existing (disabled) test's fixtures/assertions where they still matched
real behavior. A and C did the same kind of exploratory before/after
comparison as verification, but reverted all of it — neither left new
test coverage behind. B additionally caught **two specific
stale-expectation bugs in the disabled test that A and C didn't
report**: one disabled test expects HTML-decoded text but production
actually returns HTML-entity-encoded text; another disabled test
expects a nonzero placeholder value but the real code treats that input
as "no value" and returns null. Also noticed (and correctly did *not*
act on) an unrelated branch in the repo that deletes this whole file as
part of a larger experimental rewrite — logged as an observation, not
treated as a reason to change plans.

**Verification**: same "found it's disabled, don't trust that as the
answer" move as A — ran it before/after, found the *whole* class fails
on an unrelated pre-existing bug (a date-parsing pattern mismatch)
before ever reaching accommodation, so pivoted to testing the new
class's entry point directly instead. Strongest single piece of
evidence: diffed the original method body against the new class's body
via `git show` — **zero differences**, a mechanical guarantee of no
logic drift, not just a test-passing claim. Full module suite: 901
tests, 0 failures, 0 errors (901 vs. A/C's 890 — the 11 new tests).

## Session C — trigger check

**Did not self-invoke any skill** — opposite of round 6's C, which
self-triggered on a similarly-shaped task. New class for the extracted
flow, same convention choice as A/B independently. Same shared-helper
decision as A (shared package-private static, no duplication) —
landing on the same answer as baseline, not the skill-guided approach.

**Verification**: essentially identical methodology to A — found the
same disabled test class, discovered the same two unrelated
pre-existing bugs (the date-parsing mismatch, a null-array crash on a
field the fixtures never set) blocking the whole test class, patched
them locally as scratch-only fixes, ran before/after against a
locally-patched copy of the original pre-extraction code, got
byte-identical results, then fully reverted every scratch change. Full
module suite: 890 tests, 0 failures, 0 errors.

## Comparison

**Diagnosis converged completely, independently, across all three.**
All three found the same disabled test class, the same root cause (a
date-parsing pattern mismatch) blocking the *entire* test class
regardless of accommodation, and used the same core technique to get
real signal anyway — a same-fixture before/after comparison against the
unmodified original, proving zero behavior drift rather than trusting a
green run that was never achievable to begin with.

**The real, reproducible finding is the shared-helper split**: 2 of 3
sessions (A, baseline; C, trigger-check, no skill) independently chose
to share it as a package-private static method — no duplication. The
one with-skill session (B) duplicated it with a `REFACTOR NOTE`,
following the playbook's Step 5 guidance literally. Neither choice is
wrong — a shared static helper with zero instance-state dependency is
a legitimate alternative to Step 5's duplicate-with-note pattern, and
the playbook itself doesn't rule it out — but it's a genuine, repeatable
divergence traceable directly to the skill's specific prescribed
pattern, not incidental variance. Worth watching whether this recurs
if a future round hits another shared-dependency extraction.

**B's edge, independent of the skill question**: the only session that
left permanent test coverage behind, and the only one that caught two
specific stale-expectation bugs in the disabled test (not just the
class-blocking date bug all three found) — both plausible products of
writing new assertions against real behavior rather than only
comparing pass/fail signatures.

**Everything else matched**: identical extraction shape, identical
naming convention choice (independently, all three landed on the
package's existing convention without being told to), identical
real-caller handling (neither caller touches the extracted methods
directly, so none of the three needed to change any caller code), and
— verified independently by the orchestrating session running all
three module test suites from outside their own reports, not just
trusting each one's self-report — all three genuinely compile and pass
clean (890/890/901 tests, 0 failures across all three).

## Verdict

The skill's contribution this round wasn't catching anything baseline
missed — all three sessions independently diagnosed the same
pre-existing test-suite problem and used the same rigorous
before/after technique to route around it, with or without the skill.
What the skill did demonstrably change was the shared-dependency
decision (duplicate-with-note vs. shared-static, a real divergence
traceable to Step 5) and, separately from that, the with-skill session
happened to be the one that left new test coverage behind and caught
two extra stale-expectation bugs — plausibly a byproduct of its more
thorough Step 3/7 process, not proof the skill itself finds bugs
baseline can't. Consistent with every round since round 3: the skill's
most reliable effect is making already-good judgment legible and
documented (a REFACTOR NOTE, cited playbook steps, a new test file),
not correcting judgment a careful session gets wrong. Trust the
extraction from any of the three arms — independently reverified from
outside all three, not just taking their reports at face value.
