# Principle 4 — Law of Demeter

## Case A — should flag

```java
public class ShippingLabelService {
    public String buildLabel(Order order) {
        String city = order.getCustomer().getAddress().getCity().toUpperCase();
        return city;
    }
}
```

**Expected**: flag it. Principle: Law of Demeter. Why: `order.getCustomer()
.getAddress().getCity()` is a three-level getter chain reaching into
objects `ShippingLabelService` has no direct relationship with — if
`Customer`'s internal structure changes (e.g. multiple addresses), this
call site breaks even though it has nothing to do with that change.
`order.shippingCity()` (or similar) would hide the path.

## Case B — should NOT flag (calibration)

```java
public record Money(long cents, String currency) {}
public record LineItem(String sku, int quantity, Money unitPrice) {}
public record Order(String id, List<LineItem> items) {}

public class ReceiptPrinter {
    public String priceOf(LineItem item) {
        return item.unitPrice().currency() + " " + item.unitPrice().cents();
    }
}
```

**Expected**: do NOT flag. Why: `LineItem`/`Money` are immutable, purely
structural Value Objects composed together — navigating
`item.unitPrice().currency()` isn't reaching into a mutable object's
internals, it's reading a composed value type. The principle's own "when
NOT to apply it": some navigation through composed Value Objects is normal
and isn't real coupling.
