# Principle 13 — Package by feature vs package by layer

## Case A — should recommend switching to feature

**Scenario**: A project organizes code as `controller/`, `service/`,
`repository/`, `domain/`, each folder holding classes for every feature
the product has (booking, payments, notifications, reporting — a dozen
features total, and growing). A developer reports that adding one small
feature meant opening five different folders and cross-referencing class
names by prefix to find all the related pieces, and a recent onboarding
engineer took most of a week just to locate everything related to the
payments flow.

**Expected**: recommend switching to package-by-feature. Why: this is the
problem package-by-feature solves directly — on a project with many
features where "everything related to X" is scattered across N technical
layers, by-layer organization makes normal work (find everything for one
feature) slower than it needs to be. A `payments/` folder holding its own
controller+service+domain+repository would put all of that in one place.

## Case B — should NOT recommend switching (calibration)

**Scenario**: A small internal admin tool has three related screens
(user list, user detail, user edit) organized as `controller/`,
`service/`, `repository/`. A new engineer unfamiliar with the domain is
about to onboard onto the project.

**Expected**: do NOT recommend switching. Why: the principle's own
"when NOT to apply it" — on a small project, by-layer is often *easier*
to navigate for someone who doesn't know the domain yet, since the
technical shape (all controllers together, all repositories together) is
a familiar landmark regardless of domain knowledge. There's no absolute
winner between the two layouts; recommending a switch here optimizes for
a problem (feature-scatter on a large codebase) this project doesn't have.
