# Real-world validation — legacy batch migration, 2026-09-08

Rounds 1-4 were all god-class *extractions* (move a flow that already lives
in the target codebase into its own component, keep every caller working).
Round 5 is a different shape of task: a real **implementation/migration**
request — port a flow from an old, separate legacy codebase into a modern
sibling project, restructured to match an architectural pattern (async job
queue + internal parallelism) a neighboring flow in the *target* codebase
already established. Same baseline/with-skill/trigger-check methodology
(3 isolated git worktrees, one fixed task sentence, no cross-visibility),
adapted to this shape the same way round 3's instructions anticipated
("substitute that project's repo... this runbook still applies").

This round ran in two passes. Pass 1 is the initial task sentence, run
independently by all three sessions. Pass 2 is a follow-up correction —
new information the orchestrating session gathered *after* pass 1, fed
back to all three sessions identically, on their own branches (not fresh
sessions). Both passes are reported because pass 1's convergent mistake,
and what closing it took, is itself real evidence, not noise to discard.

**Project**: a Spring Boot, multi-module Maven backend (Java, DB2 via
JDBC/JPA, H2-in-DB2-compat-mode for tests) for a travel-industry back
office, receiving a migration of one flow out of its own predecessor: a
separate, older, standalone Ant/Java 7 batch application (direct JDBC,
a SOAP client, JAXB/XSLT-based XML document diffing) that the target
project is gradually absorbing. A sibling flow with the same shape had
already been migrated in an earlier, unrelated piece of work — a full
async job-queue rewrite (single-slot executor, DB-backed job
create/track/cancel, REST start/status/cancel endpoints, internal
`ForkJoinPool` parallelism) — and that migration is what this round's task
explicitly asked all three sessions to mirror.

**Stack**: Java / Spring Boot, Maven multi-module, DB2 (JDBC + JPA), H2
for tests — a different stack from rounds 1-4's Java 7/8 + Struts 1.x +
WebSphere target, though the same broader DB2-based back-office domain.

**Branch/worktree**: 3 isolated `git worktree` checkouts off the same base
commit (verified identical base across all three). That base turned out to
be several commits behind the target branch's actual tip at dispatch time
— a real setup defect on the orchestrating side, caught only after the
fact (see "A methodology defect" below). It affected all three sessions
identically, so the A/B/C comparison stays valid; it's reported as a
process finding, not blamed on any session.

## The task (pass 1)

> Port the legacy flow (a single, large, self-contained class in the old
> batch app — direct JDBC across several DB2 schemas, a SOAP call to fetch
> a document, build/diff/persist a version of that document) into a new
> component under the target codebase's already-migrated module,
> restructured to be async and multithreaded the same way the sibling flow
> already is (job queue + REST start/status/cancel endpoints + internal
> parallelism for processing multiple records concurrently). Do not
> delete/remove any existing code — additive port only. If something
> legacy needs duplicating rather than reusing, leave a short note
> explaining what/why/removal-criterion. The legacy source tree is
> READ-ONLY reference — do not write/modify/delete anything there. Verify
> with a best-effort compile/test run only — no real DB2 or SOAP endpoint
> is reachable in this environment. Commit locally when done; do not push
> or open a PR.

All three sessions got the same pointer to exactly which classes/files in
the target codebase implement the sibling flow's job infrastructure, so
none had to rediscover that pattern from scratch — pass 1 wasn't testing
"can you find the precedent," it was testing what you do once you have it.

## Pass 1 — what all three did

**All three converged, independently, on the same scope decision**: port
the flow's outer control flow faithfully (poll the pending-work table,
resolve each record's owning DB2 schema, apply the eligibility policy,
update the pending-work flag) into the sibling batch's exact job-queue/
`ForkJoinPool`/controller shape — and **stub the actual document-fetch-
and-diff engine** behind an interface with a loudly-failing default,
reasoning that the deep XML build/diff/persist step depends on generated
model classes, XSLT stylesheets, and a SOAP client stub that looked
absent from the legacy source tree and unreachable/unverifiable in this
environment.

**This turned out to be a wrong premise, not a defensible engineering
call** — see "The correction" below. Before that was known, session-by-
session:

- **A (baseline, no skill)**: faithful port, stub behind a plain
  interface + failing default. Reused the sibling's executor bean,
  parallelism helper, and shared DTOs unchanged; duplicated the job
  entity/repository/manager/gateway quintet (each tied to its own table)
  with a one-line rationale each. Caught and fixed two of its own real
  bugs before shipping (a Javadoc comment that broke compilation; a
  `java.sql.Date.toInstant()` call that would have thrown by contract on
  every production invocation). Preserved two real legacy bugs verbatim
  rather than silently fixing them.
- **B (with-skill)**: same faithful port and same stub decision, framed
  explicitly as an Anti-Corruption-Layer/Hexagonal port and named as such.
  Generalized one real shared piece (a progress-accumulator helper with
  zero flow-specific coupling — widened its visibility and reused it
  directly). Largest test suite of the three (81 tests). One deliberate
  correctness-over-fidelity deviation, documented as such: propagates a
  DB exception instead of swallowing it like the legacy code does.
- **C (trigger check, no mention of skills)**: same faithful port, same
  stub shape (arrived at independently, same interface-plus-failing-
  default pattern, no skill vocabulary attached). One real architectural
  disagreement with A/B: gave the new flow its own separate execution
  lane instead of sharing the sibling's single slot. **Did not
  self-invoke the skill** — and said so candidly when asked afterward,
  not dressed up as a considered decision. Also produced this round's one
  genuinely new failure mode: while exploring for context, it read files
  from the *un-isolated main checkout path* instead of its own worktree,
  found real files there its own branch's history doesn't contain, and
  wrote a code comment asserting their existence as established fact —
  caught only when directly challenged, not by its own review. B showed a
  milder version of the same contamination (one dangling cross-reference
  to a class absent from its own branch). A showed none.

## The correction

Before writing up pass 1 as final, the orchestrating session checked the
stubbing decision's premise directly rather than taking it at face value,
and found it didn't hold:

- The "missing" generated model classes (the JAXB document model the
  diff logic operates on) are **not missing** — they're full, checked-in
  source in the legacy tree, confirmed file-by-file against what the
  legacy diff code actually references.
- The one genuinely unusable piece is a *specific* generated SOAP client
  stub bound to a proprietary application-server runtime — not the whole
  integration. A **working, modern, already-in-production replacement for
  exactly that piece** exists in a sibling repo: a plain JAXB + Spring-WS
  client hitting the identical SOAP endpoint, no proprietary runtime
  dependency.
- That endpoint is **not actually unreachable**. The orchestrating
  session live-tested it directly (a repo-local test script + skill built
  for exactly this purpose) and got back a real, substantial, correctly-
  shaped document response — the endpoint is up, reachable from this
  environment, and returns real data for a real, valid test case.

This is a stronger, more concrete correction than anything found in rounds
1-4: not a scope-ambiguity or a preserved-bug finding, but three
independently-reasoned "unreachable/unverifiable/absent" premises that
were each, on direct inspection, false. The task sentence had told all
three sessions the deep step was unverifiable in this environment; that
was wrong, and none of the three challenged it before building around it.

## Pass 2 — the same three sessions, corrected

The orchestrating session sent all three sessions (on their own branches,
not fresh sessions, to avoid re-paying setup cost) the same corrected
information: the dead-end confirmed as dead, the working modern-client
pattern's exact shape, the live-reachability proof with a worked example,
and the now-confirmed-present model classes — then asked each to revisit
its stub decision. No session was told which skill to use or not use;
that disposition carried over unchanged from pass 1 (A still off, B still
on, C still untouched).

**All three replaced the stub with a real, working engine, and — this
time — verified it with genuine live network calls, not just a compile.**
Session-by-session:

- **A**: built the fetch step as a hand-rolled SOAP envelope over a plain
  HTTP client rather than the suggested modern SOAP-client library,
  because this environment has no dependency-resolution network access at
  all and only an old, incompatible version of that library was already
  cached locally — a reasoned, documented substitution with identical
  wire behavior, not a shortcut. Copied the (now confirmed-present) model
  classes mechanically. Live-verified twice against the real endpoint:
  first call inserted a first version, second call correctly detected
  "unchanged" via a real diff against what the first call had just
  stored — a real round trip, not a canned response. Found and fixed two
  real bugs only exposed by actually running the pipeline: an XSLT
  stylesheet calling a Java extension function the JDK's built-in
  transformer can't compile (traced to its exact cause, one optional
  branch neutralized with a documented reason), and a missing package-
  metadata file that broke JAXB namespace resolution. 32/32 tests green.
- **B**: found that the suggested modern SOAP-client library was, in this
  specific case, already present in the local dependency cache from
  unrelated prior work — verified this directly rather than assuming
  either way — and used it for real, matching the sibling repo's
  production pattern exactly. Hit the **same XSLT/extension-function bug
  A found, independently** and fixed it the same way; then introduced and
  caught a second bug in its own fix (an illegal construct in an XML
  comment that broke Spring's startup for the *entire* test package, not
  just its own tests — caught because unrelated sibling-flow tests
  started failing too, a real "this is bigger than my change" signal).
  Refused to report a test count it hadn't actually re-confirmed after
  that fix when first asked, waited for a real rerun, then reported
  83/83 green with the actual command output. Live-verified against the
  real endpoint, 2/2.
- **C**: same real engine, same live verification (2/2 against the real
  endpoint), largest total test count (47/47 on every docversioning-
  related test, run alongside the sibling flow's own suite to confirm no
  regression there either). Caught a wiring bug (a diff-engine class
  missing a framework annotation, only surfaced once it ran the *whole*
  suite rather than the subset that happened to route around it) and a
  test that needed updating now that the seam it exercised made a real
  network call instead of returning a canned value.

**Independently confirmed, not just self-reported**: the orchestrating
session re-ran a clean compile against all three worktrees' final commits
from outside their own sessions after pass 2 and got `BUILD SUCCESS` on
all three.

## Comparison

**Did the skill catch the wrong premise that baseline and the
trigger-check session missed?** No — and this is the most important
result of the round. All three sessions, skill-guided or not, accepted
the same false "unreachable/absent" premise in pass 1 without challenging
it. The correction came from the *orchestrating* session choosing to
verify a claim before trusting it, not from any of the three arms. This
extends, rather than complicates, the standing finding from rounds 1-4:
the skill's effect is about making a given judgment legible and
checkable — it did not, here or in any prior round, catch a wrong premise
none of the sessions questioned. A generic instruction to verify
"unreachable" claims before building around them, in the task sentence or
the skill's own checklist, would be worth testing directly in a future
round.

**Once corrected, did all three converge again?** Yes, more strongly than
in pass 1 — not just on the same scope decision but on the same specific
technical failure (the XSLT extension-function incompatibility), found
independently by two of three sessions with no visibility into each
other's work, fixed the same way both times. That's a real, repeated
signal that this particular gap is a property of the actual legacy code,
not an artifact of one session's approach.

**Where did pass 2 differ across sessions?** Mostly in verification
discipline under pressure, not engineering judgment: B was the only one
of the three to explicitly decline reporting a test count it hadn't
actually just confirmed, instead of estimating or reusing a stale number
— worth noting on its own, independent of whether it happened to be the
with-skill arm. A's dependency substitution (hand-rolled SOAP envelope vs.
the sibling's client library) was a real, reasoned, environment-forced
deviation, not a shortcut — the other two didn't need it only because a
compatible library build happened to already be cached locally for them,
which is closer to lucky than better.

**A methodology defect, reconfirmed from pass 1**: all three worktrees
were still on the stale base commit through pass 2 — a real setup gap the
orchestrating session chose not to fix mid-round (rebasing risked real
conflicts in files all three sessions had already modified, for a gap
that turned out not to block this round's actual work). Flagged again
here rather than treated as resolved, since it should be fixed *before*
dispatch in a future round, not worked around after the fact.

**Trigger accuracy, still 1-for-3 across rounds**: C did not self-invoke
the skill in either pass of this round, consistent with its pass-1 report
of this being a real gap rather than a considered call. Round 1's
trigger-check session self-invoked; round 2's and this round's didn't.
Leaning further toward "not a reliable auto-trigger" on a task shape
(large legacy-class extraction/port) that should be a clean hit.

## Verdict

Would trust this again for a "port a legacy flow, don't touch the
original, match an existing sibling pattern" task shape — once the
premise it's built on is actually verified, not assumed. The single
biggest lesson of this round isn't about the skill at all: three
independent engineering judgments (one with the skill, two without) all
accepted the same unverified "this is unreachable" claim without
challenging it, and the correction only came from deliberately testing
that claim before trusting it. What would make a round 6 better: (1)
verify worktree base commits against the intended tip before dispatch —
still not fixed after two passes; (2) put "verify claims of
unreachability/absence before building around them" directly in the task
sentence or the skill's checklist and see whether that changes the
pass-1 outcome; (3) pin the "shared vs. dedicated execution lane"
disagreement between sessions, the same way round 3 closed round 2's
caller-rewiring gap.
