# Principle 14 — Fail Fast: where to validate, where to trust

## Case A — should flag

```java
public void handleCheckout(CheckoutRequest request) {
    validateCheckout(request);
    checkoutService.process(request);
}

public void process(CheckoutRequest request) {
    validateCheckout(request); // same checks as the controller, again
    var order = buildOrder(request);
    save(order);
}

private void validateCheckout(CheckoutRequest request) {
    if (request.items().isEmpty()) throw new IllegalArgumentException("No items");
    if (request.customerId() == null) throw new IllegalArgumentException("Missing customer");
}
```

**Expected**: flag it. Principle: Fail Fast (where to validate, where to
trust). Why: the same validation runs twice — once at the real trust
boundary (the controller receiving the HTTP request) and again one layer
in, on data that's already been validated and hasn't crossed any new
boundary since. The repetition doesn't add safety, it adds noise and a
second place to keep in sync if the rule ever changes.

## Case B — should NOT flag (calibration)

```java
@PostMapping("/checkout")
public ResponseEntity<?> checkout(@RequestBody CheckoutRequest request) {
    if (request.items().isEmpty()) {
        return ResponseEntity.badRequest().body("No items");
    }
    checkoutService.process(request); // trusts the request from here on
    return ResponseEntity.ok().build();
}
```

**Expected**: do NOT flag. Why: this validates exactly once, at the real
trust boundary (an HTTP request from an external caller), and everything
downstream trusts that guarantee instead of re-checking it — this is the
principle applied correctly, not a violation to find.
