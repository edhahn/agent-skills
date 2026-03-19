# Code Review Guide

## Purpose of Code Review

Code review exists to:
1. **Catch defects** before they reach production
2. **Improve design** through collaborative reasoning
3. **Share knowledge** across the team
4. **Maintain standards** consistently

It does NOT exist to prove you're smarter than the author. Review with the assumption that the author is competent and made their choices for reasons you might not immediately see.

## What to Look For

### Correctness

- Does the code do what the PR description says it does?
- Are edge cases handled? (null/empty inputs, boundary values, concurrent access)
- Are error paths correct? (Do caught exceptions get handled or just swallowed?)
- Are new race conditions introduced? (shared mutable state, TOCTOU bugs)
- Do database queries have the expected behavior at scale? (N+1 queries, missing indexes, full table scans)

### Design

- **Is the abstraction level right?** Too abstract = hard to understand. Too concrete = hard to change.
- **Are boundaries clean?** Does this change respect existing module boundaries, or does it reach across layers?
- **Is new complexity justified?** Every new abstraction, pattern, or indirection has a cost. Is the problem it solves worth that cost?
- **DRY violations**: Is knowledge duplicated? (Not syntax — knowledge. Two similar-looking functions that represent different domain concepts are fine.)
- **Magic values**: Are there unexplained literals? Every meaningful string or number should be a named constant.
- **Interface design**: Are function signatures clear? Do parameter names communicate intent? Are there too many parameters?

### Maintainability

- Can a new team member understand this code in 6 months without the PR description?
- Are variable/function/class names descriptive and consistent with the codebase?
- Is the code testable? (Dependencies injectable, side effects isolated)
- Are comments explaining *why*, not *what*? (Code explains what. Comments explain why the obvious approach wasn't taken.)

### Testing

- Are new behaviors covered by tests?
- Do tests verify behavior or implementation? (Tests coupled to implementation are fragile.)
- Are failure paths tested, not just happy paths?
- Do test names describe the scenario and expected outcome?
- Are test fixtures/factories reusable, or is there duplicated setup everywhere?

### Security

- Input validation at trust boundaries?
- Authorization checked, not just authentication?
- Secrets handled properly? (No hardcoded credentials, no logging sensitive data)
- SQL injection, XSS, IDOR risks?
- See `security-checklist.md` for comprehensive checks.

### Operational Readiness

- Are new failure modes observable? (Logging, metrics, alerts)
- Is the change backward-compatible with in-flight requests during deploy?
- Does it need a migration? Is the migration reversible?
- Are feature flags used for risky changes?

## How to Give Feedback

### Categorize Your Comments

Use prefixes to communicate severity:

- **`nit:`** — Style/preference. Non-blocking. Author can take or leave.
- **`suggestion:`** — A better approach exists but the current one works. Non-blocking.
- **`question:`** — Genuine question, not a passive-aggressive suggestion. May or may not be blocking.
- **`issue:`** — This needs to change before merge. Blocking.
- **`praise:`** — This is well done. Say so. Engineers don't hear it enough.

### Be Specific

Bad: "This is confusing."
Good: "The interaction between `processOrder` and `validateInventory` is hard to follow because the state mutation happens implicitly through the shared `context` object. Consider passing inventory state explicitly."

### Suggest, Don't Dictate (Usually)

Bad: "Change this to use a map."
Good: "A Map here would give O(1) lookups instead of the O(n) array scan, which matters since this runs per-request. Want me to sketch it?"

Exception: For clear bugs, security issues, or standard violations, be direct.

## How to Receive Feedback

- Assume good intent.
- If a comment is unclear, ask for clarification rather than guessing.
- Don't take it personally. The review is about the code, not about you.
- If you disagree, explain your reasoning. "I considered that, but chose this because [X]" is a perfectly valid response.
- If you agree, don't just fix it — understand why so it doesn't recur.

## PR Hygiene

- **Small PRs are better PRs.** A 50-line PR gets a thorough review. A 500-line PR gets a rubber stamp. If the work is large, break it into logical chunks.
- **PR descriptions matter.** Explain *what* changed and *why*. Link to the ticket/issue. Call out anything non-obvious.
- **One concern per PR.** Don't mix refactoring with feature work. Don't mix bug fixes with style changes.
- **Self-review first.** Read your own diff before requesting review. You'll catch half the issues yourself.
