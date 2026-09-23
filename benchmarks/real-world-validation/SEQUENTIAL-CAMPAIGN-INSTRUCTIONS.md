# Real-world validation — sequential campaign, ready-to-run instructions

Self-contained runbook, same spirit as `ROUND-3-INSTRUCTIONS.md`: open
Claude Code in the target repo and say something like:

> Follow `benchmarks/real-world-validation/SEQUENTIAL-CAMPAIGN-INSTRUCTIONS.md`
> (from the software-design-principles repo) and run a sequential campaign.

No memory of this conversation required — everything needed is below.

## What this tests, and why it's different from rounds 1–7

Every round so far (1–7) picked **one** real flow on a project, ran
baseline/with-skill/trigger-check in three **isolated, throwaway**
worktrees, and merged nothing back — a clean, independent comparison
each time. That design deliberately can't answer one question round 2
first raised: **does the skill's marginal value shrink as a codebase
accumulates its own conventions?** Round 2's with-skill session read
project memory/precedent instead of leaning on the generic playbook;
round 7's C didn't self-invoke the skill at all, reasoning from
accumulated project convention instead. Both are single glimpses across
*different* codebases at different maturity — never one codebase watched
*while* it matures.

This campaign watches one. **5 extractions on the same real project,
done in sequence, each one actually merged into the codebase** (with
normal review — this is the one deliberate exception to every prior
round's "nothing gets merged" rule, because compounding conventions is
the whole point and can't happen otherwise). 3 of the 5 (round 1, round
3, round 5) get the full baseline/with-skill/trigger-check comparison,
same as every prior round, in throwaway worktrees that don't merge.
Rounds 2 and 4 are with-skill only, merged directly — cheaper, and
that's fine, because the checkpoints (1/3/5) are what answer the actual
question: **is the baseline-vs-with-skill gap at round 5 smaller than at
round 1?**

## Step 0 — Preflight

Same as every other round:

1. Run `benchmarks/check-plugin-sync.sh` — stale plugin invalidates any
   with-skill session in this campaign, not just one round.
2. Note the target repo's current tip (`git rev-parse HEAD`).
3. Pick a project with **at least 5 real, distinct extractable
   god-classes/flows** — this campaign needs runway. If the project
   already used for rounds 3–7 doesn't have 5 untouched candidates left,
   use a different real project; don't manufacture targets on one that's
   run dry.

## The 5-round structure

| Round | Type | Arms | Merged? |
|---|---|---|---|
| 1 | Checkpoint | A + B + C | Only B, after review |
| 2 | Sequence-only | B | Yes, after review |
| 3 | Checkpoint | A + B + C | Only B, after review |
| 4 | Sequence-only | B | Yes, after review |
| 5 | Checkpoint | A + B + C | Only B, after review |

For every round: pick the target (same rule as always — a real flow you
already suspect needs work, not manufactured), write the task sentence
before dispatching anything, verify worktree base commits match the
*current* tip (which has shifted since the last round's merge — this
matters more here than in any prior round, since the codebase is
genuinely moving round to round), and dispatch.

**Checkpoint rounds (1, 3, 5)**: 3 throwaway worktrees off the current
tip, exactly like rounds 1–7 — baseline (A), with-skill (B), trigger
check (C). After writing the round's findings, **only B's changes get
merged** (real review, real PR/merge) — A and C stay as reference,
never merged, same as every prior round.

**Sequence-only rounds (2, 4)**: one worktree off the current tip,
with-skill only, told to use `software-design-principles`. Merge after
review. No baseline or trigger-check this round — that's the cost
saving that makes 5 rounds affordable instead of 15 isolated sessions.

## Dispatch hygiene (added after the first run, 2026-09-23)

- Give every session its own scratch/log directory in the prompt; a
  shared temp path let one arm read another's build log.
- Say in the report whether the arms inherited project memory or
  `CLAUDE.md` conventions derived from this skill. In the first run they
  did, so round 1's baseline already knew the skill's conventions and the
  round-1 gap is understated. For a clean starting point, run round 1's
  baseline without them.
- If the target repo can't take commits, "merged" can be a local-only
  integration branch with no upstream; branch each round's worktrees
  from its current tip.

## What to record every round (in addition to the usual)

Beyond the standard "what it did / anything notable" from
`TEMPLATE.md`, each round's write-up should explicitly address:

- **Did this round's session reference or build on a *previous* round's
  extraction** (reusing an already-extracted service, following a
  REFACTOR NOTE left by an earlier round, matching a naming/structure
  convention this campaign itself established rather than the generic
  playbook)? Quote it if so.
- **Tool-call / token / time trend** — is round 4 cheaper or more
  expensive than round 1 for a comparably-sized target? Not conclusive
  on its own (targets differ in size), but worth tracking across all 5.

**Checkpoint rounds only, additionally:**

- **The baseline-vs-with-skill gap, compared to the previous
  checkpoint.** Round 1 is the campaign's own baseline for this
  comparison — round 3 and round 5 should each explicitly say whether
  the gap (in whatever this round's task actually tests: catching
  something baseline misses, following a convention baseline doesn't
  know about, structural consistency) looks smaller, the same, or
  bigger than it did at round 1. This is the central question the whole
  campaign exists to answer — don't bury it in the general Comparison
  section, call it out explicitly.
- **Did the trigger-check session (C) self-invoke the skill?** Track
  across all 3 checkpoints — rounds 1–7 never got 3 data points on the
  *same* codebase for this, only 1 each on different ones.

## Step Final — Write the campaign report and push

Copy `TEMPLATE.md`'s structure but write **one report covering all 5
rounds**, not five separate files —
`benchmarks/real-world-validation/YYYY-MM-DD-sequential-campaign.md`
(today's date for when the campaign *finishes*, not when it started).
Structure: one subsection per round (same shape as `TEMPLATE.md`'s
Session A/B/C for checkpoints, a shorter single-session writeup for
rounds 2/4), then a dedicated **"Does the gap shrink?"** section
answering the central question directly using the 3 checkpoints'
findings, then a **Verdict**.

Index it in `benchmarks/README.md`'s real-world-validation section
(below the existing round summaries, matching that section's style),
push. **The mandatory anonymization checklist from `TEMPLATE.md`
applies to every round's content and to the README paragraph** —
5 rounds means 5 chances to leak a real name, not one; run the grep
check before every single commit in this campaign, not just the final
one.

## If a round finds something that changes the plan

If round 2 or round 3 reveals the codebase doesn't actually support 5
rounds (candidates dry up, or a target turns out unsuitable mid-round —
same as round 3's generated-code surprise in the original series),
that's real data too: stop, report what happened and why, and note in
the Verdict whether a shorter campaign (3 rounds, 1+1+1) would have been
the better call going in. A campaign that honestly stops at round 3
with a clear reason is worth more than one padded to 5 with a
manufactured target.
