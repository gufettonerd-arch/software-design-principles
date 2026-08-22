# Quality axis — LLM-judge grading rubric

`score-quality.sh` only measures what a script can measure without opinion
(nesting depth, magic-literal count). This fills the gap noted in
`task-quality.md`: the qualitative half of Step 7, graded by an independent
agent reading blind — it sees only the final `ShippingEligibilityService.java`
from a run, not which arm produced it, not the other arm's version, and not
this rubric's answer key.

Run clean at N=4 — see
[the 2026-08-19 report](results/2026-08-19-principles-and-rerun.md) for
results.

## Why an LLM judge, not another mechanical check

Nesting depth and magic-number counts are objective. Whether a variable name
"says what it holds," or a comment survives "if I delete it, does it still
make sense" — Step 7's own wording — are judgment calls. Forcing those into
a regex would just relocate the opinion into the regex's design, less
visibly. A grading pass makes the judgment call, and shows its reasoning.

## Rubric — lifted directly from Step 7's text, not invented

For each criterion: PASS / FAIL / N/A, one sentence of evidence quoting the
actual code.

1. **Names say what they hold.** No abbreviations that require the reader to
   decode them (`c`, `o`, `w`, `cc`, `ok` in the original are the smell this
   checks for). PASS = every parameter/local in the extracted method has a
   name a new reader understands without cross-referencing the caller.
2. **Guard clauses over nesting.** Where the original had nested
   `if`/`else` with no early exit, does the rewrite flatten it? PASS doesn't
   require zero nesting — the eligibility logic has a genuine two-way branch
   (EU vs. non-EU) that guard clauses alone won't remove; PASS means the
   *invalid-input* checks (weight, null country) exit early instead of
   wrapping the whole method.
3. **Magic literals replaced with named constants.** For each of the four
   original numbers (`0`, `30`, `20`, `5`) and three strings
   (`"IT"`, `"FR"`, `"DE"`): is it still a bare literal in a comparison, or a
   named constant? Score literal-by-literal, not method-by-method — a
   partial cleanup should show as a partial score, not a pass or a fail.
4. **Comments survive deletion.** For every comment in the final method: if
   you delete it, does the code still make the same sense? A comment that
   restates the line below it is a FAIL; a comment explaining a genuinely
   non-obvious constraint is a PASS; no comments at all on already-clear
   code is also a PASS (Step 7 doesn't require comments, it requires the
   ones that exist to earn their place).
5. **Dead/redundant checks removed.** The original's `c != null`/`o != null`
   checks are unreachable — `requireCustomer`/`requireOrder` always throw
   instead of returning null. PASS = removed or never introduced; FAIL =
   copied over as dead code.

## Grading agent prompt (template)

```
You are grading a single Java file, blind: you don't know which of two
agents produced it, and you don't know what the "expected" answer is.

File: ShippingEligibilityService.java (paste the file)

Score it against these five criteria. Answer PASS / FAIL / N/A for each,
with one sentence of evidence quoting the actual code — not a general
impression. Do not infer intent you can't see in the code itself.

1. Names say what they hold (no abbreviations needing decoding).
2. Guard clauses used for invalid-input checks instead of wrapping the
   whole method in nested conditionals.
3. Magic literals (list: 0, 30, 20, 5, "IT", "FR", "DE") — score each one
   individually: still a bare literal, or promoted to a named constant?
4. Every comment present survives "if I delete it, does the code still
   make the same sense?" — quote each comment and say which side it falls on.
5. The `c != null` / `o != null` checks (or your name for the equivalent
   guard) are absent, since the lookups they'd guard against already throw
   instead of returning null.

Output as a table: criterion | verdict | evidence.
```

## Aggregation

Once graded, per run: count PASS criteria out of 5 (criterion 3 counted as
fraction: literals promoted / 7). Compare with-skill vs. baseline medians,
not just means — a single outlier run shouldn't carry the finding. Report
the literal-by-literal breakdown for criterion 3 in the write-up, not just
the aggregate number: which specific literals get missed most often is more
useful than a single score.

## A known risk with this rubric, stated up front

Criterion 1 and 4 ask the grading agent to exercise judgment about naming
and comment quality — the same kind of judgment this whole benchmark is
trying to measure in the *subject* agents. A grading agent with no design
guidance of its own is answering "is this a good name" from its own
untuned priors, which may not match the playbook's own standard. Whether to
give the grading agent the `software-design-principles` skill too (so it
grades against the same rubric it would apply as a *subject*) or keep it
deliberately naive is an open methodological question — not resolved here,
noted so it isn't quietly decided by default when this rubric is actually
used.
