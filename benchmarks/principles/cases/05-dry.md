# Principle 5 — DRY / KISS / YAGNI

## Case A — should flag

```java
public class GoldTierPricing {
    public double price(double base) {
        if (base >= 1000) return base * 0.85;
        if (base >= 500) return base * 0.90;
        return base * 0.95;
    }
}

public class GoldTierRefunds {
    public double refund(double base) {
        double discountRate;
        if (base >= 1000) discountRate = 0.85;
        else if (base >= 500) discountRate = 0.90;
        else discountRate = 0.95;
        return base * discountRate;
    }
}
```

**Expected**: flag it. Principle: DRY. Why: the same tiered-discount
*knowledge* (the 1000/500 thresholds and their rates) is encoded twice in
different shapes — not copy-pasted text, but the same business rule
duplicated conceptually, which is exactly what DRY is about (the same
knowledge, not necessarily the same text). A change to the thresholds has
to be made in both places or they silently drift apart.

## Case B — should NOT flag (calibration)

```java
public class WelcomeEmailBuilder {
    public String subject(String name) { return "Welcome, " + name + "!"; }
}

public class ReminderEmailBuilder {
    public String subject(String name) { return "Don't forget, " + name + "!"; }
}
```

**Expected**: do NOT flag. Why: both build a greeting string with the
customer's name, but this is coincidental similarity, not shared
knowledge — the two subjects express unrelated business rules that happen
to both involve interpolating a name. Extracting a shared "name greeting"
abstraction here would be premature generalization based on
surface-level similarity, not a real repeated concept (DRY's own
distinction: same knowledge, not same-looking text).

## Case C — should NOT flag (calibration, the rule-of-three trap specifically)

```java
public class WelcomeEmailBuilder {
    public String subject(String name) { return "Welcome, " + name + "!"; }
}

public class ReminderEmailBuilder {
    public String subject(String name) { return "Don't forget, " + name + "!"; }
}

public class GoodbyeEmailBuilder {
    public String subject(String name) { return "Sorry to see you go, " + name + "."; }
}
```

**Expected**: do NOT flag. Why: same reasoning as Case B, extended to a
third instance on purpose. Welcome, reminder, and goodbye are still three
unrelated business rules that happen to share a "greeting + name" shape —
adding a third coincidentally-similar snippet doesn't make it duplicated
knowledge any more than two did. This case exists because the "rule of
three" heuristic (repeat 3 times → consolidate) is easy to satisfy on
instance count alone without ever asking whether the third occurrence
means the same thing as the first two — a real, measured failure mode
(see
[2026-08-22-n4-partial.md](../../regressions/results/2026-08-22-n4-partial.md)'s
"rule-of-three trap" section: with-skill hard-flagged or soft-deferred
this exact snippet at roughly a 50% rate across two different attempts
to fix the guidance in `principles.md` — restructuring the section, and
adding a worked counter-example in a different domain (a numeric
threshold) — neither of which moved the number). If a response reasons
"not yet, wait for a fourth" instead of "these are still unrelated
regardless of count," that's the same miss as flagging it outright — the
instance-count framing is the failure being tested here, not just the
yes/no verdict.

**Fixed, 2026-09-08, reverified 2026-09-09 — closed.** A third fix
attempt targeted the actual gap the first two didn't control for — the
existing worked counter-example used a numeric threshold
(`o.getTotal() >= threshold`), a shape this snippet doesn't share at all
(no numbers, just string concatenation). Added a new worked example in
`principles.md` matching this snippet's *exact* surface shape (three
one-line string-builders, same signature, no threshold to point at as
"obviously different data"). Tested blind, N=4, fresh sessions given
only the candidate guidance and this snippet (no answer key): **4/4
explicit, correct non-flags** — every response reasoned through the
knowledge question by name and explicitly rejected the "no numbers =
generic" framing, rather than falling back to instance counting.
**Reverified the next day on an independent second batch, same setup:
4/4 again** — 8/8 total across two seeds, every single response
explicitly naming the knowledge question rather than counting instances.
Held to this project's own standard (a second seed clean moves a finding
from "real, not yet confirmed" to "closed") — this one clears it. First
case in this project's history where a third distinct fix attempt closed
something two prior attempts (0/4, then 2/4) had left as a genuinely
open, resistant limitation.
