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

---

## Step 1 — Extract without deleting the old one

Create the new class/module (in the project's services package/folder, or its convention's equivalent) with a faithful copy of the code — same logic, same bug if there is one, no cleanup yet. The goal of this step is to *move*, not to improve.

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
- **Names**: cryptic abbreviations inherited from legacy layouts/systems (e.g. Hungarian-notation prefixes, raw column names) → names that say what they hold in the current domain.
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

---

## Definition of done (condensed checklist)

- [ ] Old code removed from the god class, verified "dead" even toward external templates/resources
- [ ] Shared code duplicated with a `REFACTOR NOTE` and an explicit removal criterion (or consolidated, if this is the second consumer)
- [ ] Fix applied as its own isolated step, with a test that failed before and passes after
- [ ] Short methods, clear names, targeted logs, no comments that just repeat the code
- [ ] Service/Repository/Validator separated; Value Objects instead of magic numbers and positional tuples
- [ ] Specific exceptions, verified with tests that force the real failure
- [ ] Queries with bind parameters (not concatenation), no mutable formatters/parsers shared in static fields, immutable Value Objects — none of these change an observable output
- [ ] Coverage ≥80% per new class, guard branches included
- [ ] Verified end-to-end locally with real data, not just the automated build/test
- [ ] Documentation/references naming the moved class updated, if any exist (e.g. a code-review doc or a README naming the god class)
- [ ] Build/test green at the final step, not just halfway through
- [ ] If more flows remain in the god class, none of them started before every item above was checked for this one

---

See `principles.md` for the general principles this procedure puts into practice step by step.
