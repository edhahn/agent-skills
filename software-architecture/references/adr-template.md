# Architecture Decision Record Template

## When to Write an ADR

Write an ADR when a decision is:
- Expensive to reverse (migration-level effort)
- Cross-cutting (affects multiple teams or components)
- Precedent-setting (establishes a pattern others will follow)
- Controversial (reasonable engineers disagree)

Don't write an ADR for routine choices. If the decision can be reversed in a single PR with no coordination, it doesn't need one.

## Template

```markdown
# ADR-[NUMBER]: [TITLE]

**Status**: Proposed | Accepted | Deprecated | Superseded by ADR-[N]
**Date**: YYYY-MM-DD
**Deciders**: [who is making or approving this decision]

## Context

What is the situation that motivates this decision? What forces are at play?
Include relevant constraints, requirements, and the current state of the system.
Keep it factual. This is not the place to argue for your preferred option.

## Decision

State the decision clearly and concisely. One or two sentences.

Example: "We will use PostgreSQL as the primary datastore for the billing service,
accessed via our standard ORM."

## Options Considered

### Option 1: [Name]

Brief description.

**Pros**: What's good about this option.
**Cons**: What's bad about this option.
**Estimated effort**: Rough cost to implement.

### Option 2: [Name]

(Same structure)

### Option 3: [Name] (if applicable)

(Same structure)

## Rationale

Why did we choose this option over the others? What was the deciding factor?
Be specific — "it's simpler" is not a rationale. "It requires no new infrastructure
and the team has 3 years of production experience with it" is.

## Consequences

What becomes easier or harder because of this decision?
What new constraints does this create?
What will we need to revisit if circumstances change?

## References

Links to relevant docs, RFCs, benchmarks, or prior art.
```

## Conventions

- Number ADRs sequentially. Never reuse a number.
- ADRs are immutable once accepted. If a decision changes, write a new ADR that supersedes the old one and update the old ADR's status.
- Store ADRs in the repo, close to the code they affect (e.g., `docs/adrs/` or `architecture/decisions/`).
- Keep them short. An ADR that takes more than 15 minutes to read is too long.
