# Principles benchmark — methodology (not run yet)

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

Written today, not run — see the parent conversation's decision to write
benchmark infrastructure first and test everything tomorrow.

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

**Out of scope for this methodology (6 principles)**: DDD strategic
(bounded context), Package by feature vs by layer, Anti-Corruption Layer,
Strangler Fig, Modular Monolith, Legacy code/Characterization Test. These
are either about project *structure* (folders, module boundaries — no
single file shows a "bounded context violation") or about a *process*
decision over time (Strangler Fig, Characterization Test — the question
isn't "is this snippet wrong," it's "given this situation, what do you do
next"). They need a different benchmark shape: either a small multi-file
project layout to review, or a scenario description with a decision to
grade, not a code snippet. Not designed yet — noted here so the gap is
visible, not silently absent.

## Running it (for tomorrow, not today)

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
