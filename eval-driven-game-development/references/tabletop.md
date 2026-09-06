# Tabletop Evals (Board and Card Games)

Eval-driven development for physical games. The method is identical to digital — scenarios, metrics, thresholds, baselines — but the runner is either a lightweight simulator you write from the rulebook, or a room full of humans with a scoring sheet.

Tabletop teams often get the most out of EDD, because the alternative iteration loop (print, schedule, teach, play, discuss) costs days per data point.

## Contents

- [What to simulate and what not to](#what-to-simulate-and-what-not-to)
- [Building a rules model from a rulebook](#building-a-rules-model-from-a-rulebook)
- [Stating the model's omissions](#stating-the-models-omissions)
- [Tabletop-specific metrics](#tabletop-specific-metrics)
- [Structured playtest logging](#structured-playtest-logging)
- [The hybrid loop](#the-hybrid-loop)
- [Versioning physical content](#versioning-physical-content)
- [Component and production evals](#component-and-production-evals)
- [Blind playtesting and the rulebook](#blind-playtesting-and-the-rulebook)

## What to simulate and what not to

Simulation answers questions with a numeric answer over many games. Human play answers questions about experience. Sorting a question into the right bucket is most of the skill.

| Simulate | Playtest |
|----------|----------|
| Seat / turn-order advantage | Is it fun |
| Faction and strategy win rates | Is the rulebook clear |
| Game length in turns | Is downtime tolerable |
| Dead or auto-include cards | Does tension build |
| Economy and score curves | Do negotiations work |
| Scoring-track calibration | Does the theme land |
| Component quantities needed | Are the icons readable |
| Whether a rule is ever invoked | Does the table talk |
| Runaway-leader / kingmaking rates | Whether players *notice* runaway leaders |

Note the last row: simulation tells you a leader wins 84% of the time from turn 6; only humans tell you whether that feels hopeless or exciting. Both are real findings, and the pair is more useful than either alone.

**Games that resist simulation**: heavy negotiation, bluffing and hidden-information reads, social deduction, dexterity, and anything where the interesting decisions are about *people*. For these, simulate the substrate (does the economy work, is the scoring calibrated, does the game end at the right time) and playtest everything above it.

## Building a rules model from a rulebook

The goal is the smallest model that answers the approved scenarios — not a digital implementation of the game.

1. **Extract the state.** What must be tracked: resources per player, board or tableau contents, deck/discard, turn and phase, score. Write it down as a data structure first; it usually reveals ambiguities in the rules immediately.
2. **Enumerate legal actions** per state. This is the step where rulebooks turn out to be incomplete — the questions it raises are worth surfacing to the designer regardless of the eval work.
3. **Implement resolution and end conditions.** Turn structure, action effects, scoring, and every way the game ends.
4. **Write the simplest policies** that play legally: `random_legal` first, then a greedy heuristic reflecting how a new player actually plays. Do not build a strong AI before you have any results.
5. **Validate against reality.** Run games and check the outputs against known human playtests: is the median score in the right range, does the game last the right number of turns, do the same strategies look strong? A model that disagrees with observed play is wrong until proven otherwise, and finding out *why* usually teaches you something about the game.
6. **Then add scenarios.**

Keep the model in the same repo as the rules and content files. It's a design artifact, not a throwaway script, and it will be edited every time a rule changes.

**Scope discipline**: skip components that don't affect the measured outcome. If the question is faction win rate, a rough model of the trading phase is usually fine — but say so, because that simplification is exactly where a wrong answer would come from.

## Stating the model's omissions

Every simulator lies somewhere. Report where, alongside every result, so a designer can judge how much to trust a number.

```markdown
**Model coverage** (v0.4, rules v1.7)
Modelled: turn order, resource economy, card play, combat resolution, scoring.
Simplified: trading (bots accept any trade with positive immediate EV); the reputation
  track is modelled as a linear bonus rather than the tiered effect in the rules.
Not modelled: table talk, alliance formation, the endgame bidding round.
Implication: seat-advantage and economy findings should hold. Faction win rates for
  Merchant are least trustworthy, since Merchant's strength routes through trading.
```

This paragraph is what separates a credible sim result from a number a designer is right to ignore. It also tends to focus the next round of modelling work on the thing that matters.

## Tabletop-specific metrics

Beyond the general catalogue in `metrics.md`:

| Metric | Definition | Why it matters |
|--------|-----------|----------------|
| Seat win rate | Win rate by turn-order position, per player count | The most common tabletop balance failure, and the easiest to miss in live playtests where seating is arbitrary |
| Player-count parity | Win-rate spread, game length, and score margin at each supported count | "2–5 players" on the box is a promise the game rarely keeps at both ends without testing |
| Winning margin | Distribution of the gap between 1st and 2nd | Blowouts read as unfair; ties every game reads as arbitrary |
| Score compression | Spread between last and first | Calibrates the scoring track's printed length |
| Kingmaking rate | Frequency with which a non-contending player's choice determines the winner | A structural flaw simulation catches cheaply |
| Time-to-decided | Turn after which the winner is effectively fixed | The gap to game end is the part players describe as "dragging" |
| Downtime | Median gap between one player's consecutive decisions | Grows superlinearly with player count; the top complaint in heavy games |
| Rules-invocation rate | Fraction of games in which each rules clause is used | Never-invoked rules are rulebook length you can delete |
| Component peak demand | Max simultaneous need per component across trials | Directly sets how many cubes go in the box |
| Setup-variance impact | Correlation of a setup-quality heuristic with the winner | Tells you whether setup needs balancing or a draft |

The last three are unique to physical games and pay for themselves in production: component counts affect unit cost, and rulebook length affects both printing and how many people finish reading it.

## Structured playtest logging

When humans are the runner, the eval manifest becomes a scoring sheet. Same scenario definition, same metrics, far fewer trials.

```markdown
# Playtest log — [game] v1.7 — session [id]

Date / group / experience level (new, played once, veteran)
Content version: rules v1.7, card set 2026-02-11
Players and seats: 1 [name/faction], 2 [...], 3 [...], 4 [...]

## Outcome
Winner (seat, faction) | Final scores by seat | Total minutes | Turns played

## Metrics
Median turn length | Longest single turn | Rules lookups (count + which rules)
Turn on which the winner became obvious (each player's private guess, collected at end)

## Observations
Rules confusion (what, when, whose)
Perceived downtime (1-5, per player)
Moments of tension or excitement (turn + what happened)
Anything a player did that the rules didn't cover

## Player quotes
Verbatim. The exact wording of a complaint is usually more useful than your summary.
```

Making it work:

- **Collect the same fields every session.** The value is comparability across versions; a free-form recap is not aggregatable.
- **Fix what's being tested per session.** Changing three things between sessions means learning nothing from n=1.
- **Be honest about n.** Twelve sessions can detect a 30-point win-rate skew and cannot detect a 5-point one. Report it as "no strong signal at n=12" rather than a precise-looking rate.
- **Log the version.** Results not attached to a content version are unusable within two revisions.
- **Ask for the private "who's winning" guess mid-game.** It measures perceived runaway leader, which is what actually affects the experience, and no simulation can produce it.
- **Keep sheets in the repo** next to the rules and content, so a design change can be traced to the sessions that motivated it.

## The hybrid loop

The pattern that gets the most out of both runners:

1. **Simulate broadly** to cut a large tuning space — 40 candidate cost tables become the 3 that keep faction win rates in band.
2. **Playtest the shortlist** with humans, testing the questions simulation can't reach.
3. **Feed playtest findings back as new scenarios.** When testers say "the leader always runs away," that becomes a `P(win | leading at turn 6)` scenario, and it will be checked automatically on every revision from then on.
4. **Re-simulate after every rules change** to catch what the change broke elsewhere — this is the regression tier, and it's where the harness earns its keep over a project's life.
5. **Blind playtest** near the end, where the eval question is the rulebook itself.

Each loop should end with the simulator updated to match the current rules. A model that has drifted from the rules produces worse-than-useless numbers, because they still look authoritative.

## Versioning physical content

- Keep card lists, faction sheets, cost tables, and the rulebook in version control, in a diffable format (CSV, YAML, JSON, Markdown).
- **Generate print-and-play files from that data**, so the physical prototype can never disagree with what the simulator read.
- Tag each playtest build with a version, and put that version on the physical components — a card with no version on it will end up in a playtest of a different revision, and it will corrupt the results silently.
- Stamp the content version into every simulation report and every playtest log.

## Component and production evals

Cheap simulations with direct manufacturing consequences:

- **Peak component demand** across thousands of trials → how many of each token to produce. Simulation gives you the p99, not the anecdote from one playtest.
- **Score-track length** → the p99 final score sets the printed track length.
- **Card-count sufficiency** → how often does a deck run out, and does the reshuffle rule then matter?
- **Table footprint** → maximum simultaneous board area, which determines box and board size.
- **Setup and teardown time** — measured in playtests, not simulated, but tracked in the same log; it is a real determinant of how often a game gets played.

These are worth running before art and manufacturing lock, because after that a shortage of one component type is an expensive problem.

## Blind playtesting and the rulebook

Once the numbers are in band, the remaining eval question is whether a group can learn the game from the box alone.

- Hand over components and rulebook, no teaching, no answering questions.
- **Metrics**: minutes to first turn, rules looked up (and which), rules played *wrong* (and which — the most valuable output), completion rate, and post-game comprehension questions.
- Treat every misplayed rule as a defect in the rulebook, not in the players. The rules-invocation data from simulation pairs with this directly: a clause that is rarely invoked *and* frequently misread is a strong candidate for deletion rather than rewriting.
