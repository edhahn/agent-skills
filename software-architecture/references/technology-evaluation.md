# Technology Evaluation Checklist

Use this when making a formal recommendation to adopt (or reject) a technology. Not every item applies to every evaluation — skip what's irrelevant, but consciously skip it rather than forget it.

## Problem Fit

- [ ] What specific problem does this solve that our current stack doesn't?
- [ ] Can we solve this problem with what we already have, possibly with modest effort?
- [ ] Does it solve the problem at our current scale? At 10x our current scale?
- [ ] Are we adopting this because it solves a real problem or because it's interesting?

## Maturity & Ecosystem

- [ ] How old is the project? Is it past the "move fast and break things" phase?
- [ ] What's the release cadence? Are there recent commits, or is it abandoned?
- [ ] Who maintains it? Single person, small team, well-funded org, large OSS community?
- [ ] What's the bus factor? If the primary maintainer disappears, what happens?
- [ ] Is there a commercial entity behind it? Does that create risk (rug-pull, license change) or stability?
- [ ] What's the license? Is it compatible with our use case (including commercial use)?
- [ ] How large and active is the community? Can we find answers to problems when we hit them?
- [ ] Are there production references at our scale or larger?

## Operational Cost

- [ ] What infrastructure does it require? (Servers, managed services, sidecars, agents)
- [ ] What's the monitoring story? Does it expose metrics, logs, health checks?
- [ ] What happens when it breaks at 2am? Is the failure mode graceful or catastrophic?
- [ ] What's the upgrade path? Can we upgrade without downtime?
- [ ] Does it have known operational sharp edges? (Memory leaks, GC pauses, connection pooling issues)

## Integration & Migration

- [ ] How does it integrate with our existing stack? Native support, adapters, or custom glue?
- [ ] Can we adopt it incrementally, or is it all-or-nothing?
- [ ] What's the migration path FROM this if it doesn't work out? How coupled are we?
- [ ] Does it require changes to our CI/CD pipeline, deployment process, or infrastructure?
- [ ] What data migration is required?

## Team Readiness

- [ ] Does anyone on the team have production experience with this?
- [ ] How steep is the learning curve? What's the realistic ramp-up time?
- [ ] Is the documentation good enough to learn from, or are we reverse-engineering from source?
- [ ] Can we hire for this skill if we need to?

## Cost

- [ ] What's the licensing cost (if any) at current scale? At 10x?
- [ ] What's the infrastructure cost?
- [ ] What's the engineering time cost to adopt, including learning curve?
- [ ] What's the ongoing maintenance cost (upgrades, patches, operational care)?

## Security

- [ ] Does it have a security disclosure process?
- [ ] What's the CVE history? How quickly are vulnerabilities patched?
- [ ] Does it handle credentials/secrets properly?
- [ ] Does it support our authentication/authorization requirements?
- [ ] Is it SOC2/HIPAA/FedRAMP compliant if we need it to be?

## Decision Format

Summarize the evaluation as:

```
## [Technology Name] — [Adopt / Trial / Hold / Reject]

**Problem it solves**: One sentence.
**Key tradeoff**: What we gain vs. what we give up.
**Recommendation**: Adopt / Trial (time-boxed experiment) / Hold (watch but don't act) / Reject (with rationale).
**Risks**: Top 2-3 risks if we adopt.
**Exit strategy**: How we'd migrate away if needed.
```
