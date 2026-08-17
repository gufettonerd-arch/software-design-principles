# Principle 11 — Hexagonal Architecture / Ports & Adapters

## Case A — should flag

```java
public class PayrollDomainService {
    private final SftpPayslipUploader uploader = new SftpPayslipUploader("payroll.internal", 22);

    public void distribute(List<Payslip> payslips) {
        for (Payslip p : payslips) {
            uploader.upload(p.toPdf());
        }
    }
}
```

**Expected**: flag it. Principle: Hexagonal Architecture (same root cause
as SOLID's Dependency Inversion, at the architecture-boundary level). Why:
core domain logic (`PayrollDomainService`) directly depends on a concrete
infrastructure detail — an SFTP client, hardcoded host and port — instead
of an interface the domain defines for what it needs ("deliver this
payslip somewhere"). Testing distribution logic now requires a real SFTP
server; swapping the delivery mechanism means editing domain code.

## Case B — should NOT flag (calibration)

```java
public class ReportExportTool {
    public void exportToCsv(List<Row> rows, Path outputFile) throws IOException {
        try (var writer = Files.newBufferedWriter(outputFile)) {
            for (Row r : rows) writer.write(r.toCsvLine());
        }
    }
}
```

**Expected**: do NOT flag. Why: this is a standalone CLI/export utility,
not domain logic with business rules to protect — there's no "core" being
coupled to a technical detail, the whole point of the class *is* the
technical detail (writing CSV to disk). The principle's own "when NOT to
apply it": for simple utilities with no real domain logic to isolate,
introducing ports/adapters is pure overhead.
