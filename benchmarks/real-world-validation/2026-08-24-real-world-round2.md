# Real-world validation — the target codebase (round 2: biggest class), 2026-08-24

## Before starting

- [x] Pick **one** real flow or class you already suspect needs work —
      don't manufacture a task, use something you'd do anyway.
- [x] Create a branch or worktree for this.
- [x] Note the project's stack here.

**Project**: the target codebase (a travel-document generation app)
**Stack**: Java 7/8, Apache Struts 1.x, IBM WebSphere 8.5, Ant build, ISO-8859-1 source encoding, JUnit 4

This is a second, independent round on the same project (see
`2026-08-24-real-world-round1.md` for round 1). Round 1 picked a mid-size class from a
real ticket; this round targets the single biggest class in the repo instead
— `legacy.app.common.CommonUtils`, **14719 lines**, confirmed via
`find . -name "*.java" | xargs wc -l | sort -rn`. Round 1's Verdict flagged
scope ambiguity as the biggest source of divergence between sessions, so
this round's task sentence pins the exact method list up front.

**Branch/worktree**: three isolated git worktrees off `master` (<base-commit>), one per session:
- A (baseline): `worktree-a`
- B (with-skill): `worktree-b`
- C (trigger check): `worktree-c`

Target flow: `sendNotificationEmail`, the email-notification path in
`CommonUtils` — entry point plus 9 private helpers (MIME assembly, recipient
resolution, marketing-cloud routing, a DB-backed param lookup). Real external
callers (confirmed by repo-wide `grep -a`, required since a plain `grep`
silently misreads these ISO-8859-1 files as binary and produces false
negatives — a gotcha discovered mid-round and folded into this round's own
task prompt): `PreviewActionA.java:180`, `DocumentPreviewAction.java:1019`
call `sendNotificationEmail`; `ConsentAction.java:108` calls the sibling
`sendNotificationEmailNoMktCloud`.

## The task

> In `legacy.app.common.CommonUtils`, extract the `sendNotificationEmail`
> email-notification flow into a properly separated component under
> `legacy.app.service`, preserving exact current behavior for every
> caller. In scope: `sendNotificationEmail`, `sendNotificationEmailNoMktCloud`,
> `buildMimeMessage`, `resolveRecipientEmail`, `buildMailText`,
> `sendPreB2BEmail`, `sendPostB2BEmail`, `setAttachmentFileName`, `isMktCloudEnabled`,
> `isMktCloudParamEnabled`, `isMktCloudCallCenter`. Do NOT move
> `isAgencyDirectSales` (shared by 5+ other unrelated flows — must
> stay). Before deleting anything from `CommonUtils.java`, grep the whole
> repo for real callers, using `-a` to avoid the binary-misdetection trap.

All three sessions were fresh (no shared context), told not to run the full
Ant/Docker/WebSphere build (best-effort `javac`/grep verification instead),
to commit locally when done but not push, and not to ask clarifying
questions.

## Session A — baseline

Fresh session, explicitly told **not** to consult any skill.

**What it did**: New `service/NotificationEmailService.java` (public, 9
orchestration methods) + `service/NotificationEmailRepository.java`
(package-private, `isMktCloudParamEnabled`, reused `DbConnectionProvider.getDbConnection()`
instead of re-duplicating the JNDI lookup, try-with-resources).
`CommonUtils.java`: REFACTOR NOTE comment only, every original method left
in place byte-for-byte — after an earlier pass had incorrectly deleted
`sendNotificationEmailNoMktCloud` believing it dead (a stale, `-a`-less grep
had missed its one real caller), A caught its own mistake on a second,
corrected grep pass, reverted `CommonUtils.java` to `HEAD`, and redid the
edit as comment-only. Rewired **one** of the flow's real callers
(`DocumentPreviewAction.java`) to the new service; left `PreviewActionA.java`
and `ConsentAction.java` still calling the (unchanged, still-working)
`CommonUtils` methods directly.

**Anything notable**: The self-caught grep mistake is the most interesting
thing A did — it's a direct instance of the exact pitfall this round's task
sentence had already warned about, independently rediscovered and fixed
without being told twice. No new tests added. No commit made (this
session's copy was reverted/redone mid-flight, final state committed
locally in its worktree same as B/C).

## Session B — with-skill

Fresh session, told to use `software-design-principles` and follow the
god-class-extraction playbook.

**What it did**: New `service/NotificationEmailService.java` (all 10
methods) + `service/MktCloudParamRepository.java`. `CommonUtils.java`: purely
additive — a `REFACTOR NOTE` above each of the 10 moved methods, `git diff
--stat` confirms 30 insertions / 0 deletions, nothing removed. **Rewired
zero callers** — `PreviewActionA`, `DocumentPreviewAction`, and
`ConsentAction` all still call `CommonUtils` directly; the new service
exists but nothing in the codebase uses it yet.

**Anything notable**: Found and correctly handled a real shared-code case A
and C didn't flag as explicitly: `setAttachmentFileName` is also called from
`CommonUtils.sendSimpleEmail()`, an out-of-scope flow — duplicated it with
its own `REFACTOR NOTE` naming the remaining caller (playbook Step 5), rather
than silently taking it or leaving a dangling shared dependency. Also
independently found and preserved three mutable shared static fields
(`attachmentNameAgency`/`Cliente`/`Preventivo`) that are runtime-reloaded
from DB elsewhere in `CommonUtils` — read them via `CommonUtils.fieldName`
at call sites instead of duplicating, specifically to avoid a silent-breakage
bug where a duplicated copy would never receive the reload. Dropped dead
`Class.forName(...)`/unused `Properties` leftovers in the DB lookup
(non-behavioral). Narrowed the repository's catch to
`SQLException | NullPointerException`, kept the NPE deliberately for a
genuine `.trim()`-on-null-column risk in the original.

**Did it follow the playbook's actual steps?** Yes: Step 0 (encoding +
dependency mapping) surfaced the `setAttachmentFileName` shared caller before
touching anything; Step 5 (duplicate-with-note, not move) applied correctly;
Step 7/8 (Service/Repository split, targeted log tags instead of generic
`"CommonUtils - error"`); Step 9/10 (narrowed exception, hardening: bind
parameter instead of string-concatenated SQL, try-with-resources replacing
a leaked `PreparedStatement`/`ResultSet`); Step 13 (fresh-eyes re-review,
explicitly reported). Steps 3/11 (dedicated tests) explicitly skipped and
called out as a known gap rather than silently omitted — no existing
JavaMail/JNDI mocking infrastructure in this repo, out of the stated time
budget.

## Session C — trigger check

Fresh session, no mention of skills either way — just "do the task as you
normally would."

**What it did**: New `service/MailNotificationService.java` (public
orchestration) + `service/MailNotificationRepository.java` (package-private) +
**new characterization tests** — `MailNotificationServiceTest.java`,
`MailNotificationRepositoryTest.java`, plus a SQL fixture, 4 tests total,
verified passing in isolated-JVM-per-test mode (matching Ant's actual
`forkmode="perTest"`, not just a bulk run). `CommonUtils.java`: REFACTOR NOTE
above `sendNotificationEmailNoMktCloud` only (not all 10 methods — narrower
documentation than B, though the same "leave originals in place" choice).
**Rewired all three real external callers** (`PreviewActionA`,
`DocumentPreviewAction`, `ConsentAction`) to the new service — the only one
of the three sessions to fully cut the codebase over.

**Anything notable**: Caught a false-positive lead the task's own grep
instructions could have walked straight into — `MktCloudClient.java`
has its own **unrelated** private methods with the identical names
(`setAttachmentFileName`, `isMktCloudCallCenter`), confirmed via read that they
don't call `CommonUtils`'s versions and are a coincidental naming collision,
not a real shared caller. Same hardening instincts as B (try-with-resources,
narrowed catch list including `NullPointerException` for the same
`.trim()`-on-null risk, dead `Properties` object dropped) — arrived at
independently, without the skill. Explicitly left two string-concatenated
SQL clauses as-is, reasoning that `key` is always a hardcoded literal from
the caller (never user input), so "fixing" it would be a scope-expanding
security change rather than a same-behavior extraction — same judgment B
made, same conclusion, different route.

**Skill usage**: Did **not** self-invoke `software-design-principles`. Its
own stated reasoning: the project's own memory file
(`feedback_extraction_flow_convention.md`) already gave the exact
extraction convention, and it cross-checked that convention directly against
real precedent code already in the worktree (`VoucherService`/
`Repository`, `DbConnectionProvider`) instead of loading the skill. This is
the opposite trigger-check result from round 1, where Session C *did*
self-invoke the skill on the same kind of task.

## Comparison

- **Extraction shape converged, integration didn't.** All three sessions
  independently arrived at the same Service+Repository split, the same
  `DbConnectionProvider.getDbConnection()` reuse, the same
  "leave `CommonUtils` originals in place, REFACTOR NOTE instead of
  delete/stub" call (all three found real external callers via the corrected
  `-a` grep and treated that as the reason not to delete). But how far each
  session carried the extraction *into the rest of the codebase* varied a
  lot: **C rewired all 3 real callers**, **A rewired 1 of 2**, **B rewired
  0** — despite an identical task sentence and identical scope list. B's
  result is a fully-built, fully-verified, entirely unused new service; C's
  is the only one where the extraction actually changes what runs in
  production. The task sentence said "preserving exact current behavior for
  every caller," which all three satisfied (nothing broke), but only C
  treated that as also meaning "and make the callers use the extraction" —
  a second scope ambiguity round 1's fix (pinning the method list) didn't
  anticipate, because it's about caller migration, not extraction scope.
- **Skill-on (B) vs. skill-off (A)**: broadly comparable code quality —
  both narrowed exceptions, both used try-with-resources, both preserved the
  same kind of latent bugs. B's one clear edge: it found and correctly
  handled a second real shared caller (`sendSimpleEmail()` also using
  `setAttachmentFileName`) that neither A nor C's reports mention checking for —
  though since both A and C also left the original `CommonUtils` methods
  physically in place, that caller keeps working regardless; B's REFACTOR
  NOTE just documents the dependency explicitly where A/C's don't. A's most
  interesting move (self-correcting a grep mistake mid-task) is a data point
  about carefulness, not about the skill — nothing in B's transcript
  suggests the skill was *why* A caught its own error elsewhere in the
  round.
- **The C vs. round-1-C divergence is the headline finding of this round.**
  Same "no skill mentioned either way" framing, same kind of task
  (god-class flow extraction), and this time the skill was **not**
  self-invoked, where in round 1 it was. Combined with C nonetheless
  producing the most complete extraction (full caller rewiring, new tests,
  the false-positive-name catch) purely from reading the project's own
  memory file and precedent code, this suggests the skill's marginal value
  drops on a codebase that has already accumulated a concrete, discoverable,
  code-verified convention — the model reached for what was already sitting
  in the repo instead of the general playbook, and did fine.
- Did the skill catch something real that baseline missed? Not clearly this
  round — A's self-corrected grep mistake and C's false-positive-name catch
  are both examples of careful verification paying off, and neither is
  attributable to the skill (A didn't have it; C didn't invoke it).
- Did the skill add ceremony baseline correctly skipped? No — B's additions
  (bind parameter, try-with-resources, narrowed catch, the extra
  `setAttachmentFileName` REFACTOR NOTE) all showed up independently in C too,
  without the skill, so they read as "what careful extraction in this repo
  looks like" rather than skill-specific ceremony.

## Verdict

Would trust this again, but the task sentence needs one more clause: this
round fixed round 1's "how much code moves" ambiguity by pinning the method
list, and a **new** ambiguity showed up in its place — "how much of the rest
of the codebase gets switched over to the extraction." Pin that too next
time (e.g. "and update every real caller to use the new service") or the
diffs will keep landing anywhere between B's shape (fully built, zero
callers switched) and C's (fully built, fully switched) even with identical
scope. The more interesting result this round wasn't A-vs-B at all — it was
that Session C solved the task well without the skill, leaning entirely on
this repo's own accumulated memory/precedent instead, which is either a
sign the skill's marginal value shrinks as a codebase's own documented
conventions mature, or a sign the trigger check itself is inconsistent
run-to-run (round 1's C self-invoked on a near-identical task, this one
didn't) — worth another data point before concluding either way.
