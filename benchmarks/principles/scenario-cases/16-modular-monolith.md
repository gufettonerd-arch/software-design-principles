# Principle 16 — Modular Monolith

## Case A — should recommend it

**Scenario**: A project already organizes code by bounded context —
`booking/`, `payments/`, `privacy/`, each with its own controller,
service, and domain classes. Nothing technical stops one module from
reaching into another's internals, though: a recent change in
`booking/BookingService` directly imports and calls
`privacy.internal.ConsentRepository` (a class explicitly named
"internal" in `privacy/`'s own package structure) because it was the
fastest way to check a consent flag. Nobody flagged it in review — there's
no automated check that would have caught it, only convention.

**Expected**: recommend it. Why: bounded contexts already exist here
(the folder structure), but with nothing enforcing the boundary, a
convention-only boundary erodes exactly the way this example shows — a
deadline-driven shortcut reaches across into another module's declared
"internal" package, and nothing stops it from compiling and shipping. An
automated boundary-enforcement tool (e.g. ArchUnit-style rules forbidding
`booking` from depending on `privacy.internal.*`) would turn this from a
review miss into a build failure.

## Case B — should NOT recommend it (calibration)

**Scenario**: A project has bounded-context-style folders (`booking/`,
`availability/`) but is maintained by one team of three people with no
plans to grow the team or split ownership. No cross-module leaks have
happened in the project's two-year history, and the team already
consistently reviews PRs for exactly this kind of boundary violation.

**Expected**: do NOT recommend it. Why: the principle's own "when NOT to
apply it" — a single small team with no growth expected gets little from
automated enforcement over manual discipline that's already working (two
years, no incidents). Adding a boundary-enforcement tool and its
maintenance overhead here is solving a problem (undisciplined
cross-module coupling) that isn't actually occurring.
