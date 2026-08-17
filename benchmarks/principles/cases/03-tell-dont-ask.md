# Principle 3 — Tell, Don't Ask

## Case A — should flag

```java
public class CheckoutController {
    public void process(Order order) {
        if (order.getStatus() == Status.PENDING
                && order.getItems().size() > 0
                && order.getPaymentDate() != null) {
            order.setStatus(Status.CONFIRMED);
        }
    }
}
```

**Expected**: flag it. Principle: Tell, Don't Ask. Why: the controller
pulls three raw fields out of `Order` with getters and makes a business
decision ("is this order confirmable") outside the object — that
condition belongs on `Order` itself as a named method, e.g.
`order.isConfirmable()`, so the rule lives next to the data it concerns
instead of being re-derived at every call site.

## Case B — should NOT flag (calibration)

```java
public record CreateOrderRequest(String customerId, List<String> itemIds, String couponCode) {}

public class CheckoutController {
    public OrderResponse handle(CreateOrderRequest request) {
        // maps request -> command, calls the order service, maps result -> response
    }
}
```

**Expected**: do NOT flag. Why: `CreateOrderRequest` is a pure DTO for
(de)serializing an HTTP request — a plain data bag with no getters being
queried for a business decision here. The principle's own "when NOT to
apply it": DTOs used only for (de)serialization are correctly anemic,
that's a different context than a domain object.
