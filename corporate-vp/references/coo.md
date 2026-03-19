# COO — Execution, Operations & Scale

## Decision Frameworks

### Operational Readiness Assessment

Before launching anything (product, market, campaign, partnership), assess:

1. **Process**: Is the workflow documented end-to-end? Who owns each step?
2. **People**: Do we have the headcount and skills to operate this at projected volume?
3. **Tools**: Are the systems in place, integrated, and tested?
4. **Metrics**: Can we measure quality, throughput, and cost per unit?
5. **Failure modes**: What breaks first at 2x volume? At 10x? What's the manual fallback?

If any answer is "we'll figure it out," that's a risk — quantify it or mitigate it before launch.

### Scaling Bottleneck Analysis

At every growth stage, exactly one thing is the binding constraint. Find it.

| Stage | Typical bottleneck | Symptom |
|---|---|---|
| 1-10 employees | Founder bandwidth | Everything depends on 1-2 people |
| 10-30 | Hiring velocity | Can't backfill fast enough to keep up with work |
| 30-75 | Process debt | Things that "just worked" start breaking |
| 75-200 | Middle management | Decisions stall, context is lost between layers |
| 200-500 | Cross-functional coordination | Teams optimize locally, conflict globally |
| 500+ | Culture drift | New hires don't understand "how we do things here" |

The COO's job is to solve the current bottleneck and start preparing for the next one.

### Build vs. Buy vs. Hire (Operations)

For any operational capability:

- **Buy (SaaS/vendor)**: When it's not a competitive differentiator, a vendor does it better, and the integration cost is low.
- **Build (internal tooling)**: When it's core to the product or workflow, when no vendor fits, or when vendor costs don't scale.
- **Hire (agency/contractor)**: When you need the capability now but aren't sure it's permanent. Test with contractors, convert to FTE if it sticks.

## Operational Metrics Framework

### Efficiency Metrics

- **Revenue per employee**: Benchmark varies by industry. SaaS: $150K-300K at scale.
- **Burn multiple**: Net burn / net new ARR. Under 1.5 is efficient. Over 3 is a problem.
- **Cycle time**: How long from decision to delivery? Measure at every critical workflow.
- **Rework rate**: What percentage of work gets done twice? High rework = process or communication failure.

### Quality Metrics

- **SLA adherence**: Are we meeting our commitments to customers?
- **Incident frequency and severity**: Trending down = healthy ops. Trending up = scaling faster than quality.
- **Customer effort score**: How hard is it to get something done with us?
- **Internal handoff errors**: How often does work break at the seams between teams?

## Common COO Failure Modes

- **Over-process**: Adding process for every problem. Process has overhead — it should earn its place. If a process doesn't obviously save more time than it costs, kill it.
- **Under-process**: Glorifying chaos as "startup culture." Repeatable outcomes require repeatable processes.
- **Reacting to incidents, not patterns**: Fixing the immediate problem without asking why it happened and whether the same class of problem will recur.
- **Centralized decision-making**: If every cross-functional decision routes through the COO, you're a bottleneck, not a leader.
- **Ignoring internal tooling**: Bad internal tools compound into massive efficiency losses. An engineer spending 30 minutes a day fighting a bad deploy pipeline is a week per quarter wasted.

## COO Deliverables

### Operational Review (Monthly/Quarterly)

1. **Throughput & Quality Dashboard**: Key metrics with trend lines, not just snapshots.
2. **Bottleneck Report**: What's the current binding constraint? What's being done about it?
3. **Capacity Plan**: Current headcount vs. workload. Where do we need to hire? Where are we overstaffed?
4. **Process Changes**: What changed this period, why, and what's the measured impact?
5. **Cross-Functional Issues**: What's falling through the cracks between teams?

### Incident Postmortem Template

1. **Summary**: What happened, when, impact (users affected, revenue impact, duration).
2. **Timeline**: Minute-by-minute sequence of events.
3. **Root cause**: The actual root cause, not the proximate trigger. Use "5 whys" or equivalent.
4. **Contributing factors**: What made the impact worse or detection slower?
5. **Action items**: Owner, deadline, and how we'll verify it's fixed. No action item without an owner.
