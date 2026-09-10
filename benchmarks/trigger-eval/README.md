# Trigger eval

`queries.jsonl` — 48 blind trigger-accuracy probes: 20 principles × 2
phrasing shapes each (`code-rich`: a concrete snippet/scenario;
`abstract`: the same underlying question with no code shown) plus 8
out-of-scope distractors for false-positive rate. Same style as every
other trigger probe in `../README.md`'s "Trigger accuracy" section —
built to make that ad-hoc sampling systematic and rerunnable, not a
different method.

**First run, 2026-09-09 — invalidated by its own methodology, not by the
result.** Ran as 6 batches of 8 queries each, one subagent per batch, to
save on dispatch overhead. That batching is what broke it: inside one
subagent conversation, the Skill tool only needs to be invoked once for
its content to be in context for every later query in the same batch —
so "Skill used: X" on query 6 doesn't mean query 6 independently
triggered it, it can mean the subagent is reporting *reuse* of what
query 2 already loaded. Evidence this actually happened, not just a
theoretical risk: one batch showed `tool_uses: 1` total against **4**
reported hits out of 8 queries in that batch. A second batch's `none`
answers stopped exactly where the skill was first invoked and every
query after was a hit — consistent with "loaded once, applied
downstream" rather than 8 independent routing decisions.

**Concretely, this produced a false positive.** DRY's code-rich query
(`dry-1`) came back as a hit in its batch — directly contradicting the
clean, independently-confirmed **0/3** DRY has held on every isolated
probe in `../README.md` (including after the 1.5.0 fix). Reran `dry-1`
twice, each as its own fully isolated single-query dispatch (no other
queries in the same conversation): **0/2, both explicit `none`**. The
batched "hit" didn't hold up — it was contamination, not a real trigger.
DRY's 0/N stands.

**The rule going forward, and the reason this file exists**: one
probe, one fully isolated session, every time — never more than one
query per dispatch, no matter how much cheaper batching looks. The
distractor batch (8 queries, `tool_uses: 0`, 8/8 correctly silent) is
the one exception where batching happens to be safe: since the skill
is never invoked at all, there's nothing to leak downstream. Any batch
that produces even one real hit can't be trusted for the rest of that
batch's later queries.

## Second run, 2026-09-10 — done properly, first real number

All 40 positive-expected queries run as 40 fully independent isolated
dispatches (no batching, no shared conversation — the rule the first
run's failure established). The 8 distractors weren't rerun; the first
run's 0/8 on them stands as-is, since a batch that never invokes the
skill at all has nothing to leak between queries (see above) — the one
batching exception that's actually safe.

**Headline: 15/40 (37.5%) triggered, 0/8 distractors — zero false
positives.** This is the first trustworthy systematic hit-rate number
this benchmark has produced. Every earlier trigger-accuracy finding in
`../README.md` came from ad-hoc single-probe (N=1) or small-N (N=3)
sampling, picked principle by principle as gaps were found; this is the
first time all 20 got the same-size, same-method sample at once.

**Per principle (N=2 each, isolated):**

| Result | Principles |
|---|---|
| **2/2** | Fail Fast, Characterization Test, Package by feature, Anti-Corruption Layer, Modular Monolith |
| **1/2** | Value Object, Tell Don't Ask, Law of Demeter, DDD strategic |
| **0/2** | SOLID, Composition over Inheritance, DRY, CQS, Specific exceptions, Readability, DDD tactical, Hexagonal, Strangler Fig, Shared state, Strategy |

**Reading this against the session's own earlier single-probe data,
not around it**: several principles that showed a clean hit at N=1
earlier the same day (SOLID, Composition over Inheritance, Hexagonal,
DDD tactical) came back 0/2 here. That's not necessarily a
contradiction — N=1 was never claimed as settled, and the earlier hits
and these fresh isolated misses are different sessions, different
phrasing, and (per the standing finding across this whole project,
e.g. Strategy Case A, DDD tactical/Hexagonal Case A) real seed-to-seed
variance is normal. What's new here is the first same-day, same-size,
same-method comparison across *all* 20 at once, which is a different
kind of evidence than another single N=1 data point — read it as
"trigger rate on a random unprimed question about this principle is
genuinely inconsistent for most of them," not as a fresh set of
confirmed misses each needing their own fix. **The 5 clean 2/2s are the
most useful signal**: Fail Fast and Characterization Test both got a
dedicated description-cue fix earlier this session and both held here,
on prompts different from the ones used to verify the fix — real
evidence those two fixes generalize beyond the exact prompts that
proved them. Package by feature, Anti-Corruption Layer, and Modular
Monolith weren't targeted fixes but came back clean anyway.

**Strangler Fig and Shared state are worth flagging specifically**:
both 0/2 here, and Shared state (principle 18) is the one that got the
most fix effort of any principle this session (2 dedicated rounds,
3/4 on its own targeted reverification). A fresh, unprimed, differently-
worded pair of prompts still missing it both times is a real signal
that the fix's reach is narrower than the targeted reverification
suggested — worth a closer look before assuming principle 18 is settled.

**What this number is not**: a precision/recall benchmark with a
correct answer per query. Every positive-expected query here is a
plausible-but-not-certain trigger candidate (the same shape as every
other trigger probe this project has run) — a 0/2 doesn't mean the
skill was "wrong" the way a should-not-flag case miss in the main
`principles/` benchmark would be. It means: on this specific phrasing,
unprimed, the skill didn't engage. Distractor precision (0/8 false
positives) is the one part of this that is a clean correct/incorrect
measure, and it held perfectly.
