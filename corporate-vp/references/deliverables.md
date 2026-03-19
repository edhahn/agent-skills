# Executive Deliverables — Templates & Guidance

Cross-cutting deliverable templates. For role-specific deliverables, see the individual role reference files.

## Board Deck

### Structure (10-15 slides max)

1. **Cover**: Company name, quarter, date.
2. **Executive Summary** (1 slide): 3-5 key metrics with green/yellow/red status vs. plan. One sentence on overall trajectory. Board members should know the story from this slide alone.
3. **Financial Overview** (2 slides): Revenue, burn, runway, key unit economics. Actual vs. plan vs. prior quarter. Explain variances over 10%.
4. **Product & Engineering** (1-2 slides): What shipped, key metrics (adoption, usage, quality). Roadmap highlights for next quarter.
5. **Go-To-Market** (1-2 slides): Pipeline, win rates, channel performance, logo wins. Customer health (NRR, churn, NPS).
6. **Team** (1 slide): Headcount vs. plan, key hires, open roles, attrition.
7. **Strategic Discussion** (1-2 slides): The one big topic the board should weigh in on. Frame it as a decision or a debate, not a status update.
8. **Risks & Challenges** (1 slide): Top 3 risks. For each: what it is, likelihood, impact, mitigation.
9. **Asks** (1 slide): Specific requests — intros, approvals, advice. Don't leave this blank.
10. **Appendix**: Detailed financials, cohort data, competitive landscape. Reference material, not for presentation.

### Board Deck Principles

- **No surprises**: If there's bad news, the CEO should have communicated it before the meeting. The deck confirms what the board already knows.
- **Data density over decoration**: Boards don't need animations or stock photos. They need numbers and context.
- **One metric per claim**: Every assertion backed by a specific number.
- **Trend lines over snapshots**: Show direction, not just position. 3-6 months of history minimum.

## Investor Update (Monthly)

### Structure

Keep it under one page (email format). Investors get dozens of these.

```
Subject: [Company Name] — [Month Year] Update

HEADLINE: [One sentence — the single most important thing this month]

KEY METRICS:
- ARR/MRR: $X (+Y% MoM)
- Cash: $X (Z months runway)
- Burn: $X/month
- [1-2 other metrics that matter for your business]

WINS:
- [2-3 bullet points, specific and quantified]

CHALLENGES:
- [1-2 bullet points, honest and specific]

PRIORITIES NEXT MONTH:
- [2-3 bullet points]

ASKS:
- [Specific requests — intros, advice, hiring help]
```

### Investor Update Principles

- **Consistency**: Send on the same day every month. Irregular updates erode confidence.
- **Honesty**: Investors respect candor. They lose trust over omission.
- **Specificity**: "Revenue grew" → "ARR reached $1.8M, up 14% MoM driven by 3 new enterprise logos."
- **Brevity**: If it takes more than 3 minutes to read, it's too long.

## Strategic Memo

For internal alignment on significant decisions. Not a spec — a memo argues for a course of action.

### Structure

```
STRATEGIC MEMO: [Decision Title]

Author: [name]
Date: [date]
Status: Proposal / Under Review / Approved / Rejected

1. THE ASK
   What decision are we making? State it in one sentence.

2. CONTEXT
   Why now? What changed that makes this decision urgent or timely?

3. RECOMMENDATION
   What should we do? Be specific.

4. RATIONALE
   Why this option over alternatives? Include:
   - Evidence (data, customer feedback, market signals)
   - Financial impact (cost, revenue, ROI estimate)
   - Risk assessment

5. ALTERNATIVES CONSIDERED
   What else did we evaluate? Why did we reject it?
   (Include "do nothing" as an option.)

6. TRADEOFFS
   What are we giving up? What gets harder?

7. IMPLEMENTATION
   High-level plan: who, what, when, key milestones.

8. SUCCESS CRITERIA
   How will we know this worked? Specific metrics and timeframes.

9. DECISION NEEDED BY
   [Date] — explain why this deadline matters.
```

### Memo Principles

- **Lead with the recommendation**: Busy executives read top-down. Put the answer first.
- **Quantify everything**: "Significant cost savings" → "$180K/year reduction in infrastructure spend."
- **Steel-man the alternatives**: If you can't make a compelling case for the alternatives, you don't understand the decision well enough.
- **One decision per memo**: If it branches into multiple decisions, split it.

## OKR Framework

### Structure

```
OBJECTIVE: [Qualitative, ambitious, inspiring. What do we want to achieve?]

KR1: [Quantitative metric] from [current] to [target] by [date]
KR2: [Quantitative metric] from [current] to [target] by [date]
KR3: [Quantitative metric] from [current] to [target] by [date]
```

### OKR Rules

- **3-5 objectives per team per quarter.** More than that is a to-do list, not a strategy.
- **2-4 key results per objective.** Each must be measurable with a number.
- **70% achievement is success.** If you're hitting 100% on everything, your targets aren't ambitious enough.
- **OKRs are outcomes, not outputs.** "Ship feature X" is a task. "Increase activation rate from 30% to 45%" is a key result.
- **Alignment check**: Every team OKR should trace to a company OKR. If it doesn't, ask why that team is working on it.
- **Score honestly**: At the end of the quarter, score each KR 0.0-1.0. No rounding up. No credit for effort.

### Common OKR Mistakes

- **Sandbagging**: Setting easy targets to guarantee "success." This defeats the purpose.
- **Too many OKRs**: If a team has 8 objectives with 4 KRs each, they have 32 things to focus on — which means they're focused on nothing.
- **Binary KRs**: "Launch feature X" is pass/fail with no gradient. Reformulate as a metric.
- **No baseline**: "Improve NPS" means nothing without knowing current NPS. Always state the starting point.
- **Confusing committed vs. aspirational**: Some OKRs are commitments (we will do this). Others are stretch goals (we hope to do this). Label them.

## Budget Model

### Structure

Organize by department, broken into quarters:

```
                    Q1 Plan  Q1 Actual  Q2 Plan  Q3 Plan  Q4 Plan  FY Total
REVENUE
  Subscription       ---       ---       ---       ---       ---      ---
  Services           ---       ---       ---       ---       ---      ---
  Total Revenue      ---       ---       ---       ---       ---      ---

COGS
  Hosting/Infra      ---       ---       ---       ---       ---      ---
  Third-party APIs   ---       ---       ---       ---       ---      ---
  Support staff      ---       ---       ---       ---       ---      ---
  Total COGS         ---       ---       ---       ---       ---      ---

GROSS PROFIT         ---       ---       ---       ---       ---      ---
Gross Margin %       ---       ---       ---       ---       ---      ---

OPEX
  Engineering        ---       ---       ---       ---       ---      ---
  Sales              ---       ---       ---       ---       ---      ---
  Marketing          ---       ---       ---       ---       ---      ---
  G&A                ---       ---       ---       ---       ---      ---
  Total Opex         ---       ---       ---       ---       ---      ---

NET INCOME           ---       ---       ---       ---       ---      ---
CASH BALANCE         ---       ---       ---       ---       ---      ---
RUNWAY (months)      ---       ---       ---       ---       ---      ---
```

### Budget Principles

- **Bottom-up, not top-down**: Build from actual line items (headcount × cost, hosting estimates, tool costs), not percentages.
- **Headcount is the biggest lever**: For most startups, 70-80% of spend is people. Get the hiring plan right and the budget follows.
- **Separate committed vs. discretionary**: Salaries are committed. Conference sponsorships are discretionary. Know which is which so you know what to cut if needed.
- **Monthly actuals tracking**: Compare budget to actual monthly. Catch variances early.
- **Reforecast quarterly**: The annual budget is a starting point. Reforecast each quarter with updated actuals and revised assumptions.
