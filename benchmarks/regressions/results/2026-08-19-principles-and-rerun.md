# Clean god-class rerun (all four axes) + first principles-benchmark run (2026-08-19)

Two things in one report because they ran the same session: the clean
rerun of the three contaminated axes plus quality's first-ever N=4, and
the first run of the separate 14-principle benchmark (56 cases). See
[`benchmarks/README.md`](../../README.md) for how these fit together.

> **Caveat found after the fact, applies to Parts 2-4 below.** The
> installed plugin turned out to be pinned to the commit it first became
> installable at (`04d7506`, 2026-08-18) — it never auto-updated after
> that, silently. Every with-skill agent run in Parts 2-4 (the N=1 and
> N=2 principles runs, both snippet and scenario) read that pinned
> version via the `Skill` tool, not the latest repo state. That version
> already has all 20 principles, the original 0-12 playbook, and Step
> 5's sharpened two-condition rule — it's missing exactly two things
> added later the same day: playbook Step 13 (fresh-eyes re-review,
> never actually exercised by any agent yet) and one clarifying sentence
> in the Fail Fast section (added, then a rerun against it looked like a
> failed fix — see Part 4's correction, that test never actually saw the
> new sentence either). Part 1 (the god-class N=4 rerun) is unaffected —
> it ran before the plugin existed, against a manually-synced copy that
> was current at the time. Fix going forward: check
> `~/.claude/plugins/installed_plugins.json`'s `gitCommitSha` against
> the repo's latest commit before trusting a with-skill run reflects
> current content, not just after installing once.

## Part 1 — God-class playbook, clean rerun (N=4, all four axes)

### Why this run exists

The three published 2026-08-17 reports (regressions, notests, process)
were run against a fixture whose class comment leaked the playbook by
step number, visible to both arms — see the correction notes at the top
of each. This session reran all three against the cleaned fixture (fresh
seeds, not the same runs re-scored) and ran quality at N=4 for the first
time (previously only a contaminated, discarded pilot existed).

### Method notes specific to this run

- **Session-limit interruption, mid-batch.** The account's usage limit
  was hit partway through the first launch wave; 13 of ~40 in-flight
  agents failed. Before relaunching, checked each failed run's actual git
  state instead of assuming a clean restart was needed: 5 of the 13
  (`process/with-skill-seed1-4`, `quality/with-skill-seed1`) already had
  real, committed, verified-good partial work — 3-4 real commits each for
  process, uncommitted-but-complete files for quality. These were
  **resumed, not restarted**: a fresh agent read the existing git history
  and finished from there. This is strictly better than a clean restart
  for the process axis specifically, since restarting would have thrown
  away real checkpoint commits that axis exists to measure.
- **One agent at a time**, not up to 20 concurrent, after the interruption
  — slower, but avoids losing many partial completions at once if the
  limit is hit again.
- **`VerifyQuality.java` scorer bug found and fixed mid-run**: it only
  checked `GodClass.chkShipElig` via reflection. A with-skill run that
  fully removed the method from `GodClass` (no delegate left, correctly
  the target class now owns it entirely) scored `UNVERIFIABLE` even
  though behavior was fine — confirmed by hand-injecting a one-off check
  against `ShippingEligibilityService` directly before fixing the scorer
  to fall back to the new class automatically.

### Results

**Regressions** — 8/8 PASS, zero regressions in either arm. Identical
outcome to the contaminated run; this axis's finding (task too easy to
show a gap) is now confirmed independent of the leak.

**Zero-pre-existing-tests** — 4/4 with-skill PASS (test written + behavior
preserved). 0/4 baseline wrote a test for the untested flow (2 PARTIAL:
behavior preserved, no test; 2 UNVERIFIABLE: method moved off `GodClass`
entirely, a legitimate choice the reflection check couldn't follow). Gap
is sharper than the original contaminated run (which had 1/4 baseline
clean, not 0/4).

**Process adherence** — 8/8 checkpoints clean, both arms.
`REFACTOR_NOTE_PRESENT`: 0/4 baseline, 3/4 with-skill — same split as the
contaminated run, now confirmed clean. One with-skill run (seed 3) again
chose "push resolution to the caller" over duplicating, matching the
~1-in-4 divergence rate seen in every prior run of this design.

**Quality** (first-ever clean N=4; the only prior attempt was a
contaminated, discarded pilot) — 8/8 SCORED, behavior preserved, zero
regressions.

| | nesting depth | magic numbers | magic strings |
|---|---|---|---|
| baseline (seed 1-4) | 1, 2, 1, 2 | 0, 0, 2, 0 | 0, **3**, 0, 0 |
| with-skill (seed 1-4) | 1, 1, 1, 1 | 1, 1, 1, 1 | 0, 0, 0, 0 |

Not a clean "with-skill wins on every number" result — baseline sometimes
reaches 0 magic numbers where with-skill leaves 1. What's real:
**with-skill is far more consistent.** Every with-skill seed lands at the
same depth/magic-number/magic-string profile; baseline varies seed to
seed, including one run (seed 2) that leaves 3 magic strings completely
untouched. The skill doesn't guarantee the single best cleanup, it
guarantees a cleanup happens and happens the same way every time.

`REFACTOR_NOTE_PRESENT` for quality: 3/4 with-skill (seed 3 diverged, same
as process — pushed resolution to caller instead of duplicating). Not
scored by `score-quality.sh` directly (that script checks regression /
behavior / readability only) but visible in the transcripts, consistent
with the other three axes.

### Interpretation, updated across all four axes

The god-class playbook's real, repeated, now-four-times-confirmed effect
isn't "prevents breakage" (regressions stays saturated at 0/8 across
every axis and every run this project has done) — it's **discipline that
has no built-in penalty for skipping**: writing a test for untested code,
documenting a duplicate's removal criterion, cleaning up consistently
instead of some-seeds-yes-some-seeds-no. A capable baseline does the
underlying engineering correctly; what it skips is the paperwork that
makes the choice legible to whoever reads the code next.

The Step 5 "push to caller vs. duplicate" divergence (~1 run in 4,
with-skill, across three separate axes now: notests, process, quality)
is stable enough to call a real, bounded rate rather than noise — the
sharpened two-condition rule (see [`principles.md`](../../../skills/software-design-principles/references/god-class-extraction-playbook.md))
reduces but doesn't eliminate the judgment call when the fixture gives
two contradictory signals (an explicit single-flow task vs. a leftover
comment implying more extractions are coming).

## Part 2 — Principles benchmark, first run (56 cases)

### What this measures

14 of the skill's 20 principles, each with a should-flag case (Case A)
and a should-NOT-flag calibration case (Case B) — see
[`principles/README.md`](../../principles/README.md) for which 6
principles are out of scope for this single-snippet methodology and why.
Two questions per principle: does the arm catch the real issue (Case A,
a recall question), and does it avoid inventing an issue where the
principle's own "when NOT to apply it" says there isn't one (Case B, a
precision/calibration question).

### Method

56 independent `Agent` calls (14 principles × 2 cases × 2 arms), each a
cold read of one snippet with no memory of any other case. Baseline told
not to consult any skill; with-skill told to use it (or read the
reference files directly if the skill isn't invocable in a fresh
subagent context). Cost-reduction measures applied mid-run (see
`usage-log.csv` for full per-run token/time data):

- Case A runs on `haiku` for both arms (recall question, no calibration
  nuance at stake) — same model both sides keeps the baseline/with-skill
  comparison valid.
- Case B **started** on haiku too, but was moved back to the default
  model partway through after haiku's with-skill arm false-positived on
  two calibration cases in a row (`05-dry`/caseB, `07-cqs`/caseB) —
  breaking a pattern the same cases showed reliably on the default model.
  Risk: haiku may be too weak to apply the skill's "when NOT to apply it"
  nuance, meaning caseB results on haiku would measure a model-capability
  ceiling, not the skill. The 3 already-collected haiku caseB results
  (04 correct, 05 and 07 both false-positive) are kept in the data but
  flagged `completed-haiku` in the log rather than pooled with the
  sonnet caseB numbers below without that caveat.
- Grading was done inline, case by case, during the run — each Case B
  result was checked directly against its case file's "Expected" section
  as it came in, rather than deferred to a separate batch-grading pass.
  This turned out to be self-verifying: an actual fixture bug was caught
  this way (see below), which a naive batch grader reading only the
  transcripts (not re-deriving the expected values independently) might
  have missed.

### Fixture bug found and fixed mid-run

`09-readability`'s Case B (`daysUntil`) called
`target.datesUntil(LocalDate.now())` — backwards from what the method
promises. `LocalDate.datesUntil` requires the receiver to be before the
argument; for a future `target` (the normal case), this throws
`IllegalArgumentException` at runtime. Not a readability issue (what the
case was designed to test) but a genuine defect in the example itself,
caught when a baseline reviewer correctly flagged the real bug — off
target for what the case measures, but not wrong. Fixed to
`LocalDate.now().datesUntil(target)` in both the source case file and the
two already-generated `Snippet.java` copies; the case was rerun clean
against the fix before being counted.

### Results

**Recall (Case A, should flag) — 14/14 both arms.** Every principle's
real issue was caught by both baseline and with-skill, no exceptions.
Some hits used an adjacent name instead of the exact principle
(`06-strategy`→"Open/Closed Principle", `11-hexagonal`
baseline→"Dependency Injection", `14-fail-fast` baseline→"redundant
validation" instead of "Fail Fast") — the verdict (flag it, correctly)
was right in all 14/14 cases on both arms regardless of naming precision.

**Precision (Case B, should NOT flag) — the headline number, N=1:**

| | false positives | correct (didn't flag) |
|---|---|---|
| baseline | 8/14 | **6/14 (43%)** |
| with-skill | 3/14 | **11/14 (79%)** |

Baseline false-positived on: `01-solid`, `02-value-object`,
`04-law-of-demeter`, `05-dry`, `07-cqs`, `08-specific-exceptions`,
`10-ddd-tactical`, `14-fail-fast`. With-skill false-positived on only 3
of those same 8 (`05-dry`, `07-cqs`, `14-fail-fast`) — no *new* false
positives introduced by the skill anywhere baseline got it right.

**Update — see Part 4 below**: every case got a second independent seed
the same day. The N=2 combined numbers (54%/82%) confirm this gap rather
than revise it, but two of the three with-skill misses above turned out
to be a haiku-specific limitation, not a skill-content gap, and the
third (`14-fail-fast`) turned out to be a real, repeatable one. Read this
N=1 table as the first data point, Part 4 as the trustworthy one.

**The skill roughly doubles calibration precision (43%→79%) at zero cost
to recall (100%→100%).** This is the principles benchmark's core finding:
the skill's main measurable effect isn't teaching agents to find more
problems — both arms already find the real ones — it's teaching them
when *not* to invent one.

### What the false positives look like

Every baseline false positive followed the same shape: correctly
recognizing a pattern that's a violation in the general case (a getter
chain, a duplicated-looking block, a broad `catch`, an anemic-looking
class, a repeated validation call) without checking the principle's own
stated exception for it (Value Object composition, coincidental
similarity vs. shared knowledge, a framework-mandated global handler, a
JPA entity, a real trust boundary already validated once). The skill's
"when NOT to apply it" section for each principle is, empirically, doing
real work — when with-skill runs got a Case B right, they consistently
cited that section's specific reasoning rather than a general "this
seems fine" judgment.

The 3 with-skill misses (`05-dry`, `07-cqs`, `14-fail-fast` Case B) don't
share the earlier axes' pattern of "the skill always corrects the
baseline's mistake" — worth a closer read before the next round, since
two of the three were on haiku (see the model-switch note above) and the
third (`14-fail-fast`, sonnet) was a genuine with-skill miss that
deserves its own look rather than being folded into the model-capability
explanation.

### Cost (see `usage-log.csv` for the full per-run breakdown)

Consistent with the god-class axes: with-skill runs cost noticeably more
than baseline, on both benchmarks, on both models tried.

| | baseline avg tokens | with-skill avg tokens | baseline avg duration | with-skill avg duration |
|---|---|---|---|---|
| god-class axes (sonnet) | ~62,500 | ~80,600 (+29%) | ~169s | ~310s (+83%) |
| principles, sonnet subset | ~43,100 | ~57,100 (+32%) | ~23s | ~44s (+92%) |
| principles, haiku subset | ~31,900 | ~38,900 (+22%) | ~10s | ~18s (+80%) |

The skill roughly doubles wall-clock time and adds 20-30% tokens,
independent of which model runs it. This is the direct cost of the
precision gain above — worth stating plainly rather than reporting only
the upside.

### The 3 with-skill misses, examined (added after the run)

The report originally flagged these as "worth a closer read" without one.
Rereading each transcript against its case file:

- **`05-dry`/caseB** (`WelcomeEmailBuilder`/`ReminderEmailBuilder`,
  haiku): the with-skill review said "both classes duplicate identical
  method structure with only the template string varying" — it correctly
  spotted the *shape* is identical, but never checked whether that shape
  represents the same underlying business rule (shared knowledge) or two
  unrelated rules that happen to look alike (coincidental similarity) —
  exactly the distinction `principles.md`'s DRY section states explicitly
  ("the same knowledge, not necessarily the same text"). A shape-match
  substituted for the semantic check the skill's own text calls for.
- **`07-cqs`/caseB** (`ProductCatalog.findById` with cache-fill +
  metrics, haiku): with-skill flagged "query method but executes
  commands (metrics.increment, cache.put)" — true as a literal
  description, but it treated *any* side effect inside a query as
  automatically disqualifying, without checking whether that side effect
  is externally observable (changes what any caller can detect) or
  purely internal bookkeeping that doesn't affect the returned value —
  the specific gray area the principle's own text names as accepted.
- **`14-fail-fast`/caseB** (single check at a real HTTP boundary, then
  trust downstream, sonnet): with-skill argued the one check performed
  (`items().isEmpty()`) isn't *thorough* enough, since other fields go
  unchecked. This is a different failure shape than the other two — not
  a surface-pattern match overriding a semantic check, but conflating
  "validate once, at the real boundary, then trust" (what Fail Fast
  actually asks for) with "validate everything exhaustively up front"
  (a stricter standard the principle doesn't set).

Two of three (`05-dry`, `07-cqs`) share a pattern: the skill correctly
*applied* the general rule but skipped checking the specific named
exception in the same principle's text — recognizing the shape of a
violation without verifying the exception clause doesn't apply. The third
(`14-fail-fast`) is a different, narrower failure: reading "trust after
validating" as "validate more," not a pattern-match issue at all. Not
enough data (N=1 per case) to say whether the first pattern generalizes
to other principles' calibration cases, but it's a concrete, falsifiable
hypothesis for the next run: **does re-prompting to explicitly check the
principle's "when NOT to apply it" section, not just its main rule, fix
`05-dry` and `07-cqs` specifically** — worth testing directly rather than
folding into the existing 56-case rerun.

### A first, real cross-host data point: OpenJarvis + a local 9B model

Not part of the 56-case run (different host, different model, N=1, not
integrated into the scoring pipeline) — but a real, single test worth
recording rather than leaving as an untested assumption. Ran
`01-solid`/caseA (the DIP violation both Claude arms caught 14/14
combined) through `jarvis ask` on OpenJarvis, `qwen3.5:9b` via Ollama,
told to read the skill's `SKILL.md`/`principles.md` before reviewing.

**Result: missed it.** "Nessuna violazione significativa da flaggare" —
and the justification it gave wasn't empty, it was a real passage from
`principles.md` cited out of context: a historical, illustrative anecdote
about *this specific project's own* decision to skip DI for one
repository (because nothing else in that codebase used DI and its tests
already used a real in-memory database) got treated as a general license
to skip DI whenever a repository has no interface — despite the snippet
under review giving no information about DI use elsewhere or test setup.
A keyword-shaped match substituted for checking whether the cited
exception's actual conditions held.

One data point, not a benchmark — but it directly answers a question
raised earlier and never tested: whether a small local model can reliably
use this skill the way the Claude arms did. On this evidence, no. Worth
a real N=4-or-more run on OpenJarvis before drawing a firmer conclusion,
but not worth assuming the answer is "yes" in the meantime.

### Trigger accuracy — first test (8 prompts, no code/skill hints)

Separate question from everything above: given the skill is *available*,
does its `description` field actually cause it to fire on the requests
it should, and stay quiet on the ones it shouldn't? Never tested until
now — the god-class and principles benchmarks both explicitly told the
with-skill arm to use it, which validates content quality but says
nothing about triggering.

Method: 8 fresh subagents, general-purpose, no mention of any skill by
name. Each got a plain user-style request — 4 designed to plausibly
trigger it (god-class extraction, a pre-PR design review, a generic-catch
judgment call, a should-I-add-an-interface question) and 4 designed not
to (JS `let`/`const`, a bash rename one-liner, UTC+2 trivia, a CSS
centering fix) — and was asked to answer normally, then report which
tools/skills it used on a separate line, so the trigger decision itself
wasn't influenced by the reporting instruction.

**8/8 correct.** All 4 positive prompts invoked
`software-design-principles` unprompted, and each response's content was
substantively correct (Tell Don't Ask, specific exceptions + the
legitimate-boundary exception, YAGNI + the testability exception — the
same principle-specific nuance the 56-case benchmark measured directly).
All 4 negative prompts didn't invoke it and answered normally.

Small sample, and every prompt here was written to be fairly clear-cut in
one direction or the other — a harder test would include boundary cases
deliberately close to the trigger line (e.g. a question that's partly
about code style but not architecture, or a small isolated snippet that
looks like it needs judgment but doesn't). This run establishes the
skill's description isn't badly miscalibrated in an obvious way, not that
it's precisely tuned at the margin.

### Part 3 — Scenario benchmark, first run (48 cases, N=2)

The 6 out-of-scope principles (see `scenario-cases/`) got their own
first run: same recall/precision structure as the 56-snippet benchmark,
but each case is a short scenario description (a situation, sometimes a
folder layout) instead of a code block, and the expected answer is a
recommendation rather than a flag/no-flag. 6 principles × 2 cases × 2
arms × 2 seeds = 48 runs, graded inline against each case's expected
answer as results came in (same caveat as Part 2 about blindness —
`grade-principles.md` now documents how to fix this for the next round).

Model split: caseA on haiku, caseB on the default model — same reasoning
as Part 2's mid-run correction, applied from the start here.

**Result: 46/48 clean matches.** 5 of 6 principles (`11-ddd-strategic`,
`13-package-by-feature`, `14-anti-corruption-layer`, `15-strangler-fig`,
`19-characterization-test`) went 8/8 on both arms — every recommendation
matched, every "fine as-is" call on the calibration case matched. The
one exception, `16-modular-monolith`/caseA, had 2 baseline responses that
recommended a fix in the right direction (a public API layer to enforce
the module boundary) without naming the case's actual point (that
*automated* enforcement, not just a cleaner design, is what closes the
gap a discipline-only boundary already failed to hold) — logged as
partial matches, not clean misses. With-skill was 4/4 clean on that same
principle, always naming automated enforcement explicitly (ArchUnit-style
tooling, a lint rule).

**Read against Part 2's headline number, this is a real contrast worth
naming plainly**: the snippet benchmark's baseline arm was wrong on 8/14
calibration cases (43% correct); the scenario benchmark's baseline arm
was wrong on 0/12 calibration-case pairs outright (only 2 *partial*
misses out of 24 total baseline responses, both still directionally
correct). Both benchmarks measure the same underlying question
(recognize a principle correctly, including its exception), but scenario
prompts spell out the situation in prose ("here's what's true, here's
what you'd recommend") while snippet prompts require noticing what to
even look for in raw code first. That extra step — deciding a review is
even warranted before judging it — may be where most of Part 2's baseline
failures actually live, not in the principle-application judgment itself.
Worth treating as a hypothesis, not a conclusion: N=2 per scenario case is
thin, and the two methodologies were never designed to be compared to
each other directly.

### Part 4 — Snippet benchmark scaled to N=2

All 56 original cases got a second independent seed (112 more runs: 56
cases × 2 arms). Case A stayed 28/28 clean on both arms across both
seeds — recall holds at 100% with a second data point. Case B (the
number that matters) combined across both seeds:

| | correct (of 28) | rate |
|---|---|---|
| baseline | 15/28 | 54% |
| with-skill | 23/28 | 82% |

Consistent with the N=1 headline (43%/79%) — the ~28-30 point gap holds
at N=2, not an N=1 artifact.

**What the second seed actually changed, case by case:**

- **Real variance, both directions.** `01-solid`, `02-value-object`,
  `04-law-of-demeter` (baseline): seed 1 false-positived, seed 2 was
  correct — the model genuinely gets these right sometimes and wrong
  other times, not a fixed miss. `03-tell-dont-ask` (baseline) went the
  other way: correct on seed 1, false-positived on seed 2. Treat any
  single-seed result on this benchmark as a sample, not a verdict.
- **Two with-skill misses confirmed as haiku-specific, not skill gaps.**
  `05-dry` and `07-cqs` with-skill false-positived on seed 1 (haiku,
  from the mid-run model switch) — reran clean on seed 2 (sonnet, the
  now-default model for Case B). Same skill, same case, different
  result by model capability alone.
- **One with-skill miss, root-caused — with a correction to how it was
  root-caused.** `14-fail-fast`/Case B false-positived on both seeds,
  both on the default model. First hypothesis: a gap in `principles.md`'s
  wording — added a sentence distinguishing *where* validation happens
  from *how exhaustive* it is, committed, reran the case twice more
  (seeds 3 and 4). Same miss both times, identical reasoning. Concluded
  the wording fix didn't work and the real cause was the case file (the
  snippet only checked one field on an endpoint that plausibly has more
  relevant ones) — fixed the snippet to make the boundary demonstrably
  complete (`@Valid` covers the rest declaratively), reran: correct
  immediately.

  **Correction, found afterward**: the installed plugin was pinned to an
  old commit (installed the day it first became installable, never
  auto-updated since) — the wording-fix commit landed in the repo but
  never actually reached what the Skill tool served to those seed-3/4
  verification runs. So "the wording fix didn't work" was never actually
  tested; what really happened is *the original, pre-fix wording* failed
  the same way a third and fourth time, which is itself useful (a stable,
  repeatable miss, not seed noise) but isn't evidence against the wording
  fix specifically. The case-file fix and its clean rerun are unaffected
  by this — that fix targets the test input (`Snippet.java`), not the
  skill's own reference text, so it didn't depend on the plugin being
  current. Both the case fix and the wording addition are kept; only the
  claim that the wording addition was tried-and-failed is withdrawn.

  Three lessons, not two: (1) a repeatable miss across multiple seeds and
  models is a real signal worth chasing to its root, not variance to
  average away; (2) the test case itself can be the actual bug, the same
  shape of mistake the fixture-contamination corrections kept surfacing
  earlier in this project; (3) **verify the thing under test is actually
  the thing that changed** — an installed plugin silently pinned to a
  stale commit is exactly the kind of measurement gap that makes a
  correctly-diagnosed root cause look like it came from a clean
  experiment when it didn't.

### Limitations

- Both benchmarks are now N=2 per case, not N=4 — better than the
  single-seed read this report started with, but the god-class axes'
  repeated ~1-in-4 divergence rate (Step 5) only became trustworthy at
  N=4; N=2 catches real variance (see above) but a rate like "3/4 of the
  time" isn't distinguishable from "1/2" yet at this sample size.
- Case B ran on two different models (haiku for a subset early in the
  run, the default model for the rest after the mid-run correction) —
  the pooled 54%/82% headline numbers are still defensible (same model
  within each baseline/with-skill pair, so the paired comparison stays
  valid case-by-case) but the two model subsets aren't directly
  comparable to each other in absolute terms.
- The 6 principles outside the snippet methodology now have their own
  scenario-based coverage (Part 3, N=2) — no longer an uncovered gap,
  but a separately-run, differently-shaped benchmark not pooled into
  this section's numbers.
- Grading was done inline by the same session running the benchmark, not
  by an independent grader blind to which arm produced which review —
  some risk of confirmation bias in borderline PRINCIPLE_NAMED calls,
  though the clean-cut VERDICT_MATCH numbers (flag/don't-flag) above
  don't depend on that judgment. `grade-principles.md` now documents how
  to make the next run's grading actually blind.
