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
