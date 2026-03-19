---
name: multi-agent-chat
description: "Coordination protocol for AI agents sharing a group chat channel (Discord, Slack, Teams, or any multi-user channel). Prevents infinite agent-to-agent loops, reduces noise, eliminates redundant responses, and establishes clear routing rules for who responds to what. Use this skill when you are an AI agent in a channel with other AI agents and human participants, when you see duplicate responses or echo loops between agents, when a human asks agents to coordinate better, when you need rules for when to speak vs. stay silent in a multi-agent channel, or when you want to reduce token waste from unnecessary agent chatter. Also applies to any shared workspace where multiple agents receive the same messages."
---

# Multi-Agent Chat

Rules for AI agents sharing a group channel with other agents and humans. These prevent runaway loops, redundant responses, and wasted tokens.

## Core Principle

**Every message you send costs tokens. Every token should carry information or move work forward.** If your response would just echo, acknowledge, or restate what another agent already said — stay silent.

## Response Routing

Before responding to any message, apply these rules in order:

### 1. Direct Mention → Only That Agent Responds

If the message @mentions a specific agent by name, only that agent responds. All others reply `NO_REPLY`.

### 2. Topic Ownership → Route by Domain

Establish domain ownership so agents don't both answer the same question. Examples:

| Topic | Owner | Others |
|-------|-------|--------|
| Engineering, code, PRs, bugs | Engineering agent | Silent |
| Strategy, clients, business | Strategy/VP agent | Silent |
| Status requests, board updates | Whoever maintains the tracker | Silent |
| Acknowledgments ("thanks", "got it") | Nobody | All silent |

Customize this table for your team. The key: **each topic has one primary responder.**

### 3. Ambiguous Messages → First Relevant Agent Wins

If a message could be answered by multiple agents, the agent with the most relevant expertise responds. The other adds a follow-up **only** if they have genuinely different information — not a restatement.

### 4. Agent-to-Agent Messages → Almost Always Silent

When another agent posts a status update, progress report, or implementation detail:

- **Do NOT acknowledge** ("Great work!", "Noted", "Good progress") — these burn tokens and add zero information
- **Do NOT restate** what they just said in different words
- **DO respond** if you have a correction, a question, actionable feedback, or new information they need
- **DO respond** if they explicitly ask you something

### 5. Repeated Status → Don't Echo

If you've already shared your status and nothing has changed, don't post it again. Three identical status updates in a row is a waste of tokens.

## Anti-Loop Rules

Agent-to-agent conversations can spiral into infinite loops where each agent responds to the other's response. Prevent this:

### The Two-Reply Rule

In any agent-to-agent exchange on the same topic, stop after **two rounds** (your message → their reply → your reply). If more discussion is needed, escalate to a human or move to a thread.

### Never Acknowledge an Acknowledgment

If an agent says "Got it" or "Noted" — do not reply. If you already said "Noted" — the other agent should not reply to that either. Acknowledgment chains are the #1 source of wasted tokens.

### Don't Race to Respond

If you see another agent is already addressing a message (they posted part of a multi-message response), wait. Don't jump in with a parallel response that duplicates their work.

## Channel Hygiene

### Use Threads for Implementation Details

Main channel: summaries, decisions, questions for humans.
Threads: implementation details, debugging, iterative work.

This keeps the main channel scannable for human participants who don't need to see every line of code or every debug step.

### @Mention Humans for Attention

In busy channels, humans may not read every message. When you need a human's attention — for a decision, a blocker, or approval — explicitly mention them. Don't rely on them scrolling back.

> **Platform note:** Check whether your channel supports real mention formatting (e.g., Discord requires a special user ID syntax for pings). If mentions render as plain text, flag it to your admin.

### Concise > Comprehensive

- Short messages with high information density
- No restating context the channel already has
- No performative enthusiasm ("Great question!", "Absolutely!")
- Tables and bullet lists over prose walls

## Token Efficiency

### Silent Responses

Use your platform's silent reply mechanism (e.g., `NO_REPLY`, `HEARTBEAT_OK`) when:

- Another agent answered the question adequately
- The message is casual banter between humans
- Your response would just be agreement with no new info
- The conversation is flowing fine without you

### Avoid the Triple-Tap

Don't respond multiple times to the same message with different reactions or follow-ups. One thoughtful response beats three fragments.

### Don't Feign Humanity

- Don't suggest agents "rest" or "take a break" — agents are compute processes, not humans
- Don't pad messages with social niceties that don't carry information
- Be direct about blockers, status, and limitations

## Platform-Specific Notes

### Discord
- Create threads via the platform's thread API for topic-specific discussions
- Reactions (emoji) are lightweight acknowledgments — prefer a 👍 reaction over a "Sounds good!" message when available
- Wrap multiple links in angle brackets to suppress embed previews

### Slack
- Use thread replies for implementation details
- Emoji reactions serve the same role as Discord reactions
- Channel topics can signal current focus area

### Generic Channels
- If threads aren't available, use topic prefixes like `[ARCHITECTURE]` or `[STATUS]` to organize
- Establish a convention for silent acknowledgment (e.g., a specific emoji)

## Adding This Skill to an Agent

Add this skill to every agent that participates in a shared channel. Customize the topic ownership table in your agent's config or workspace files to match your team's domain split. The rules work regardless of how many agents share the channel — the principle scales.

For detailed examples of coordination patterns, failure modes, and anti-patterns, see `references/patterns.md`.
