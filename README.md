<h1 align="center">Software Design Principles</h1>

<p align="center">
  <em>Twenty principles with teeth: what they are, the smell they catch, and — just as important — when to leave them alone.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-111111?style=flat-square" alt="MIT license">
  <img src="https://img.shields.io/badge/for-Claude%20Code-111111?style=flat-square" alt="For Claude Code">
  <img src="https://img.shields.io/badge/status-early%20%26%20validated%20once-111111?style=flat-square" alt="Status: early, validated once">
</p>

---

Most "clean code" references are a wall of theory you read once and never open again. This one is a [Claude Code](https://claude.com/claude-code) skill: a checklist and 20 principles the agent actually consults mid-task — before touching business logic, while deciding whether that `catch (Exception e)` deserves a narrower type, before extending a class "just to reuse a method". Each principle carries the same four questions: what it is, what it fixes, how to apply it, and — the part most guides skip — **when not to**. The second most common mistake, once you know the principles, isn't ignoring them. It's applying them everywhere.

A second, longer document — the **god-class extraction playbook** — walks through extracting one flow out of an oversized legacy class (Java, Python, PHP, doesn't matter) without a big-bang rewrite: map the dependencies first, copy before you delete, move the tests, isolate the bug fix from the move, harden last. Twelve steps, each one required to leave the build green before the next starts.

## What's inside

```
SKILL.md                                   entry point: when to trigger, working checklist
references/principles.md                   the 20 principles, in full
references/god-class-extraction-playbook.md  the 0→12 extraction procedure
```

**The 20 principles**, grouped the way the doc groups them:

| Writing code (micro) | Organizing a project (macro) |
|---|---|
| SOLID · Composition over Inheritance | Tactical & strategic DDD |
| Value Object & Immutability | Hexagonal Architecture |
| Tell, Don't Ask · Law of Demeter | Package by feature vs by layer |
| DRY / KISS / YAGNI | Anti-Corruption Layer |
| Named design patterns | Strangler Fig |
| Command-Query Separation | Modular Monolith |
| Specific exceptions | Shared state beyond its boundary |
| Readability (methods/vars/comments) | Legacy code: Characterization Test |
| | Fail Fast: where to validate, where to trust |

## How it works

Before a review or a refactor, the skill runs through the same three questions the working checklist asks on every task:

```
1. Does this decision have a name?        → look it up, don't reinvent it worse
2. Does the principle's "when not to"      → read it before applying the "how to" —
   apply here?                               that's where most misuse hides
3. Is this legacy and untested?           → the first test captures what IS,
                                              not what SHOULD be (Characterization Test)
```

The god-class playbook adds one more: map who else calls the code you're about to move, *before* you move it — the plan for "exclusive use" and "shared use" is not the same, and finding out mid-extraction is expensive.

## Validated on

No synthetic benchmark yet — this is genuinely early. What it has done so far, on one real Spring Boot + Angular app:

- **Caught a real bug**: a generic `RuntimeException` in a service method was silently mapped to a 500 by the global handler instead of a 404 — traced by reading the exception handler, not guessed. Fixed and verified with the existing test suite (21/21 green).
- **Caught a second one, client-side**: an Angular singleton service holding an admin's unread-notification count with no reset on logout — the exact "shared state beyond its boundary" smell principle 18 describes, found by applying the principle, not the other way around.
- **Ran the extraction playbook end-to-end**: pulled a ZIP-export feature out of an oversized gallery component into its own service, step 0 through 12. Step 0's dependency mapping caught an already-diverged duplicate of the same feature in a second component *before* the extraction started — exactly the situation the playbook's "shared use" branch exists for.

One project, two languages, a handful of files. Small sample, real findings — treat it as promising, not proven.

## Pairs well with [ponytail](https://github.com/DietrichGebert/ponytail)

They pull in opposite directions on purpose, and that's the point.

Ponytail's first question is *"does this need to exist at all?"* — stdlib before a library, one line before fifty, delete before add. This skill's job starts one step later: *given that it needs structure, which structure, and how do you get there without breaking what's already running?* SOLID, Value Objects, Strategy, DDD — all of it is exactly the kind of thing ponytail will (correctly) push back on if you reach for it out of habit instead of need.

Run both at once, not one instead of the other:

- Ponytail keeps this skill honest — every principle here ends in a "when NOT to apply it" section for the same reason ponytail exists: **structure applied without judgment is over-engineering with better vocabulary.**
- This skill keeps ponytail's YAGNI from becoming an excuse — the god-class playbook is proof that "the lazy way" and "the safe way" aren't opposites: extracting without deleting, testing before fixing, hardening last, isn't extra ceremony, it's the shortest path that doesn't regress.

If you only install one: install ponytail first, it's the one that stops you from writing code you don't need. Add this one when you're about to write code you *do* need and want it to hold up.

## Install

```bash
git clone https://github.com/gufettonerd-arch/software-design-principles ~/.claude/skills/software-design-principles
```

Claude Code picks up user-level skills from `~/.claude/skills/`. For a single project instead, clone into `.claude/skills/` at the repo root.

Restart the session (or start a new one) so the skill shows up in the available-skills list.

## License

[MIT](LICENSE).
