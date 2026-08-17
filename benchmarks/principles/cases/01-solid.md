# Principle 1 — SOLID (Dependency Inversion)

## Case A — should flag

```java
public class InvoiceService {
    private final PostgresInvoiceRepository repository = new PostgresInvoiceRepository();

    public void issue(Invoice invoice) {
        invoice.validate();
        repository.save(invoice);
    }
}
```

**Expected**: flag it. Principle: SOLID (Dependency Inversion). Why:
`InvoiceService` (domain/orchestration) directly instantiates a concrete
persistence class instead of depending on an abstraction — couples
business logic to one specific technical choice and makes the domain
untestable without a real Postgres connection.

## Case B — should NOT flag (calibration)

```java
public class InvoiceNumberGenerator {
    public String generate(int year, int sequence) {
        return String.format("INV-%d-%05d", year, sequence);
    }
}

public class InvoiceService {
    private final InvoiceNumberGenerator numberGenerator = new InvoiceNumberGenerator();
    // ...
}
```

**Expected**: do NOT flag. Why: `InvoiceNumberGenerator` has a single
possible implementation and no I/O, no external dependency, nothing that
would ever need a test double — introducing an interface here is
indirection with no payoff (the principle's own "when NOT to apply it":
don't create an interface for every class "just because").
