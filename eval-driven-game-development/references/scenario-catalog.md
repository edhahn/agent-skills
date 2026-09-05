# Scenario Catalog

A menu of eval scenario archetypes to draw proposals from. These are starting points, not a checklist — pick the ones that match the game's actual dimensions and the designer's actual worry, then adapt the metric and band.

## Contents

- [How to use this catalog](#how-to-use-this-catalog)
- [Universal scenarios](#universal-scenarios-almost-every-game)
- [Asymmetric / faction games](#asymmetric--faction-games)
- [Card games and deckbuilders](#card-games-and-deckbuilders)
- [Roguelikes and run-based games](#roguelikes-and-run-based-games)
- [Autobattlers and team-composition games](#autobattlers-and-team-composition-games)
- [4X and strategy](#4x-and-strategy)
- [RPG and combat systems](#rpg-and-combat-systems)
- [PvP and matchmaking](#pvp-and-matchmaking)
- [Economy and progression](#economy-and-progression)
- [Board games](#board-games)
- [Rule-interaction scenarios (deterministic)](#rule-interaction-scenarios-deterministic)

## How to use this catalog

Each entry gives the **balance question**, the **metric** that answers it, a **threshold shape** (not a number — the number is the designer's call), and rough **cost**. Cost assumes a headless sim; multiply generously if the game must render.

Before picking, enumerate the game's dimensions — factions, player counts, seats, maps, content sets, bot policies, formats — because the interesting scenarios are usually specific *combinations*, not whole categories.

## Universal scenarios (almost every game)

| Scenario | Balance question | Metric | Threshold shape | Cost |
|----------|------------------|--------|-----------------|------|
| Baseline drift | Did this change move anything it shouldn't have? | Every headline metric vs committed baseline | Delta within ±X of baseline | full sweep |
| Game length | Do games run to the intended length? | Turn/minute distribution: median, p10, p90 | Median in band; p90 under a hard ceiling | medium |
| Degenerate states | Can the game fail to end, or end instantly? | Rate of games hitting turn cap; rate ending before turn N | Both near zero | medium |
| Decision impact | Do player choices matter? | Win rate of `random_legal` vs `greedy` policy | Skilled policy must beat random by a clear margin | medium |
| Determinism | Is the sim reproducible? | Same seed twice → identical transcript hash | Exact match | seconds |

The last two are worth building first. A determinism check protects every other eval, and a random-vs-skilled comparison is the cheapest test of whether a game has any strategic depth at all — if random play wins 45% of the time against your best bot, no other balance number means much.

## Asymmetric / faction games

| Scenario | Balance question | Metric | Threshold shape |
|----------|------------------|--------|-----------------|
| Global faction spread | Is any faction dominant or dead? | Win rate per faction, all player counts | Each within ±X of 1/N |
| Matchup matrix | Is any pairing unplayable? | Win rate per (faction A vs faction B) cell | No cell outside a wider band than the global one |
| Player-count sensitivity | Does a faction only break at 4P? | Win rate per faction × player count | Band holds at every supported count |
| Seat/turn order | Does going first decide it? | Win rate by seat position | Each seat within ±X of 1/N |
| Faction × map interaction | Is any faction map-locked? | Win rate per (faction × map) | No faction swings more than X across maps |
| New-faction integration | Does the new faction warp the field? | Win rate of all factions with vs without the new one in the pool | Existing factions move less than X |

The matchup matrix is quadratic in faction count and gets expensive fast. When it does, sample it: test the pairings the designer suspects plus a random rotating subset per nightly run.

## Card games and deckbuilders

| Scenario | Balance question | Metric | Threshold shape |
|----------|------------------|--------|-----------------|
| Card usage spread | Any auto-include or dead card? | Play/pick rate per card | Every card between a floor and a ceiling |
| Card win-rate delta | Does drawing this card decide the game? | Win rate of games where card was played vs not | Delta under X points |
| Cost-curve fit | Are costs consistent with power? | Regression of measured win-rate contribution against printed cost | Residual per card under X |
| Archetype spread | Is one deck the meta? | Win rate per archetype in a mirror-skill field | Each within band; no archetype below the "unplayable" floor |
| Mana/resource screw | How often is a hand unplayable? | P(cannot play anything by turn N) | Under X% |
| Draft signal | Does draft order dominate? | Win rate by draft seat / pick order | Flat within X |
| Format legality | Does a card break one format only? | Per-format win-rate delta for the card | Each format independently in band |
| Combo detection | Does any pair produce runaway wins? | Win rate of all 2-card co-occurrences, ranked | Top of the ranking flagged for review, not auto-failed |

Combo detection is best run as a *ranked report* rather than a pass/fail gate: the point is to surface the top 10 suspicious pairs for a designer to look at, since a strong combo is often intentional.

## Roguelikes and run-based games

| Scenario | Balance question | Metric | Threshold shape |
|----------|------------------|--------|-----------------|
| Run completion | Is the run beatable and not trivial? | Win rate per difficulty tier, per starting class | Each tier in its intended band, monotonic across tiers |
| Death curve | Where do runs end? | Distribution of run-ending floor/stage | No single spike; matches intended pacing |
| Item power spread | Any must-take or never-take item? | Win rate of runs containing item vs not; pick rate | Delta under X; pick rate above a floor |
| Build viability | Do multiple builds work? | Win rate per identified build archetype | Every archetype above a viability floor |
| Snowball | Does an early lead decide the run? | P(win \| ahead at stage 2) | Under a ceiling — a lead should matter, not decide |
| Bad-luck floor | Can RNG make a run unwinnable? | Rate of runs with no viable option at stage N | Near zero |
| Seed fairness | Are some seeds impossible? | Win rate distribution across seeds for a fixed policy | Variance across seeds under X |

## Autobattlers and team-composition games

| Scenario | Balance question | Metric | Threshold shape |
|----------|------------------|--------|-----------------|
| Unit tier balance | Is a unit at a given tier overtuned? | Win rate of boards containing unit, controlled for tier and gold | Delta within band |
| Composition spread | How many comps are viable? | Number of comps above a win-rate floor; usage entropy | Above a diversity minimum |
| Economy vs tempo | Is one economic strategy strictly right? | Win rate of scripted econ policies (greedy roll, hard save, level rush) | No policy dominating by more than X |
| Positioning value | Does positioning matter? | Win rate of optimized vs random placement, same board | Clear but bounded margin |
| Item/augment power | Any augment strictly best? | Win rate per augment at offer parity | Each within band |
| Scaling curve | Do units scale as intended? | Simulated 1v1 win rate per unit pair at equal cost | Matches the intended power ordering |

## 4X and strategy

| Scenario | Balance question | Metric | Threshold shape |
|----------|------------------|--------|-----------------|
| Victory-type spread | Is one win condition the only one? | Distribution of victory types achieved | Each type above a floor |
| Runaway leader | Is the game decided by turn X? | Correlation of turn-X score with final win; P(win \| leading at turn X) | Under a ceiling |
| Map generation fairness | Are some starts unwinnable? | Win rate by start-position quality bucket | Spread under X |
| Tech/build order | Is one opening solved? | Win rate per scripted opening | No opening dominant by more than X |
| AI difficulty ladder | Are difficulty levels ordered and spaced? | Human-proxy win rate per difficulty | Monotonic, with intended gaps |
| Turn-length creep | Does the late game bog down? | Median decision count and sim time per turn, by game phase | Under a ceiling |

## RPG and combat systems

| Scenario | Balance question | Metric | Threshold shape |
|----------|------------------|--------|-----------------|
| Class/build parity | Is any build strictly better? | Encounter clear rate and TTK per build at equal level/gear | Within band |
| Encounter difficulty | Is this fight tuned right? | Player win rate at intended level; damage-taken fraction | In the designed band |
| Difficulty curve | Does difficulty rise smoothly? | Clear rate per encounter in progression order | Monotonic-ish, no spikes above X |
| Gear power budget | Does one item break the curve? | TTK delta from swapping a single slot | Under X% |
| Action economy | Does one action dominate? | Usage rate per ability in optimized play | Every ability above a usage floor |
| Level scaling | Does under/over-leveling break tuning? | Clear rate at level ±2 | Degrades gradually, no cliff |
| Status/CC stacking | Can a target be locked out? | Rate of enemy turns lost to CC | Under a ceiling |

## PvP and matchmaking

| Scenario | Balance question | Metric | Threshold shape |
|----------|------------------|--------|-----------------|
| Skill expression | Does the better player win? | Win rate of stronger policy across a skill ladder | Above a floor — high enough to reward skill, below total determinism |
| Rating convergence | Does the rating system settle? | Games to converge on true skill in a simulated population | Under X games |
| Smurf/new-player experience | Are new players crushed? | Win rate of a fresh account in its first N games | Above a floor |
| Comeback potential | Is being behind hopeless? | P(win \| behind at the midpoint) | Above a floor, below a ceiling |
| Queue-composition effects | Does a party stomp solos? | Win rate by party size | Spread under X |

## Economy and progression

| Scenario | Balance question | Metric | Threshold shape |
|----------|------------------|--------|-----------------|
| Currency curve | Do players earn as intended? | Median cumulative currency by session N | Tracks the design curve within X% |
| Sink/faucet balance | Does currency inflate or starve? | Net currency slope over a long simulated horizon | Slope in band; no unbounded growth |
| Time-to-unlock | Is the grind the intended length? | Sessions to reach each progression gate | Each gate in band |
| Price coherence | Is anything mispriced? | Simulated value-per-cost per purchasable | No item more than X above the fit line |
| Exploit search | Can the economy be farmed? | Max currency/hour found by an optimizing policy over a repeatable action space | Under a ceiling |
| Drop-table calibration | Are drops honest? | Empirical drop rate vs declared rate; P(no drop in N tries) | Empirical matches declared; dry-streak tail under a ceiling |

The exploit search is the highest-value economy eval and the most often skipped: point an optimizer at the repeatable actions and let it look for the loop. It finds in an hour what a community finds in a week.

## Board games

| Scenario | Balance question | Metric | Threshold shape |
|----------|------------------|--------|-----------------|
| Seat advantage | Does turn order decide it? | Win rate by seat, per player count | Within ±X of 1/N |
| Player-count scaling | Does the game work at every count? | Win-rate spread, game length, and score margins per supported count | All in band at every count |
| Kingmaking | Can a losing player pick the winner? | Frequency of the leader being decided by a non-contending player's choice | Under a ceiling |
| Score spread | Are finishes close? | Distribution of winning margin | Median margin in band; blowout rate under X |
| Setup variance | Does setup decide it? | Correlation of a setup-quality heuristic with the winner | Under a ceiling |
| Component sufficiency | Do the bits run out? | Max simultaneous demand per component type across trials | Under the produced count |
| Rules-edge frequency | How often do rare rules come up? | Rate of games invoking each rules clause | Flags never-invoked rules for cutting |

Component sufficiency and rules-edge frequency are cheap, uniquely tabletop, and directly save money: one tells you how many cubes to put in the box, the other tells you which paragraph to delete from the rulebook.

## Rule-interaction scenarios (deterministic)

These are not statistical. They're fixed-seed, fixed-state assertions — the fast PR tier — and they behave like ordinary unit tests.

- A specific board state resolves to a specific outcome (the corner case someone argued about).
- A rules clause is actually reachable (construct the state; assert it's legal).
- An illegal action is rejected in every state that should reject it.
- A known past balance bug stays fixed (regression test per fixed bug).
- A scoring calculation matches a hand-computed reference.
- A previously-found infinite loop or lock is still impossible.

Every balance bug that ships should leave one of these behind. They cost milliseconds and they are the only part of the eval suite that never goes noisy.
