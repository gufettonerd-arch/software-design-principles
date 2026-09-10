# Real-world validation — round 6, 2026-09-10

**Project**: the same target codebase as round 5 — a Spring Boot,
multi-module Maven back-office backend. Sixth real-world round, second
one on this codebase (round 5 was the first, a different module and a
different task shape — a port/migration, not an extraction).

**Stack**: Java, Spring Boot, Maven multi-module, DB2 (H2 in tests) — a
genuinely different flavor from every prior round: rounds 1-4 ran on a
legacy Struts 1.x/WebSphere 8.5 codebase, round 5 was a Spring-WS SOAP
integration. This round's target does neither I/O nor persistence — it's
pure in-memory string parsing (one method, no network, no database),
closer to a "classic" extraction candidate than anything tested before.

**Branch/worktrees**: 3 isolated `git worktree`s off the same verified
base commit — verified via `git merge-base` against the tip before
dispatching any session, per the process fix round 5 added.

**Target, and why it was picked**: a ticket-parsing module's primary
`TicketFormatAParser` class (1044 lines) — a real, undocumented, single
giant `processDocuments` method (not a multi-method god class like
rounds 1-2; a **god method**) with no sub-methods, no existing tests, no
fixture data anywhere in the module, and exactly one real caller.
Picked deliberately to test whether the "verify before you build around
it" checklist item — added to the skill after round 5 found all three
of that round's sessions independently accept the same false
unreachable/unverifiable claim — actually changes a pass-1 outcome. The
setup: this module's own documentation describes downloading ticket
files from an external network share at a specific internal hostname,
which primes an assumption that real ticket data requires that network
share. It doesn't — `processDocuments` takes a plain `String` already
read elsewhere — but nothing in the task sentence says so; whether a
session notices this on its own, the same way round 5's sessions should
have noticed their dependency was reachable, was the actual test.

## The task

> In the ticket-ingestion module's TicketFormatAParser class
> (service/parsing/TicketFormatAParser.java, ~1044 lines), extract the
> ticket-parsing flow — the processDocuments method and whatever
> internal structure it needs — into a properly separated structure,
> preserving exact current behavior for its one real caller
> (TicketParsingOrchestrator.parsingAndSave, which calls
> ticketFormatAParser.processDocuments(docOut, fileToParsing.fileContent(),
> fileToParsing.fileName())). Update that caller if the extraction changes
> TicketFormatAParser's public shape. Verify your extraction actually
> parses real ticket data correctly before calling it done — don't settle
> for a syntax-only check.

All three sessions: work only inside their own worktree, no visibility
into the others (told explicitly, after round 5's cross-contamination
incident), best-effort module-scoped compile instead of a full
multi-module build, commit locally when done, don't push, don't ask
clarifying questions.

## Session A — baseline

No skill. Reduced the parser class to a thin facade delegating to a new
extracted class (one private handler method per ticket record type, a
small context object for per-call mutable state). Merged two near-
identical record-handler branches (near-identical ~100-line blocks)
after diffing them line-by-line to confirm the only real difference was
the literal marker value. Converted a double-brace-init `HashMap` to
`Map.of(...)`.

**What it found for verification, unprompted**: a real, pre-existing
test in a *different* module — an integration test which feeds a real
embedded ticket dump through the full Spring Boot flow and asserts exact
field-by-field equality against expected parsed entities. Ran it on the
unmodified code first (2/2 pass, established as the actual baseline),
then again after the extraction (2/2 pass, identical). Also ran the full
suite of that other module before and after (74 tests; 7 pre-existing
failures in an unrelated module, reproduced identically on unmodified
code via `git stash` to confirm they predate this change).

**Anything notable**: didn't fabricate synthetic data for the record
types the real fixture doesn't cover — verified those by careful
line-by-line comparison against the original instead, and said so
explicitly rather than presenting partial coverage as complete.
Preserved a real latent bug (four fields persist across calls on the
singleton bean, so a file missing a certain header line can silently
inherit dates from whatever file was parsed before it) rather than
silently fixing it, and documented it.

## Session B — with-skill

Used `software-design-principles`, cited playbook steps by number
(0, 1, 2, 3, 4, 5, 7, 9 — deliberately *not* applied, with reasoning —
10, 13). Same facade + extracted-parser shape as A. Wrote a
characterization test first against the *original* code (green), then
re-ran it unchanged against the extracted code (still green).

**The gap**: reported searching the repo for real ticket data and
concluding none exists ("checked via targeted grep/find before
starting"), then hand-built a synthetic-but-format-faithful ticket by
tracing the original code's `substring`/`StringTokenizer` offsets.
That search missed the real fixture A found. Caught and fixed a real
near-miss of its own before committing: a first-draft consolidation of
one branch would have turned two independent sequential `if`s into an
`else if`, silently changing behavior for the rare case where a value
matches both conditions — caught while writing, corrected back to match
the original's sequential-if structure.

**Findings matching A and C independently** (see Comparison): a
reference-equality string comparison, a date-formatter pattern bug
(minute-of-hour instead of month), the cross-call singleton state
leak — all three sessions found and preserved (not fixed) all three,
independently.

## Session C — trigger check

**Self-invoked `software-design-principles`** ("since the task is
exactly its target scenario") — matching round 1's C, not round 2's or
round 5's. Same facade-plus-extracted-parser shape, different naming.
Distinguished two similar-looking record handlers explicitly (a boolean
flag) after noticing they looked identical but weren't (one defaults an
empty fare to `"0.00"`, the other doesn't) — A and B also kept these two
handlers separate, so this wasn't a unique catch, but C is the only one
that documented *why* they can't be merged.

**Same gap as B**: also reported checking for real ticket data via
"a raw grep/find sweep of the repo" and also concluded none exists, also
missing the real fixture. Built its own standalone differential harness
(not committed) comparing the untouched original against the extraction
on identical hand-crafted input, diffed byte-for-byte, 9 cases covering
every record type plus edge cases (the two-handler divergence, all four
sub-branches of one record type, the cross-call state leak). **Caught a
real bug in its own test harness**: an early draft used a 3-character
header line, one character short of the dispatch guard's length check,
so that branch silently never fired and the "skip path" test showed the
wrong status with no warning logged — caught by noticing the *absence*
of an expected log line, not by a red test.

## Comparison

**The result the round was designed to test, and it didn't hold**: two
of three sessions — including the one with the skill's own
"verify before you build around it" checklist item live — searched for
real verification data, concluded (wrongly) that none exists, and built
around that false conclusion instead of finding it. The one session that
found the real fixture was baseline, with no skill guidance at all.
Independently re-verified from outside all three sessions (not just
trusting A's report): the real fixture does exist, in a sibling module,
and passes 2/2 clean against **all three** sessions' extracted code, not
just A's — confirming all three extractions are behaviorally correct
regardless of which verification method each session used to convince
itself of that.

**A plausible reason, not a confirmed one at the time** (see Addendum —
extending this to N=2 the same day found it doesn't hold up as a
repeatable pattern): A's search wasn't scoped to the module under edit;
B and C's searches (explicitly, in both reports) were framed around
"does a fixture exist for this module" — and the real fixture lives in
a sibling module (the one that actually assembles and runs the
ticket-ingestion module as a dependency), not inside the module being
edited. The "verify before you build around it" checklist item's own
wording and its one worked example (a file, a dependency, an endpoint,
a cache) center on external dependencies and environment claims — the
exact shape of round 5's SOAP case — not on "search sibling modules of
a multi-module repo for existing test fixtures." That's a narrower
trigger surface than this round's failure mode needed.

**Everything else converged**: same extraction shape (facade class +
extracted parser class) across all three, same three real latent bugs
found and preserved (not silently fixed) by all three independently —
the reference-equality check, the date-formatter month/minute mixup,
the cross-call singleton state leak — and all three verified clean
against the real fixture once checked from outside. No regressions, no
behavior changes, in any of the three.

## Addendum — N=2 replication, same day

The Comparison section above flagged its own explanation as "not
confirmed... not done here without a second data point." Got that
second data point the same day, cheaply: 2 isolated read-only
with-skill probes (no worktree, no extraction, no commit — just the
verification-search step in isolation) on a matched-shape second
target, the second ticket-format parser in the same module (same
package, same god-method shape, and confirmed beforehand to have the
identical trap: a real fixture sitting in the same sibling module that
B and C missed for the first parser).

**Both probes found it immediately.** Both searched repo-wide, not
scoped to the module under edit, both located the real fixture method
**and** a second regression-fixture method pinned to a real historical
production bug, both explicitly quoted the same "verify before you
build around it" checklist clause as what drove the search before
assuming synthetic data was needed.

**This does not confirm the round's explanation — it undercuts it.**
Combined tally across both sessions of this exact search behavior:
**2 misses (round 6's B and C) + 2 hits (this replication) = 2/4.**
That's not a repeatable, checklist-shaped gap the way principle 18's
was (which went 0/5 clean across every probe before its fix, and 3/4
after) — it's run-to-run variance on a specific search task, closer to
the Strategy Case A flip or the Anti-Corruption Layer CONTRADICTED
result that didn't repeat at seed4 earlier in this project's history.
The correct read: **round 6 alone overstated a pattern from N=1.** The
checklist item's wording may still be worth broadening someday, but not
on the strength of this evidence — there's no clean before/after
delta here the way there was for principle 18 or Fail Fast, just two
runs each way.

## Verdict

The skill's process discipline (playbook step citations, a written
characterization test, documenting rather than silently fixing
preserved bugs) showed up in B and C same as prior rounds. What the
round set out to test — whether the post-round-5 "verify before you
build around it" fix changes a pass-1 outcome — came back negative on
its own N=1, but a same-day N=2 replication on a matched second target
came back positive both times, so the honest verdict is **inconclusive,
not negative**: this specific search behavior varies run to run, and
round 6 by itself wasn't enough data to call it a real, fixable gap.
Trust the extraction itself from any of the three original arms — all
three are independently confirmed correct against real data, regardless
of which verification method convinced each session. Don't trust either
"the checklist fix doesn't work" or "the checklist fix works" as
settled from this round; a real answer needs a larger, properly isolated
sample on this specific behavior, not two more rounds' worth of
full extractions.
