# Playbook — Extracting a flow from a legacy god class

A step-by-step procedure for extracting a flow (one method + its exclusive helpers) from a legacy god class — an oversized class/module that has accumulated too many responsibilities (e.g. `OrderProcessor`, `Utils`, `CommonHelpers`) — without a big-bang rewrite and without losing behavior along the way. The sequence is meant for any language and stack: where a detail is specific to one ecosystem (e.g. a build format, an exception type) it's flagged as an example, with the equivalent to look for in your own.

This isn't a document of principles (for that, see `principles.md`, which this playbook puts into practice concretely at every step) — it's the operational sequence: what to do, in what order, and how to verify each step hasn't broken anything before moving to the next.

**Guiding rule**: every step must leave the build green. If a step breaks something, the problem is isolated to that step — not to "the whole extraction".

**One flow per pass**: this procedure extracts a single flow at a time, start to finish. Don't start the next flow until this one has cleared every item in its own Definition of Done below — a god class with dozens of flows left to extract makes "just one more while I'm already in here" tempting, but batching passes is exactly the big-bang risk this playbook exists to avoid, even when each individual flow looks small on its own. One pass, fully validated, then the next.

---

## Step 0 — Before starting

- [ ] **Run the existing test suite and save the list of what's already red**: the project's test script, before touching anything. Without this initial snapshot, at Step 1 you can't tell "same red build as before" from "red build for a new reason I just introduced" — and on a god class with sparse tests, a test already red for a known bug is common, not an anomaly.
- [ ] **Identify the flow**: a self-contained method (or a small group) inside the god class, with a clear responsibility boundary (e.g. "all the logic for a specific campaign/channel/request type").
- [ ] **Map the dependencies**: for every method/helper the flow uses, count its callers across the whole file (a text search for the method name is enough, no need for advanced tooling).
  - **Exclusive use** (a single call site, inside the flow itself) → move it entirely, no compromises.
  - **Shared use** (also called by other flows not yet extracted) → do NOT immediately duplicate the complex domain logic: see Step 5.
- [ ] **Check the source file's encoding** before the first edit: if the project uses a non-UTF-8 encoding (common in legacy code — check the project's docs or any existing verification scripts), an editor/tool that assumes UTF-8 can silently rewrite it, corrupting accented/special characters with no visible errors until the build fails further down the line. If the project has a non-standard encoding, use a byte-safe tool that respects the declared encoding from the very first edit — don't wait until you have to recover it from git.
- [ ] **Check for concurrent/prior work on the same code**: `git log`/`git blame` on the file (and, where reachable, other open branches or recent PRs touching it) before extracting. Two real risks, not one: (1) someone else is mid-edit on the same method on another branch, and your extraction either conflicts outright or silently reverts their change once merged; (2) someone has *already* extracted this exact flow (or a helper it needs) into a class elsewhere in the codebase — grep for a plausible existing name (the domain term, not just the old method's name) before assuming you're creating something new. Neither risk is fully checkable from inside one working copy — a branch nobody has pushed yet, or fetched but not locally inspected, stays invisible — so this is a mitigation, not a guarantee: it catches what's visible, and its absence should be stated as a limitation of the extraction, not silently assumed away.
- [ ] **Check for a framework-native or off-the-shelf replacement before committing to a faithful move**: if the flow reimplements something the project's own stack already provides (a hand-rolled retry loop where the HTTP client has one, hand-assembled email sending where the framework has a mail-starter, a hand-written date-diff routine where the standard library has one), decide *before* Step 1 whether this pass is "move as-is" (this playbook, behavior frozen) or "replace with the native equivalent" (a different, larger-blast-radius change — new dependency, different failure modes, needs its own review and sign-off, not something to fold silently into an extraction). Don't let the answer default to "move as-is" just because that's what this playbook optimizes for — raise it explicitly, and if the team decides to replace, treat that as Step 6-style: isolated, its own step, with the faithful extraction as the safe fallback if it doesn't pan out. Extracted code should not end up locked into matching the existing code's quality ceiling by default — that's a choice to make on purpose, not the path of least resistance.

---

## Step 1 — Extract without deleting the old one

Create the new class/module (in the project's services package/folder, or its convention's equivalent) with a faithful copy of the code — same logic, same bug if there is one, no cleanup yet. The goal of this step is to *move*, not to improve.

- **The new class's own name is the one exception to "no cleanup yet"**: give it a real domain name now (what the flow *does*, e.g. `HotelEbookXmlBuilder`), not a placeholder that names the *move itself* (`OrderProcessorExtracted`, `OrderProcessorNew`, `OrderProcessorV2`, `OrderProcessorRefactored`). A placeholder container name has a way of becoming permanent — Step 7's readability pass tends to focus on the body once the file already exists and compiles, and "rename the class" then reads as a bigger, riskier change (import updates everywhere) than it did before the class existed, so it keeps getting deferred. Decide the real name before the first line is written; the method/variable names inside stay untouched until Step 7, exactly as before.
- The old method stays in place in the god class, untouched.
- Add a `REFACTOR NOTE` (or the equivalent comment in your language) above any piece of shared code you're duplicating (see Step 5) — not needed yet if you're only moving exclusive code.
- Run the project's build/test script (**use the script, not the commands it wraps**: a script encapsulates prerequisites/ordering that's easy to drift from when copied by hand).
- **Expected check**: same green/red build as before. If a test was already failing (e.g. because it reproduces a known bug), it must keep failing *the same way* — that's the proof the extraction is faithful.

## Step 2 — Update the references

Change the call sites in the god class to delegate to the new class/module. One change at a time if there are multiple call sites.

- Run the build/test script again.
- **Expected check**: identical to Step 1. Behavior must not change — only *who* executes it.

## Step 3 — Move/rewrite the tests onto the new code

If the old flow had no dedicated tests (a common case in god classes), write them now pointing at the new code, not the old one.

- Prefer testing the public entry point closest to the logic (not necessarily the one used in production) — this often lets you **avoid heavy fixtures**: if the god class's original method requires building the entire application context (session, request, several linked tables) to be called, testing the newly-extracted method directly (which only receives the data it needs) can eliminate most of that fixture, since the domain objects involved can be built by hand in the test.
- Include at least one test reproducing the *wrong* behavior if you're also fixing a bug (see Step 6) — it must fail now, to prove the following fix genuinely resolves it.
- Run the build/test script.

## Step 4 — Remove the now-dead code from the god class

Methods/fields exclusive to the flow, now with no more callers in the god class.

- Also look for fields that became orphaned (a constant used only by the method you just moved) — easy to forget.
- Run the build/test script.
- **Before considering it truly dead**: also search for references outside the main compiled/interpreted code. The compiler/linter won't see calls from external templates (a report engine, server-side templates, scripts embedded in pages, config files that reference method names via reflection) — these need a separate text search across the whole repository, template folders included. If you find no references and the method was already unreachable from outside the class anyway (e.g. `private`/module-internal), the check is just a confirmation; but it should always be done when removing public/exported code, which *could* be reachable from a template or a dynamic mechanism.

## Step 5 — Shared code: duplicate with a criterion, don't scatter it

When a helper is also used by other flows not yet extracted (e.g. a validation/lookup used from many places in the god class):

- **Don't** leave it coupled to the god class (the next flow would just re-duplicate it from there).
- **Don't** try to extract it for all its callers in one shot (a regression risk disproportionate to the task).
- **A third option exists and is tempting**: instead of duplicating the shared lookup, push it to the caller — the extracted class takes an already-resolved object instead of an id, and the god class keeps doing the lookup itself before delegating. This avoids duplication for *this* extraction, but only pays off if **both** hold: (1) this is genuinely the only flow you're pulling out of this god class — no more extractions are planned — and (2) the shared lookup has no anticipated need to change. If either is uncertain, duplicate with a `REFACTOR NOTE` instead, even though it looks like the less clean option today. A real god class worth writing a playbook for rarely has just one flow worth extracting — every later extraction that still has to resolve the same lookup through the god class keeps that god class necessary indefinitely, no matter how thin its own logic gets. Duplication with a tracked removal criterion is what actually lets the god class's surface shrink toward zero, one pass at a time; a clean-looking dependency back into it does not.
- Duplicate it into a dedicated class/module **once**, with an explicit comment (syntax adapted to your language):
  ```
  // REFACTOR NOTE (#ticket): duplicated from GodClass.originalMethod() to isolate this
  // flow. Flows extracted next should use THIS copy; the original in
  // GodClass should be removed once it has no more callers.
  ```
- **When the second flow that needs it shows up**: don't duplicate again. Move the shared code into its own dedicated class/module (born when the question "does the next flow call it from here, or is there a dedicated class?" comes up), and update the `REFACTOR NOTE` on the original to point there instead of to the first extracted class.
- This is Strangler Fig with an explicit completion criterion (see principle 15) — not "move it and see".

## Step 6 — The fix, isolated and last

If the extraction rides along with a bug fix: apply it **only now**, as its own step, after the faithful extraction is already green.

- A commit/diff that shows *only* the fix is far easier to review than one that mixes "moving" and "fixing".
- The test written in Step 3 (which was failing) must now pass.
- Run the build/test script → all green.

## Step 7 — Readability pass

On the code just extracted (not on the whole god class — that stays out of scope):

- **Long methods**: if a method does 6+ independent sequential things, extract a method per thing. If a method validates 5-6 conditions in sequence, flatten with guard clauses (`if (!condition) return;`) instead of nesting `if/else`.
- **Comments**: keep only the ones explaining a non-obvious *why* (ticket references, historical reasons). Delete ones that just repeat an already-readable line.
  - **Every fact in a comment must be independently verified before it's written, not inferred or reconstructed from the surrounding code's shape.** A ticket number, a date, an author, "this changed because X" — if you didn't get it from an actual source (a commit message, an existing comment you're relocating, a ticket the task itself named), don't write it, even as a plausible-sounding guess. A wrong fact in a comment is worse than no comment: it reads as authoritative, a future reader won't re-verify it, and it will be committed to production code where the bar is rigor for whoever maintains it next, not narrative color.
  - **Short and factual over a "dissertation."** A comment on extracted code states what's non-obvious about *this* code — not a retrospective on how the god class got this way, not a guess at the original author's reasoning, not a summary of the surrounding system's history. If the why genuinely needs more than 2-3 lines to state, that's usually a sign the *code* needs a better name or a smaller method, not a longer comment (see the "Names"/"Long methods" bullets above).
- **Names**: cryptic abbreviations inherited from legacy layouts/systems (e.g. Hungarian-notation prefixes, raw column names) → names that say what they hold in the current domain. **Applies to every method signature and every local variable in the moved code, not just the class name** (already renamed in Step 1) or the ones that happen to be easy to rename in isolation — a class with a clean domain name whose methods and locals still read `procCustXmlGenV3()`/`wkTmp2`/`flReq99` is not done; it moved the abbreviation problem one level down instead of fixing it. If a name is unclear only because of what it does inside the method (not what a caller needs to know), a doc comment doesn't substitute for renaming it — rename it.
- **Declarations close to use**: a variable reassigned 6 times in a long method is a sign the method needs splitting (see above) — decomposition fixes this too.
- **Targeted logs**: one log per rejection/failure reason (with the involved record's identifier), not a dump of the entire raw record on every call. If the class name is already in the logger, don't repeat it in every message.
- Run the build/test script after each group of changes, not only at the end.

## Step 8 — Separation of responsibilities (MVC-like)

Inside the flow you just extracted, if a single class handles orchestration, data access, and validation together, split it:

- **Service** — orchestration only (which branch applies, in what order). Zero direct dependencies on the data-access library.
- **Repository** — data access only (queries, row→object mapping). Zero business rules.
- **Validator/Lookup** — pure domain logic only, no I/O (ideally testable without a DB).
- **Value Object** — for every group of thresholds/fields with repeated magic numbers (see principle 2) or positional tuples (lists/arrays read by index) replaced with a named type.
- With no DI framework in the project, don't introduce Repository interfaces "on principle" — only if you genuinely need a second adapter or a mock in tests (see principle 12, "when not to apply it").
- Run the build/test script.

## Step 9 — Specific exceptions

Replace every generic ("catch everything") catch inherited from the original code with the type genuinely raisable in that block (see principle 8):

- Data-access blocks (connection/statement/result) → your language/library's specific data-access exception (e.g. `SQLException` in Java/JDBC).
- Date/number parsing → the specific parsing exception (e.g. `ParseException` in Java), possibly alongside other realistic errors on missing data (e.g. an unexpected null value).
- Verify the narrowing with a test that *genuinely* forces that exception (e.g. a nonexistent DB schema for the data-access exception, a non-numeric date for the parsing exception) — don't just read the code, a catch that's too narrow and silently breaks is worse than one that's too wide.

## Step 10 — Robustness and safety, without changing the logic

While the code is already under your eyes for the extraction, fix weaknesses that don't change *what* the flow decides — only *how solid/safe* it is while doing it. If a fix here would change an observable output, it doesn't belong in this step: go back to Step 6.

- **Queries: parameters, not concatenation**, for every value that varies (id, codes, dates) — a bind parameter (e.g. `WHERE id = ?` with a typed JDBC parameter, or your library/ORM's parameterized equivalent), never `"WHERE id = " + value`. The schema/table name often stays concatenated because many libraries don't allow it to be parameterized — acceptable only if its value comes from a known, fixed set (e.g. a configuration qualifier), never from direct user input.
- **No shared mutable state in static/global fields**: non-thread-safe mutable formatters/parsers (e.g. `SimpleDateFormat`/`Calendar` in Java) shared as a static field on a class used by concurrent requests (typical in a web god class) are a latent data-corruption bug under load. In the new class, instantiate them locally inside the method that uses them, or use the standard library's thread-safe equivalent if available.
- **Immutability where the data allows it**: an immutable Value Object — no setters, fields set only at construction. An object that can't be mutated after construction is safe to pass around without defensive copies, and eliminates an entire class of bugs (mutation from an unexpected caller).
- **Fail-safe on errors, preserving existing behavior**: if the original code already degrades to a neutral value (empty list, `0`, `false`) when a query/parsing fails, keep exactly that behavior in the exception narrowing (Step 9) — don't let it propagate "because it would be more correct": that's a silent logic change, to be decided explicitly with the team, not decided on a whim during an extraction.
- **Don't log sensitive data**: if the flow touches PII/credentials, verify any logs added/moved don't print them, not even in error messages (a data-access exception's message can contain query fragments with values).
- Run the build/test script.

## Step 11 — Coverage

Target: ≥80% line coverage on every new class, measured with your stack's coverage tool (e.g. JaCoCo for Java, coverage.py for Python, nyc/Istanbul for JS/TS) — not just "the tests pass":

```
# Java/Ant + JaCoCo example — adapt to your project's tool
export JAVA_TOOL_OPTIONS="-javaagent:path/to/jacocoagent.jar=destfile=target/jacoco.exec"
ant clean test
unset JAVA_TOOL_OPTIONS
ant -f jacoco-report.xml report
# then inspect the XML/HTML report for the touched classes
```

- Don't stop at the golden path. Write a test for every guard branch: record not found, blocked, out of range, malformed data, I/O failure, empty list, zero results.
- For pure Value Objects (no I/O), tests don't need a DB/fixtures — they're the cheapest to bring to 100%, always do it.
- For the Repository, an error-branch test is often achievable without mocks: a nonexistent schema/table in an in-memory database produces a genuine data-access exception.

## Step 12 — End-to-end verification (not just unit tests)

If the flow is reachable from a real endpoint/page, start it locally and hit it with real data before considering the work done:

- Use the project's startup script, not a manual reconstruction of its steps.
- Compare the output/logs for known cases (e.g. the inputs from the original bug report) before/after the fix — application logs often give the most direct, readable proof, more convincing than an assert in a test.
- Stop the containers/processes when you're done.

## Step 13 — Fresh-eyes re-review (after the move is verified safe)

Steps 1–12 are necessarily conservative: every choice in them is constrained by "don't change behavior, don't break the build." That constraint is exactly right during the move, but it also means some principles only become visible once the flow no longer lives inside the god class — a Value Object that wasn't worth introducing for one field buried in a 3000-line class, a Strategy pattern invisible when the branch was one of forty in the same method, a name that made sense as "part of X's fifth responsibility" but not as the name of a standalone class. Extracting safely and finishing the job aren't the same checklist.

Once the extraction is verified safe (Steps 1–12 done, tests green, coverage met), step back and review the finished new class **cold — as if it were someone else's PR you're seeing for the first time**, not as the extraction you just performed:

- Re-run the Working Checklist (see `SKILL.md`) against the new class as a whole, not just the specific lines touched during Steps 7–10.
- Ask explicitly: does anything about this class only make sense in light of where it came from? A comment referencing "the original method in GodClass," a name that echoes the old context, a parameter shaped the way the god class happened to pass it rather than the way this class actually needs it, a usage pattern that was a workaround for something the god class did nearby that no longer applies.
- If this surfaces a genuine improvement (not a speculative one — see YAGNI in principle 5), treat it as its own small step: change, run the build/test script, don't fold it silently into an earlier commit.

This is also why **one flow per pass** matters more than it looks: the fresh-eyes review works best right after the extraction, not three flows deep into the same god class and eager to move on.

---

## Definition of done (condensed checklist)

- [ ] Checked for concurrent work (other branches/recent commits on the same file) and for an existing extraction of the same flow elsewhere in the codebase, before starting
- [ ] Decided explicitly — not by default — whether this is a faithful move or a framework-native/off-the-shelf replacement; if the latter, handled as its own isolated step, not folded into the move
- [ ] Old code removed from the god class, verified "dead" even toward external templates/resources
- [ ] Shared code duplicated with a `REFACTOR NOTE` and an explicit removal criterion (or consolidated, if this is the second consumer)
- [ ] Fix applied as its own isolated step, with a test that failed before and passes after
- [ ] New class named for what it does (no `*Extracted`/`*New`/`*V2`/`*Refactored`-style placeholder); every method and local variable inside it renamed too — not just the ones renamed "for free" during the move
- [ ] Short methods, clear names, targeted logs, no comments that just repeat the code
- [ ] Every fact stated in a new/moved comment (ticket, date, author, historical reason) is independently verified, not inferred — none invented
- [ ] Service/Repository/Validator separated; Value Objects instead of magic numbers and positional tuples
- [ ] Specific exceptions, verified with tests that force the real failure
- [ ] Queries with bind parameters (not concatenation), no mutable formatters/parsers shared in static fields, immutable Value Objects — none of these change an observable output
- [ ] Coverage ≥80% per new class, guard branches included
- [ ] Verified end-to-end locally with real data, not just the automated build/test
- [ ] Reviewed the finished class cold, as a fresh PR — not just the lines touched during the move (Step 13)
- [ ] Documentation/references naming the moved class updated, if any exist (e.g. a code-review doc or a README naming the god class)
- [ ] Build/test green at the final step, not just halfway through
- [ ] If more flows remain in the god class, none of them started before every item above was checked for this one

---

See `principles.md` for the general principles this procedure puts into practice step by step.
