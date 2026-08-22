# Software Design Principles

A guide for writing code, reviewing it, and organizing a project — meant to be reused on any project and any language, not tied to one stack. The principles are general; examples are written in pseudocode or in a common syntax (C-like/OOP style), and where a technical detail is language-specific (e.g. an exception type, a non-thread-safe library) it's flagged as such, with a pointer to the equivalent in your own stack.

This isn't a list to read once and file away: it's meant to be consulted **before every task** (see the "Working checklist" section at the bottom) and updated with your own notes whenever you find a concrete example in your work.

---

## How it's organized

Two levels, because they're two different problems:

- **Part 1 — Writing code (micro)**: principles that apply to a class, a method, a module. You use these every day, in every PR.
- **Part 2 — Organizing a project (macro)**: principles that apply to folder structure, boundaries between modules, migrating legacy code. You use these when designing a new feature or revisiting the architecture.

For each principle you'll find: **what it is**, **the problem it solves** (the code smell that reveals its absence), **how to apply it** in practice, an **example**, and **when NOT to apply it** — because the most common risk, once you're past the "I didn't know these" stage, isn't ignoring them but overusing them.

## Table of contents

**Part 1 — Writing code**
1. SOLID
2. Value Object & Immutability
3. Tell, Don't Ask
4. Law of Demeter
5. DRY / KISS / YAGNI
6. Named design patterns (Strategy, Factory, Builder, Specification)
7. Command-Query Separation
8. Specific exceptions, not generic ones
9. Readability: methods, variables, comments

**Part 2 — Organizing a project**
10. Domain-Driven Design (DDD) — tactical part
11. Domain-Driven Design — strategic part (Bounded Context)
12. Hexagonal Architecture / Ports & Adapters (Clean/Onion Architecture)
13. Package by feature vs package by layer
14. Anti-Corruption Layer (ACL)
15. Strangler Fig Pattern
16. Modular Monolith
17. Composition over Inheritance
18. Shared state beyond its boundary (server-side concurrency, client-side survival)
19. Legacy code: Characterization Test first
20. Fail Fast: where to validate, where to trust

**Also in this file**: Suggested learning roadmap, Working checklist, How to measure progress over time.

---

# Part 1 — Writing code

## 1. SOLID

**What it is**: five OOP principles.
- **S**ingle Responsibility — a class has only one reason to change.
- **O**pen/Closed — open for extension, closed for modification (add behavior without touching existing code).
- **L**iskov Substitution — a subclass must be substitutable for its superclass without breaking the caller.
- **I**nterface Segregation — many small, specific interfaces beat one large, generic one.
- **D**ependency Inversion — depend on abstractions (interfaces), not concrete implementations.

**Problem it solves**: classes that grow huge and fragile, where every change risks breaking something else.

**How to apply it**:
- When a class has more than one reason to be modified (e.g. "changes if the business logic changes" *and* "changes if the persistence format changes"), split it.
- When adding a new case forces you to modify an existing `if/else`/`switch` instead of adding a new implementation, that's a sign of an Open/Closed violation.
- Before injecting a concrete class into a constructor, ask: "does an interface already exist, or would it make sense to create one?" — especially for anything touching I/O (repositories, HTTP/SOAP clients, filesystem).

**Example**: a domain class that depends directly on a concrete persistence class (an ORM repository, a DAO, a concrete HTTP client) instead of an abstract interface violates Dependency Inversion — the domain should define *what* it needs, not *how* it's implemented. Another frequent case: a thousands-of-lines "god class" that handles orchestration, data access, and validation together — splitting it into classes with one responsibility each (orchestration, data access, validation: see the god-class extraction playbook) is the most direct application of Single Responsibility. A concrete sign the refactor worked: the resulting orchestration class no longer has any direct dependency on the data-access library.

**When NOT to apply it**: don't create an interface for every class "just because" — if a class has only one possible implementation and no need for test doubles (mocks), the interface is just indirection with no value (YAGNI, see below).

---

## 2. Value Object & Immutability

**What it is**: modeling a concept (a code, an amount, an identifier, a date range) as a small immutable type with its own behavior, instead of passing it around as a raw string/number.

**Problem it solves**: validation/formatting logic duplicated everywhere that data is used; no guarantee the data is always valid.

**How to apply it**:
- If you notice you're writing the same validation/parsing on a string in multiple places (e.g. a product code, a phone number), that's the signal: encapsulate it in a type.
- No public setters: build the object valid once, then it's immutable.
- Equality by value (two Value Objects with the same data are equal), not by identity.

**Example**: a `ProductCode` or `PhoneNumber` type that parses/normalizes a raw string and exposes behavior (`isLowCost()`, `isNational()`), with no setters, is the base form. Three different code smells that lead to the same principle: (1) a numeric threshold repeated as a raw comparison (`amount >= 1700`) in multiple places in the code — it's exactly that repetition, not textual but conceptual, that causes real bugs when a spot forgotten during a change is left with the old threshold; a dedicated Value Object centralizes it in one place. (2) A fixed-length record read with offsets/`substring` and magic numbers scattered through the code, encapsulated instead behind named methods (`isLocked()`, `brand()`, `priority()`). (3) A positional tuple (a list or array read by index, `[0]`/`[1]`) replaced by a named type with methods (`isValid()`, `priority()`) instead of indices nobody remembers the meaning of.

**When NOT to apply it**: for a field used in exactly one place, with no associated logic, a primitive type is perfectly fine — don't encapsulate on principle.

---

## 3. Tell, Don't Ask

**What it is**: give behavior to objects instead of pulling their data out with getters and deciding outside.

**Problem it solves**: business logic scattered across callers instead of living close to the data it concerns — the first step toward an "anemic model" (see DDD below).

**How to apply it**: if you write `if (booking.getStatus() == X && booking.getDate().isBefore(Y))`, ask whether that condition shouldn't be a `booking.isConfirmed()` method on the object itself.

**Example**: a `booking.isConfirmed()` method on the domain object is correct; an object that exposes only public getters/setters and leaves all transformation logic to the calling service is the opposite pattern, worth fixing when you write new code there. The same principle applies to an object that reads an external format (a fixed-length record, a network response): answering questions about its own content (`isLocked()`, `matchesBrand(x)`, `needsDateCheck()`) instead of exposing raw fields and leaving the caller to interpret them — the calling code moves from manipulating offsets/substrings to reading a sequence of named questions.

**When NOT to apply it**: pure DTOs used only for (de)serialization (HTTP requests/responses) are correctly plain data bags — they don't need behavior there, that's a different context (see "DTO vs Entity vs Domain Object" further below).

---

## 4. Law of Demeter

**What it is**: only talk to your direct "neighbors". Avoid chains like `a.getB().getC().getD()`.

**Problem it solves**: hidden coupling — if `B`'s internal structure changes, code that has nothing to do with `B` breaks.

**How to apply it**: if a getter chain goes past 2 levels, consider adding a method that hides that path (e.g. `booking.travelNumber()` instead of `booking.getHeader().getTravel()`).

**When NOT to apply it**: with purely structural/immutable objects (e.g. composed Value Objects), some level of navigation is normal and not a real coupling problem.

---

## 5. DRY / KISS / YAGNI

**What it is**: three complementary heuristics, often in tension with each other.
- **DRY** (Don't Repeat Yourself) — don't duplicate the same *knowledge* (not necessarily the same code text).
- **KISS** (Keep It Simple) — the simplest solution that solves the problem is the right one.
- **YAGNI** (You Aren't Gonna Need It) — don't build flexibility/abstractions for a hypothetical future need.

**Problem it solves**: on one side, duplication that makes bug fixes incomplete (you fix it in one place, forget the other); on the other, over-engineering that makes the code harder to understand than it needs to be.

**How to apply it**: two separate questions, in this order — asking them out of order is the trap. First, *is it actually the same knowledge*: if this rule changes, does the other one have to change too, for the *same* reason? A shape that repeats — three near-identical one-line methods, three similar-looking validations — can rack up an instance count without ever being the same knowledge; a String reading `"contains('@')"` twice for two unrelated purposes looks like duplication and isn't. Instance count can't answer this question, only the meaning behind each copy can. Only once the answer is yes does the second question (timing) matter: has it repeated 3 times with the same meaning, or is the need still hypothetical (rule of three)? If the first two occurrences already prove the need is real — the code itself says more consumers are coming, or a shared rule with a name attached to it is duplicated verbatim — don't wait for a third just to satisfy the rule of thumb; if it's genuinely still just two occurrences with no evidence a third is coming, wait.

**Example**: a frequent case of unmet YAGNI — a mapping/code-generation tool configured across the whole build (dependency + annotation processor/plugin) but used in a single class: tooling set up for a need that never materialized. On the flip side, while extracting shared code out of a god class, the question "do I create a shared class right now, or wait for a real third occurrence?" comes up often. If the original code already explicitly states (in a comment or a caller count) that many other consumers haven't been migrated yet, the future need isn't hypothetical — that's not the case where YAGNI applies to "whether" to consolidate. But the shared class should only be created once a *second* flow that would duplicate the same logic again concretely shows up, not at the first extraction — so you don't introduce an abstraction with a single consumer. Rule of three applied with judgment (the real signal is the need being real, not the literal copy count).

**A second example, the coincidence trap specifically**: `isEligibleForFreeShipping(Order o)`, `isEligibleForLoyaltyPoints(Order o)`, and `isEligibleForGiftWrap(Order o)` each boil down to one line — `return o.getTotal() >= threshold`. Same signature, same shape, three occurrences: everything the rule of three looks for. It's tempting to extract one shared `isEligible(Order o, double threshold)` and call it done. But look at what each threshold *means*: free shipping's is a shipping-cost break-even point set by logistics, loyalty points' is a marketing-tier boundary set by the loyalty program, gift wrap's is an operational capacity limit set by the warehouse — three unrelated business rules owned by three different teams, that happen to compile down to an identical one-liner. If free shipping's threshold changes tomorrow, nothing about loyalty points or gift wrap has any reason to change with it — that's the knowledge-question answer, and it's "no," regardless of the shape repeating three times right now or growing to five later. A shared `isEligible` here wouldn't remove duplication, it would manufacture a dependency between three business rules that were never actually connected — the day any one of them needs to diverge (and being unrelated, they will), the "shared" method either becomes wrong for two of its three callers or grows a branch per caller, which is strictly worse than the three separate one-liners it replaced. Counting occurrences never settles this; only checking whether each one has the same *reason* to exist does.

**When NOT to apply it**: KISS doesn't justify avoiding the patterns listed here when the problem genuinely calls for them — "simple" doesn't mean "without structure", it means "without superfluous structure". And don't let the rule of three stand in for the knowledge question above: counting instances is a timing heuristic for *when* to act on a duplication that's already confirmed real, not a way to decide *whether* something is duplication in the first place — a third, fourth, or Nth copy of a coincidentally similar-shaped but conceptually unrelated snippet is still not DRY's concern, no matter how repetitive the block looks stacked three or four times.

---

## 6. Named design patterns (Strategy, Factory, Builder, Specification)

**What it is**: recurring solutions to recurring problems, with a shared name — useful for communicating quickly with other developers ("it's a Strategy") instead of describing the structure from scratch.

**Problem it solves**: reinventing (possibly worse) a solution that's already known; code that does the same thing as a Strategy/Factory but with no name, so it's harder to recognize.

**How to apply it**: when you notice you're writing an `if/else`/`switch` on a type to pick a behavior, and that list is set to grow, consider the **Strategy pattern** (an interface + many implementations, selected at runtime).

**Example**: a textbook case — a common interface with many implementations (even 20-30), orchestrated in order by a coordinating class. Recognizable at a glance as a Strategy by anyone joining the team, and easier to extend (add an implementation) than to modify (touch a giant `if/else`).

**When NOT to apply it**: if there are only 2 implementations and they won't grow, a plain `if/else` is more readable than a pattern spread across multiple files.

---

## 7. Command-Query Separation

**What it is**: a method should *either* answer a question (query: returns a value, no side effects) *or* do something (command: produces an effect — writes, logs, mutates state), never both. It's a companion principle to Tell, Don't Ask: that one says "give behavior to objects", this one adds "but don't let method names lie about what that behavior involves".

**Problem it solves**: methods with a name that promises only an answer (typically `is*`/`has*`/`get*`) but that hide a side effect — whoever calls them to "just check a fact" ends up with unrequested consequences (a log written, state mutated), often without noticing, and calling them repeatedly or in a test becomes risky.

**How to apply it**: when you write a method that looks like a question (`has...`, `is...`, `get...`), verify its body does *only* that. If you also need to log, notify, or mutate state in response to the result, keep that responsibility in the caller (or in a separate, explicitly-called command method), not inside the query.

**Example**: while refactoring a Value Object that validates a fixed-format field (see point 2), the temptation is to have the check methods (`hasMinimumLength()`, `isNumeric()`) log directly when validation fails, to shorten the caller to a single `if`. Worth discarding precisely because of this principle: those methods are called as questions, they should behave as questions — the logging (a command, with a message specific to the caller's context) stays in the caller, which often needs different messages depending on which check failed.

**When NOT to apply it**: methods that compute a value at a cost (expensive queries, e.g. a network call or a DB query) sometimes log for internal diagnostics (timing, cache hit/miss) — this is an accepted gray area when the logging is purely observational and doesn't alter behavior or surprise whoever calls the method for its return value.

---

## 8. Specific exceptions, not generic ones

**What it is**: catching (and declaring) exactly the exception/error types a block can genuinely raise, not a generic "catch everything" type.

**Problem it solves**: a generic catch traps everything — including real bugs (a programming error elsewhere in the same block, a failed cast, etc.) — and treats them the same as an expected failure (e.g. a query failing due to a network issue). This hides bugs instead of surfacing them: a swallow-and-continue over *everything* means a programming error produces the same "silent degradation" as a legitimate I/O failure, and readers can no longer tell, from the caught type, what the block expects might go wrong.

**How to apply it**: look at which exception/error the deepest call in the block can genuinely raise (e.g. a data-access exception for a query, a parsing exception for a format conversion) and catch that, not the generic type. If the block can realistically also produce "undeclared" errors (e.g. a null value on missing data), handle them explicitly instead of widening the catch for convenience.

**Example**: data-access and validation methods written faithfully from legacy code with a generic catch, copied from the original during an extraction — a common anti-pattern (in the Java ecosystem, this is Sonar rule S112). Narrowed to the exception genuinely raisable at that point (e.g. a data-access exception in the block talking to the database, a parsing exception plus any realistic errors on missing data in the validator). Verified with a test that *actually* forces that failure (a nonexistent schema/table for the data-access exception, a non-convertible value for the parsing exception), not simulated — the narrowing shouldn't reduce error handling, only its width.

**When NOT to apply it**: at a very external, generic entry point (an HTTP filter/middleware, a job's entry point) a final generic catch that logs and returns a generic error is correct and intentional — it's the application's last safety net, not a block where you're expected to already know which exceptions can arrive.

---

## 9. Readability: methods, variables, comments

**What it is**: three tightly related disciplines, exercised together every time you write or review a method.
- **Methods** — do one thing, read top to bottom without jumping back and forth; no deep nesting when guard clauses would do.
- **Variables** — names that say what they hold (not abbreviations inherited from other languages or legacy layouts), declared as close as possible to where they're used, not all at the top of the method out of habit.
- **Comments** — explain the non-obvious *why* (a hidden constraint, a counterintuitive choice, a reference to a bug/ticket), never the *what* that's already readable from the code itself.

**Problem it solves**: code that has to be "figured out" instead of "read" — a 100-line method with 7 levels of nesting, variables with names like abbreviated codes declared all together at the top and reassigned multiple times, comments that repeat the line below instead of explaining why that line exists. The cost isn't cosmetic: anyone touching that code in the future (including you, six months from now) starts from zero rebuilding the flow instead of reading it.

**How to apply it**:
- If a method does more than 4-5 independent sequential things, extract a method per thing — a well-chosen method name replaces the comment that would explain what that block does.
- If a method validates N conditions in sequence and each can interrupt the flow, flatten with guard clauses (`if (!condition) return X;`) instead of nesting `if/else`.
- Declare a variable as close as possible to its first use, not before. A variable reassigned multiple times in a long method is almost always a sign the method needs splitting — decomposition fixes both problems at once.
- Before writing a comment, ask: "if I delete it, will the next reader understand just as well?" If yes, delete it. If no — because it explains a constraint/rationale not derivable from the code — keep it, short.
- Apply the same eye to logs as to comments: one log per rejection/failure reason, with the involved record's identifier, is more useful than an indiscriminate dump of the whole object on every call.

**Example**: a ~100-line validation method, 7 levels of nesting, abbreviated-name variables all declared together and read repeatedly by offset/index, two log lines that printed the entire raw record on every call regardless of outcome. After rewriting: a flat method with one guard clause per condition, each with a log specific to the rejection reason instead of an indiscriminate dump; fields read through a dedicated Value Object (see principle 2) instead of offsets scattered through the code, variables declared one at a time where they're needed.

**When NOT to apply it**: don't fragment an already-short, linear method (5-10 lines) just to "follow the rule" — decomposition makes sense when a method does multiple independent things, not when it's already a simple sequence. A comment explaining a genuinely non-obvious algorithm (a calculation, a workaround for a library bug) stays useful even if it describes the "what": the "why only" rule has an exception when the "what" itself isn't obvious from the code at all.

---

# Part 2 — Organizing a project

## 10. Domain-Driven Design (DDD) — tactical part

**What it is**: modeling code around the real concepts of the business domain (not around database tables), distinguishing:
- **Entity** — has an identity that persists over time (e.g. a booking).
- **Value Object** — see point 2.
- **Aggregate root** — the single entry point through which a group of related objects is read/modified as a consistency unit (instead of letting callers touch internal parts independently).
- **Domain Service** — business logic that doesn't naturally belong to a single object.
- **Repository** — an abstraction (interface) defined by the domain to fetch/save aggregates, whose real implementation lives in infrastructure.

**Problem it solves**: the "anemic model" — classes that are just getters/setters, with *all* business logic moved into services. It works, but becomes fragile: nothing prevents putting the object into an invalid state, and business logic is scattered instead of living close to the data.

**How to apply it**:
- Identify your domain's aggregates: which groups of data must always be consistent together?
- Give behavior to domain objects (see Tell Don't Ask), not just to services.
- Explicitly distinguish three levels that often get confused: **persistence entity** (can stay anemic: many ORMs need mutability) → **domain object** (where business logic lives, should be rich) → **DTO** (HTTP input/output, rightly anemic).

**Example**: a well-built aggregate root wraps an anemic persistence entity (correctly so) and adds real behavior (e.g. `isConfirmed()`, `daysUntilDeparture()`). Conversely, it's common for other classes at the same domain level to stay anemic (getters/setters only) — an inconsistency worth noting when you write new code in that area, not necessarily something to fix everywhere right away.

**When NOT to apply it**: for a simple CRUD with no real business rules (e.g. a configuration table), tactical DDD is pure overhead — use it where business logic is genuinely complex.

---

## 11. Domain-Driven Design — strategic part (Bounded Context)

**What it is**: the part of DDD concerned with project structure, not individual classes. A **Bounded Context** is an explicit boundary within which a model and its language (the terms used) are consistent — outside that boundary, the same term can mean something else.

**Problem it solves**: a single layered architecture shared by all business features (e.g. `controller/`, `service/`, `repository/` holding everything, mixing unrelated features) makes it hard to tell what belongs to what, and every change risks touching unrelated code.

**How to apply it**: when designing a new feature, ask which "business area" it belongs to, and consider grouping it by capability (`booking/`, `privacy/`, each with its own controller+service+domain) instead of by technical layer.

**Example**: a project where all features (e.g. bookings, payments, notifications, reporting) share the same `controller/service/domain/repository` packages — no explicit bounded context. This is often the biggest architectural gap in a project that grew without explicit design, but **shouldn't be fixed with a big refactor**: it's a risky structural change, worth evaluating only if the project grows a lot or different teams start working on different areas.

**When NOT to apply it**: on a small/medium project with a single team, splitting by bounded context adds ceremony with no real benefit — it's an investment that only pays off past a certain complexity.

---

## 12. Hexagonal Architecture / Ports & Adapters (Clean/Onion Architecture)

**What it is**: the domain defines interfaces ("ports") for everything it needs from the outside (persistence, external services); infrastructure implements those interfaces ("adapters"). The domain never depends on a concrete technical detail.

**Problem it solves**: exactly the violation seen at point 1 — a domain that depends on concrete persistence/infrastructure classes, which makes it impossible to test the domain in isolation and couples business logic to a specific technical choice (e.g. a particular ORM).

**How to apply it**: if a domain class needs to read/write data, make it depend on an interface defined in the domain itself, not on the concrete data-access class.

**Example**: in many projects no repository is a domain abstraction — they're all concrete data-access classes (direct queries, ORM) injected everywhere. The most direct case to fix is a domain class that depends on a concrete repository instead of an interface: it could return the intent to persist, letting the caller (which already depends on the repository) execute the write.

**Example — the "when NOT to apply it" case in practice**: while extracting a flow from a god class, the explicit question came up: "should the new repository be an interface with an implementation (port/adapter), or is a concrete class enough?". Decision: a concrete class, matching the style already used elsewhere in the project for data access. Reason: no other class in the project uses DI/interfaces for data access, and tests already isolate with a real in-memory database, not mocks — an interface here would have been indirection with no payoff, not a consequence of the domain genuinely needing to be isolated from a swappable technical detail.

**When NOT to apply it**: for simple CRUD services with no real domain logic to protect, introducing ports/adapters is pure overhead — use it where the domain has real behavior to isolate.

---

## 13. Package by feature vs package by layer

**What it is**: two ways to organize folders.
- **By layer**: `controller/`, `service/`, `repository/`, `domain/` — each folder holds classes of *different technical types*, across *all* features.
- **By feature**: `booking/` (with its own controller, service, domain, repository inside), `privacy/`, etc. — each folder holds *everything* needed for one feature.

**Problem it solves**: with "by layer" on a growing project, finding everything related to a feature means jumping across 4-5 different folders; with "by feature" all related code sits together.

**How to apply it**: it's the practical consequence of adopting bounded context (point 11) — not a change to make in isolation, but one to consider alongside it.

**When NOT to apply it**: on small projects, "by layer" is easier to navigate for someone who doesn't know the domain yet — there's no absolute winner, it depends on project size.

---

## 14. Anti-Corruption Layer (ACL)

**What it is**: an explicit boundary that translates concepts between two different models (e.g. between your modern domain and a legacy/external system), so the "dirty" details of the other system don't contaminate your model.

**Problem it solves**: when integrating with legacy code or external systems (SOAP, mainframe, old data formats), without an explicit boundary those details end up infiltrating the new code everywhere.

**How to apply it**: when writing code that talks to a legacy/external system, isolate the translation in one single place (a dedicated converter/mapper) — don't let its types/formats propagate into the rest of the domain.

**Example**: a minimal pattern of this kind is a converter that decouples raw database column codes from the names used in the domain (a "coded" enum with its dedicated converter). Also relevant anywhere a modern package/module touches a legacy or deprecated one: that boundary should be made explicit and tight, not left diffuse.

**When NOT to apply it**: if you're integrating with a system that's already well-designed and conceptually aligned with your domain, an extra translation layer is bureaucracy with no value.

---

## 15. Strangler Fig Pattern

**What it is**: a strategy for gradually migrating from a legacy system to a new one, replacing one piece at a time while the system stays functional, instead of a big-bang rewrite.

**Problem it solves**: complete rewrites that take months/years, with high risk and no delivered value until the end.

**How to apply it**:
- Define an explicit criterion for "when a piece counts as migrated" (don't leave it implicit).
- Route traffic/calls to the new implementation piece by piece, keeping the old one as a fallback until you're confident.
- Don't leave old code "paused" indefinitely next to the new one with no removal plan.

**Example**: this is what happens when a project's recent commits move old code into a `deprecated`/`legacy` package with no plan. Worth governing consciously: track what's already migrated, what isn't, and a completion criterion — otherwise that package risks staying there forever.

**Example — a full cycle observed during a god-class extraction**: two shared methods duplicated (not moved) from a god class into a new class, with an explicit comment (`REFACTOR NOTE` or equivalent) stating what's duplicated, why (other callers remain on the original code, not yet extracted), and the removal criterion ("once the original has no more callers, remove it"). The criterion materializes as soon as a second flow that would duplicate the same logic again comes into view: the two methods get consolidated into a shared class instead of being duplicated a second time, and the refactor note on the original is updated to point there. Contrast with a frequent opposite case: a refactor that moves historical debt into new files without consolidating it and without tests — there the duplication never gets a completion criterion and stays indefinitely. In the first case, instead, the duplication is transitional, declared, with a single planned convergence point, and covered by tests before being considered "done".

**When NOT to apply it**: for small, well-isolated modules with no operational risk, a direct replacement can be faster and is normal.

---

## 16. Modular Monolith

**What it is**: a middle ground between a layered monolith and microservices — modules with strong internal boundaries (often enforced by an automated tool) but a single deployment.

**Problem it solves**: the temptation to "go microservices" to fix weak internal boundaries, when the real problem is organizational (missing bounded context), not about deployment.

**How to apply it**: if you adopt bounded context (point 11), consider enforcing boundaries between modules with an automated check (an architectural-enforcement tool for your ecosystem, e.g. ArchUnit in Java, forbidding `booking/` from depending on internal details of `privacy/`), instead of relying on manual discipline.

**Example**: a boundary-enforcement tool is often already available as a dependency in a project even if never activated — infrastructure ready to enforce these boundaries, should the team decide to adopt bounded context in the future.

**When NOT to apply it**: if the project has a single small team and no growth expected, the overhead of automated boundary enforcement doesn't pay off.

---

## 17. Composition over Inheritance

*(Part 1 — writing code; numbered at the end so as not to break the "see principle N" references elsewhere in this document)*

**What it is**: preferring to compose an object with other objects (a "has-a" relationship, delegation) rather than extending a base class (an "is-a" relationship) to reuse behavior.

**Problem it solves**: fragile inheritance hierarchies — a change in the base class propagates unpredictably to every subclass (the "fragile base class problem"), and it's easy to end up with a subclass that inherits methods it doesn't need or has to override to "switch off" inherited behavior, violating Liskov Substitution (principle 1).

**How to apply it**: before extending a class to reuse its behavior, ask whether the relationship is genuinely "is-a" (a `Dog` is-a `Animal`) or just "I want its behavior" (a `Logger` is not a `HashMap` even if it uses one internally). In the second case, inject the object as a dependency and delegate, don't extend.

**Example**: a `PdfReportGenerator` that needs date and number formatting shouldn't extend a `Formatter` class "for convenience" — it should receive an instance in its constructor and delegate. Extending couples the generator to *all* of `Formatter`'s public interface, including methods it doesn't use and that might break down the line.

**When NOT to apply it**: when the "is-a" relationship is genuine and stable (a custom exception extending the language's base exception, a concrete `Strategy` implementing an interface), inheritance is the right tool — the principle doesn't ban inheritance, it bans using it as a shortcut for reuse when the relationship doesn't hold up.

---

## 18. Shared state beyond its boundary (server-side concurrency, client-side survival)

**What it is**: no mutable data shared across multiple "consumers" — concurrent threads/requests on a server, or successive components/users/navigations reusing the same client-side singleton — without an explicit mechanism that isolates or resets it at the right boundary. Same root cause, two different manifestations depending on where the code runs:
- **Server-side** (multi-threaded): a static/global field, or an instance field on an object reused across requests, read/written by different threads with no synchronization.
- **Client-side** (SPA, single-threaded): a singleton service (e.g. an Angular service `providedIn: 'root'`, a React context/store, a module-level store) that keeps mutable state beyond the boundary it should be scoped to — a user session, a navigation, a component — because over the lifetime of a browser tab the singleton is never recreated on its own, unlike a per-request object server-side.

**Problem it solves**: two different symptoms of the same cause. Server-side: silent data corruption under load — a bug you never see locally (one request at a time) that only shows up in production under concurrent traffic, hard to reproduce because the symptom (data mixed between two different requests) doesn't obviously point to the cause. Client-side: leftover data that survives a boundary meant to reset it — the most concrete example is a user logging out on the same tab and another logging in: if the singleton service isn't reset, for an instant (or until the next load) the UI can show the previous user's data.

**How to apply it**:
- Server-side: when you see a static/global field of a type known to be non-thread-safe (a date formatter, a mutable builder or parser — in Java typically `SimpleDateFormat`/`Calendar`/`DecimalFormat`) in a class used by multiple requests, move it to a local variable inside the method, or replace it with your language's immutable/thread-safe standard-library equivalent, if available (e.g. `DateTimeFormatter` in Java, thread-safe by design).
- Client-side: when a singleton service holds state specific to a user/session (not immutable global configuration), explicitly check *who* resets it and *when* — on logout, user switch, or leaving a feature. If there's no explicit point that does this, it's a latent bug: in practice it survives until the page reloads, not until "the request ends" like server-side.

**Example**: server-side, a class used by concurrent web requests declared a shared static field holding a non-thread-safe date formatter, used by every request — a latent bug that never surfaced only because of low traffic; fixed by instantiating it locally inside the method that uses it. Client-side, a singleton service that keeps in a field (or a reactive stream/store) the last result loaded for the current user, with no listener on logout/user-change to clear it — the client-side equivalent of server-side shared static state, except the risk isn't concurrent traffic: it's state surviving past the boundary (session/user) it should be tied to.

**When NOT to apply it**: shared state that's *immutable*, or not tied to a specific user/session (a constant, a configuration/feature flag loaded once at startup, valid the same way for everyone), doesn't have this problem in either form — the rule is about mutability tied to a boundary (thread/request server-side, user/session client-side), not about sharing itself.

---

## 19. Legacy code: Characterization Test first

**What it is**: when touching legacy code with no tests, the first test you write doesn't describe the "correct" behavior — it captures the *current* behavior, bugs included. A concept from Michael Feathers ("Working Effectively with Legacy Code"): a test that protects the change without gating it on an idea of correctness nobody has verified yet.

**Problem it solves**: the temptation, faced with untested legacy code, to immediately write the "correct" test — which often fails before you've touched a single line, because the existing code has wrong or surprising behaviors nobody had noticed. A characterization test instead passes right away (it describes what the code does *now*), and becomes the safety net for the refactor that follows: if you change it and the test goes red, you know you changed behavior — regardless of whether the original behavior was "correct".

**How to apply it**: write a test that calls the existing code with real/representative input and verifies the output matches what the code produces *today*, not what it "should" produce. Only afterward, if you're also fixing a bug, add a second test describing the expected correct behavior — one that must fail until the fix is applied.

**Example**: the entire god-class extraction playbook applies this principle implicitly — its first step requires the build to stay green/red *exactly as before* the extraction, not "correct"; a later step explicitly includes a test that reproduces the wrong behavior when a bug fix rides along, and that test must fail until the fix (isolated in its own separate step) resolves it.

**When NOT to apply it**: on new code, or legacy code already well covered by tests, this principle isn't needed — it's specific to the moment you touch untested code you don't yet fully understand.

---

## 20. Fail Fast: where to validate, where to trust

**What it is**: validate input explicitly only at the system's boundaries (user input, external HTTP calls, parsing external files/layouts) and fail as early as possible with a clear error when it's invalid; inside the system, trust the guarantees already given by whoever validated upstream, without repeating the same checks at every layer. This principle is about *where* validation happens, not *how exhaustive* it is — a boundary that deliberately checks only the specific conditions the flow actually depends on (not every theoretically-invalid state someone could imagine) is still correctly applying Fail Fast, as long as internal code doesn't re-check what the boundary already covers. "Should this boundary validate more fields" is a separate, legitimate question about validation coverage — don't conflate it with this principle's actual concern, which is duplication and the wrong layer failing.

**Problem it solves**: two opposite symptoms of the same misjudgment. On one side, invalid data traveling through 5 layers before an exception blows up far from the real cause (fail *slow*, hard to diagnose). On the other, defensive guard clauses repeated in every internal method "just in case" — noise that hides the real logic and gives a false sense of safety, since nobody actually checks whether those conditions are reachable.

**How to apply it**: when adding a validation, first ask "does this data come from outside the trust boundary (user, network, external file), or from internal code already validated elsewhere?" In the first case, validate immediately and fail with a message that pinpoints exactly what's wrong. In the second case, don't validate again — repetition is a sign the *where* of the trust boundary isn't clear.

**Example**: a validator that receives a record read from an external fixed-length file/layout — that's a real boundary (the data comes from outside, it can be malformed) and its guard clauses are correctly placed there. The layer that calls it doesn't revalidate the same data — it trusts the result, because the boundary has already been crossed once, at the right point.

**When NOT to apply it**: in a system with multiple teams/services that don't trust each other (e.g. a public API), even the "internal" boundary may need validation — the rule assumes a clear, shared trust boundary, which needs to be explicitly established, not assumed.

---

# Suggested learning roadmap

Not everything needs to be learned with the same urgency. Suggested order, from most immediate to most strategic:

1. **Weeks 1-2** — SOLID, Composition over Inheritance, Value Object, Tell Don't Ask, Law of Demeter, DRY/KISS/YAGNI, Command-Query Separation, Specific exceptions, Fail Fast (where to validate/where to trust), Readability (methods/variables/comments). These are the principles you use in *every* PR, regardless of project or language.
2. **Situational, but worth recognizing the moment they show up** — Shared state beyond its boundary (as soon as you touch code used by concurrent requests server-side, or a singleton service with state tied to a user/session client-side), Characterization Test (as soon as you touch legacy code with no tests). No dedicated week for these: the risk is discovering them after a bug has already happened instead of reading the signal beforehand.
3. **Weeks 3-4** — Tactical DDD (Entity/Value Object/Aggregate/Repository as an abstraction). If you've already done a code-review analysis on your project (reference style → inconsistencies found → proposals), reread it as a concrete case study.
4. **Month 2** — Hexagonal Architecture / Ports & Adapters. It's the natural consequence of tactical DDD applied well (repository as a domain interface).
5. **Months 2-3** — Anti-Corruption Layer and Strangler Fig — especially relevant if you're actively migrating legacy code in an existing project.
6. **Later, only if needed** — Strategic DDD (bounded context), package by feature, Modular Monolith. These are big architectural investments: don't apply them until you concretely feel the pain they solve (too many developers stepping on each other in the same package, difficulty finding where a feature lives).

---

# Working checklist — use on every task

**Before starting (during task analysis)**
- [ ] Does this change touch business logic? If so, where *should* that logic live — in the domain or in the service? (Tell Don't Ask)
- [ ] Am I about to introduce/touch a dependency on infrastructure (DB, HTTP, file)? Does the calling code already go through an interface, or am I about to couple the domain directly to a technical detail? (Dependency Inversion / Ports & Adapters)
- [ ] Does this task touch both modern and legacy code? If so, is there (or should there be) an explicit translation boundary between the two? (Anti-Corruption Layer)
- [ ] Is the code I'm about to touch legacy and untested? The first test to write should capture the *current* behavior (bugs included), not the "correct" one (Characterization Test).

**While developing**
- [ ] Am I writing an `if/else`/`switch` that's likely to grow over time? Consider the Strategy pattern.
- [ ] Am I duplicating a validation/formatting already written elsewhere for the same concept? Consider a Value Object.
- [ ] Am I writing a getter chain longer than 2 levels? (Law of Demeter)
- [ ] Am I abstracting something that only repeats 1-2 times "because it might be needed later"? Stop (YAGNI).
- [ ] Am I writing a generic ("catch everything") catch block? Check which exception/error the deepest call in the block can genuinely raise and catch that instead (Specific exceptions) — unless this really is a generic external entry point (a filter/middleware, a job's entry point).
- [ ] Am I extending a class only to reuse its behavior, not because the relationship is genuinely "is-a"? Compose and delegate instead (Composition over Inheritance).
- [ ] Am I adding/touching a mutable static/global field (or a non-thread-safe object) in code used by concurrent requests (server), or state tied to a user/session inside a singleton service (client, e.g. Angular `providedIn: 'root'`, a React/Vue store)? In the second case, who resets it and when? (Shared state beyond its boundary)
- [ ] Am I validating data that's already been validated elsewhere in the flow, instead of at the real trust boundary (user input, external file/layout)? (Fail Fast)

**Before opening the PR**
- [ ] Does this class have more than one reason to change? (Single Responsibility)
- [ ] If you had to explain this change to a colleague using a pattern name, which one would you use? If you can't find one and the solution looks ad-hoc, reread Part 1.
- [ ] Did I touch legacy code with no explicit plan for when/how it'll be removed? (Strangler Fig)
- [ ] If I deliberately duplicated code (Strangler Fig), is there a note stating what, why, and when it should be removed — not just "TODO: clean up"?
- [ ] Is there a method I wrote/touched without rereading it with fresh eyes? Check its size, variable names, and whether every comment survives the question "if I delete it, does it still make sense?" (Readability)

---

# How to measure progress over time

- Every time you notice a concrete example (in your own work or in someone else's code review) of one of these principles applied well or violated, add it as a note under the relevant section of this file, with a reference to the project/file. Over time this document becomes your personal casebook, not just theory.
- Every 2-3 months, reread the Working checklist and ask whether it's become automatic (good, level up) or you're still ignoring it (go back to the corresponding Part 1/2).
- When you work on a different project, you can redo the same kind of analysis (reference style → inconsistencies found → proposals) to build the same kind of concrete casebook there too.
