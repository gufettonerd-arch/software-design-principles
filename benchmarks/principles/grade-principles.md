# Principles benchmark — grading rubric

Companion to `README.md`. One grading pass per (case, arm) response.

## Grading agent prompt (template)

```
You are grading one agent's review of a small code snippet, blind: you
don't know whether this response came from a baseline run or a run using
a design-principles skill.

The snippet: (paste Case A or Case B)

The expected verdict: (paste from the case file — either "should flag:
<principle>, because <reason>" or "should NOT flag, because <reason>")

The agent's response: (paste)

Answer three questions:

1. VERDICT_MATCH — for a Case A (should-flag) snippet: did the agent flag
   the specific issue described in the expected verdict (not just *some*
   issue — reviewers can always find something to say; does the response
   name the actual violation)? For a Case B (should-not-flag) snippet: did
   the agent correctly stay quiet on this specific point, or explicitly
   reason through it and conclude it's fine? Answer MATCH / MISS.

2. PRINCIPLE_NAMED — did the response name the specific principle (SOLID,
   DRY, Fail Fast, whichever applies), or use language that clearly maps to
   it, even without the exact name? A correct diagnosis described in plain
   English without the principle's name still counts. Answer YES / NO.

3. NOISE — for Case B specifically: did the agent flag anything else in the
   snippet that isn't actually a problem, beyond the one point being
   tested? This is a secondary precision check, since a response could
   correctly pass check 1 while still being generally trigger-happy.
   Answer NONE / SOME / A LOT, with what was flagged.

One sentence of evidence per answer, quoting the agent's response.
```

## Aggregation

Per principle, per arm: recall = MATCH rate on Case A across seeds; precision
proxy = MATCH rate on Case B (staying quiet correctly) combined with NOISE
staying at NONE/SOME rather than A LOT. Report per-principle, not just an
overall average — an average across 14 principles hides exactly the kind of
principle-specific gap (e.g., good at SOLID, weak at Fail Fast) that's
useful to know and fix.

## Making "blind" actually blind (added after the 2026-08-19 run)

The rubric above says the grader shouldn't know which arm produced a
response — the 2026-08-19 run didn't actually enforce that: grading was
done inline, by the same session that launched the runs and therefore
already knew which directory (`.../baseline/` or `.../with-skill/`) each
response came from. The per-case VERDICT_MATCH numbers are still
trustworthy (they're checked against an objective answer key, not a
subjective feel), but the softer PRINCIPLE_NAMED/NOISE judgment calls
carry a real risk of the grader's prior expectation ("this is the
with-skill one, it should be more careful") leaking into borderline
calls.

**Concrete fix for the next run**: before grading, copy each response
into a flat directory with an opaque, non-suggestive filename (e.g. a
random 6-character id, tracked in a separate manifest not shown to the
grader) — never `baseline-response.txt` / `with-skill-response.txt`
sitting next to each other. The grading pass reads only the case file's
expected verdict and the anonymized response; the arm mapping gets
joined back in only after every verdict is recorded, at aggregation
time. This is a filing convention, not new infrastructure — costs
nothing but discipline, and removes the one documented gap between the
rubric's stated design and how the first run actually graded.

## A risk to watch, same shape as the quality-axis rubric

The grading agent is itself making a judgment call about whether a named
issue "is" the expected principle — two correct-but-differently-worded
diagnoses shouldn't be scored as a miss just because they don't share
vocabulary. Err toward MATCH when the underlying reasoning is right even if
the label differs; the thing being tested is recognition of the smell, not
recall of this document's specific terminology.
