# A real blind grading pass — 2026-08-22

`grade-principles.md`'s "Making 'blind' actually blind" section has said
since the first run that grading was never actually blind — the same
session that launched the runs also graded them, already knowing which
arm produced each response. That gap is now closed for a subset: the 24
Batch 1/2 responses from
[the N=4 partial run](2026-08-22-n4-partial.md) (Fail Fast/CQS/DRY,
seed3+seed4, both cases, both arms), using the raw transcripts saved in
[2026-08-22-n4-raw-transcripts.md](2026-08-22-n4-raw-transcripts.md).

## Method

Each response was assigned an opaque label (R1–R4) per case, shuffled so
order carries no information, and given to an independent grading agent
along with only the case's snippet and Expected text — never told which
response came from baseline vs. with-skill, or which seed. The
arm/seed → label mapping was kept in a private manifest, joined back in
only after every verdict was recorded. One principle per grading agent
(3 agents total), following `grade-principles.md`'s existing
VERDICT_MATCH / PRINCIPLE_NAMED / NOISE rubric. CQS Case A had 3
responses graded, not 4 — one transcript (with-skill-seed3) was lost
during today's collection (see the raw-transcripts file's own note on
this); not fabricated to fill the slot.

## Result 1 — DRY and CQS: blind grading matches today's own reads

Decoded against the private manifest, both principles' blind verdicts
land exactly where today's inline grading already had them:

- **DRY**: Case A 4/4 MATCH (all four correctly named the duplication).
  Case B: with-skill-seed3 MATCH, baseline-seed3 MATCH, baseline-seed4
  MATCH, with-skill-seed4 **MISS** — the exact same seed4 miss already
  reported, independently reproduced by a grader with no knowledge of
  which arm produced which response.
- **CQS**: Case A baseline-seed3 MISS, baseline-seed4 MISS,
  with-skill-seed4 MATCH — matches the reported baseline recall gap.
  Case B: all 4 pre-fix responses graded MISS or soft-partial-MISS, with
  the grader explicitly noting none of them engaged the actual
  metrics-logging question — independently confirms the case-file
  confound diagnosis from earlier today, on the same pre-fix responses.

No sign of the bias `grade-principles.md` worried about (inline grading
unconsciously favoring with-skill) on these two principles — the blind
pass reproduces the same pattern a differently-motivated grader would
have no reason to invent.

## Result 2 — Fail Fast: the blind pass found a real error today's own grading missed

This is the one that matters. Case A: clean 4/4 MATCH, no surprises.
**Case B, the calibration case already declared "fixed and stable at N=4"
earlier today, came back 1 clean MATCH, 2 hedged/borderline, and 1
outright MISS** — decoded: with-skill-seed4 MISS, baseline-seed3 weak
MATCH (heavy noise, doesn't actually articulate Fail Fast reasoning),
with-skill-seed3 hedged MATCH, baseline-seed4 hedged MATCH (the "just
slightly redundant" phrasing this report had already flagged as
borderline, not smoothed into a clean pass).

The MISS is the important one. The with-skill-seed4 response reads:

> "the empty-items check belongs at the HTTP boundary, and returning a
> raw `ResponseEntity.badRequest().body('No items')`... is inconsistent
> with a `@Valid` bean-validation setup — better to make it expressible
> via validation (e.g. `@NotEmpty` on `items` in `CheckoutRequest`)"

Today's own inline grading, done while collecting the transcript, called
this a clean pass — read it as a minor consistency suggestion, not a
disagreement with the case's premise. The blind grader caught what that
missed: the case file's own comment claims "'at least one item' isn't
expressible [via bean-validation annotations]" — **and that's factually
wrong**. `@NotEmpty` and `@Size(min=1)` are standard Jakarta Bean
Validation constraints, explicitly documented as applicable to
`Collection` types, not just `CharSequence` — putting `@NotEmpty` on a
`List<Item> items` field is a completely ordinary, common pattern.

This isn't a one-off: two separate with-skill responses across two
different seeds (seed3's "`@Size(min=1)` on `items` would've covered it
declaratively" and seed4's `@NotEmpty` suggestion) independently reached
for the exact same real, valid technical observation. That's convergent
evidence it's a correct catch, not a random model quirk — the case
file's premise had a genuine hole, and two different runs found it
without prompting each other.

**Fixed the case file same day**: `14-fail-fast.md`'s Case B no longer
claims the non-empty check "isn't expressible" via bean validation.
Instead, the comment and Expected text now explain the real reason the
manual check belongs where it is — `CheckoutRequest` is a shared DTO also
used by a save-for-later draft endpoint that legitimately allows an
empty cart, so a DTO-level `@NotEmpty` would break that endpoint, and the
non-empty rule has to stay local to the checkout handler specifically.
Same pedagogical point (validate once, at the right boundary), a
technically accurate reason instead of a false one. Not reverified with
new runs today — flagging that explicitly rather than presenting an
unverified case-file edit as settled, same discipline as the rest of
today's work.

## What this changes about earlier claims today

The [N=4 partial report](2026-08-22-n4-partial.md) said, in its opening
summary: "Confirms the Fail Fast case-file fix is stable (not a fluke)."
That claim was true for the specific thing it was checking (the earlier,
different fix — adding `@Valid` so the boundary is complete) — Case A and
the boundary-completeness point held up fine across all 8 runs. But
"stable" implied cleaner than it actually was: 1 of 4 Case B with-skill
responses was a genuine miss the same-day grading missed, caused by an
actual defect in the case file's premise, not by the skill or the model.
The headline finding (the fix generalizes) still holds; the supporting
"8/8 clean" framing was too clean. Corrected in that report and in
`benchmarks/README.md`.

## Why this matters beyond today's specific finding

This is the first time this project has run a genuinely blind grading
pass with real saved data, and it found something same-session inline
grading missed on the first try — not because the with-skill response
was wrong, but because the case file itself had an error, and
evaluating a response against a flawed answer key produces a flawed
grade regardless of how careful the grading is. Worth remembering the
next time a case file gets written: the "Expected" text is a claim about
the world (Java's validation API, in this instance), not just a design
choice, and claims about the world are the kind of thing that can simply
be wrong in a way "does the code look right" review doesn't catch.
