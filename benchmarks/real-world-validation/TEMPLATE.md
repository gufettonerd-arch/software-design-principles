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
