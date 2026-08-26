# Real-world validation, round 3 — ready-to-run instructions

Self-contained runbook. To execute: open Claude Code in the target
codebase's repo (or whichever real project you're validating against — see "Not on
the target codebase?" below) and say something like:

> Follow `benchmarks/real-world-validation/ROUND-3-INSTRUCTIONS.md`
> (from the software-design-principles repo) and run round 3.

Claude Code should be able to execute the whole thing — pick a target,
set up worktrees, run all three sessions, write the report, push — from
that one instruction. This file carries everything it needs: no memory
of this conversation required.

**Kept up to date as a living runbook, not a one-time snapshot** — the
title still says "round 3" (that's when it was first written) but every
round since has folded its process lessons back in here rather than
leaving them to be rediscovered. As of 2026-09-08 (after round 5): a
plugin-sync preflight check and worktree base-commit verification, see
Step 0 and Step 2 below.

## Step 0 — Preflight (added after round 5)

Before picking a target or touching any worktree:

1. Run `benchmarks/check-plugin-sync.sh` from a clone of this repo. If
   it reports stale, update/reinstall the plugin before dispatching any
   with-skill session — otherwise session B silently reads an old
   version and the round measures the wrong thing.
2. Note the target branch's current tip commit (`git rev-parse HEAD` in
   the target codebase) before creating any worktree. You'll compare
   against this in Step 2.

## Why round 3, and what it must fix

Two rounds already done on the target codebase
(`2026-08-24-real-world-round1.md`, `2026-08-24-real-world-round2.md`).
Read both before starting — they're short — because round 3 exists
specifically to close a gap round 2 found and flagged in its own Verdict:

- **Round 1** found the task sentence was ambiguous about *how much
  code* should move. Round 2 fixed that by pinning an exact method list
  in the task sentence. It worked — all three sessions agreed on scope.
- **Round 2** found a *new* ambiguity in its place: how many of the
  flow's real external callers actually get rewired to use the new
  service. Same task sentence, same scope, and the three sessions
  produced wildly different answers — C rewired all 3, A rewired 1 of 2,
  B rewired 0. Round 2's own Verdict says explicitly:
  **pin that too next time** ("and update every real caller to use the
  new service").

**Round 3's task sentence must pin both**, or it's not really testing
anything new. See the template below — it already has both clauses
baked in as a fill-in-the-blank, so this isn't something to remember to
do by hand.

One more thing to carry forward: round 2 found that a plain `grep`
silently misreads the target codebase's ISO-8859-1 source files as binary
and produces false negatives on caller searches — always use `grep -a`
(or your platform's equivalent for forcing text-mode search) when hunting
for real callers in this codebase, and say so explicitly in the task
sentence like round 2 did, so a session that would otherwise hit the
same trap gets warned up front instead of rediscovering it mid-round.

**Two more things carried forward from round 5** (a different project,
but both are properties of the methodology, not of any one codebase):

- **Verify worktree base commits before dispatching sessions.** Round 5
  found all three worktrees had silently branched from a commit several
  behind the target branch's actual tip, missing recent history the task
  sentence assumed was present — undetected until after the round, and
  not fixed even after being found (rebasing mid-round risked more
  conflict than it was worth by then). See Step 2 below for the concrete
  check; do it *before* Step 4, not after.
- **Verify any "unreachable/absent/unverifiable" claim before letting a
  session build around it** — whether that claim is in the task sentence
  you write, or in a session's own scope reasoning once it starts. Round
  5 found all three sessions, with-skill or not, independently accept the
  same false version of this claim and stub real work around it; the
  correction only came from testing the claim directly from outside all
  three sessions. If your task involves an external dependency, file, or
  environment a session might reasonably call "unreachable," check that
  yourself first (or say explicitly in the task sentence that it's been
  checked and is real) rather than letting three sessions independently
  guess the same wrong thing.

## Step 1 — Pick the target flow

Same rule as every round: **don't manufacture a task, use something you
already suspect needs work.** Prefer a candidate where:

- It's a real flow/method group inside one god class (same shape as
  rounds 1–2), not a from-scratch feature.
- It has **at least 2 real external callers** — round 2's caller-
  rewiring question only produces a signal if there's something to
  rewire. A flow with 0 or 1 callers won't test this round's point.
- It's reachable with the same constraints as before: no full
  Ant/Docker/WebSphere build required to verify (best-effort
  `javac`/grep instead).

If nothing obvious comes to mind, grep the codebase for the next-biggest
undocumented class after `CommonUtils` (round 2's target), or pull the
next ticket off whatever backlog prompted rounds 1–2.

Record here before starting either session:

- **Target class/flow**:
- **Real external callers found** (file:line each, via `grep -a`):
- **Stack** (should match rounds 1–2: Java 7/8, Struts 1.x, WebSphere
  8.5, Ant, ISO-8859-1): confirm or note if different.

## Step 2 — Set up 3 isolated worktrees

Same pattern as rounds 1–2 — one worktree per session so they can't see
each other's work:

```bash
git worktree add ../round3-a -b round3-agent-a
git worktree add ../round3-b -b round3-agent-b
git worktree add ../round3-c -b round3-agent-c
```

(Adjust paths/branch names to taste — what matters is three separate
working directories off the same base commit.)

**Verify the base commit before going further** (added after round 5 —
this step didn't exist when rounds 3–5 ran, and round 5 paid for it):

```bash
TIP=$(git rev-parse HEAD)   # the target branch's tip, noted in Step 0
for b in round3-agent-a round3-agent-b round3-agent-c; do
  BASE=$(git merge-base "$TIP" "$b")
  if [ "$BASE" != "$TIP" ]; then
    echo "⚠️  $b's base ($BASE) is behind tip ($TIP) — recreate it"
  fi
done
```

If any worktree fails this check, remove it and recreate from the actual
current tip before running any session — don't discover this after the
sessions have already committed work on top of a stale base.

## Step 3 — Write the task sentence

Fill in this template — **both bracketed clauses are required**, that's
the whole point of this round:

> In `[class]`, extract the `[flow name]` flow into a properly separated
> component under `[target package]`, preserving exact current behavior
> for every caller. In scope: `[exact method list — copy from Step 1]`.
> Do NOT move `[anything explicitly shared with other flows, if
> applicable]`. Before deleting anything from `[class]`, grep the whole
> repo for real callers using `-a` to avoid the binary-misdetection
> trap. **Update every real external caller found above to call the new
> service directly** — do not leave callers still pointing at the
> original class if the extraction is otherwise complete.

Write the final sentence down before running any session, so it doesn't
drift between arms:

> _______________________________________________

All three sessions get: not to run the full Ant/Docker/WebSphere build
(best-effort `javac`/grep verification instead), to commit locally when
done but not push, and not to ask clarifying questions.

## Step 4 — Run the three sessions

Use the Task/Agent tool to run these as three genuinely independent
sessions, each working only inside its own worktree directory — or open
three separate terminal sessions if you'd rather watch them run. Either
way, each session must have **no visibility into the other two**, and
must be told explicitly to do all its file reads and greps from inside
its own worktree directory, not from any other checkout of the same
repo — round 5 found a session read reference files from the main
checkout by mistake and wrote a false claim into its own delivered code
as a result.

- **Session A — baseline**: told explicitly **not** to consult any
  skill. Give it the task sentence from Step 3, working in the `a`
  worktree.
- **Session B — with-skill**: told to use the `software-design-
  principles` skill and follow the god-class-extraction playbook.
  Same task sentence, working in the `b` worktree.
- **Session C — trigger check**: no mention of any skill either way —
  "do the task as you normally would." Same task sentence, working in
  the `c` worktree. Note afterward whether it self-invoked the skill —
  round 1's C did, round 2's C didn't, round 5's C didn't either, on
  variously-shaped tasks; a further data point either way is useful.

For each session, capture: what it did (new files, diff shape on the
god class, whether it duplicated-with-note vs. deleted vs. left
originals in place), whether it rewired callers (and how many of the
ones found in Step 1), whether it wrote tests, verification method used,
and — for B — whether it followed the playbook's actual numbered steps
(cite which ones).

## Step 5 — Write the report

Copy `benchmarks/real-world-validation/TEMPLATE.md` to
`benchmarks/real-world-validation/YYYY-MM-DD-real-world-round3.md`
(today's date) and fill it in with what Step 4 produced. Structure to
match rounds 1–2 (session-by-session findings, then a "Comparison"
section, then "Verdict"). Specifically address in the Comparison
section:

- Did pinning the caller-rewiring clause actually produce consistent
  behavior this time, the way pinning scope did in round 2? Or is there
  a third ambiguity hiding underneath this one?
- Did the trigger-check session (C) self-invoke the skill? Compare
  against round 1 (yes) and round 2 (no) — is a pattern forming, or is
  it still inconsistent run to run?
- Anything genuinely new: a bug found, a shared-dependency judgment
  call, a hardening choice — same as prior rounds, report it even if
  it's not what this round set out to test.

## Step 6 — Index it and push

1. Add a short section to `benchmarks/README.md`'s real-world-validation
   part (below the existing round summaries) — a few sentences,
   matching the style already there, not a rewrite of the existing text.
2. Commit the new report file and the README update **from the main
   repo clone**, not from inside any of the three worktrees.
3. Push. **Nothing from worktrees A/B/C gets merged to the target
   codebase's own `main`** — those stay as local branches for reference;
   only the report and README update go to the software-design-principles
   repo.
4. Clean up the three worktrees once the report is written
   (`git worktree remove` ×3) unless you want to keep poking at the
   diffs.

## Not on the target codebase?

If tomorrow's real work happens to be on a different project entirely,
this runbook still applies — just substitute that project's repo for
every mention of the target codebase above, note its stack in Step 1,
and name the report file after it instead (`YYYY-MM-DD-<project-slug>.md`).
The caller-rewiring fix from round 2, and the worktree/unreachable-claim
fixes from round 5, are all properties of the *methodology*, not of any
specific project, so they're worth carrying into a fresh project too,
not just another round on the same one.
