# Principle 6 — Named design patterns (Strategy)

## Case A — should flag

```java
public class FeeCalculator {
    public double fee(String paymentMethod, double amount) {
        if (paymentMethod.equals("CREDIT_CARD")) return amount * 0.029 + 0.30;
        if (paymentMethod.equals("BANK_TRANSFER")) return 0.50;
        if (paymentMethod.equals("PAYPAL")) return amount * 0.034 + 0.35;
        if (paymentMethod.equals("CRYPTO")) return amount * 0.01;
        if (paymentMethod.equals("APPLE_PAY")) return amount * 0.029;
        throw new IllegalArgumentException("Unknown method: " + paymentMethod);
    }
}
```

**Expected**: flag it. Principle: Strategy pattern. Why: a `switch`/`if`
chain choosing behavior by type, already at 5 branches and structured so
every new payment method requires editing this method again (violates
Open/Closed too) — a Strategy (one interface, one implementation per
payment method, selected at runtime) would let a new method be added
without touching existing code.

## Case B — should NOT flag (calibration)

```java
public class DiscountEligibility {
    public boolean isEligible(String customerType, double orderTotal) {
        if (customerType.equals("VIP")) return true;
        return orderTotal >= 200;
    }
}
```

**Expected**: do NOT flag. Why: two branches, and the domain has exactly
two customer types by definition (VIP / regular) with no roadmap for more —
a Strategy pattern here would be a pattern with more files than the
`if/else` it replaces. The principle's own "when NOT to apply it": if the
implementations are 2 and won't grow, a plain conditional is more readable.
