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

## Shared state follow-up (2026-09-18) — the flagged 0/2 doesn't hold up as a distinct gap

Following through on the flag above: 2 fresh isolated single-query
dispatches, same rule as everywhere else in this file (one query, one
fully independent dispatch, no batching). Reran the exact `shared-state-1`
and `shared-state-2` prompts, and added 2 new phrasings —
`shared-state-3` (client-side, Angular `providedIn: 'root'` singleton
caching a field, added to `queries.jsonl`) and `shared-state-4`
(symptom-only: "two customers see each other's cart totals under load,"
also added).

**Result: 2/4 — `shared-state-1` re-missed (0/2 total, durably silent
on this exact phrasing across both runs), `shared-state-2` flipped
(missed originally, triggered this time — 1/2, genuine run-to-run
inconsistency on identical wording), `shared-state-3` (client-side)
triggered clean, `shared-state-4` (symptom-only) missed** — consistent
with this project's standing finding that symptom-only prompts with no
code or matching keywords structurally can't fire off a description-based
trigger, the same shape as the original principle-18 symptom-only miss
and the bare Characterization Test miss.

**Combined shared-state tally across all 6 probes run so far: 3/6
(50%)** — close to the 37.5% overall average across all 20 principles,
not a uniquely broken principle the way the original 0/2 made it look.
The one genuinely durable pattern in the data: `shared-state-1`'s exact
phrasing (`private static SimpleDateFormat sdf` on a Spring `@Service`)
has now missed twice in a row, despite being nearly the principle's own
textbook example — worth a narrower look at *that specific phrasing*
sometime, not the whole principle. Everything else here reads as the
same run-to-run variance this project has documented repeatedly
(Strategy Case A, DDD tactical/Hexagonal Case A, and half the 0/2s in
the main sweep above) — extending N=2 to N=4-6 on the specific principle
flagged as "worth a closer look" found exactly what the project's own
prior lesson predicted: more data, not a confirmed gap.

## The four 1/2 principles extended to N=3 (2026-09-18)

Same treatment as Shared state above, applied to the 4 principles that
landed at 1/2 in the original sweep (Value Object, Tell Don't Ask, Law
of Demeter, DDD strategic) — 1 new isolated probe each, new phrasing
(added to `queries.jsonl` as `*-3`), not a rerun of the existing 2.

**4/4 triggered.** Value Object, Tell Don't Ask, Law of Demeter, and DDD
strategic all went from 1/2 to **2/3** on this new data point. Small N,
same caveat as everywhere else in this file, but directionally
consistent — none of the 4 look like a principle heading toward a
durable 0-rate; all 4 sit around the same 2-in-3 range as the cleanest
principles in the original sweep. No fixes made — nothing here showed
the kind of durable, repeated miss that justified the earlier
description-cue fixes (principle 18's original gap, Fail Fast,
Characterization Test, Package by feature, DRY/Strangler Fig/
Readability's unchanged 0/3s). Read together with the Shared state
follow-up above: extending N on principles flagged from a single small
sample continues to find more variance, not more confirmed gaps —
consistent enough now across two separate follow-ups that it's probably
the right default expectation for any principle sitting at 1/2 or 0/2
on this dataset, rather than something to re-verify every time.

## The one remaining thread, closed (2026-09-18) — `shared-state-1` wasn't durable either

The narrower candidate left standing above: `shared-state-1`'s exact
phrasing (`private static SimpleDateFormat sdf` on a Spring `@Service`)
had missed twice in a row, worth checking whether it's a real,
phrasing-specific gap — hypothesis: maybe a question this close to a
famous, instantly-recognizable Java gotcha reads as "I already know
this cold" and the model doesn't feel it needs the skill's checklist,
unlike less iconic non-thread-safe cases.

Tested with 3 more isolated probes: the exact `shared-state-1` phrasing
run a third time, plus 2 new same-shape variants swapping the type for
something less textbook-famous (`Calendar`, and a plain `HashMap` used
as a manual cache — added to `queries.jsonl` as `shared-state-5/6`).
**3/3 triggered, including the exact original phrasing.**

**The hypothesis doesn't hold, and the "gap" doesn't either.**
`shared-state-1`'s combined tally is now 1/3 — not 0, and not
distinguishable from ordinary small-N variance once a third sample
exists. No fix made, none needed. This closes out the Shared state
investigation started above: at N=9 total across all 6 shared-state
prompts and all 3 fresh follow-ups this session, nothing about this
principle looks different from the general ~40-50% trigger rate the
rest of the dataset shows. The original "worth a closer look" flag was
correct methodologically (a real signal deserved a follow-up rather than
being fixed or ignored on N=2) but the underlying gap it pointed at
didn't survive more data — the right outcome to report either way.
