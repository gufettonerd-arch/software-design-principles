# Principle 10 — Domain-Driven Design (tactical)

## Case A — should flag

```java
public class Subscription {
    private String status;
    private LocalDate renewalDate;
    private LocalDate cancelledDate;

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDate getRenewalDate() { return renewalDate; }
    public void setRenewalDate(LocalDate d) { this.renewalDate = d; }
    public LocalDate getCancelledDate() { return cancelledDate; }
    public void setCancelledDate(LocalDate d) { this.cancelledDate = d; }
}

public class SubscriptionService {
    public void cancel(Subscription s) {
        if (s.getStatus().equals("ACTIVE") && s.getCancelledDate() == null) {
            s.setStatus("CANCELLED");
            s.setCancelledDate(LocalDate.now());
        }
    }
}
```

**Expected**: flag it. Principle: DDD tactical (anemic model). Why:
`Subscription` is pure getters/setters with a raw `String` status and no
behavior — all the business logic ("can this be cancelled, what does
cancelling mean") lives in `SubscriptionService` instead, so nothing stops
`s.setStatus("CANCELLED")` from being called directly and leaving
`cancelledDate` null and inconsistent.

## Case B — should NOT flag (calibration)

```java
@Entity
public class SubscriptionRow {
    @Id private Long id;
    private String status;
    private LocalDate renewalDate;
    // JPA-required no-arg constructor, getters, setters
}
```

**Expected**: do NOT flag. Why: this is explicitly a persistence-layer
entity (`@Entity`), not the domain object — the principle's own guidance
distinguishes this: a JPA/ORM entity can and often should stay anemic,
since the framework needs mutability; the rich behavior belongs on a
separate domain object that wraps or maps from this one, not on the
persistence row itself.
