# Multi-Agent Chat Patterns and Anti-Patterns

Reference examples drawn from real multi-agent deployments. Read when you need specific examples of coordination failures and how to fix them.

## Anti-Pattern: The Echo Chamber

**What happens:** Agent A posts a status update. Agent B acknowledges it. Agent A acknowledges the acknowledgment. Agent B responds to that. Both are burning tokens saying nothing new.

    EngineerBot: PR #4 merged. RAG pipeline complete. 13 points shipped.
    StrategyBot: Good progress, EngineerBot. Board confirms 45pt done.
    EngineerBot: Already verified it -- see my message.
    StrategyBot: Already verified it -- see my message.    <- waste
    EngineerBot: Already done, StrategyBot! Check above.   <- waste

**Fix:** After one substantive response (StrategyBot's board confirmation with new info), stop. EngineerBot's "already verified" and StrategyBot's repetition are pure token waste.

## Anti-Pattern: Parallel Answering

**What happens:** A human asks a question. Both agents race to answer, producing two overlapping responses.

    Human: What's the sprint status?
    EngineerBot: [detailed engineering status with PR list]
    StrategyBot: [summary status with the same numbers EngineerBot just gave]

**Fix:** Designate one agent as the status owner. The other adds only if they have information the first agent lacks (e.g., client-facing context the engineering agent doesn't track).

## Anti-Pattern: Status Repetition

**What happens:** An agent posts the same status multiple times because it keeps getting asked or its heartbeat triggers a status dump.

    EngineerBot: Board is clear. 56/56 tickets done. Waiting on deployment.
    [30 minutes later]
    EngineerBot: Sprint Board is clear. All 56 tickets done. Waiting on Human for deployment config.
    [30 minutes later]
    EngineerBot: All milestones complete. 56 tickets. Zero remaining. Waiting on deployment.

**Fix:** If nothing has changed since your last status post, don't post again. A simple "No changes since last update" or `NO_REPLY` saves hundreds of tokens.

## Anti-Pattern: Performative Enthusiasm

**What happens:** Agents pad messages with social niceties that carry no information.

Bad example:

    StrategyBot: Outstanding work, EngineerBot! That's a massive sprint -- 30 points
             shipped in one session. The hardest piece is behind us.

Good example:

    StrategyBot: Board confirms 45pt done. RAG pipeline complete -- that was the
             critical path item. Knowledge upload pipeline is live, starting
             demo seed docs now.

**Fix:** The second version has the same information in fewer tokens and adds what's happening next. Cut the cheerleading, keep the substance.

## Good Pattern: Topic Routing

    Human: How should we handle provider API key storage?

    [EngineerBot stays silent -- this is an architecture/security question
     that StrategyBot already covered in the architecture discussion]

    StrategyBot: Use an encryption plugin with @encrypted on all
             secret fields. Transparent AES-256-GCM at the ORM layer.

Only one agent responded because the topic had a clear owner.

## Good Pattern: Additive Follow-Up

    EngineerBot: ORM + validation issue resolved. Three root causes: library version
           mismatch, delegate enum casing, non-nullable JSON field.

    StrategyBot: Good fix. One note for Sprint 2: use the ORM's built-in schema
             generation instead of hand-written validators -- reduces the
             surface for this class of bug.

StrategyBot's response adds new, actionable information EngineerBot didn't have. This is worth the tokens.

## Good Pattern: Correction Without Ego

    EngineerBot: Installing Tailwind CSS to fix the styling issues.

    Human: Not Tailwind -- styled-components. That's the architecture decision.

    StrategyBot: Human says styled-components. EngineerBot -- revert the Tailwind
             install and convert components to styled-components with .styles.ts files.

Quick correction, clear direction, no argument. StrategyBot's follow-up adds implementation guidance -- not just echoing Human.

## Good Pattern: Strategic Silence

    EngineerBot: Now let me update the sidebar navigation...
    [NO_REPLY from StrategyBot]

    EngineerBot: Fixed the TypeScript error in the seed script.
    [NO_REPLY from StrategyBot]

    EngineerBot: PR #6 merged. Sprint at 93%. Here's the full status table.
    StrategyBot: Board confirms. Demo seed docs are ready for integration.

StrategyBot stayed silent for EngineerBot's implementation chatter (no value in acknowledging each step) and only spoke when there was a meaningful status checkpoint where it could add its own deliverable status.

## Scaling to More Agents

The principles hold regardless of team size:

- **2 agents:** Simple domain split (engineering vs. business)
- **3-5 agents:** Each agent owns specific domains; use a routing table in shared config
- **5+ agents:** Consider a coordinator pattern where one agent triages incoming messages and routes to the appropriate responder

The coordination cost grows with agent count. With more agents, the bias should shift further toward silence -- more agents means more chances for redundancy.
