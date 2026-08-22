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
public ResponseEntity<?> checkout(@Valid @RequestBody CheckoutRequest request) {
    // @Valid already enforces customerId/paymentMethod/shippingAddress via
    // bean-validation annotations on CheckoutRequest. items *could* carry
    // @NotEmpty too, but CheckoutRequest is also the body for the
    // save-for-later draft endpoint, which legitimately allows an empty
    // cart — a DTO-level annotation would break that endpoint, so the
    // non-empty rule stays local to this handler, which is the only place
    // it actually applies.
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
principle applied correctly, not a violation to find. The boundary isn't
incomplete: `@Valid` covers every field the shared DTO can safely
constrain for *every* endpoint that uses it, and the one manual check
handles the one rule that's specific to *this* endpoint and would be
wrong to bake into the DTO itself — not a gap, two complementary
mechanisms at the same boundary. (A reviewer suggesting `@NotEmpty` on
`items` isn't wrong about the annotation existing — it's missing that the
DTO is shared with an endpoint that needs the opposite rule; that's the
actual point being tested, not whether the annotation is technically
available.)
