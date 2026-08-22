# Principle 11 — DDD strategic (Bounded Context)

## Case A — should recommend it

**Scenario**: A project has grown to cover booking, payments, notifications,
and reporting. All four live in the same `controller/`, `service/`,
`repository/`, `domain/` folders — e.g. `service/` alone has
`BookingService`, `PaymentService`, `NotificationService`,
`ReportingService` side by side, no further grouping. Three separate
teams now each own one of these business areas, but changes to one
service routinely require touching shared classes the other teams also
depend on, and merge conflicts between teams are a recurring complaint in
retros.

**Expected**: recommend it. Principle: DDD strategic (Bounded Context).
Why: multiple teams working on distinct business areas through a single
undifferentiated layer structure is exactly the situation bounded context
exists for — an explicit boundary per business area (`booking/`,
`payments/`, each with its own controller+service+domain) would let each
team change their area without routing through shared layer folders every
other team also touches. Should be flagged as worth evaluating, not
demanded as an immediate rewrite — the principle's own guidance is to
consider it, not force a big-bang restructure.

## Case B — should NOT recommend it (calibration)

**Scenario**: A project has the same `controller/`, `service/`,
`repository/`, `domain/` layered structure, containing three related
features (booking, availability, cancellation) for one team of four
people. No other teams are involved, no near-term growth is planned, and
nobody has reported friction navigating the code.

**Expected**: do NOT recommend it. Why: a small project with a single
team and no reported navigation friction is exactly the principle's own
"when NOT to apply it" — splitting into bounded contexts adds ceremony
(more folders, more indirection, a translation layer per boundary) with
no benefit yet to offset it. Recommending the split here would be solving
a problem that doesn't exist, on the strength of the pattern's name alone.
