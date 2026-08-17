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
.claude-plugin/marketplace.json                           lets /plugin install this repo directly
.claude-plugin/plugin.json                                plugin manifest (no hooks, no commands — skill only)
skills/software-design-principles/SKILL.md                entry point: when to trigger, working checklist
skills/software-design-principles/references/principles.md                    the 20 principles, in full
skills/software-design-principles/references/god-class-extraction-playbook.md the 0→12 extraction procedure
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

## Known limitations

Nothing here blocks usage — it's MIT, plain markdown, zero runtime dependencies, zero config. But before you install it expecting it to behave exactly as it did for the author, know this:

- **Trigger accuracy is untuned.** The `description` field is what an agent matches against your request to decide whether to consult the skill. It was written by hand, not run through a trigger-accuracy eval loop (query variety, hit rate measured, description iterated against it). It may under- or over-trigger on phrasing the author never tried.
- **Validated on one project, by one person.** Everything under "Validated on" above comes from a single Spring Boot + Angular codebase. Principle 18 already had a real gap (missed the client-side case entirely) that only surfaced once it was applied outside the context it was written in — expect more gaps like that on a different stack.
- **Examples still skew OOP.** The prose is written to be language-agnostic, but concepts like SOLID, Strategy, DDD, and Hexagonal are inherently object-oriented framings. On a functional or non-OOP-heavy codebase, several principles will need more translation than the text implies.
- **No auto-update.** A `git clone` install is a snapshot. If the principles get revised later, installs don't learn about it — see [Install](#install).
- **Verified on two hosts, not more.** Confirmed working unchanged on Claude Code and [OpenJarvis](https://github.com/openjarvis) (same files, no edits). The skill format follows the [agentskills.io](https://agentskills.io/specification) standard, so it should work on any compliant host — but "should" isn't "verified" for anything beyond those two.
- **Installing via an indexed-skill flow may show a generic warning.** Hosts with a trust-tier system (e.g. OpenJarvis's `jarvis skill install github:...`) classify anything from an unindexed GitHub repo as "unreviewed" and show a sandbox notice — not because the skill declares any dangerous capability (it declares none), just because it hasn't been submitted to that host's official index.

## Pairs well with [ponytail](https://github.com/DietrichGebert/ponytail)

They pull in opposite directions on purpose, and that's the point.

Ponytail's first question is *"does this need to exist at all?"* — stdlib before a library, one line before fifty, delete before add. This skill's job starts one step later: *given that it needs structure, which structure, and how do you get there without breaking what's already running?* SOLID, Value Objects, Strategy, DDD — all of it is exactly the kind of thing ponytail will (correctly) push back on if you reach for it out of habit instead of need.

Run both at once, not one instead of the other:

- Ponytail keeps this skill honest — every principle here ends in a "when NOT to apply it" section for the same reason ponytail exists: **structure applied without judgment is over-engineering with better vocabulary.**
- This skill keeps ponytail's YAGNI from becoming an excuse — the god-class playbook is proof that "the lazy way" and "the safe way" aren't opposites: extracting without deleting, testing before fixing, hardening last, isn't extra ceremony, it's the shortest path that doesn't regress.

If you only install one: install ponytail first, it's the one that stops you from writing code you don't need. Add this one when you're about to write code you *do* need and want it to hold up.

## Install

### Claude Code (plugin, recommended)

```
/plugin marketplace add gufettonerd-arch/software-design-principles
/plugin install software-design-principles@software-design-principles
```

This is the only install path that gets you updates — see [Known limitations](#known-limitations). Auto-update is off by default for third-party marketplaces like this one; turn it on from `/plugin` → **Marketplaces** → *Enable auto-update*, or pull the latest manually with `/plugin marketplace update software-design-principles`.

### Any skill-capable agent (manual)

```bash
git clone https://github.com/gufettonerd-arch/software-design-principles /tmp/sdp
cp -r /tmp/sdp/skills/software-design-principles ~/.claude/skills/software-design-principles
```

Swap the destination for your host's user-level skills folder (e.g. `~/.openjarvis/skills/` for OpenJarvis) — the skill itself is just `SKILL.md` + `references/`, no Claude-specific parts. For a single project instead of user-wide, copy into `.claude/skills/` (or the equivalent) at the repo root. This path is a snapshot: see [Known limitations](#known-limitations) for what that means.

Restart the session (or start a new one) so the skill shows up in the available-skills list.

## License

[MIT](LICENSE).
