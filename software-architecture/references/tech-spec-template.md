# Technical Specification Template

## When to Write a Tech Spec

Write a tech spec before building when:
- The work spans multiple components or services
- Multiple engineers will contribute
- The system has non-obvious failure modes
- Stakeholders need to align on approach before committing engineering time
- You need to think through edge cases that are cheaper to find on paper than in code

A tech spec is NOT a detailed implementation guide. It defines *what* the system does, *why* it's designed this way, and *where the boundaries are*. The *how* at the code level belongs in the code.

## Template

```markdown
# [Feature/System Name] — Technical Specification

**Author**: [name]
**Reviewers**: [names]
**Status**: Draft | In Review | Approved | Implemented
**Date**: YYYY-MM-DD
**Target release**: [version or date, if applicable]

## Summary

One paragraph. What are we building and why? A busy engineer should be able to read
this and decide if they need to read the rest.

## Goals and Non-Goals

### Goals
- Concrete, measurable outcomes this work achieves.

### Non-Goals
- Things this work explicitly does NOT address, to prevent scope creep.
  Especially important for things a reader might assume are in scope.

## Background

Context a reader needs to understand the problem. Link to prior art, ADRs, or
existing systems. Don't repeat information available elsewhere — link to it.

## Design

### Architecture Overview

High-level diagram or description of components and their interactions.
Include a diagram if the system has more than 3 interacting components.

### Data Model

Schema changes, new tables/collections, or data flow changes.
Include field types and constraints for new schemas.

### API Changes

New or modified endpoints/interfaces. Include request/response shapes
for significant changes. Note backward compatibility implications.

### Key Design Decisions

For each non-obvious design choice, briefly explain:
- What you chose
- Why you chose it (link to ADR if one exists)
- What you considered and rejected

### Failure Modes

What happens when:
- Dependencies are unavailable?
- Input is malformed or malicious?
- The system is overloaded?
- A partial failure occurs mid-operation?

For each, describe the expected behavior and recovery path.

## Security Considerations

- Authentication/authorization changes
- New data sensitivity classifications
- Input validation requirements
- Audit logging needs

## Observability

- Key metrics to emit
- Log events for debugging
- Alerting thresholds
- Dashboard changes

## Rollout Plan

How will this be deployed?
- Feature flags?
- Phased rollout?
- Migration steps?
- Rollback procedure?

## Open Questions

Things that still need resolution. Track who owns each question
and when it needs to be answered by.

| Question | Owner | Deadline |
|---|---|---|
| ... | ... | ... |
```

## Tips

- **Keep it under 4 pages.** If it's longer, the scope is too big — split it.
- **Diagrams are worth 500 words.** Use them for data flow, component interaction, and state machines. Mermaid or simple ASCII diagrams are fine.
- **Write for the skeptic.** Assume the reader is smart, busy, and will ask "why not just do X instead?" Answer that question preemptively.
- **Non-goals are as important as goals.** They prevent the spec from expanding during review.
- **The spec is a living document during design, frozen during implementation.** If implementation reveals the spec is wrong, update it — but acknowledge the change.
