# CTO — Technology Strategy & Architecture

## Decision Frameworks

### Technology Strategy vs. Engineering Management

The CTO lens in this skill is about **technology as a business lever**, not engineering management. Key questions:

- What technical capabilities give us competitive advantage?
- Where should we invest in building proprietary technology vs. using off-the-shelf?
- What's our platform strategy?
- How does our technical architecture constrain or enable business strategy?
- What technical risks could threaten the business?

### Technology Debt Assessment

Not all tech debt is bad. Categorize it:

| Type | Description | Action |
|---|---|---|
| **Deliberate, prudent** | "We know this won't scale past 10K users, but we need to ship now and we'll refactor in Q3." | Track it. Pay it down on schedule. |
| **Deliberate, reckless** | "We don't have time for tests." | This always costs more than it saves. Push back. |
| **Inadvertent, prudent** | "Now that we understand the domain better, we'd design this differently." | Natural and healthy. Refactor when you're in the area. |
| **Inadvertent, reckless** | "What's a load balancer?" | Skill gap. Fix through hiring or training, not just code. |

Measure debt by its **cost of carry** (how much it slows the team down per sprint) and its **risk exposure** (what breaks if we don't fix it). Pay down the debt with the highest cost-of-carry first.

### Build vs. Buy (Technical)

The CTO's version of build vs. buy adds technical dimensions:

- **Control**: Do we need to modify the internals? Can the vendor's API surface area cover our use cases?
- **Performance**: Does the off-the-shelf solution meet our latency/throughput requirements? At what cost?
- **Data sovereignty**: Where does data live? Can we keep it in our infrastructure if needed?
- **Integration complexity**: How well does it fit our existing architecture? Is the integration one-time or ongoing?
- **Upgrade path**: When the vendor releases a new version, does our integration break?

Rule of thumb: if you're wrapping a vendor's product so heavily that you're effectively reimplementing it, just build it. If your wrapper is thin and standard, buy it.

### Platform Strategy

At some point, a company needs to decide whether it's building a product or a platform. Signals that platform investment is warranted:

- Multiple products or features share the same core capabilities
- Partners or customers want to build on top of your product
- Internal teams are duplicating infrastructure work
- The cost of integrating a new feature is dominated by "plumbing," not domain logic

Platform investment is expensive and slow to pay off. Don't platformize prematurely — extract platforms from successful products, don't build them speculatively.

## Engineering Velocity

### Measuring Developer Productivity

Avoid single metrics. Use a balanced set:

- **Deployment frequency**: How often do we ship to production? Daily is healthy for most SaaS.
- **Lead time for changes**: Time from commit to production. Under a day is excellent. Over a week is a problem.
- **Change failure rate**: What percentage of deployments cause incidents? Under 5% is healthy.
- **Mean time to recovery**: When something breaks, how fast do we fix it? Under an hour is excellent.

These are the DORA metrics — well-validated and hard to game individually. Game them as a set and you're actually improving.

### What Slows Teams Down

In rough order of prevalence:

1. **Unclear requirements**: Engineering builds the wrong thing, discovers late, rebuilds.
2. **Slow CI/CD**: If the build takes 30 minutes, developers context-switch and lose flow.
3. **Flaky tests**: Tests that fail randomly erode trust. Engineers start ignoring failures.
4. **Code review bottlenecks**: PRs waiting days for review. Review within 24 hours or the context is lost.
5. **Environment problems**: "Works on my machine." Dev/staging/prod drift.
6. **Dependency hell**: Unresolvable version conflicts, breaking changes in upstream packages.
7. **Meeting overload**: Makers need long blocks of uninterrupted time. Protect them.

The CTO's job is to identify which of these is the current bottleneck and fix it systematically.

## Security & Compliance (CTO View)

The CTO owns the technical security posture. Key responsibilities:

- **Threat modeling**: Understand the attack surface and prioritize defenses accordingly.
- **Security architecture**: Defense in depth, least privilege, zero trust where appropriate.
- **Compliance as code**: SOC2, HIPAA, etc. should be automated, not manual. Audit readiness should be a CI check, not a quarterly fire drill.
- **Incident response**: Have a plan. Test it. The CTO should be the technical incident commander or have a clear delegate.
- **Vendor security review**: Every new SaaS tool or API is an extension of your attack surface. Review before adoption.

## Common CTO Failure Modes

- **Resume-driven architecture**: Choosing technology because it's interesting, not because it solves the problem. Boring technology that works is better than exciting technology that doesn't.
- **Premature optimization**: Building for 10M users when you have 100. You will rewrite it anyway when you actually understand the load patterns.
- **Ivory tower architecture**: Designing systems the team can't build, operate, or debug. Architecture must be implementable by the team you have, not the team you wish you had.
- **Ignoring operational concerns**: Building features without thinking about how they'll be deployed, monitored, debugged, and rolled back.
- **Not investing in developer experience**: Internal tooling, CI/CD, documentation, and onboarding are infrastructure that compounds. Neglecting them is borrowing against the entire team's productivity.
- **Cargo culting big-company patterns**: Microservices, event sourcing, CQRS, k8s — powerful at scale, expensive overhead at small scale. Match architecture complexity to organizational complexity.

## CTO Deliverables

### Technology Radar

Classify technologies into four rings:

- **Adopt**: Proven in production. Use by default for new work.
- **Trial**: Promising. Use in a bounded experiment with clear success criteria.
- **Assess**: Worth watching. Research and evaluate but don't commit.
- **Hold**: Don't start new work with this. Migrate away when practical.

Update quarterly. Include rationale for any changes.

### Technical Strategy Document

1. **Current state**: Architecture overview, tech stack, key strengths and weaknesses.
2. **Business context**: What does the business need from technology in the next 12-18 months?
3. **Strategic initiatives** (max 3-4): The big technical investments. For each: what, why, expected impact, rough cost, timeline.
4. **Principles**: The decision-making guidelines the team follows (e.g., "we prefer managed services over self-hosted," "we build for observability first").
5. **Risks**: Top technical risks to the business and mitigation plans.
