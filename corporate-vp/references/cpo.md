# CPO — Product Strategy & Customer Value

## Decision Frameworks

### Prioritization: RICE with Teeth

RICE (Reach × Impact × Confidence / Effort) is a starting point, not gospel. The real work is in honest scoring.

| Factor | How to score honestly |
|---|---|
| **Reach** | How many users/customers does this affect per quarter? Use data, not feelings. |
| **Impact** | How much does it move the metric that matters? Score: 3 = massive, 2 = high, 1 = medium, 0.5 = low, 0.25 = minimal. |
| **Confidence** | How sure are you about reach and impact? 100% = data-backed. 80% = strong signal. 50% = gut feel. If confidence is below 50%, run a discovery spike, don't build. |
| **Effort** | Person-weeks of engineering, design, and QA. Include integration, migration, and documentation — not just "the fun part." |

RICE doesn't capture strategic importance. A low-RICE feature that's a prerequisite for a major deal or market entry might still be the right call. Use RICE as input, not as the decision.

### Product-Market Fit Assessment

PMF isn't binary — it's a spectrum. Measure where you are:

**Lagging indicators** (you have PMF):
- NRR > 110%
- Organic/word-of-mouth > 30% of new customers
- Sales cycle is shortening
- Customers resist switching even when competitors undercut on price

**Leading indicators** (you're approaching PMF):
- Users complete the core value loop without hand-holding
- Activation rate is improving month-over-month
- Qualitative feedback shifts from "it's interesting" to "I can't work without this"
- Retention curves flatten (usage stabilizes rather than declining)

**PMF red flags**:
- High acquisition, low retention
- Customers use it but wouldn't recommend it
- Every deal requires heavy customization
- Churn correlates with "champion left the company"

### Build vs. Buy vs. Partner

| Factor | Build | Buy (vendor/SaaS) | Partner (integration) |
|---|---|---|---|
| **When** | Core differentiator, unique requirements, long-term strategic value | Commodity capability, proven vendors, not your core competency | Complementary product, shared customer base, mutual benefit |
| **True cost** | Engineering time + maintenance + opportunity cost | License + integration + vendor dependency + switching cost | Integration + relationship management + dependency |
| **Risk** | Takes longer than expected. Always. | Vendor changes pricing, pivots, or dies | Partner priorities diverge from yours |
| **Exit cost** | Sunk cost but you own it | Data migration + process change | Integration teardown + customer communication |

The most common mistake is building what you should buy and buying what you should build. If it's where you compete, build it. If it's table stakes, buy it.

## Product Strategy Tools

### Opportunity Solution Tree

Map the path from outcome to delivery:

```
Business Outcome (e.g., increase NRR to 120%)
├── Opportunity 1 (e.g., users churn because onboarding is too complex)
│   ├── Solution A (guided setup wizard)
│   ├── Solution B (white-glove onboarding service)
│   └── Solution C (simplify the product — remove features)
├── Opportunity 2 (e.g., power users want features that would justify higher tier)
│   ├── Solution D (advanced analytics dashboard)
│   └── Solution E (API access for custom integrations)
└── Opportunity 3 (e.g., ...)
```

Validate opportunities before investing in solutions. The biggest product waste is solving the wrong problem well.

### Jobs to Be Done (JTBD)

When [situation], I want to [motivation], so I can [expected outcome].

- **Situation**: The triggering context. When does the need arise?
- **Motivation**: What the user is trying to accomplish (not what feature they want).
- **Expected outcome**: How they'll know they succeeded.

Good JTBD: "When I'm onboarding a new enterprise client, I want to configure their workspace in under 10 minutes, so I can handle more clients without hiring more CSMs."

Bad JTBD: "I want a better dashboard." (That's a feature request, not a job.)

## Roadmap Philosophy

### What a Roadmap Is

A roadmap is a **communication tool** that shows strategic intent and sequencing. It is not a delivery commitment with dates.

### Roadmap Structure

Organize by time horizon and certainty:

| Horizon | Timeframe | Certainty | Detail level |
|---|---|---|---|
| **Now** | This quarter | High (committed) | Specific features with scope |
| **Next** | Next quarter | Medium (planned) | Themes with candidate features |
| **Later** | 2-4 quarters out | Low (exploratory) | Strategic bets and opportunity areas |

Never put dates on "Later" items. They will be treated as commitments.

### Saying No

The CPO's most important job is saying no. A product that tries to do everything does nothing well.

Useful frameworks for declining requests:
- "That's a great feature for a different product."
- "We'd need to see [specific signal] before investing in that area."
- "That's on our radar for [Later horizon] — here's what we're prioritizing first and why."
- For sales-driven requests: "How many deals did we lose specifically because of this? What was the total revenue?"

## Common CPO Failure Modes

- **Roadmap by loudest customer**: Enterprise customers will design your product for their specific workflow if you let them. That's consulting, not product.
- **Feature factory**: Shipping features without measuring outcomes. If you can't tie a feature to a metric that moved, you don't know if it worked.
- **Ignoring activation**: Acquiring users who never experience the core value. Fix activation before adding features.
- **Over-indexing on competitors**: Building what competitors have instead of what customers need. Fast followers win on execution, not feature parity.
- **No kill criteria**: Features that underperform should be removed. Every feature has maintenance cost. Dead features are operational debt.

## CPO Deliverables

### Product Strategy One-Pager

1. **Vision** (1 sentence): Where are we going?
2. **Current state**: Where are we now? Key metrics.
3. **Target customer**: Who, specifically, and what's their primary job-to-be-done?
4. **Strategic bets** (max 3): The big moves this year. For each: hypothesis, success metric, investment required.
5. **What we're NOT doing**: Explicit exclusions.

### Feature Spec (Lightweight)

1. **Problem statement**: What user pain are we addressing? Evidence it's real.
2. **Success metric**: How will we know this worked?
3. **Scope**: What's in and what's out.
4. **User flows**: Key interactions, happy path and error states.
5. **Technical considerations**: Anything the engineering team needs to know early.
6. **Launch plan**: How will users discover this? What's the rollout strategy?
