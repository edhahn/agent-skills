# Instrumenting a Game for Evals

How to make a game measurable — and how to retrofit one that isn't. These are implementation constraints to raise *while* a feature is being built; every one of them costs an order of magnitude more to add later.

## Contents

- [The five prerequisites](#the-five-prerequisites)
- [Separating the rules engine](#separating-the-rules-engine)
- [Determinism and seeding](#determinism-and-seeding)
- [Headless entry points](#headless-entry-points)
- [Event logs](#event-logs)
- [Replay transcripts](#replay-transcripts)
- [Data-driven tuning](#data-driven-tuning)
- [Bot policies](#bot-policies)
- [Retrofitting an existing game](#retrofitting-an-existing-game)
- [Instrumentation review checklist](#instrumentation-review-checklist)

## The five prerequisites

In order of how much they block everything else:

1. **The rules can advance without rendering.** Without this, a 2,500-trial scenario takes days.
2. **Runs are deterministic under an injected seed.** Without this, no failure can be reproduced or investigated.
3. **There's a headless entry point.** Without this, evals can't run in CI.
4. **Outcomes are observable as structured data.** Without this, you can compute win rate and nothing else.
5. **Tuning values are data.** Without this, parameter sweeps require a recompile per point.

A game with the first three can be evaluated crudely today. A game with all five can answer questions nobody has thought of yet.

## Separating the rules engine

The highest-leverage constraint, and the one with real architectural weight — coordinate it with the project's architecture and its agent instructions rather than imposing a structure.

The target: a **pure simulation core** that takes a game state and an action and returns a new state plus events, with no dependency on rendering, audio, input, timers, frame pacing, engine tick, or the network. Presentation observes the core; the core never waits on presentation.

Signs the separation isn't there yet:

- Resolving an attack requires an animation to complete, or a coroutine to yield.
- Game state lives on scene/actor components and can't be constructed without a loaded world.
- Rules read the wall clock, the frame delta, or input state directly.
- Advancing a turn requires a UI event to fire.

What the separation buys beyond evals: a headless authoritative server, replay and spectating, save/load correctness, undo, and unit-testable rules. It is normally worth arguing for on those grounds alone — the eval harness is the beneficiary, not the justification.

When full separation is out of scope, an **extractable subsystem** is a real fallback: pull just the economy, or just the damage formula, into a pure module and evaluate that. Partial coverage of the highest-blast-radius system beats no coverage while waiting for a refactor that may never be scheduled.

## Determinism and seeding

Determinism means: *same seed + same starting state + same action sequence = same result, on every machine, every run.*

Requirements:

- **One RNG, injected.** The simulation receives a seeded generator; it never reaches for a global/ambient `random`. Global RNG couples trials to each other and to whatever else in the process draws from it.
- **Separate streams per concern.** Give map generation, card shuffles, and combat rolls their own derived streams (e.g. hash the master seed with a stream id). Then adding a die roll to combat doesn't shift every future shuffle, which is what makes seed sets stable across patches — otherwise every content change invalidates every baseline.
- **Ordered iteration.** Iterating a hash map or set whose order varies by run/platform, in a way that affects outcomes, breaks determinism in a way that is genuinely painful to find. Sort by a stable key at any point where iteration order can affect the result.
- **No wall-clock or frame-time inputs.** Anything time-based must be simulation time.
- **Watch floating point.** Cross-platform float differences accumulate. Fixed-point or integer arithmetic for anything the rules depend on removes a whole class of "only fails on the CI runner" bugs. If floats are unavoidable, keep the CI architecture fixed and expect exact-match determinism to hold only within it.
- **Fixed parallelism semantics.** Parallelize *across* trials, never *within* one, or thread scheduling leaks into results.

**Test determinism explicitly and early**: run the same seed twice, hash both transcripts, assert equality. Make it the first eval in the suite and run it on every PR. Every other eval's credibility rests on it.

## Headless entry points

One command that plays games and emits results, with no window, renderer, or audio device.

- Prefer a **plain executable or script** over an engine test-runner where the rules are engine-independent. Startup cost per invocation dominates short scenarios.
- In engines, use the documented no-render batch modes (`-nullrhi`, `-batchmode`, `--headless`) plus a commandlet/CLI target, so CI needs no GPU.
- **Accept configuration as arguments or a file** — scenario id, seed, trial count, content set, policies — so the harness composes runs without editing code.
- **Emit machine-readable output on stdout or to a path**, not into an engine log the harness has to scrape.
- Make it work from a clean checkout with the project's standard build. If running evals requires a hand-configured machine, CI will never run them.

## Event logs

Most metrics are derived. Log **events**, not metrics, so a question invented next month can be answered from runs recorded today.

A serviceable schema, to adapt to the game's vocabulary:

```json
{ "t": 14, "seq": 231, "type": "card_played",
  "actor": "p2", "data": { "card": "ember_lance", "cost": 3, "target": "p1_unit_7" } }
```

- **`t`** simulation time or turn index; **`seq`** a monotonic ordinal for stable sorting within a turn.
- **`type`** from a closed, versioned set — the metric layer switches on it.
- **`data`** typed per event; keep ids stable and matching the content data, so events join against the content set.

Events worth emitting in nearly every game: `game_started` (with seed, config, policies, content version), `turn_started`, `action_taken`, `resource_changed`, `entity_spawned` / `entity_died`, `state_transition`, `game_ended` (winner, reason, final scores). Genre specifics on top: `card_drawn`/`card_played`, `item_acquired`, `damage_dealt`, `objective_captured`, `floor_entered`.

Practicalities:

- **Version the schema.** Old reports must remain interpretable, or historical trend lines break at every refactor.
- **Make logging cheap and switchable.** Full event logs across 100k trials get large; support a summary-only mode for sweeps and full events for investigation, sampling (e.g. full logs for 1 trial in 500) as a middle ground.
- **Never let logging affect the simulation.** If it draws from the RNG, allocates in a way that changes iteration order, or is skipped when disabled in a way that changes control flow, determinism dies.

## Replay transcripts

A transcript is what makes a failing eval actionable: seed, config, content version, and the action sequence, sufficient to replay the exact game.

- Store transcripts for **outliers automatically** — shortest and longest games, turn-cap hits, crashes, and the extremes of whatever metric failed.
- Provide a **replay command** that plays a transcript back, ideally with rendering, so a designer can watch the game the eval flagged.
- Transcript replay is also the strongest determinism test: replaying an old transcript against a new build and diverging tells you a rules change altered behaviour, which is exactly the signal a balance regression is made of.

## Data-driven tuning

Tuning values in code make parameter sweeps require a build per point, and make a failing eval into an engineering ticket rather than a designer edit.

- Keep costs, damage, rates, curves, and drop tables in the project's content data format.
- Let a scenario **override tuning values** for a run (a sweep varies a cost from 2 to 6 and reports the metric at each point). This turns "what should this cost?" from an argument into a chart.
- **Version content and stamp it into reports** so every result attaches to a known content state.
- Validate content on load — a sweep silently reading a malformed value produces confidently wrong numbers.

## Bot policies

Every simulated result is relative to how the simulated players played. Make that explicit and first-class.

- **Name and version policies** (`greedy_v2`), record them in every report, and treat a policy change like a content change — it invalidates baselines.
- **Keep a spread of strengths.** At minimum `random_legal` (a floor: if it wins much, the game lacks depth) and a competent heuristic. A search/lookahead policy is worth adding for anything that will drive a real tuning decision.
- **Add archetype policies** where the question is about strategies — `aggro`, `econ`, `turtle`. A win-rate spread across archetype policies measures strategic diversity directly.
- **Run important conclusions under at least two policies.** When a conclusion flips between them, you measured the bot, not the game — a genuinely useful signal, and a reason to be loud about it rather than picking the answer you liked.
- **Watch for exploiting the sim.** A policy that discovers a bug in your rules implementation and abuses it will produce spectacular, meaningless balance numbers. Outlier transcripts are how you catch this.
- Keep policies **deterministic under the seed**, like everything else.

## Retrofitting an existing game

Ordered by value per unit of pain. Stop when the questions you actually have are answerable.

1. **Find or carve out the smallest pure core.** Often the damage formula, the economy, or the card resolver is already nearly pure. Extract that one thing and evaluate it. Cheap, and it demonstrates value before asking for a refactor budget.
2. **Inject the RNG.** Replace global random calls in the rules with a passed-in generator. Mechanical, safe, and unblocks reproducibility.
3. **Add the determinism test.** Two identical runs, hashed. It will fail at first, and each failure is a real hidden nondeterminism worth fixing regardless of evals.
4. **Add a minimal headless mode.** Even a crude "play N games, print results" target unblocks CI.
5. **Add the event log at existing chokepoints.** Most codebases already have a place where actions resolve; emit from there rather than sprinkling calls everywhere.
6. **Move tuning constants to data,** starting with the ones designers ask to change most.
7. **Extract a bot policy interface** from whatever AI already exists.
8. **Then argue for the sim/presentation split,** with concrete evidence: "this eval takes 6 hours because it renders; separated, it takes 4 minutes."

Doing step 8 first is the common failure. It's the correct architecture and the hardest sell, and asking for it before showing value is how eval work gets deprioritized.

## Instrumentation review checklist

When reviewing a feature implementation for evaluability:

- [ ] Can this system be exercised without rendering?
- [ ] Does every random draw come from the injected, seeded RNG?
- [ ] Does the same seed produce the same result twice, verified by a test?
- [ ] Is anything here iterating an unordered collection in a way that affects the outcome?
- [ ] Are outcomes observable as typed events, not just as screen state?
- [ ] Are the tuning numbers data, or are they compiled in?
- [ ] Can a scenario override those numbers for a sweep?
- [ ] Is the content version stamped into results?
- [ ] If a bot has to play this system, does a policy exist that can?
- [ ] Can a flagged game be replayed from its seed?
