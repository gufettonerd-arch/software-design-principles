# Investigating the with-skill contradiction pattern — 2026-08-23

Investigation only, no fixes applied here (deliberately deferred to a
future session, per explicit instruction). Companion to
[2026-08-22-n4-partial.md](2026-08-22-n4-partial.md) and
[2026-08-22-blind-grading.md](2026-08-22-blind-grading.md), which first
flagged this as "the model over-generalizing a principle it just used
correctly, within the same review" on Law of Demeter and DDD tactical.
That framing turns out to be imprecise in a way worth correcting before
anyone tries to fix it.

## The framing was wrong on one detail that matters

Case A and Case B for a given principle are **independent agent runs**
— separate calls, no shared conversation, no memory of one while
answering the other. So "over-applied a principle it just used correctly
in the same review" can't be literally true: there is no single review
spanning both cases. What's actually happening is two *separate*,
context-free applications of the same skill content to two different
snippets, one landing right and one landing wrong. That's a different,
more useful thing to explain than in-context reasoning drift.

## What the transcripts actually show: a "Tell Don't Ask magnet"

Re-read every Case B with-skill response in
[2026-08-22-n4-raw-transcripts.md](2026-08-22-n4-raw-transcripts.md)
that flags anything, looking specifically at *which principle name* the
response reaches for. Four responses across three different principles
reach for **Tell Don't Ask by name**, even though Tell Don't Ask isn't
the principle each of those cases is testing:

| Principle under test | Seed | With-skill quote | Outcome |
|---|---|---|---|
| Law of Demeter | seed3 | "classic Tell Don't Ask violation" (Money should format itself, not let ReceiptPrinter reach in) | **CONTRADICTED** — confirmed by independent blind grading |
| Law of Demeter | seed4 | "priceOf violates Tell Don't Ask by reaching into Money's fields" — same framing, same snippet shape | Same wrong angle (graded AMBIGUOUS inline, not re-run blind) |
| DDD tactical | seed3 | "public setters on every field... invites 'ask' logic... Tell Don't Ask" | **CONTRADICTED** |
| Hexagonal | seed3 | "Tell Don't Ask: ask Row for its already-valid line — fine as-is" | Correct, benign use |

Three of four land wrong; the fourth happens to be right. That's not
random noise — it's the same mechanism firing four times, three of
which happen to be checking a case where it doesn't hold.

## Why Tell Don't Ask specifically, and why it's wrong here

Checked `skills/software-design-principles/references/principles.md`
directly. Tell Don't Ask's own "When NOT to apply it" (line 99) is
narrow:

> pure DTOs used only for (de)serialization... are correctly plain data
> bags

That's the *only* exemption Tell Don't Ask states for itself. But the
correct exemptions for these two specific cases are written **under a
different principle's heading**, not Tell Don't Ask's:

- Law of Demeter's own "When NOT to apply it" (line 111): "purely
  structural/immutable objects... some level of navigation is normal."
  This is exactly what Case B tests (`ReceiptPrinter` reading a `Money`
  record) — and it's the *right* carve-out, sitting one principle away
  from the one the model reached for.
- DDD tactical's persistence-entity distinction (line 214): "persistence
  entity (can stay anemic: many ORMs need mutability) → domain object
  (should be rich) → DTO." Case B's JPA entity is explicitly the first
  category — again, the correct answer exists in the document, just not
  under Tell Don't Ask's heading, and DTO-only is the only exemption
  visible from there.

So the mechanism isn't "the skill lacks the right answer." Both correct
carve-outs are already written in `principles.md`. It's that a snippet
shaped like "object A reads object B's internal state before acting" is
*ambiguous* between several principles at once — Tell Don't Ask, Law of
Demeter, DDD tactical all describe some version of that shape — and
nothing in the skill tells the model to check the *other* principles'
specific exemptions before naming a violation under the first one that
matches. Tell Don't Ask's shape is the most general and the easiest
pattern-match, so it wins the race even when a more specific,
better-fitted principle (with its own correct exception) is sitting
right next to it in the same document.

The Hexagonal case shows why this isn't automatically harmful: there,
the borrowed Tell Don't Ask framing happened to reach the same
conclusion ("fine as-is") that the case's actual reasoning would have.
It's only wrong when the borrowed principle's own exemption list doesn't
cover the case, which is true for Law of Demeter and DDD tactical here
and evidently not for Hexagonal.

## Strategy's seed4 miss is a different mechanism, not this one

Worth separating cleanly: Strategy's with-skill Case A miss (seed4,
see the raw transcripts) invoked Strategy's *own* "when NOT to apply
it" clause — the correct principle, correctly recalled — and
misjudged the snippet's actual branch count/growth shape against that
clause's threshold (treated 5 already-present branches as "small and
stable enough for a plain conditional," which is the opposite of what
the case's Expected reasoning says). No cross-principle borrowing here;
it's a quantity/threshold misjudgment within the right principle. Don't
conflate the two when scoping a future fix — they'd need different
fixes (a cross-reference note vs. a clearer numeric heuristic).

## What this does and doesn't establish

- N is small: 4 Tell-Don't-Ask-reframing instances total, from 3
  principles, mostly single-seed. Enough to call this a real, named
  mechanism worth fixing, not enough to claim a rate.
- Doesn't establish this is the *only* thing behind every SILENT/soft-miss
  Case B result today — CQS and Readability's confounds are a separate,
  already-diagnosed cause (distracting real bugs in the snippet, not
  principle mis-selection).
- Candidate fix direction for a future session, not applied here: add a
  short cross-reference in Tell Don't Ask's own "When NOT to apply it"
  clause pointing at Law of Demeter's Value-Object-navigation exemption
  and DDD tactical's persistence-entity exemption, so the exception is
  visible from the principle that's actually pattern-matched first,
  instead of requiring the model to recall it lives one principle over.
  Reverify against exactly these two case files (Law of Demeter Case B,
  DDD tactical Case B) before touching anything broader, the same
  discipline used for the DRY/CQS/Fail Fast fixes.

## Fix applied and reverified, same day (2026-08-23)

Applied the candidate fix above to Tell Don't Ask's "When NOT to apply
it" clause (`skills/software-design-principles/references/principles.md`,
plugin version 1.2.4 → 1.2.5) and reverified against exactly the two
case files the investigation named — 1 with-skill run each.

- **Law of Demeter Case B**: clean EXPLICIT pass, opening line "Tell,
  Don't Ask / Law of Demeter — not violations here... both records are
  immutable Value Objects, and what's happening is formatting/display
  logic being built from a VO's own already-validated fields for a
  different consumer's representation — that's the explicit exception in
  both principles above." Names the exact new clause, correctly.
- **DDD tactical Case B**: clean EXPLICIT pass, opening line "this class
  is *correctly* anemic. It's a JPA `@Entity`, and both principles in the
  checklist carve out exactly this case." Also goes on to correctly
  redirect the real Tell Don't Ask question to "where does the business
  logic live," rather than pushing behavior onto the entity itself —
  exactly the distinction the case is testing.

Both fixed on the first attempt, unlike DRY's three failed attempts —
consistent with this session's earlier finding that a real wording/gap
defect (as this was: the correct answer existed elsewhere in the same
document, just not cross-referenced) closes cleanly with one fix, while
a genuine reasoning-pattern limit (DRY's rule-of-three instinct) doesn't.
N=1 per case here — the same next step as every other single-run
reverification this session: hold as "fixed, lightly verified" until a
future N=3+ pass confirms it generalizes, not yet claimed as fully
proven at scale.
