# Principle 15 — Strangler Fig Pattern

## Case A — should flag/recommend it

**Scenario**: Eight months ago, a team started migrating the pricing
engine to a new implementation and moved the old code into a
`pricing/legacy/` package "to be removed once the new one's proven." The
new implementation now handles most traffic, but `pricing/legacy/` is
still referenced from 12 call sites across the codebase, nobody can say
which of those 12 still need it versus are just stale, and there's no
written criterion for when it's safe to delete. It comes up in nearly
every sprint planning as "we should really clean that up sometime."

**Expected**: flag it, recommend applying Strangler Fig discipline. Why:
this is the pattern's own cautionary example almost exactly — code moved
into a deprecated/legacy package with no explicit removal plan risks
staying there indefinitely, which is exactly what's happening here (8
months, no criterion, no visibility into which callers still need it).
The fix isn't a rewrite; it's making the completion criterion explicit
and tracking the remaining callers down to zero.

## Case B — should NOT flag (calibration)

**Scenario**: A small, self-contained date-formatting utility class (60
lines, one public method, three call sites, no external dependencies) is
being replaced with a call to a standard library function instead. The
change is made directly in one PR: old class deleted, three call sites
updated, tests pass.

**Expected**: do NOT flag. Why: the principle's own "when NOT to apply
it" — for a small, well-isolated module with no operational risk (three
known call sites, no ambiguity about what depends on it, no risk of
breaking production traffic mid-migration), a direct replacement is
normal and faster than staging an incremental migration. Strangler Fig
earns its overhead when the blast radius or the migration timeline is
large enough that a direct swap is risky; neither is true here.
