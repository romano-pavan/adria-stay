## ADR-001: Write core Terraform modules by hand instead of using registry modules

**Date:** 2026-07-10

**Context:** Community modules like terraform-aws-modules/vpc are
battle-tested and production-ready. Using them would get me to a
working stack much faster.


**Options considered:**
- A) Registry modules — fast, proven, but I'd be learning the module's
  input variables instead of the actual AWS resources underneath.
- B) Hand-written modules — slower, more mistakes along the way, but I
  learn every resource, every argument, every relationship.


**Decision:** B for v1 of this project.

**Why:** The main output of this project is my understanding, not the
infrastructure itself. I'm sacrificing speed for depth on purpose.


**Revisit when:** In a team/production context I would default to
registry modules and review their source instead.