# Principle 13 — Shared state beyond its boundary

## Case A — should flag

```java
public class InvoiceRenderer {
    private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("dd/MM/yyyy");

    public String renderDate(Date issued) {
        return DATE_FORMAT.format(issued);
    }
}
```

**Expected**: flag it. Principle: Shared state beyond its boundary
(server-side manifestation). Why: `SimpleDateFormat` is not thread-safe,
and it's held in a `static` field on a class that will be called from
concurrent web requests — under load, two requests formatting a date at
the same time can corrupt each other's output. It should be a local
variable inside the method, or replaced with `DateTimeFormatter` (`java.time`,
thread-safe by design).

## Case B — should NOT flag (calibration)

```java
public class TaxRates {
    public static final double VAT_STANDARD = 0.22;
    public static final double VAT_REDUCED = 0.10;
}
```

**Expected**: do NOT flag. Why: these are immutable constants loaded once,
not mutable state — nothing ever writes to them after class-load, so
there's no concurrent-access hazard regardless of how many requests read
them simultaneously. The principle's own "when NOT to apply it": shared
state that's immutable, or a configuration loaded once at startup, doesn't
have this problem in either its server-side or client-side form — the
rule is about mutability tied to a boundary, not about sharing itself.
