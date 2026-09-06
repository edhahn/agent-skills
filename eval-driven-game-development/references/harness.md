# Harness Contract and Instrumentation

The shape of a balance eval harness, expressed so it can be built in any language, plus what a game must expose for evals to be possible at all.

**This is a contract, not an implementation.** Build it in the project's existing language and test framework. JSON below is for concreteness; YAML, TOML, engine data tables, or typed structs are equally valid as long as the fields survive.

## Contents

- [Manifest schema](#manifest-schema)
- [Runner contract](#runner-contract)
- [Report schema](#report-schema)
- [Baseline file](#baseline-file)
- [CLI surface](#cli-surface)
- [Stack mappings](#stack-mappings)
- [CI recipes](#ci-recipes)
- [Instrumentation](#instrumentation)
- [Build order](#build-order)

## Manifest schema

Scenarios as data, so a designer can add one without an engineer and CI can select by tier.

```json
{
  "version": 1,
  "defaults": { "trials": 1000, "seed_base": 1000, "policy": "greedy_v2" },
  "scenarios": [
    {
      "id": "faction-spread-4p",
      "description": "No faction dominates a 4-player mirror-skill game.",
      "rationale": "Band is my inference from measured spread, not a design target. 2500 trials gives a ~2pt CI, so the band is +/-3.",
      "owner": "design",
      "tier": "nightly",
      "setup": {
        "players": 4,
        "factions": ["crimson", "verdant", "azure", "umber"],
        "content_set": "base+expansion1",
        "policies": ["greedy_v2", "greedy_v2", "greedy_v2", "greedy_v2"]
      },
      "seeds": { "base": 1000, "count": 2500, "mirrored": true },
      "metrics": ["win_rate_by_faction", "game_length_turns", "turn_cap_rate"],
      "thresholds": [
        { "metric": "win_rate_by_faction", "shape": "band", "lo": 0.22, "hi": 0.28,
          "per_key": true, "status": "provisional", "gate": false, "owner": "design" },
        { "metric": "win_rate_by_faction", "shape": "regression", "max_delta": 0.04,
          "per_key": true, "status": "approved", "gate": true },
        { "metric": "turn_cap_rate", "shape": "ceiling", "hi": 0.002,
          "status": "approved", "gate": true }
      ]
    }
  ]
}
```

The fields that carry the sign-off contract:

- **`status`** — `provisional` (your inference) or `approved` (a stated design target). Anything you derived yourself starts provisional.
- **`gate`** — whether this threshold can fail the build. A provisional threshold reports its verdict and is excluded from the exit code.
- **`owner`** — who can approve it. Unowned thresholds decay into `# TODO: re-enable`.
- **`rationale`** — why this number. Make the loader **reject** a scenario missing `rationale` or `owner`; it costs five lines and prevents the whole system from rotting.

Enforce the contract in code, not prose: a test asserting that no `status: provisional` threshold has `gate: true` makes approval a deliberate edit. Without it, "provisional" is a comment.

Note that the regression threshold gates while the absolute band does not — a metric moving 6 points since last week is a fact; whether 25% is the right target is an opinion.

## Runner contract

Six steps, whatever the language:

1. **Load** the manifest, filter by tier/id, resolve defaults.
2. **Execute trials** at `seed_base + i` (plus mirrors), each deterministic under its seed. Parallelize *across* trials, never within one.
3. **Collect events or per-trial records.** Prefer events: metrics you haven't invented yet can be computed from stored events, not from stored metrics.
4. **Aggregate** with confidence intervals and trial counts.
5. **Judge** — evaluate thresholds, diff against baseline. Distinguish `PASS` / `FAIL` / `NO_BASELINE` / `REPORTED` (provisional). A new scenario must not report as passing a regression check it never ran.
6. **Emit** machine report, human summary, and an exit code driven only by gating thresholds.

Guarantees worth holding:

- **Same manifest + seeds + build = same report.** Without it no failure can be investigated.
- **Trials are isolated.** A shared cache or static RNG silently correlates trials and shrinks your effective sample far below the trial count.
- **A crashed trial is recorded with its seed and does not abort the sweep.** A nonzero crash rate is itself a finding.
- **Progress is visible.** A 40-minute silent sweep gets killed by whoever is watching it.
- **Clustered sampling is reported honestly.** If one seed is reused across 4 faction rotations, those are not 4 independent trials — cluster by seed before computing intervals, or the CIs are too narrow.

## Report schema

```json
{
  "run_id": "2026-02-14T03:12:00Z",
  "commit": "a1b2c3d",
  "content_version": "base+expansion1@7f21c9",
  "scenarios": [
    {
      "id": "faction-spread-4p",
      "trials": 2500, "errors": 0,
      "seeds": { "base": 1000, "count": 2500, "mirrored": true },
      "policies": ["greedy_v2"],
      "metrics": {
        "win_rate_by_faction": {
          "crimson": { "value": 0.572, "ci95": [0.552, 0.591], "baseline": 0.510, "delta": 0.062 }
        }
      },
      "verdicts": [
        { "metric": "win_rate_by_faction", "key": "crimson", "shape": "band",
          "result": "FAIL", "gating": false, "status": "provisional",
          "detail": "0.572 outside [0.22, 0.28]" }
      ],
      "outliers": [ { "seed": 1183, "reason": "shortest game", "turns": 4 } ],
      "duration_s": 341
    }
  ],
  "summary": { "gating_failed": 0, "reported_failed": 1, "no_baseline": 2 }
}
```

`outliers` earns its place: it turns a failing number into a game a designer can replay. Always include the seed.

## Baseline file

Metric values from the last known-good sweep, plus provenance:

```json
{
  "generated": "2026-02-01T00:00:00Z",
  "commit": "9f8e7d6",
  "content_version": "base+expansion1@3a11bd",
  "seed_set": "1000-3499",
  "reason": "Post-1.4 balance pass approved by design",
  "metrics": { "faction-spread-4p": { "win_rate_by_faction": { "crimson": 0.510 } } }
}
```

- **CI must not be able to write it.** No `--update` in the pipeline, no commit step, read-only permissions. Regeneration is a human command requiring an explicit reason.
- **Verify before you freeze.** Baselining a build that already contains a regression locks the bug in as correct. Check the changelog and the code agree before generating.
- **Expect intentional breaks.** A patch meant to change balance *should* fail the regression check; the PR that lands the patch lands the new baseline, reviewed together.

## CLI surface

```
<runner> --scenario faction-spread-4p --trials 300      # ad hoc: designer mid-tuning, seconds
<runner> --all --report out/report.json                 # full sweep: before a release
<runner> --tier pr --baseline evals/baseline.json \
         --report out/report.json --junit out/balance.xml   # CI
```

The ad hoc path matters more than it looks: if checking a tuning change takes 40 minutes, designers stop checking; at 8 seconds they check every change. JUnit XML is usually worth emitting — most CI providers render it natively.

## Stack mappings

| Stack | Manifest | Runner | Integration |
|-------|----------|--------|-------------|
| **Python / pytest** | JSON/YAML in `evals/`, loaded by a fixture | Parametrize over scenarios; `multiprocessing.Pool` over trials | `--junitxml`; JSON via session fixture |
| **TypeScript / vitest** | JSON in `evals/`, imported | `test.each(scenarios)`; workers for trials | `--reporter=junit`; JSON in `globalTeardown` |
| **Go** | JSON or `embed`, table-driven | Subtests per scenario, errgroup per trial | `go test -json`; JSON via `TestMain` |
| **Rust** | JSON/TOML via serde | `#[test]` per scenario or a bin target; rayon over trials | custom harness |
| **C# / Unity** | ScriptableObject or JSON | NUnit `TestCaseSource`; `-batchmode -runTests` | NUnit XML + custom writer |
| **UE5 / C++** | Data table or JSON in `Content/Evals` | Automation Spec; `-nullrhi` headless, or a commandlet | Automation report + JSON writer |
| **Godot** | JSON or Resource in `res://evals` | GUT/GdUnit, or `--headless --script` | exit code + JSON from the script |
| **Standalone binary** | JSON beside the binary | The sim takes `--manifest` directly | JSON + JUnit |

Two engine notes: UE5 and Unity boot slowly and cost a lot per trial, so keep the rules sim engine-free and test it as a plain library, using engine automation only where the engine is genuinely required. And editor-mode runs are not headless — use `-nullrhi`/`-batchmode` or CI needs a GPU.

## CI recipes

| Tier | Trigger | Budget | Blocking |
|------|---------|--------|----------|
| `deterministic` | every PR | seconds | yes |
| `pr` | every PR | 1–3 min | yes |
| `nightly` | schedule + pre-release | unbounded | no — files an issue |
| `manual` | on demand | unbounded | no |

```yaml
name: balance-evals
on:
  pull_request:
  schedule: [{ cron: "0 6 * * *" }]

jobs:
  pr-tier:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions: { contents: read }        # cannot write the baseline
    steps:
      - uses: actions/checkout@v4
      # ... project's standard setup ...
      - run: <runner> --tier deterministic,pr --baseline evals/baseline.json --report out/report.json --budget-s 120
      - uses: actions/upload-artifact@v4
        if: always()
        with: { name: balance-report, path: out/report.json }
      # post a short delta table as a sticky PR comment

  nightly-sweep:
    if: github.event_name == 'schedule'
    runs-on: ubuntu-latest
    timeout-minutes: 180
    steps:
      - uses: actions/checkout@v4
      - run: <runner> --all --baseline evals/baseline.json --report out/report.json
        continue-on-error: true
      # open or update a tracking issue instead of failing
```

Ports directly to GitLab CI, Jenkins, Buildkite, CircleCI — **use whichever the project already has.**

Rules that keep a gate alive: only fast tiers block merges; enforce a runtime budget in the runner so the PR tier can't creep (and when it trips, cut trials rather than raising the budget); pin seeds so failures reproduce locally, and print the reproduce command in the failure; cache the build, never the results; post the delta, not the dump.

## Instrumentation

What a game must expose. Raise these while a feature is being built — retrofitting costs far more.

- **Rules engine separable from presentation.** Balance evals advance state thousands of times per second, impossible if resolving an attack awaits an animation. Highest-leverage constraint, and it also buys headless servers, replays, and testable rules — argue for it on those grounds.
- **Determinism under an injected seed.** One seeded RNG threaded through the sim, never ambient global random. Give map generation, shuffles, and combat their own derived streams, so adding a die roll to combat doesn't shift every future shuffle and invalidate every baseline. Sort before any iteration whose order affects outcomes. No wall-clock or frame-time inputs. Prefer integer/fixed-point math for rules — cross-platform float drift produces "only fails on CI" bugs.
- **A determinism test, first.** Same seed twice, hash both transcripts, assert equality; run it on every PR. Every other eval's credibility rests on it.
- **Headless entry point.** One command, no renderer, configuration via arguments, machine-readable output, working from a clean checkout with the standard build.
- **Structured event log.** Typed events (`game_started` with seed/config/policies/content version, `turn_started`, `action_taken`, `resource_changed`, `entity_died`, `game_ended` with winner and reason). Version the schema; make logging cheap and switchable; never let it draw from the RNG or change control flow.
- **Replayable transcripts.** Store seed and inputs for outliers automatically, and provide a replay command. Replaying an old transcript against a new build is also the sharpest regression signal available.
- **Tuning as data**, overridable per scenario so a sweep can vary a cost from 2 to 6 without a rebuild. Validate on load. Stamp the content version into every report.
- **Named, versioned bot policies.** Keep at least `random_legal` (a floor — if it wins often, the game lacks depth) and a competent heuristic. Treat a policy change like a content change: it invalidates baselines.

**Retrofit order** for an existing game, by value per unit of pain: carve out the smallest pure core (often the damage formula or economy) → inject the RNG → add the determinism test → minimal headless mode → event log at existing chokepoints → tuning constants to data → policy interface → *then* argue for the sim/presentation split, with evidence ("this eval takes 6 hours because it renders"). Asking for the big refactor first is the common way this work gets deprioritized.

## Build order

1. **Determinism check** — everything downstream depends on it.
2. **One scenario end to end**, hardcoded. Proves the sim can be driven headlessly.
3. **Manifest + runner** — generalize that one scenario into data.
4. **Report + human summary.**
5. **Ad hoc CLI mode** — what makes the system get used daily.
6. **Baseline + regression**, once metrics are stable enough to freeze.
7. **CI wiring** — deterministic tier, then sampled, then nightly.
8. **More scenarios**, driven by the proposal-and-review loop.

Resist building thirty scenarios before step 5. A harness nobody runs interactively is a harness that rots.
