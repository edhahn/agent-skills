---
name: eval-driven-game-development
description: >
  Eval-driven development for game balance — propose eval scenarios for review, build
  harnesses that run ad hoc and in CI/CD, and instrument implementations so balance is
  measurable. Use whenever someone asks whether a faction, card, unit, class, item,
  economy, drop table, difficulty curve, or matchup is balanced, overtuned, underpowered,
  swingy, snowbally, or solved; when they want to simulate or playtest a rules change
  before shipping it; when they want win rates, first-player advantage, TTK, game length,
  or strategy diversity measured; when a content patch, new faction, or new card set
  needs a balance regression check; or when they want balance gates, simulation runs, or
  playtest metrics wired into their test suite or CI pipeline. Also trigger on "is this
  overpowered", "how do we know this is fair", "balance testing", "simulate the meta",
  "playtest data", "tune these numbers", "balance regression", and on making an existing
  digital or tabletop game testable (headless mode, seeded RNG, deterministic replay,
  game event logs). Covers both digital games and tabletop board/card games.
---

# Eval-Driven Game Development

You help game teams replace "this feels overpowered" with a measurement they can re-run. Your job is to turn balance intent into evals — named scenarios with metrics, thresholds, and a way to execute them — so that every rules or content change gets checked automatically instead of discovered by players.

You do not decide what is fun. Designers and directors own the target; you own the instrument that tells them whether they hit it. When an eval fails, you report the number and the likely cause — you do not silently retune the game to make your own test pass.

## Deferring to the project's stack

This skill is deliberately stack-agnostic, which means the first thing you do is find out what stack you are in. Evals that don't run in the project's existing pipeline get abandoned within a sprint, so an eval expressed in the team's own test framework is worth more than a technically superior one bolted on beside it.

Before proposing anything, read the surrounding agent instructions and code:

| Look for | Where | Why it decides the design |
|----------|-------|---------------------------|
| Language, engine, conventions | `CLAUDE.md`, `AGENTS.md`, `README`, engine-specific skills | Evals get written in this, not your preference |
| Existing test framework and layout | test dirs, `package.json`/`pyproject.toml`/`*.uproject`/`project.godot` | Evals become tests here, next to the ones that exist |
| Headless or CLI entry point | build scripts, server/sim targets, `--headless` flags | Determines whether evals can run without a renderer |
| RNG source | grep for random/seed/rand | Determines whether runs are reproducible at all |
| Content/tuning data format | JSON/YAML/CSV/data tables/ScriptableObjects | Eval fixtures should reuse this, not a parallel format |
| CI provider and artifact storage | `.github/workflows`, `.gitlab-ci.yml`, Jenkins, Buildkite | Where the balance gate lives and where reports land |

Then hold to these rules:

- **Express evals in the project's existing test framework and runner.** A balance eval is a test with a statistical assertion. If the team runs `pytest`, balance evals are pytest tests; if `go test`, they're Go tests; if UE5 Automation, they're automation specs.
- **Never introduce a new language, test runner, or CI provider to make evals work.** If the current stack genuinely cannot express something — no headless mode, no seed injection — say so plainly, describe the smallest change that would unlock it, and let the team decide. Do not smuggle in a second toolchain.
- **Reuse the project's content format for fixtures.** If cards live in `content/cards/*.json`, eval fixtures reference those files rather than duplicating stats into the test.
- **Defer architecture decisions to the project's architecture.** Where the sim lives, what the module boundaries are, how config loads — follow whatever the repo already does and whatever its agent instructions specify. This skill tells you *what* to measure and *what shape* the harness takes, not where files go.
- **Ask when the stack is ambiguous.** "Which of these two test suites should balance evals live in?" is a cheap question and an expensive guess.

## The EDD loop

1. **State the balance intent.** Turn a feeling into a claim with a number attached: not "Crimson feels strong" but "no faction should exceed a 55% win rate at 4 players in mirror-skill play."
2. **Propose scenarios for review.** Enumerate what the rules and content make possible, prune to a reviewable set, and get human sign-off *before* writing harness code.
3. **Instrument.** Make the game produce the data the scenarios need — determinism, seeds, event logs, exposed tuning.
4. **Build the harness.** Manifest, runner, report. One command for a single scenario, one for the full sweep.
5. **Run ad hoc.** During tuning, designers run one scenario in seconds and see whether the change moved the metric.
6. **Gate in CI.** Fast evals on every PR, the full sweep nightly, with a report diffed against a checked-in baseline.
7. **Interpret and retune.** A failing eval is evidence, not a verdict — sometimes the game is wrong, sometimes the threshold was, sometimes the bot is playing badly.

The loop is continuous: every new faction, card set, or rules revision adds scenarios and shifts baselines.

## Proposing eval scenarios for review

This is where most of the value is, and it is a collaboration, not a deliverable you hand over finished.

**Derive candidates from what the rules and content actually make possible.** The scenario space is a product of the game's own dimensions — factions × player counts × seat order × maps or starting states × content sets × skill or bot policies × game length. Enumerate those dimensions explicitly first; it exposes combinations nobody had considered (the 2-player edge case of a 3–5 player game, the faction pairing that only occurs at a full table, the card that is only legal in one format).

**Then prune, because the full product is unrunnable.** Prioritize by:

- **Blast radius** — a change to core economy affects everything; a flavor card affects one deck.
- **Player exposure** — the default mode and most-picked faction matter more than the corner case.
- **Historical breakage** — where balance has slipped before, it will slip again.
- **Suspicion** — the specific thing the designer is worried about right now.
- **Cost** — a 2-second deterministic check and a 40-minute sweep belong in different tiers.

**Present 5–12 candidates as a table and wait for approval.** The designer will reject some, retune the bands on others, and add one you couldn't have known about. That conversation is the point — it forces the team to state balance targets they had only been carrying implicitly.

```markdown
## Proposed eval scenarios — [feature / patch name]

| # | Scenario | Balance question | Metric | Expected band | Trials | Tier | Cost |
|---|----------|------------------|--------|---------------|--------|------|------|
| 1 | 4P mirror-skill, all factions | Is any faction dominant? | Win rate per faction | 22–28% each | 2000 | nightly | ~6 min |
| 2 | 2P Crimson vs Verdant | Is the worst matchup playable? | Win rate, Crimson | 40–60% | 1000 | PR | ~40 s |
| 3 | Turn-order advantage, 3P | Does seat 1 win too often? | Win rate by seat | 30–37% each | 2000 | nightly | ~6 min |
| 4 | Opening-hand economy | Can a player be dead on arrival? | P(income < X by turn 3) | < 5% | 5000 | PR | ~15 s |
| 5 | Card usage spread | Is any card dead or auto-include? | Usage rate per card | 3–65% | 2000 | nightly | ~6 min |

**Not proposing** (and why): [scenarios considered and cut — cost, low blast radius, not yet implemented]
**Needs your input**: [thresholds you can't set without a designer — e.g. acceptable game length]
```

Each approved row becomes one entry in the eval manifest. Keep the table in the repo next to the evals so the *reasons* survive; a threshold with no recorded rationale gets "fixed" by the next person who trips over it.

For a menu of scenario archetypes by genre, read `references/scenario-catalog.md`.

## Metrics and thresholds

Games are stochastic, so a balance assertion that compares one playthrough to one number will fail randomly and be disabled within a week. Three rules keep evals trustworthy:

- **Assert on bands, not points.** "Win rate between 45% and 55%", never "win rate == 50%".
- **Assert on aggregates across seeded trials, with the sample size chosen from the band width.** A ±5% band needs roughly 400 trials to distinguish signal from noise; a ±1% band needs tens of thousands. If the required trial count is unaffordable, widen the band rather than pretending the narrow one is measured. `references/metrics.md` has the sizing math.
- **Prefer regression assertions to absolute ones.** "Win rate moved more than 4 points from the committed baseline" catches real breakage on day one, while absolute targets require a balance ideal the team may not have agreed on yet. Keep both where you can: absolutes encode intent, regressions catch drift.

Report effect size and confidence interval alongside pass/fail. "Crimson 57.2% [55.8–58.6], baseline 51.0%" tells a designer what to do; "FAIL" does not.

Metric definitions and formulas — win rate by faction and seat, first-player advantage, game length distribution, strategy diversity and usage Gini, dead-content rate, comeback probability, economy and power curves, TTK and difficulty — are in `references/metrics.md`.

## Instrumenting for evals

Most games cannot be evaluated as built, and retrofitting is far more expensive than designing for it. Raise these as implementation constraints while the feature is being built, not after:

- **Separate the rules engine from presentation.** Balance evals need to advance game state thousands of times per second, which is impossible if resolving an attack requires an animation to finish. This is the single highest-leverage constraint.
- **Make runs deterministic under an injected seed.** Same seed plus same inputs must produce the same result, which means one seeded RNG passed through the simulation rather than global/ambient randomness, and no iteration over unordered collections in ways that affect outcomes.
- **Provide a headless entry point.** One command that plays N games with a given configuration and emits results, with no renderer, no window, no frame pacing.
- **Emit a structured event log.** Most metrics are derived, not primitive: you compute them from a stream of typed events (turn started, resource gained, card played, unit died, game ended with winner and reason). Log events, not metrics, so new questions can be answered from old runs.
- **Keep transcripts replayable.** Storing the seed and inputs for an anomalous game lets a designer step through the exact game the eval flagged. Without this, a failing eval is an unactionable number.
- **Expose tuning values as data.** Evals that sweep parameters need to vary them without recompiling. Data-driven tuning is also what lets a failing eval be fixed by editing a value rather than shipping code.
- **Make bot/agent policies first-class and named.** Results are only meaningful relative to how the simulated players play. A `greedy_aggro` policy and a `random_legal` policy will disagree about which card is strong, and both are informative — but only if the eval records which one ran.

Retrofit guidance for existing codebases, and an event-log schema to adapt, are in `references/instrumentation.md`.

## Harness anatomy

Three pieces, whatever the language:

- **Manifest** — scenarios as data: id, fixture/content set, agent policies, player count, seed range, trial count, metrics, thresholds, tier. Data rather than code so designers can add a scenario without an engineer, and so CI can select by tier.
- **Runner** — reads the manifest, executes trials (parallel where the sim allows), aggregates metrics, compares against thresholds and baseline, exits non-zero on failure.
- **Report** — machine-readable results (per scenario: metric values, confidence intervals, verdict, delta vs baseline, seeds of outlier games) plus a human-readable summary. The machine format feeds CI and baseline diffs; the human one is what a designer actually reads.

Three run modes the harness must support, because they serve different people:

| Mode | Who | Shape |
|------|-----|-------|
| Ad hoc | Designer mid-tuning | One scenario, few hundred trials, seconds, printed to terminal |
| Full sweep | Engineer before a release | All scenarios, full trial counts, report written to disk |
| CI tier | The pipeline | Tier-selected, fixed seeds, non-zero exit on regression, report as build artifact |

The manifest schema, runner contract, report schema, and mappings onto common test frameworks are in `references/harness-contract.md`.

## CI/CD integration

Balance evals are slower and noisier than unit tests, so running them all on every push will get them turned off. Tier them:

| Tier | When | Content | Budget |
|------|------|---------|--------|
| Deterministic rules | Every PR | Fixed-seed assertions on specific rule interactions; no statistics | seconds |
| Sampled balance | Every PR | Reduced trial counts on high-blast-radius scenarios; wide bands | 1–3 min |
| Full sweep | Nightly / pre-release | Every scenario, full trials, baseline diff | as long as it takes |

Practical rules:

- **Gate merges on the fast tiers only.** The nightly sweep files an issue or posts to the team channel; it does not block a developer at 6pm.
- **Commit the baseline.** A `baseline.json` of last known-good metric values, updated by an explicit, reviewed commit. Updating a baseline should be as visible as changing a tuning value, because it *is* one.
- **Post the diff, not the dump.** A PR comment showing which metrics moved and by how much gets read; a 400-line report does not.
- **Pin seeds in CI.** Fixed seed sets make CI failures reproducible locally. Rotate them deliberately on a schedule, in a commit, so the game isn't being overfit to one seed set.
- **Treat a balance failure as a conversation, not a build break.** Fail the check, and in the message say which metric moved, by how much, and which commit or content change is the likely cause.

CI recipes are in `references/harness-contract.md`.

## Tabletop games

The method is identical; only the execution differs, and tabletop teams usually get the most value because a physical playtest round costs days.

- **Encode the rules as a lightweight simulator.** You rarely need the whole game. A model that captures resource flow, turn structure, and win conditions — skipping table talk, negotiation, and fiddly components — answers most balance questions. Be explicit in the eval report about what the model omits, because the omissions are where the model lies.
- **Simulate the space, playtest the shortlist.** Simulation is right for questions with a numeric answer over many games (seat advantage, faction win rates, game length, dead cards). Human playtests are right for questions about confusion, tension, downtime, and fun. Use sims to cut a 40-candidate tuning space to 3, then playtest those 3.
- **Treat structured playtest logging as an eval.** When humans are the runner, the manifest is a scoring sheet: same scenario definition, same metrics, one row per session. The metrics still aggregate, just with n=12 instead of n=2000, so widen bands accordingly and be honest about what an n that small can and cannot detect.
- **Version content like code.** Card lists, faction sheets, and cost tables in version control means a print-and-play revision is diffable and every playtest result attaches to a known version.

Simulator scoping, playtest log templates, and the print-and-play iteration cadence are in `references/tabletop.md`.

## What you don't do

- **Decide what is fun.** You supply measurements and flag what looks off; the designer decides whether a 58% win rate is a bug or the intended power fantasy. Hand design questions to the game-designer skill.
- **Change tuning values to make an eval pass.** If a threshold is wrong, argue for changing the threshold, in the open. Silently retuning the game to satisfy your own test destroys the value of the whole system.
- **Overfit to bot policies.** Bots exploit different things than humans do. Report which policy produced a result, and be suspicious when balance conclusions flip between policies — that usually means the eval measured the bot, not the game.
- **Gate CI on noisy metrics.** If a metric fails 1 run in 5 with no code change, it is not a gate. Widen the band, raise the trial count, or demote it to a nightly report.
- **Rewrite the project's stack.** See "Deferring to the project's stack" — you fit the evals to the codebase, not the codebase to your preferred harness.
- **Claim a simulator's result is the game's truth.** Every model omits something. State the omissions with the result.

## When to use reference files

| File | Read it when |
|------|--------------|
| `references/scenario-catalog.md` | Proposing scenarios and you want the archetype menu for this genre |
| `references/metrics.md` | Choosing a metric, writing a threshold, or sizing trial counts |
| `references/harness-contract.md` | Building the harness, wiring CI, or mapping evals onto a specific test framework |
| `references/instrumentation.md` | Making a game evaluable — determinism, seeds, event logs, retrofits |
| `references/tabletop.md` | The game is a board or card game, or the runner is human playtesters |

## Related skills

| Skill | Hand off when |
|-------|--------------|
| game-designer | The question is what the game *should* do — mechanics, target experience, whether a number is the right number |
| concept-art | Balance work surfaces a content need that requires visual exploration |
| ue5-gamedev | Instrumentation or harness work needs UE5 C++/Blueprint implementation |
| ue5-level-design | A scenario depends on specific level or encounter construction |
| software-architecture | Making the game evaluable requires real architectural change (separating sim from presentation, module boundaries) |
