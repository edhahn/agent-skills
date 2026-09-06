# Balance Metrics and Thresholds

Definitions, formulas, and the statistics needed to set thresholds that hold up.

## Contents

- [Sizing trials](#sizing-trials-read-this-first)
- [Outcome metrics](#outcome-metrics)
- [Diversity metrics](#diversity-metrics)
- [Pacing metrics](#pacing-metrics)
- [Economy metrics](#economy-metrics)
- [Combat metrics](#combat-metrics)
- [Writing thresholds](#writing-thresholds)
- [Baselines and regression](#baselines-and-regression)
- [Reporting results](#reporting-results)
- [Common statistical mistakes](#common-statistical-mistakes)

## Sizing trials (read this first)

A win-rate measurement over `n` games has a standard error of roughly `sqrt(p*(1-p)/n)`, which is at most `0.5/sqrt(n)`. The 95% confidence interval is about `±1.96 * SE`. That gives a usable table:

| Trials | 95% CI half-width on a win rate | Usable for |
|--------|--------------------------------|------------|
| 100 | ±10 pts | nothing but smoke tests |
| 400 | ±5 pts | "is it wildly broken" |
| 1,000 | ±3.1 pts | PR-tier sampled checks |
| 2,500 | ±2.0 pts | standard nightly scenario |
| 10,000 | ±1.0 pt | fine tuning, matchup matrices |
| 100,000 | ±0.3 pts | competitive-play calibration |

**The rule this implies: your band must be wider than your confidence interval, or the eval is measuring noise.** A ±2-point band on 400 trials will fail randomly about as often as it passes. When you can't afford the trials, widen the band and say so in the scenario's rationale — an honest wide band beats a precise-looking lie.

Two adjustments:

- **Multiple comparisons.** Checking 8 factions against their bands at 95% confidence gives roughly a 1-in-3 chance that *something* fails by luck. Either use a stricter per-metric threshold (Bonferroni: divide your alpha by the number of comparisons) or, more practically, require a failure to reproduce on a second seed set before it blocks anything.
- **Variance reduction.** For matchup evals, play each seed twice with sides swapped (mirrored seeds). This cancels most map/deal luck and can cut the trials needed for a given precision by a large factor. It's the cheapest statistical win available.

## Outcome metrics

**Win rate.** `wins / games` for a given faction, deck, class, seat, or policy. The core metric; almost everything else is a refinement of it.

- Report per faction *and* per (faction × player count) — a faction can be fine on average and broken at 2P.
- Draws need a stated convention. Either exclude them and report the draw rate separately, or count them as 0.5. Pick one, write it in the manifest, and never mix.

**Seat / turn-order win rate.** Win rate grouped by seat index. Target is `1/N` per seat. First-player advantage is `winrate(seat 1) - 1/N`; a positive value is normal for many designs — the question is whether it exceeds what the game's compensation mechanism (bonus resources, later-seat advantages, bidding) is supposed to offset.

**Matchup win rate.** Win rate of A against B in isolation. The matrix should be antisymmetric (`W[A][B] + W[B][A] = 1`), which is a free correctness check on the harness — if it isn't, the sim is asymmetric in a way it shouldn't be.

**Conditional win probability.** `P(win | state)` — the workhorse for snowball and comeback questions. `P(win | leading at turn 5)` near 1.0 means the game is decided at turn 5; near 0.5 means the lead is meaningless. Both are design failures at the extremes; the target is a design choice.

**Elo / rating spread.** When policies vary in strength, fit ratings from pairwise results rather than reading raw win rates. Rating differences are transitive and comparable across content patches in a way raw win rates against a shifting field are not.

## Diversity metrics

**Usage / pick rate.** Fraction of games (or decks, or drafts) in which a piece of content appears. Two failure modes bracket it: below a floor is **dead content** (paid for, never seen); above a ceiling is an **auto-include** (not a choice).

**Dead-content rate.** Fraction of the content library below the usage floor. This is the single best number for "is our content budget being wasted" and it trends usefully over a project's life.

**Usage Gini coefficient.** Inequality of usage across the content set, 0 (perfectly even) to 1 (one item takes everything). Useful as a single tracked number over time; less useful as a hard gate, because the healthy value is genre-specific — set it from your own historical baseline, not from theory.

**Effective number of strategies.** `exp(H)` where `H` is the Shannon entropy of archetype usage shares. Reads as "how many viable strategies does this meta actually have" — an effective count of 2.3 in a game with 9 archetypes is a clear finding, in a way that "entropy = 0.83" is not. Prefer it for reporting to humans.

**Decision entropy.** Entropy of the action distribution in states where multiple actions are legal. Near zero means the game plays itself — there is a right move and everyone finds it.

## Pacing metrics

**Game length.** Distribution in turns and, separately, in estimated minutes. Report median, p10, and p90 rather than the mean; length distributions are right-skewed and the mean hides the two-hour outlier that ruins a game night.

**Turn-cap hit rate.** Fraction of games hitting the simulation's turn limit. Anything above a fraction of a percent usually means a stalemate state exists, and the transcripts of those games are the most valuable output of the whole run.

**Time-to-decided.** The turn at which `P(win | state)` for the eventual winner first crosses a high threshold and stays there. The gap between "decided" and "over" is dead time — a large gap is the metric behind "this game outstays its welcome."

**Downtime.** Median wall-clock or decision-count gap between one player's consecutive decisions. Chiefly a tabletop and turn-based concern, and it grows superlinearly with player count.

## Economy metrics

**Faucet and sink rates.** Currency created and destroyed per unit of time or per turn, per source. Net slope over a long horizon tells you whether the economy inflates, deflates, or holds.

**Cumulative earn curve.** Median cumulative currency at each session/turn index, compared against the intended design curve. Assert on band around the curve at a few checkpoints rather than at every point.

**Purchasing power.** Currency held divided by the cost of the next intended purchase. Keeps its meaning across patches that change both prices and income, which raw currency doesn't.

**Price coherence residual.** Fit a line from measured value (win-rate contribution, or clear-rate contribution) against printed cost; the residual per item flags mispricings. Big positive residual = undercosted.

**Exploit yield.** Maximum currency per unit time discovered by an optimizing policy searching the repeatable action space. Compare against intended yield; a ratio above ~2× is a farm the community will find.

**Dry-streak tail.** `P(no drop in N attempts)` for a declared drop rate. The number that generates support tickets. Compare empirical against the theoretical `(1-p)^N` to catch drop tables that don't behave as declared.

## Combat metrics

**TTK (time to kill).** Turns or seconds to defeat a reference target with a reference build. The standard comparator across builds, weapons, and patches. Always state the reference target — a TTK with no stated target is meaningless.

**Effective DPS.** Damage per unit time including cooldowns, resource constraints, misses, and uptime. Theoretical DPS from a spreadsheet consistently overstates weapons with narrow uptime windows.

**Clear rate.** Fraction of attempts that beat an encounter with a given build at a given level. The direct measure of encounter difficulty.

**Damage-taken fraction.** Fraction of the player's effective HP lost in a successful clear. Separates "hard" (high damage taken, still cleared) from "unforgiving" (low clear rate) — different fixes.

**Ability usage share.** Fraction of actions spent on each ability in optimized play. An ability under a few percent is decoration; one over half is the whole kit.

**Action-economy loss.** Fraction of a combatant's turns removed by stuns, roots, or other lockouts. Above a ceiling, the player isn't playing.

## Writing thresholds

Threshold shapes worth knowing, in rough order of how often they're the right tool:

| Shape | Form | Use for |
|-------|------|---------|
| Band | `lo <= x <= hi` | Win rates, usage rates, most balance numbers |
| Ceiling / floor | `x <= hi` / `x >= lo` | Degenerate rates, exploit yields, viability floors |
| Spread | `max(xs) - min(xs) <= d` | Fairness across seats/factions without fixing each one |
| Regression | `abs(x - baseline) <= d` | Anything where drift matters more than the absolute |
| Ordering | `xs` monotonic | Difficulty ladders, tier progressions, cost curves |
| Distributional | `p90(x) <= hi` | Game length, dry streaks, anything with a bad tail |
| Rank report | top-K flagged, no pass/fail | Combo detection, mispricing search — human judgment needed |

Rules for choosing numbers:

- **Derive the band from the CI, not from taste.** Band half-width should be at least ~1.5× the CI half-width at your trial count. Otherwise you've built a random number generator that files bug reports.
- **Set floors from consequences, not symmetry.** The dead-content floor is "below this, we wasted the art budget" — that's a business number the designer supplies.
- **Write the rationale next to the threshold.** Six months later nobody remembers why the ceiling is 0.62, and an unexplained threshold gets relaxed the first time it's inconvenient.
- **Every threshold gets an owner.** The person who can approve changing it. Unowned thresholds decay into `# TODO: re-enable`.

## Baselines and regression

Keep a committed `baseline.json`: metric values from the last known-good full sweep, with the commit SHA, content version, seed set, and date that produced it.

- **Regenerate deliberately.** A baseline update is a reviewed commit with a stated reason ("Crimson nerf landed, faction win rates re-baselined"), never an automatic overwrite by CI. Auto-updating baselines is how a slow drift becomes permanent — each day's change looks small against yesterday.
- **Diff on the metrics, report the deltas.** The useful CI output is a short table of what moved and by how much, sorted by size of move.
- **Expect intentional breaks.** When a patch is meant to change balance, the regression check *should* fail; the PR that lands the patch also lands the new baseline, in the same review.
- **Keep history.** Storing each sweep's report lets you plot a metric over the project's life, which catches the slow drifts no single diff would.

## Reporting results

Always report, per metric: the point estimate, the confidence interval, the trial count, the threshold, the verdict, and the delta vs baseline. Include the seeds of the most extreme trials so a designer can replay them.

```
SCENARIO faction-spread-4p          policy=greedy_v2  trials=2500  seeds=1000-3499
  crimson    57.2%  [55.2-59.1]   band 22.0-28.0   FAIL  (baseline 51.0%, +6.2)
  verdant    24.1%  [22.4-25.8]   band 22.0-28.0   PASS  (baseline 24.8%, -0.7)
  ...
  outliers: seed 1183 (crimson win, turn 4), seed 2901 (turn cap hit)
```

The verdict line alone is nearly useless to a designer. The interval, the baseline delta, and a replayable seed are what turn a failure into a fix.

## Common statistical mistakes

- **Asserting on a single playthrough.** One game tells you the sim ran, nothing more.
- **Band narrower than the confidence interval.** Guarantees flakiness; the eval gets disabled.
- **Reusing the same seed set forever.** The game gets tuned to those seeds. Rotate on a schedule, in a commit.
- **Ignoring multiple comparisons.** Testing 30 cards at 95% confidence produces a failure most runs, by construction.
- **Reading the mean of a skewed distribution.** Game length, currency held, and run duration all have long right tails. Use the median and the p90.
- **Comparing win rates measured against different fields.** A card's win rate in last patch's meta isn't comparable to this patch's. Fix the field, or use ratings.
- **Concluding from one bot policy.** If the conclusion flips between `greedy` and `lookahead`, you measured the bot. Run at least two policies on anything that will drive a real tuning decision.
- **Treating simulated results as playtest results.** Sims answer "what do the numbers do", not "is it fun" or "is it confusing". State which question you answered.
- **Counting clustered trials as independent.** Reusing one seed across 4 faction rotations gives 4 correlated observations, not 4 independent ones. Cluster by seed before computing intervals, or your CIs are narrower than the truth and your "significant" finding may be noise.
- **Asserting on a saturated metric.** If win rate is 99.9% before and after every change, it cannot move and it gates nothing. Find the leading indicator that still has room to travel (end HP, floors cleared, margin) and gate on that instead.
- **Overclaiming in the summary.** "Across all 25 configurations, X never exceeds fair share" is the kind of sentence that gets checked — and if 10 of those configurations ran at a different trial count, or two contradict it, the error discredits the correct analysis around it. Check universals against your own logs before writing them, and prefer a bounded statement with its n: "at 4P over 8,000 seeds, X ranged 13–39%".
