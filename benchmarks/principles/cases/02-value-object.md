# Principle 2 — Value Object & Immutability

## Case A — should flag

```java
public class PricingService {
    public double applyDiscount(String customerEmail, double amount) {
        if (!customerEmail.contains("@") || !customerEmail.contains(".")) {
            throw new IllegalArgumentException("Invalid email: " + customerEmail);
        }
        return amount * 0.9;
    }
}

public class MarketingService {
    public void sendPromo(String customerEmail, String message) {
        if (!customerEmail.contains("@") || !customerEmail.contains(".")) {
            throw new IllegalArgumentException("Invalid email: " + customerEmail);
        }
        // ... send message
    }
}
```

**Expected**: flag it. Principle: Value Object. Why: the same email
validation (`contains("@")`, `contains(".")`) is duplicated verbatim across
two unrelated services — the classic sign a raw `String` should be an
`Email` Value Object instead, so the validation lives in one place instead
of drifting out of sync between call sites.

## Case B — should NOT flag (calibration)

```java
public class ShippingLabelPrinter {
    public String render(String recipientName, String trackingNumber) {
        return recipientName + " — " + trackingNumber;
    }
}
```

**Expected**: do NOT flag. Why: `trackingNumber` is used in exactly one
place, with no validation or behavior attached to it — a primitive
`String` is fine here; wrapping it in a Value Object would be encapsulating
for its own sake (the principle's own "when NOT to apply it": a field used
in one place with no associated logic doesn't need a type).
