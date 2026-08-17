---
name: software-design-principles
description: Software design principles (SOLID, Value Object, Tell Don't Ask, DDD, Hexagonal, Strangler Fig, etc.) and a step-by-step procedure for extracting a flow from a legacy god class without breaking anything. Use this skill whenever you write, review, or refactor code in any project — when deciding whether to introduce an interface/abstraction, when weighing a generic catch(Exception e), when you spot magic numbers or positional tuples, before opening a PR, or when you need to extract/isolate a method from an oversized legacy class (god class) without a big-bang rewrite. Also trigger it just for the working checklist before starting a task or before opening a PR.
---

# Software design principles

A general (language/stack-agnostic) guide for writing code, reviewing it, and organizing projects. Two reference files, load them only when needed:

- `references/principles.md` — 20 principles (SOLID, Composition over Inheritance, Value Object, Tell Don't Ask, Law of Demeter, DRY/KISS/YAGNI, named design patterns, CQS, specific exceptions, readability, tactical/strategic DDD, Hexagonal, package by feature, Anti-Corruption Layer, Strangler Fig, Modular Monolith, Shared state beyond its boundary — server-side concurrency and client-side singletons, Legacy code/Characterization Test, Fail Fast). For each: what it is, the code smell that reveals its absence, how to apply it, an example, **when NOT to apply it**. Open this file when deciding whether a pattern applies to the code in front of you, or when the code shows one of the smells listed below.
- `references/god-class-extraction-playbook.md` — a 0→12 procedure for extracting a method/flow from a legacy god class (any language) without losing behavior: map dependencies, extract without deleting the old code, move the tests, remove dead code, handle shared code (Strangler Fig with an explicit completion criterion), isolate the fix, readability pass, Service/Repository/Validator separation, specific exceptions, hardening (parameterized queries, no shared mutable state), coverage, end-to-end verification. Open this file when the task is exactly "extract/isolate code from an oversized legacy class".

## How to use it

You don't need to read both reference files in full every time. Typical flow:

1. **New task/incoming PR** → skim the checklist below (taken from `principles.md`) before starting.
2. **Deciding whether a pattern applies** (interface? Value Object? Strategy? generic exception?) → open `references/principles.md` and look up the principle by name — each one has a "when NOT to apply it" section: always read it together with "how to apply it", the most common mistake isn't ignoring the principles but overusing them.
3. **Extracting a piece of code from a god class/oversized legacy file** → open `references/god-class-extraction-playbook.md` and follow the steps in order, don't skip them: every step must leave the build green before moving to the next.

## Working checklist (keep this in mind at all times)

**Before starting**
- Does this change touch business logic? Where *should* it live — in the domain or in the service? (Tell Don't Ask)
- Am I about to couple the domain directly to a technical detail (DB, HTTP, file), or does it already go through an interface? (Dependency Inversion / Ports & Adapters)
- Does the task touch both modern and legacy code? Does it need an explicit translation boundary? (Anti-Corruption Layer)
- Is the code to touch legacy and untested? The first test captures the *current* behavior (bugs included), not the "correct" one (Characterization Test).

**While developing**
- An `if/else`/`switch` that's likely to grow → consider Strategy.
- A validation/formatting duplicated for the same concept → consider a Value Object.
- A getter chain longer than 2 levels → Law of Demeter.
- Abstracting something that only repeats 1-2 times "because it might be needed" → stop, YAGNI.
- Writing a generic ("catch everything") catch block → check which exception/error the deepest call in the block can genuinely raise and catch that, unless this really is a generic external entry point (a filter/middleware, a job's entry point).
- Extending a class only to reuse its behavior, not because the relationship is genuinely "is-a" → compose and delegate instead (Composition over Inheritance).
- Touching/adding a mutable static/global field (or a non-thread-safe object) in code used by concurrent requests (server), or state tied to a user/session inside a singleton service (client, e.g. Angular `providedIn: 'root'`, a React/Vue store)? Who resets it and when? (Shared state beyond its boundary)
- Validating data that's already been validated elsewhere in the flow instead of at the real trust boundary → Fail Fast.

**Before opening the PR**
- Does this class have more than one reason to change? (SRP)
- Could you give this solution a pattern name? If it looks ad-hoc, reread the principles.
- Touched legacy code with no explicit removal plan? (Strangler Fig)
- Deliberate duplication → is there a note (`REFACTOR NOTE` or similar) stating what, why, and the removal criterion — not just "TODO: clean up"?
- Every touched method reread with fresh eyes: size, variable names, comments that survive "if I delete it, does it still make sense?"

## Note

Both reference files are written to be language/project-independent: where a concrete technical example is needed (an exception type, a non-thread-safe library, a coverage command), it's flagged as an illustration from a specific ecosystem (often Java, for historical reasons of the source material), with an invitation to adapt it to your own stack — not as a requirement. The playbook's steps (map dependencies → extract without deleting → move tests → remove dead code → isolate the fix → separate responsibilities → hardening → coverage → end-to-end verification) hold in any stack.

## Pairs well with [ponytail](https://github.com/DietrichGebert/ponytail)

Opposite pole, same discipline. Ponytail asks "does this need to exist at all?" before you write anything; this skill answers "given that it needs to exist, which structure, and how do you extract it safely from a legacy mess?" Run both: ponytail keeps this skill honest (a principle applied without judgment is over-engineering with better vocabulary — every principle here ends in a "when NOT to apply it" for that reason), and this skill keeps YAGNI from becoming an excuse to skip tests or ship an unisolated fix.
