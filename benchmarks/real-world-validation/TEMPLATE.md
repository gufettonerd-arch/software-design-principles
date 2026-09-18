# Real-world validation — [project name], [date]

Everything under `benchmarks/` so far is synthetic (a small fixture, or a
short snippet). This is the other kind of evidence — one real flow, on a
real project, same shape as the wedding-project validation in the main
`README.md`'s "Validated on" section. Copy this file to
`benchmarks/real-world-validation/YYYY-MM-DD-<project-slug>.md`, fill it
in as you go, commit and push when done — same account, same repo, so it
shows up here regardless of which machine ran it.

## Before starting

- [ ] Pick **one** real flow or class you already suspect needs work —
      don't manufacture a task, use something you'd do anyway.
- [ ] Create a branch or worktree for this. **Nothing from either arm
      below gets merged to `main` without normal review** — this is a
      comparison exercise, not a shortcut around review.
- [ ] Note the project's stack here (language, framework, size) —
      README's "Known limitations" already flags this skill as validated
      on exactly one stack (Spring Boot + Angular); every different stack
      this runs on is useful data.
- [ ] Run `benchmarks/check-plugin-sync.sh` — if the installed plugin is
      stale, a with-skill run silently reads an old version and the
      whole round measures the wrong thing. (Added 2026-09-08, after
      round 5 found this happening to the very session writing that
      round's own report.)
- [ ] If using worktrees, verify each one's actual base commit matches
      the target branch's current tip — `git merge-base <default-branch>
      <worktree-branch>` should equal the tip's sha. Round 5 found all
      three worktrees silently branched from a stale base (missing
      recent history the task sentence assumed was there), undetected
      until after the round.
- [ ] Any claim that something is unreachable/absent/unverifiable — in
      the task sentence you're about to write, or in a session's own
      scope reasoning once it starts — gets verified directly (try the
      call, grep for the file, check the cache) before it's trusted.
      Round 5 found all three sessions, skill-guided or not, build a
      stub around a false version of exactly this claim; only checking
      it from outside caught it.

**Project**: _______
**Stack**: _______
**Branch/worktree**: _______

## The task

One sentence, written before either session starts, so neither arm's
prompt drifts from the other's:

> _______

## Session A — baseline

Fresh Claude Code session (`/clear` or a new one), told explicitly not
to consult any skill for this task. Same task sentence as above, verbatim.

**What it did** (short — file list, or a one-paragraph summary of the
approach):

**Anything notable** (broke something, missed something, made a call you
disagreed with):

## Session B — with-skill

Fresh session, same task sentence, told to use the
`software-design-principles` skill.

**What it did**:

**Anything notable**:

**Did it follow the playbook's actual steps** (if this was a god-class
extraction) — REFACTOR NOTE present where it duplicated shared code,
incremental commits, a Step 13 fresh-eyes pass? Or if this was a review/PR
task — did it correctly flag something baseline missed, or correctly
*not* flag something that was actually fine?

## Session C — trigger check (optional but cheap)

Fresh session, same task sentence, **no mention of any skill at all** —
see if it invokes `software-design-principles` on its own. Note whether
it did, and whether that was the right call given the task.

## Comparison

- Did A and B produce meaningfully different code, or converge on the
  same approach?
- Did the skill catch something real that baseline missed? Quote it.
- Did the skill do anything baseline did better, or add ceremony baseline
  correctly skipped? Quote it — a case where the skill is wrong is exactly
  as useful to record as one where it's right.

## Verdict

One or two sentences — would you trust this on a task like this again,
what would make it better next time.

## Before committing and pushing (added 2026-09-18, mandatory)

This repo is public. Rounds 1, 2, 6, and 7 all pushed a real company name
and/or real class/package/module names from a proprietary codebase into
this file's content before anyone caught it — every time, only the
*current* file content got fixed afterward, not the git history that had
already shipped it, so the leak stayed live and public until a dedicated
history rewrite closed it. Don't repeat that. Before the first commit
that includes this file:

- [ ] Replace every real identifier with a generic equivalent: company/
      product name, class/package/module names, ticket or issue numbers,
      internal filenames (memory files, config files, anything with a
      project-specific name baked in). Keep the *shape* (a 2413-line
      class, a `PROV` flag, a JDBC-URL field) — that's the actual data —
      just not the literal name.
- [ ] Grep the finished file for the real project/company name and any
      other identifying string you used while writing it, right before
      `git add` — a final mechanical check, not just "I was careful."
- [ ] Also check `benchmarks/README.md`'s index paragraph once you've
      written it (Step 6 of `ROUND-3-INSTRUCTIONS.md`, or the equivalent
      for whatever runbook you're using) — this is exactly where rounds 6
      and 7 leaked a second time, in the summary, after the dedicated
      report file itself was already clean.
- [ ] If you ever find a leak *after* it's already been pushed: fixing
      the current file content is not enough, the original commit is
      still reachable in public history. Say so explicitly when you
      report it — don't silently patch forward and let it look resolved.
