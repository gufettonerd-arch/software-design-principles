# Principles benchmark — methodology

The other benchmark (`benchmarks/regressions/`) tests one document — the
god-class extraction playbook — on one kind of task: extracting a flow.
This one tests the other document — the 20 principles — on a different
axis entirely: **given a small piece of code, does the skill correctly
recognize a violation, and just as importantly, does it correctly stay
quiet when the "when NOT to apply it" condition holds?**

That second half is the point, not an afterthought. Every principle in
`principles.md` ends with a "when NOT to apply it" section specifically
because the most common failure mode, once you know a principle, isn't
ignoring it — it's overusing it. A benchmark that only rewards flagging
violations would train straight past that and measure the wrong thing.

Run at N=2 across all 20 principles (14 snippet-based + 6 scenario-based,
see below) — see
[the 2026-08-19 report](../regressions/results/2026-08-19-principles-and-rerun.md)
for full results.

## Format

One file per principle under `cases/`, each with two snippets:

- **Case A — should flag**: a small, realistic snippet with a genuine
  violation of that principle. Expected: the reviewing agent names the
  issue and the principle it maps to (not just "this looks off").
- **Case B — should NOT flag**: a snippet that looks similar on the
  surface but sits inside the principle's own "when NOT to apply it"
  condition. Expected: the agent doesn't flag it, or flags it and then
  correctly reasons its way out — either is fine, silently missing it
  because it never looked is not the same as correctly deciding it's fine.

Each snippet is 10-25 lines, self-contained, no fixture/project context
needed — deliberately smaller and more isolated than the god-class
benchmark's fixture, since the thing being measured here is recognition of
a single, specific smell, not an end-to-end task.

## What's in scope for this methodology, and what isn't

Not every principle reduces to a single-file snippet. Split honestly rather
than force it:

**In scope (14 principles, one case file each)**: SOLID, Value Object &
Immutability, Tell Don't Ask, Law of Demeter, DRY, Named design patterns
(Strategy), Command-Query Separation, Specific exceptions, Readability,
DDD tactical, Hexagonal Architecture, Composition over Inheritance, Shared
state beyond its boundary, Fail Fast. All of these have a smell that shows
up within a handful of lines of code.

**Out of scope for the snippet methodology (6 principles)**: DDD strategic
(bounded context), Package by feature vs by layer, Anti-Corruption Layer,
Strangler Fig, Modular Monolith, Legacy code/Characterization Test. These
are either about project *structure* (folders, module boundaries — no
single file shows a "bounded context violation") or about a *process*
decision over time (Strangler Fig, Characterization Test — the question
isn't "is this snippet wrong," it's "given this situation, what do you do
next"). They get a different case format instead — see
`scenario-cases/` below — not silently absent.

## `scenario-cases/` — the other 6 principles

Same Case A (should recommend the principle) / Case B (should NOT,
calibration) structure, but each case is a **short scenario description**
(a situation, sometimes with a small illustrative snippet or folder
layout) instead of a code block, because the thing being judged is a
structural or process decision, not a line-level smell. One file per
principle, matching `principles.md`'s own numbering: `11-ddd-strategic.md`,
`13-package-by-feature.md`, `14-anti-corruption-layer.md`,
`15-strangler-fig.md`, `16-modular-monolith.md`,
`19-characterization-test.md`.

Review prompt for these (replaces the snippet-review prompt above, same
two arms):

> You're asked for an architectural/process recommendation on the
> scenario below. State: (1) any recommendation you'd make, with a
> one-line reason, or (2) that the current approach is fine as-is and
> why. Don't assume more context than what's given.

Scored the same way as the snippet cases — recall on Case A, precision
on Case B — but grading is necessarily softer here: there's no single
"named the principle" string to match, since the expected answer is a
recommendation plus reasoning, not a flag. `grade-principles.md`'s rubric
applies with the same VERDICT_MATCH/PRINCIPLE_NAMED/NOISE structure, read
as "did the recommendation (or the deliberate non-recommendation) match
the expected one" rather than "did it name the exact section header."

First run: 46/48 clean matches (N=2, all 6 principles) — see the
2026-08-19 report's Part 3. 5 of 6 principles went 8/8 on both arms; the
one exception (`16-modular-monolith`) had 2 baseline responses land on
the right general fix without naming the case's specific point
(automated enforcement, not just a cleaner design).

## Running it

For each case, two arms — same as the god-class benchmark: baseline (no
skill) and with-skill, same neutral prompt:

> Review this code as you would in a PR. Note anything you'd flag, with a
> one-line reason. If you consider something and deliberately decide not to
> flag it, say so and why — silence isn't a signal here, an explicit "I
> considered X and it's fine because Y" is different from never noticing X.

Grade with an independent agent (see `grade-principles.md` for the rubric)
rather than exact string matching — "did it name principle 8" is too
brittle when the same violation can be described several correct ways.

## Scoring, two numbers per principle, not one

- **Recall on Case A**: did it flag the real violation, correctly attributed?
- **Precision on Case B**: did it correctly hold back, or did it flag
  something that isn't actually wrong here?

Report both. A principle where the skill has perfect recall but flags Case
B anyway isn't validated — it's found a way to always sound thorough, which
is exactly the over-application failure mode the "when NOT to apply it"
sections exist to prevent. Optimizing recall alone would make the skill
look better on this benchmark while making it worse to actually use.
