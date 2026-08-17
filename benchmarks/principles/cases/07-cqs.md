# Principle 7 — Command-Query Separation

## Case A — should flag

```java
public class AccountValidator {
    private final AuditLog auditLog;

    public boolean hasSufficientFunds(Account account, double amount) {
        boolean ok = account.getBalance() >= amount;
        if (!ok) {
            auditLog.record("Insufficient funds check failed for " + account.getId());
        }
        return ok;
    }
}
```

**Expected**: flag it. Principle: Command-Query Separation. Why: the
method name and return type promise a pure question ("has..."), but the
body has a side effect (writing to the audit log) hidden inside — calling
it more than once, or in a test, silently produces log entries the caller
never asked for. The logging (a command) belongs in the caller, which can
decide when and how to react to a failed check.

## Case B — should NOT flag (calibration)

```java
public class ProductCatalog {
    private final Cache<String, Product> cache;

    public Product findById(String id) {
        Product cached = cache.get(id);
        if (cached != null) {
            metrics.increment("catalog.cache.hit");
            return cached;
        }
        metrics.increment("catalog.cache.miss");
        Product loaded = repository.load(id);
        cache.put(id, loaded);
        return loaded;
    }
}
```

**Expected**: do NOT flag. Why: this is a query with a cost (a lookup that
may hit the network) doing purely observational logging (cache hit/miss
metrics) that doesn't alter the returned value or surprise the caller —
the principle's own "when NOT to apply it" names this exact gray area as
accepted.
