# Principle 8 — Specific exceptions, not generic

## Case A — should flag

```java
public double parseDiscount(String raw) {
    try {
        return Double.parseDouble(raw) / 100.0;
    } catch (Exception e) {
        return 0.0;
    }
}
```

**Expected**: flag it. Principle: Specific exceptions. Why: `catch
(Exception e)` around a single, narrow operation (`Double.parseDouble`)
swallows everything, including a real bug elsewhere that would surface as
an unrelated `RuntimeException` — it should catch `NumberFormatException`,
the one exception this call can actually raise, so a genuine programming
error doesn't silently degrade to "0.0" the same way a malformed input does.

## Case B — should NOT flag (calibration)

```java
@ExceptionHandler(Exception.class)
public ResponseEntity<ErrorResponse> handleUnexpected(Exception e, HttpServletRequest request) {
    log.error("Unhandled exception on {}", request.getRequestURI(), e);
    return ResponseEntity.status(500).body(new ErrorResponse("Internal error"));
}
```

**Expected**: do NOT flag. Why: this is a framework-level catch-all at the
very outer boundary of the application (a global exception handler), not a
narrow block where the realistic failure modes are known — the principle's
own "when NOT to apply it": a final generic catch at a truly external entry
point, that logs and returns a generic error, is the intended last safety
net.
