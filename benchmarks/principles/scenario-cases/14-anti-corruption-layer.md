# Principle 14 — Anti-Corruption Layer (ACL)

## Case A — should recommend it

**Scenario**: A modern order-processing service integrates with a
20-year-old mainframe inventory system over a fixed-width text format.
Several places in the domain layer — `OrderValidator`,
`ShippingEstimator`, `InventoryReportBuilder` — each parse the mainframe's
raw response directly: reading fixed-column substrings, checking
single-character status codes (`"A"`, `"B"`, `"X"`) inline, and passing
the mainframe's own date format (`YYYYDDD` julian dates) straight into
domain logic that otherwise uses `LocalDate` everywhere else.

**Expected**: recommend an ACL. Why: this is the exact problem the
pattern exists for — the legacy system's raw format (fixed-width
columns, single-char codes, julian dates) has leaked into three separate
places in the modern domain instead of being translated once, at one
boundary. A single converter/mapper that turns the mainframe's raw
response into proper domain types (an enum for status, `LocalDate` for
dates) would let the rest of the domain stop knowing the mainframe
exists.

## Case B — should NOT recommend it (calibration)

**Scenario**: A service integrates with a well-documented, modern REST
API from a well-regarded SaaS vendor. The API's JSON shapes map cleanly
onto the service's own domain concepts — a `Customer` from the vendor's
API has the same fields, the same types, and the same meaning as the
service's own `Customer`. The integration currently deserializes the
vendor's JSON directly into the service's own domain objects via a
standard JSON library, no intermediate translation step.

**Expected**: do NOT recommend an ACL. Why: the principle's own "when NOT
to apply it" — the vendor's model is already conceptually aligned with
the domain, nothing "dirty" or foreign is leaking in that needs
isolating. Adding a translation layer here would be bureaucracy: an extra
class, an extra mapping step, with nothing to protect against, since
there's no impedance mismatch to absorb.
