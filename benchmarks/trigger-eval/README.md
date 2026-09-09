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

**Status**: dataset is ready to run properly (48 isolated dispatches);
not yet done at that N because of the added cost of full isolation
(48 separate calls instead of 6). The 8 already-isolated data points
collected so far (all this session's earlier N=1/N=3 probes, reusable
against these exact prompts) plus the 2 DRY rechecks above are the only
trustworthy numbers from this file's first attempt.
