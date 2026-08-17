# Principle 9 — Readability: methods, variables, comments

## Case A — should flag

```java
public boolean chk(String s, int t, boolean f) {
    boolean r = false;
    if (s != null) {
        if (s.length() > 0) {
            if (t >= 18) {
                if (f) {
                    r = true;
                } else {
                    if (t >= 21) {
                        r = true;
                    }
                }
            }
        }
    }
    return r; // return the result
}
```

**Expected**: flag it. Principle: Readability. Why: single-letter
parameter/variable names that require decoding, four levels of nesting
where guard clauses would flatten it, and a trailing comment that just
restates the line above it ("return the result") instead of explaining
anything non-obvious.

## Case B — should NOT flag (calibration)

```java
public int daysUntil(LocalDate target) {
    // Business rule (ticket PROJ-482): weekends don't count toward the
    // countdown shown to customers, only business days do.
    return (int) target.datesUntil(LocalDate.now())
        .filter(d -> d.getDayOfWeek() != DayOfWeek.SATURDAY && d.getDayOfWeek() != DayOfWeek.SUNDAY)
        .count();
}
```

**Expected**: do NOT flag. Why: the method is short and linear (no nesting
to flatten), the name and variable names are already clear, and the
comment explains a *non-obvious constraint* (a business rule from a
specific ticket that isn't visible from the code itself) rather than
restating what the code does — exactly what the principle says comments
are for.
