# Raw transcripts — 2026-08-22 N=4 partial run

Companion to [2026-08-22-n4-partial.md](2026-08-22-n4-partial.md), which
summarizes and analyzes these. This file exists because
`grade-principles.md`'s "Making 'blind' actually blind" section has
flagged, since the first run, that no raw response transcripts were ever
saved to disk — every prior grading pass was inline, from conversation
context that disappears at session end, so a genuinely blind regrade was
never actually possible even though the procedure was documented. These
are the verbatim agent responses collected today, saved before that
context is lost, so a future session can run a real anonymized blind
grading pass against real data instead of paraphrase.

Each entry: principle / case / arm / model / seed-label (seed-labels are
just launch-order tags within a batch, not a reproducible RNG seed — this
project doesn't control model sampling seeds, "seedN" here means "the
Nth independent sample"). Verdict column is this session's own read at
the time, not a re-grade — a real blind pass should re-derive it from the
Expected text in the case file, not trust this column.

## Batch 1 (seed3) — 05-dry.md, 07-cqs.md, 14-fail-fast.md, all Case A/B × baseline/with-skill

### DRY Case A — baseline — haiku
> Duplicate tier logic across classes—extract to a shared static/utility method to prevent drift. Threshold values (1000, 500) and rates (0.85, 0.90, 0.95) should be named constants, not magic numbers, since changing them requires edits in two places. No input validation (base >= 0); financial code usually needs it. I considered the different code styles (early return vs variable assignment) but that's cosmetic noise compared to the real problem—the duplication is the flag. Overall: solid readability, but violates DRY and costs maintenance.

Verdict at the time: **HIT** (recall).

### DRY Case A — with-skill — haiku
> **Flag: DRY violation** — `GoldTierPricing.price()` and `GoldTierRefunds.refund()` duplicate identical threshold/rate logic; extract to shared constant or method. **Flag: Magic numbers** — Thresholds (1000, 500) and rates (0.85, 0.90, 0.95) should be named constants documenting tier boundaries and discount percentages. **Flag: Semantic ambiguity** — Both methods apply the same discount identically; unclear why refunds equal pricing or if they should diverge later. If separate, add a comment explaining the intent; if not, merge them. **Not flagged:** If-else readability is fine for three branches (not yet complex enough for Strategy); no over-abstraction detected. **Verdict:** Fix DRY + magic numbers (one constant source of truth for tier logic), clarify the pricing/refund relationship, then fold into a single class or document why they stay split.

Verdict at the time: **HIT** (recall).

### DRY Case B — baseline — sonnet
> Two flags: (1) no null-check on `name` — passing null silently produces "Welcome, null!" in a customer-facing email rather than failing fast, worth a validation guard since this sits at a trust boundary (caller-supplied input). (2) If `name` is ever rendered into HTML email (not shown here), it's unescaped and open to injection — worth confirming downstream, but not fixable from this snippet alone. I considered the duplication between the two classes (same shape, different template) but decided not to flag it — with only two variants and one method each, an interface/base class is speculative abstraction for two cases; revisit if a third builder appears. Naming is fine and the classes are trivial enough that no test is warranted.

Verdict at the time: **HIT** (calibration).

### DRY Case B — with-skill — sonnet
> Duplication (`subject()` builds an identical "greeting + name" pattern) is real but sample-size-one — with only two builders it's DRY-vs-YAGNI, and I'd let it stand until a third variant shows up rather than introducing a template/strategy abstraction now. No class-level state or behavior beyond the one method, so SRP/interface concerns don't apply. Bigger miss: `name` is a bare `String` used positionally with no validation — null/blank input silently produces `"Welcome, null!"`; a `Name` (or `Recipient`) Value Object, or at minimum a Fail-Fast null check, closes that trust-boundary gap. Also flag that `subject` is the only method shown — if these classes also build a body elsewhere, verify the two pieces aren't duplicating recipient-formatting logic in two places.

Verdict at the time: **HIT** (calibration).

### CQS Case A — baseline — haiku
> **Flag: Using `double` for financial amounts** — floating-point rounding errors can silently create or lose money. **Flag: No null checks on `account` or `auditLog`** — either being null crashes the method without meaningful error. **Flag: Missing constructor to initialize final `auditLog`** — this code won't compile as written. **Flag: No validation that `amount > 0`** — allows "check if I have funds for -$100" to pass nonsensically. I considered the asymmetric logging (only on failure, not success) and it might be intentional for signal/noise, but flagging it: does compliance require auditing both passes and failures, or is failure-only correct by design?

Verdict at the time: **MISS** (recall — never names CQS).

### CQS Case A — with-skill — haiku
> **Flag: DRY violation** — `GoldTierPricing.price()`... [note: this is a copy-paste mismatch in the original session accounting; the actual CQS Case A with-skill seed3 response was recorded separately below under "correction" — see the with-skill seed3 CQS entry in the partial report's Part-4 discussion. Left as a known gap in this archive: verify against the source conversation before treating this row as authoritative.]

### CQS Case B — baseline — sonnet
> Verdict: needs changes before merge — two real bugs, not just style. First, `metrics` and `repository` are referenced but never declared as fields, so this doesn't compile. Second, if `repository.load(id)` returns null (product not found), `cache.put(id, null)` will either NPE (most cache implementations reject null values) or silently cache a null, both wrong. I considered flagging the lack of synchronization around the get/load/put sequence but decided not to — a double load-and-put race on a cache miss is a harmless, self-correcting redundancy, not a correctness bug, so it's not worth the complexity of adding locking. I also considered the missing null/blank check on `id` but left it unflagged since that's a caller-contract question this snippet alone can't resolve.

Verdict at the time: **AMBIGUOUS** — never addresses the metrics/query-purity point (pre-fix case file).

### CQS Case B — with-skill — sonnet
> Verdict: needs revision — one real bug plus a violation worth flagging. 1. **Bug**: `repository.load(id)` can return null (or throw) for an unknown id; that gets cached via `cache.put(id, loaded)`, poisoning the cache with a null entry and making every future lookup "miss the DB, hit a null" — guard against caching a null/missing result. 2. **Race condition**: `get`-then-`put` isn't atomic, so concurrent calls for the same missing id can both miss and both hit the repository — minor and likely fine for a read-through cache unless load is expensive/side-effecting, so I'd only flag it as a comment, not block on it. 3. **Tell Don't Ask / SRP**: the method mixes cache lookup, metrics, and repository fallback inline — readable as-is at this size, so I'm not asking for a `CachingProductRepository` abstraction (YAGNI, one implementation, no need yet). 4. Considered and skipping: no interface/Value Object is warranted here.

Verdict at the time: **AMBIGUOUS** — same gap (pre-fix case file).

### Fail Fast Case A — baseline — haiku
> **Flag: Duplicate validation** — `validateCheckout` runs in both the controller and service; remove one (service should validate defensively, OR controller validates once before delegating — not both). I considered the "defense in depth" argument and decided against it: if the service can't trust the controller, then controller validation is useless noise; if it can trust it, the service call is wasted CPU. **Flag: No return value from checkout** — a checkout should return an order ID or confirmation to the client, not void... I did NOT flag `IllegalArgumentException` (correct for input validation) or the generic `save()` call (likely wrapped in a transaction elsewhere).

Verdict at the time: **HIT** (recall).

### Fail Fast Case A — with-skill — haiku
> **Flag: Duplicate validation** — `validateCheckout` runs in both layers; if `process` is only reachable through `handleCheckout`, the service check is dead code; if it's also a direct entry point, the controller check adds nothing to defense. Remove one or document the boundary. **Flag: Unclear service contract**... **Verdict:** Fix the trust boundary: either the controller validates and the service assumes valid input (remove service checks), or the service validates defensively and the controller trusts it (remove controller checks).

Verdict at the time: **HIT** (recall).

### Fail Fast Case B — baseline — sonnet
> Verdict: not ready to merge — the money-path exception handling is missing. checkoutService.process(request) isn't wrapped in try/catch... Also flag: whether @Valid actually cascades into each CheckoutRequest.items() element... Considered and not flagging: the empty items check and the plain-string 400 body — style nit, not correctness, so I'm letting it go given the size of this snippet. One more worth a mention, not a blocker: no idempotency key/dedup on process().

Verdict at the time: **HIT** (calibration — correctly holds back on the manual check).

### Fail Fast Case B — with-skill — sonnet
> Verdict: mostly fine as a controller — thin, delegates to service, fails fast on the one thing bean validation can't express. Two flags: (1) `ResponseEntity<?>` with a raw string body is untyped/inconsistent... (2) the comment "trusts the request from here on" is worth a second look, not a rewrite... I also considered flagging the manual empty-items check as duplicating bean validation, but it isn't: `@Size(min=1)` on `items` would've covered it declaratively, so this one line could actually be deleted in favor of that annotation — worth a suggestion, not a blocker.

Verdict at the time: **HIT** (calibration).

## Batch 2 (seed4) — same 12 combinations

### DRY Case A — baseline — haiku
> **Flag: Duplicate tier logic across classes**—both implement identical threshold/rate matching... **Flag: Hardcoded thresholds and rates**... **Not flagging lack of null/negative validation**... **Not flagging separate classes**... **Verdict: Consolidate to one class with shared tier definition; otherwise logic is sound.**

Verdict: **HIT**.

### DRY Case A — with-skill — haiku
> **Flag: Duplicate discount-rate logic.**... **Flag: Magic numbers.**... **Considered but not flagging: separate classes.** Without seeing how refunds vs. pricing diverge in the domain, consolidating them now violates YAGNI... **Considered but not flagging: Strategy pattern.**

Verdict: **HIT**.

### DRY Case B — baseline — sonnet
> **Verdict:** No blocking bugs; one real concern worth raising, two things deliberately not flagged. - Flag: `name` is concatenated straight into the subject with no sanitization — if this ever reaches a raw email header... a name containing CR/LF could enable header injection... - Considered the duplication between the two builders (same shape, different string) and I'm not flagging it — only two implementations exist, so extracting a shared interface/base now is premature abstraction (rule of three). - Considered `name == null`...

Verdict: **HIT**.

### DRY Case B — with-skill — sonnet
> These two classes are near-duplicates that will keep multiplying one-per-email-type — DRY smell, and per the checklist ("validation/formatting duplicated for the same concept") this is where a shared abstraction earns its keep, not YAGNI territory, since the pattern (name + template string) is already repeating twice with an obvious third on the way. I'd flag it as: collapse into one `EmailBuilder` (or a `Map<String,String>`/enum of templates)... Considered introducing an `EmailBuilder` interface with per-type implementations (Strategy) — deliberately not flagging that, it's over-engineering for two string templates with no varying behavior beyond the text itself.

Verdict: **MISS** (calibration — invents a growth signal not in the snippet).

### CQS Case A — baseline — haiku
> **Flag:** No validation of inputs—`account` could be null (NPE) and `amount` could be negative (check trivially passes). **Flag:** Incomplete audit trail—logs only failures and missing the requester's identity... **Flag:** Using `double` for currency invites floating-point precision errors... **Considered but not flagging:** Method is simple and clearly reads; the logic itself is correct if inputs are valid upstream. **Verdict:** Fix the three issues above before merge; they're security/correctness problems, not style.

Verdict: **MISS** (recall).

### CQS Case A — with-skill — haiku
> **Flag: CQS violation** — method name signals a read-only query but performs logging (side effect); callers can't distinguish between "funds insufficient, so I logged it" and "funds insufficient, I didn't log." **Flag: No null guard on account**... **Consider (not flagging): Asymmetric logging** — only failures logged, not successes — is deliberate (reduces noise) and fine since failures are the decision point. **Verdict:** Fix CQS by either making logging explicit... or rename... Add null check.

Verdict: **HIT** (recall).

### CQS Case B — baseline — sonnet
> Verdict: needs changes before merge — two real correctness issues, one deliberate non-flag. - `repository` and `metrics` are referenced but never declared/injected as fields... this won't compile as written. - `cache.put(id, loaded)` caches unconditionally, so a missing product... gets cached as `null`... - The get-then-put is a classic check-then-act race... I considered flagging the lack of input validation on `id`... but decided not to. I considered flagging missing exception handling around `repository.load`, but it's fine as-is.

Verdict: **AMBIGUOUS** (pre-fix case file).

### CQS Case B — with-skill — sonnet
> Verdict: reasonable read-through cache, but flag two things. (1) Race/atomicity: `get` then `put` isn't atomic... most cache libraries (Caffeine, Guava) offer a `get(key, loader)` compute-if-absent... (2) Null handling: if `repository.load` can return null... `cache.put(id, null)` then a later `cache.get(id)` returns null again and is misreported as another miss... I considered flagging `metrics`/`repository` as undeclared fields, but that's just an elided snippet, not a real design issue. I did not flag exception handling around `repository.load`.

Verdict: **AMBIGUOUS** (pre-fix case file).

### Fail Fast Case A — baseline — haiku
> **Duplicate validation** — `validateCheckout()` runs in both the controller and service for the same request; trace the call chain to eliminate one... **Unclear trust boundary** — The pattern suggests either the controller shouldn't validate... or the service shouldn't validate... but the code commits to both... **Potential null order** — `buildOrder()` has no visible contract...

Verdict: **HIT**.

### Fail Fast Case A — with-skill — haiku
> **Flag: Duplicated validation violates DRY and creates maintenance risk.** The real issue is unclear trust boundary—if `process()` is public, validation belongs there... if it's internal, validation belongs in the controller... **Considered the defensive-check pattern**... but that's justified only when there are multiple public entry points; this code has one (the controller), so duplication is waste. **No flag on exception types or validation logic**.

Verdict: **HIT**.

### Fail Fast Case B — baseline — sonnet
> Verdict: needs changes before merge — two real gaps, one nitpick. 1. **No authorization/ownership check** — `customerId` comes straight from the request body and is never verified against the authenticated principal... 2. **No exception handling around `checkoutService.process`**... 3. I considered the "trusts the request from here on" comment and the manual empty-items check, and it's a minor smell rather than a bug: `@NotEmpty` on `items` would let bean validation cover this case instead of a hand-rolled check, but the current code is correct, just slightly redundant. 4. No double-submission/idempotency protection... 5. `ResponseEntity<?>`... minor API-consistency nit.

Verdict: **BORDERLINE HIT** (calls the manual check "correct, just slightly redundant" — logged as-is, not smoothed into a clean pass).

### Fail Fast Case B — with-skill — sonnet
> Not thread-safe... [this response is actually the CQS Case B with-skill verify-fix response, misfiled during collection — see the "CQS Case B fix verification" section below for the correct Fail Fast B with-skill seed4 text.]

Verdict: see correction below — the actual Fail Fast B with-skill seed4 response follows.

### Fail Fast Case B — with-skill — sonnet (corrected)
> Verdict: reasonable as-is, one real gap. - Fail Fast / trust boundary: the empty-items check belongs at the HTTP boundary, and returning a raw `ResponseEntity.badRequest().body("No items")` (untyped, plain string) is inconsistent with a `@Valid` bean-validation setup — better to make it expressible via validation... - The comment "trusts the request from here on" is worth flagging only if `checkoutService.process` is also the payment/inventory boundary... - No design smell here worth a pattern name.

Verdict: **HIT** (calibration).

## CQS Case B fix verification (post-fix, 1 run per arm)

### CQS Case B — baseline — sonnet (post-fix)
> Verdict: approve with one minor nit. Flag: `findById` never validates `id`... worth a fast-fail guard if this is a public-facing entry point... I considered the cache's eviction/TTL policy and staleness handling but that's a property of the `Cache` implementation, not this method, so out of scope here. I considered whether `metrics.increment` should move after `repository.load` succeeds, but incrementing on miss regardless of outcome is correct — a miss occurred whether or not the load then failed. I did not flag the not-null contract on `repository.load` or the concurrent-double-load cost, per the comment — those are accepted and out of scope.

Verdict: **HIT** — explicitly reasons through the metrics point.

### CQS Case B — with-skill — sonnet (post-fix)
> Not thread-safe: `cache.get`/`cache.put` under concurrent misses is fine per the comment, but the constructor is missing... The real flag: `metrics.increment` runs on the happy path only when it should be unconditional bookkeeping — actually it is called on both branches, so that's fine, I considered it and it's correct. One genuine issue: `findById` mixes cache-lookup, metrics, and load-and-populate — acceptable at this size, not flagging as SRP violation since splitting a 10-line method would be over-engineering (YAGNI)... Verdict: approve as-is.

Verdict: **HIT** — explicitly reasons through the metrics point.

## CQS Case A baseline reseed (seed5, seed6)

### CQS Case A — baseline — haiku — seed5
> **Flag:** Using `double` for currency — precision loss and rounding errors on financial amounts... **Flag:** No null check on `account` parameter... **Flag:** No validation that `amount >= 0`... **Considered but not flagging:** One-way audit logging (only failures). Could be intentional security pattern, though logging both might be more complete — worth asking the author. **Considered but not flagging:** Audit log exception propagation.

Verdict: **MISS**.

### CQS Case A — baseline — haiku — seed6
> **Flag: Side effect in a query method.** `hasSufficientFunds()` sounds like a pure check but logs as a side effect — callers won't expect it, violating command-query separation. **Flag: Asymmetric audit logging.**... **Flag: Missing amount in log.**... **Considered: Null checks**... **Considered: Negative amounts**...

Verdict: **HIT** — names "command-query separation" directly.

**Full CQS Case A baseline tally, 6 seeds: seed1 HIT, seed2 HIT, seed3 MISS, seed4 MISS, seed5 MISS, seed6 HIT = 3/6 (50%).**

## DRY Case B with-skill reseed (seed5, seed6)

### DRY Case B — with-skill — sonnet — seed5
> Both classes duplicate the "subject builder" shape with only the greeting string differing — one method, two lines of real logic, doesn't need a class each; I'd flag the near-identical structure as DRY-lite but not urgent, since with only two variants and no shared state or growth signal, extracting an interface/strategy now is speculative. I considered a `Map<String, String>` or template-based `EmailSubjectBuilder(String template)` but decided against flagging it as required — YAGNI... I also considered Value Object for `name`... but didn't flag it. One real flag: no null-check on `name`... Verdict: acceptable as-is for two variants; merge into one class only when a third subject type appears (Rule of Three), don't add an interface/Strategy preemptively.

Verdict: **HIT**.

### DRY Case B — with-skill — sonnet — seed6
> Duplicated `subject()` logic across builders with no shared abstraction is the DRY smell here, but with only two near-identical one-liners the fix is a shared template method or a `Function<String,String>` field, not a base class hierarchy — I considered extracting an interface/base class and it's premature: two implementations doing string concatenation don't yet justify polymorphism (YAGNI)... Also flag: no null/blank check on `name`... Class names promise more than they deliver ("Builder" suggests a fluent multi-step build, but this is a single-method formatter)...

Verdict: **MISS** — treats coincidental similarity as a real DRY smell needing a fix.

**Full DRY Case B with-skill tally, pre-fix, 6 seeds: seed1 HIT, seed2 HIT, seed3 HIT, seed4 MISS, seed5 HIT, seed6 MISS = 4/6 (67%).**

## DRY Case B with-skill fix #1 verify (seed7, seed8 — added sentence to "when NOT to apply it")

### seed7
> Duplication between `WelcomeEmailBuilder` and `ReminderEmailBuilder` — same shape (a name-formatting `subject` method), differing only in the literal template — is real DRY territory once a third builder shows up, but with just two it's not yet a signal worth a shared interface or `EmailTemplate` abstraction. I considered extracting a common `Function<String,String>`-based base but rejected it: two implementations is exactly what YAGNI warns against pre-abstracting. The one thing I'd flag as a genuine smell: `name` is unvalidated and directly interpolated into the subject...

Verdict: soft HIT, but reasoning is rule-of-three timing, not knowledge-vs-shape.

### seed8
> Two near-identical classes differing only in the subject-line template signal duplication that should collapse into one `EmailBuilder`... but with just two variants that's marginal — I'd flag it as a comment, not block on it. No shared interface/base class exists yet, so there's no premature abstraction to fault... Verdict: acceptable as-is for two variants; note the duplication but don't force an abstraction — revisit if a third variant shows up.

Verdict: soft HIT, same reasoning gap.

## DRY Case B with-skill fix #1 reseed (seed9–12, bringing post-fix sample to 6)

### seed9
> Duplicated `subject()` shape across `WelcomeEmailBuilder`/`ReminderEmailBuilder` is only two cases with trivial bodies — not yet a pattern worth a `Strategy`/base-class abstraction (YAGNI, DRY doesn't kick in until a third occurrence or real shared logic). I considered a `MessageFormat`/`EmailBuilder` interface but skipped it... One real flag: no null/blank check on `name`...

Verdict: soft HIT, rule-of-three reasoning.

### seed10
> Verdict: minor duplication, not worth abstracting yet. - `subject()` in both classes follows the identical `"<prefix>, " + name + "!"` shape — real duplication, but with only two variants and one line each, extracting a common `EmailBuilder` base/interface now would be speculative (YAGNI); revisit if a third template or shared behavior (body, headers) appears...

Verdict: soft HIT, calls it "real duplication."

### seed11
> Verdict: fine as-is, no changes needed yet. Two classes, each a one-line `subject` method — real duplication (same shape: greeting + name + punctuation) but only two occurrences, so extracting a shared interface or template method now would be YAGNI (rule of three not met)...

Verdict: soft HIT, "real duplication" + rule-of-three framing.

### seed12
> Duplicated `subject()` logic across `WelcomeEmailBuilder`/`ReminderEmailBuilder` is real DRY violation waiting to grow, but with only two variants and one line each, a shared abstraction... is speculative — YAGNI holds until a third builder or shared behavior (body, headers) shows up...

Verdict: soft HIT on the surface ("real DRY violation" language, but doesn't force a fix) — closest to a miss in tone.

**Rereading all 6 post-fix (seed7,8,9,10,11,12): none use the fix's new "same reason" test — all reason via rule-of-three timing, several explicitly call it "real duplication." This is the finding that the hit/miss tally was measuring the wrong thing.**

## DRY 3-instance exploratory check (WelcomeEmailBuilder + ReminderEmailBuilder + GoodbyeEmailBuilder, pre-fix, 4 runs)

### seed1
> Duplication is the real issue: three near-identical builders differing only in a template string — flag as DRY, worth a Value Object/single templated `EmailBuilder`... if a fourth type shows up. No shared interface exists... I considered extracting an interface right now but deliberately don't flag it as mandatory — with only three implementations and no evidence of polymorphic use, that's YAGNI; the duplication itself is the actionable smell, not the missing interface.

Verdict: **HARD FLAG**.

### seed2
> Three near-identical classes, each a single `subject(name)` method — textbook duplication that DRY/Strategy would normally consolidate, but with three call sites and no shared caller shown, collapsing them into one parameterized class or interface is speculative abstraction the code doesn't need yet (YAGNI); flag it as "watch for a 4th case, don't refactor now."...

Verdict: **HARD FLAG** (softened to "watch for a 4th case" but still calls it textbook duplication needing eventual action).

### seed3
> Duplicated `subject()` shape across `WelcomeEmailBuilder`/`ReminderEmailBuilder`/`GoodbyeEmailBuilder` is DRY-worthy only if a fourth variant is actually coming — I considered a `Strategy`/common interface but three near-identical one-liners with no shared consumer yet is YAGNI, so I'd leave it. The one real flag: no null/blank check on `name`...

Verdict: soft, defers threshold to "fourth variant."

### seed4
> Duplication is the only real issue: three classes with identical shape and no shared abstraction — one `EmailBuilder` interface... would remove the copy-paste, but with only three trivial one-liners and no evidence of a fourth coming, this is borderline YAGNI so I'd flag it as a suggestion, not a blocker. I considered a `Strategy`/factory setup and deliberately don't push for it — three implementations of a one-line method is exactly the "1-2 times, might not repeat" case the skill says to leave alone... Verdict: approve as-is; only a light comment — "if a fourth email type shows up, unify these behind one interface, not before."

Verdict: soft, misreads its own count ("three... is exactly the 1-2 times case") to keep applying the heuristic.

**4/4: every response judged by instance count against a moving threshold; none recognized three unrelated business rules.**

## DRY 3-instance, fix #2 verify (restructured "How to apply it" — knowledge question first)

### seed1
> Three near-identical classes duplicating a `subject()` method — textbook duplication that begs for either one `EmailBuilder` taking a template/prefix parameter, or a `Function<String,String>`/enum-based strategy if more email types are truly coming; as three unrelated top-level classes there's no shared contract... I also considered YAGNI against merging them, but three call sites already share the identical signature and behavior shape, so this isn't speculative — the duplication exists today, not "might exist later." Verdict: request de-duplication behind one class/interface before merging.

Verdict: **HARD FLAG**.

### seed2
> Three near-identical classes duplicating a `subject(String name)` method — same shape, differing only in the message template — cries out for one `EmailTemplate` (enum or small class holding a format string)... DRY violation with no offsetting benefit yet, since nothing else varies per type...

Verdict: **HARD FLAG**.

### seed3
> Duplicated `subject(name)` logic across three near-identical builders, no shared abstraction — violates DRY and cries out for one `EmailBuilder`... I considered flagging missing interface/base class as its own issue but it's really the same DRY problem, not a separate SRP or OCP concern...

Verdict: **HARD FLAG**.

### seed4
> Duplication is the real issue: three classes with identical shape... — this is a Value-Object-worthy abstraction crying to be a single parameterized class or enum-with-template rather than three copies (DRY). I'd flag the missing null/blank check on `name`... I considered suggesting a common interface... but won't flag it — with only a `subject` method and no polymorphic call site shown, that's speculative structure with no proven need yet (YAGNI)... the problem isn't the type count, it's the copy-pasted method body.

Verdict: **HARD FLAG**.

**0/4 — every run hard-flagged, worse than the pre-fix exploratory batch.**

## DRY 3-instance, fix #3 verify (concrete worked counter-example added, different domain)

### seed1
> Duplication of subject-building across three near-identical classes — no shared abstraction, and no data (extends? interface?) to justify three types; a Strategy/enum with a `(name, template)` pair collapses this to one class — DRY. I considered flagging "no interface `EmailBuilder`" but decided against it: introducing one now... would be a speculative abstraction (YAGNI) — the fix is consolidation, not more indirection.

Verdict: **HARD FLAG**.

### seed2
> Duplicate `subject()` implementations differing only in the message template — flag as DRY violation, extract a shared `EmailBuilder` with a template method or a single class parameterized by (greeting, name) rather than three near-identical classes. I considered whether these warrant a Strategy/interface hierarchy but that's over-engineering for three one-line string builders — a single parameterized function or template constant is enough (YAGNI).

Verdict: **HARD FLAG**.

### seed3
> Duplicated `subject` method across three classes with only the template string differing — a Strategy/template pattern... would cut the repetition, but with just 3 tiny call sites this is arguably fine as-is per YAGNI/ponytail (don't abstract for 2-3 repeats)... I considered adding a shared `EmailBuilder` interface but deliberately didn't flag it as required — three unrelated one-liners don't yet justify an abstraction, add one only when a fourth builder or shared logic... appears.

Verdict: soft — first and only use of "unrelated" across all transcripts collected today, but still falls back to count-based deferral.

### seed4
> Duplicated `subject()` logic across three classes with no shared abstraction — same signature, same string-concat pattern, screams Strategy/interface (`EmailBuilder.subject(name)`) if more email types are coming, though with only three trivial one-liners I'd hold off per YAGNI unless a caller already needs to treat them polymorphically... Real gap: unclear who calls these and whether `name` is ever null — that's the one thing worth asking about before deciding if consolidation is worth it.

Verdict: soft, same "if more types are coming" framing.

**2/4 — statistically the same as the unedited baseline (also 2/4).**
