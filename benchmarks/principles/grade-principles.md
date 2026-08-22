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

1. For a **Case A** (should-flag) snippet — VERDICT_MATCH: did the agent
   flag the specific issue described in the expected verdict (not just
   *some* issue — reviewers can always find something to say; does the
   response name the actual violation)? Answer MATCH / MISS.

   For a **Case B** (should-not-flag) snippet, answer two separate
   questions instead of one (see "Splitting Case B's match" below for
   why):

   1a. CALIBRATION_VERDICT — did the response *actively contradict* the
       calibration point (flag the exact thing the case says is fine, or
       argue against it under a different principle's name — e.g. "not
       Law of Demeter, but a Tell Don't Ask violation" when the case is
       specifically testing whether this navigation is acceptable)?
       Answer CONTRADICTED / not contradicted. This is the only thing
       that should count as a hard miss on the calibration point itself.

   1b. CALIBRATION_ENGAGEMENT — separately from 1a, did the response
       *explicitly* reason about the specific point being tested and
       affirm it's fine ("I considered X and it's correct because Y"),
       or was it silent on that point — flagging other things in the
       snippet without ever addressing the one being measured? Answer
       EXPLICIT / SILENT. SILENT is not the same as CONTRADICTED — a
       response can be SILENT on the calibration point while still
       correctly not flagging it, which is a weaker result than an
       EXPLICIT pass but not a failure.

2. PRINCIPLE_NAMED — did the response name the specific principle (SOLID,
   DRY, Fail Fast, whichever applies), or use language that clearly maps to
   it, even without the exact name? A correct diagnosis described in plain
   English without the principle's name still counts. Answer YES / NO.

3. NOISE — for Case B specifically: did the agent flag anything that
   isn't actually a problem, beyond the one point being tested (i.e. a
   *wrong* observation, not just an unrelated one)? A secondary
   precision check, since a response could correctly pass check 1 while
   still being generally trigger-happy. Answer NONE / SOME / A LOT, with
   what was flagged.

4. OTHER_FINDINGS — for Case B: did the response find genuine, correct
   issues in the snippet that aren't what the case is testing (a real
   bug, a real edge case, a legitimate different design critique)? Not
   scored pass/fail — recorded as context. High OTHER_FINDINGS + SILENT
   on 1b is exactly the shape that shows up when a calibration snippet
   is realistic enough to contain other real things to say; it explains
   *why* a response might be SILENT without that being a quality
   problem with the response itself.

One sentence of evidence per answer, quoting the agent's response.
```

## Splitting Case B's match into two axes (added 2026-08-22)

Across a day of N=4 runs on 8 principles, the same pattern kept
recurring on Case B (calibration) responses: a response finds real,
legitimate *other* issues in the snippet and never explicitly addresses
the one specific thing being tested. Under the original single
MATCH/MISS question, this was hard to score consistently — sometimes
called MATCH (it didn't flag the wrong thing), sometimes AMBIGUOUS
(no formal answer existed for "didn't address it either way"), with no
principled way to tell "quietly correct" apart from "never looked."

It happened on 7 different principles the same day (CQS, Readability,
Value Object, Tell Don't Ask, Law of Demeter, and — before being
root-caused as case-file defects — Fail Fast and CQS again), at a
frequency that stopped looking like isolated case-file problems and
started looking like a property of realistic-enough calibration
snippets in general: the more genuinely interesting a snippet is, the
more it pulls attention toward its other real properties and away from
the one thing being measured.

Splitting the old single MATCH/MISS into 1a (CONTRADICTED — a real
miss) and 1b (EXPLICIT vs. SILENT — a *quality* distinction, not a
pass/fail one) makes this legible instead of forcing every response
into a binary that doesn't fit it. A principle whose Case B responses
are consistently SILENT-but-not-CONTRADICTED across many runs isn't
failing calibration — it's revealing that the snippet doesn't isolate
its point cleanly enough to *test* calibration reliably, which is
useful to know for a different reason (fix the case file, the same way
`07-cqs.md` and `14-fail-fast.md` were fixed this session) than a
response that actively argues the wrong thing (fix the principle's
wording, or investigate the model's reasoning, the way `05-dry.md`'s
rule-of-three trap was this session). Proposed and documented here, then
spot-checked blind on 5 principles same day — see
[the blind-grading report](../regressions/results/2026-08-22-blind-grading.md)'s
"Testing the new two-axis Case B rubric" section for the full picture:
Tell Don't Ask and Value Object (clean case files) both showed a clean,
arm-correlated split — baseline SILENT, with-skill EXPLICIT — the old
single question couldn't see, since all responses landed on the same
top-line verdict. Readability and CQS (both known-confounded case
files, one moderate, one severe) showed no such correlation — CQS in
particular went uniformly SILENT on both arms, the confound drowning out
everyone rather than exposing a skill-specific gap. Law of Demeter
(smaller sample, one collection error disclosed rather than hidden)
showed a different failure mode again: with-skill was the one that
*explicitly* reasoned through the calibration point and reached the
wrong conclusion. Four different, internally consistent stories from
one rubric — real signal where it exists, no manufactured pattern where
it doesn't, and honest reporting of a genuinely different (less
flattering) result on the one principle that showed it. Still small N
per arm on every principle — not broad enough to claim precise rates —
but it did the actual job of a grading tool on every test run so far.
The next full principles pass should use this version of the rubric
rather than the original single-question one.

## Aggregation

Per principle, per arm: recall = MATCH rate on Case A across seeds;
precision proxy = "not CONTRADICTED" rate on Case B (1a), with NOISE
staying at NONE/SOME rather than A LOT — report the EXPLICIT vs. SILENT
split (1b) and OTHER_FINDINGS alongside as secondary signal, not folded
into the same number. Report per-principle, not just an overall average
— an average across 14 principles hides exactly the kind of
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
