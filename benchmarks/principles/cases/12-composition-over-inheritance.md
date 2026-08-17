# Principle 12 — Composition over Inheritance

## Case A — should flag

```java
public class ReportFormatter extends DecimalFormat {
    public String formatTotal(double total) {
        return "Total: " + this.format(total);
    }
}
```

**Expected**: flag it. Principle: Composition over Inheritance. Why:
`ReportFormatter` extends `DecimalFormat` purely to reuse its formatting
method — a `ReportFormatter` is not a `DecimalFormat` (the "is-a" relation
doesn't hold), and extending it exposes all of `DecimalFormat`'s public
API (parsing, locale settings, mutable state) as part of
`ReportFormatter`'s own interface, whether wanted or not. Injecting a
`DecimalFormat` instance and delegating to it would give the same reuse
without the unwanted coupling.

## Case B — should NOT flag (calibration)

```java
public class PaymentDeclinedException extends RuntimeException {
    public PaymentDeclinedException(String reason) {
        super(reason);
    }
}
```

**Expected**: do NOT flag. Why: a custom exception extending the
language's base exception type is the textbook case of a genuine, stable
"is-a" relationship (`PaymentDeclinedException` really is a
`RuntimeException`) — the principle's own "when NOT to apply it" names
custom exceptions extending a base exception as exactly the case where
inheritance is the right tool, not a workaround.
