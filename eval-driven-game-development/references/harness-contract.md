# Harness Contract

The shape of a balance eval harness, expressed so it can be implemented in any language, plus mappings onto common test frameworks and CI providers.

**This is a contract, not an implementation.** Build it in the project's existing language and test framework — see "Deferring to the project's stack" in `SKILL.md`. The schemas below are shown in JSON for concreteness; YAML, TOML, engine data tables, or a typed struct are equally valid as long as the fields survive.

## Contents

- [Manifest schema](#manifest-schema)
- [Runner contract](#runner-contract)
- [Report schema](#report-schema)
- [Baseline file](#baseline-file)
- [CLI surface](#cli-surface)
- [Stack mappings](#stack-mappings)
- [CI recipes](#ci-recipes)
- [Build order](#build-order)

## Manifest schema

Scenarios live as data so a designer can add one without an engineer, and so CI can select by tier.

```json
{
  "version": 1,
  "defaults": {
    "trials": 1000,
    "seed_base": 1000,
    "policy": "greedy_v2",
    "content_version": "content/manifest.json"
  },
  "scenarios": [
    {
      "id": "faction-spread-4p",
      "description": "No faction dominates a 4-player mirror-skill game.",
      "rationale": "Approved 2026-02-11 by design. Band is +/-3 around 25% because 2500 trials gives a ~2pt CI.",
      "owner": "design",
      "tier": "nightly",
      "setup": {
        "players": 4,
        "factions": ["crimson", "verdant", "azure", "umber"],
        "map": "standard",
        "content_set": "base+expansion1",
        "policies": ["greedy_v2", "greedy_v2", "greedy_v2", "greedy_v2"]
      },
      "trials": 2500,
      "seeds": { "base": 1000, "count": 2500, "mirrored": true },
      "metrics": ["win_rate_by_faction", "game_length_turns", "turn_cap_rate"],
      "thresholds": [
        { "metric": "win_rate_by_faction", "shape": "band", "lo": 0.22, "hi": 0.28, "per_key": true },
        { "metric": "win_rate_by_faction", "shape": "regression", "max_delta": 0.04, "per_key": true },
        { "metric": "game_length_turns", "shape": "distributional", "stat": "p90", "hi": 40 },
        { "metric": "turn_cap_rate", "shape": "ceiling", "hi": 0.002 }
      ]
    }
  ]
}
```

Field notes:

- **`tier`** — `deterministic` | `pr` | `nightly` | `manual`. Drives CI selection; see [CI recipes](#ci-recipes).
- **`rationale` and `owner`** — not optional in practice. A threshold whose reasoning isn't recorded gets relaxed the first time it's inconvenient, and one with no owner gets disabled.
- **`seeds.mirrored`** — play each seed twice with seats/sides rotated. Cancels most deal and map luck; the cheapest precision gain available.
- **`per_key: true`** — the metric returns a map (faction → rate) and the threshold applies to every entry.
- **`content_version`** — pin the content the scenario ran against, so results attach to a known game state.
- **Both a band and a regression threshold on the same metric** is the normal case: the band encodes design intent, the regression catches drift before the band is breached.

## Runner contract

Whatever the language, the runner does six things in this order:

1. **Load** the manifest, filter scenarios by tier/id, resolve defaults.
2. **Execute trials** — for each scenario, run `trials` games at `seed_base + i` (plus mirrors), each fully deterministic under its seed. Parallelize across trials where the sim allows; trials are independent by construction, which makes this the easy kind of parallelism.
3. **Collect events** — each trial yields an event log or a per-trial summary record. Prefer events: metrics you haven't invented yet can be computed from stored events, but not from stored metrics.
4. **Aggregate** — compute each declared metric across trials, with confidence intervals and trial counts.
5. **Judge** — evaluate thresholds, and compute deltas against the baseline. Distinguish `PASS`, `FAIL`, and `NO_BASELINE` (a new scenario has nothing to regress against and must not be reported as passing a regression check it never ran).
6. **Emit** — machine report to disk, human summary to stdout, exit non-zero if any threshold in the selected tier failed.

Properties worth guaranteeing:

- **Same manifest + same seeds + same build = same report.** If it isn't reproducible, no failure can be investigated.
- **Trials are isolated.** No state leaks between games — a shared cache or a static RNG will silently correlate trials and shrink your effective sample size to something much smaller than the trial count.
- **Partial failure is survivable.** A crashed trial gets recorded as an error with its seed and does not abort the sweep. A crash rate above ~0 is itself a finding worth reporting.
- **Progress is visible.** A 40-minute sweep with no output gets killed by whoever is watching it.

## Report schema

```json
{
  "run_id": "2026-02-14T03:12:00Z",
  "commit": "a1b2c3d",
  "content_version": "base+expansion1@7f21c9",
  "manifest_version": 1,
  "tier": "nightly",
  "scenarios": [
    {
      "id": "faction-spread-4p",
      "trials": 2500,
      "errors": 0,
      "seeds": { "base": 1000, "count": 2500, "mirrored": true },
      "policies": ["greedy_v2"],
      "metrics": {
        "win_rate_by_faction": {
          "crimson": { "value": 0.572, "ci95": [0.552, 0.591], "baseline": 0.510, "delta": 0.062 },
          "verdant": { "value": 0.241, "ci95": [0.224, 0.258], "baseline": 0.248, "delta": -0.007 }
        },
        "game_length_turns": { "median": 27, "p10": 19, "p90": 38 },
        "turn_cap_rate": { "value": 0.0004, "ci95": [0.0, 0.0012] }
      },
      "verdicts": [
        { "metric": "win_rate_by_faction", "key": "crimson", "shape": "band",
          "result": "FAIL", "detail": "0.572 outside [0.22, 0.28]" }
      ],
      "outliers": [
        { "seed": 1183, "reason": "shortest game", "turns": 4, "winner": "crimson" },
        { "seed": 2901, "reason": "turn cap hit", "turns": 60 }
      ],
      "duration_s": 341
    }
  ],
  "summary": { "passed": 11, "failed": 1, "no_baseline": 2, "duration_s": 1780 }
}
```

The `outliers` array earns its place: it turns a failing number into a game a designer can replay. Always include the seed.

## Baseline file

Same shape as the report's metric values, plus provenance:

```json
{
  "generated": "2026-02-01T00:00:00Z",
  "commit": "9f8e7d6",
  "content_version": "base+expansion1@3a11bd",
  "seed_set": "1000-3499",
  "reason": "Post-1.4 balance pass approved by design",
  "metrics": {
    "faction-spread-4p": {
      "win_rate_by_faction": { "crimson": 0.510, "verdant": 0.248, "azure": 0.244, "umber": 0.498 }
    }
  }
}
```

Update it only by reviewed commit, with `reason` filled in. CI must never write it — a self-updating baseline converts a slow drift into the new normal, one imperceptible step at a time.

## CLI surface

Three modes, because they serve three different people. Exact flag names should follow the project's own CLI conventions.

```
# Ad hoc: designer mid-tuning, wants an answer in seconds
<runner> --scenario faction-spread-4p --trials 300

# Full sweep: engineer before a release
<runner> --all --report out/balance-report.json

# CI: tier-selected, baseline-compared, non-zero exit on failure
<runner> --tier pr --baseline evals/baseline.json --report out/balance-report.json --junit out/balance.xml
```

The ad hoc mode matters more than it looks. If checking a tuning change takes 40 minutes, designers stop checking; if it takes 8 seconds, they check every change and the whole system pays for itself.

Emitting JUnit XML alongside the JSON report is usually worth it — nearly every CI provider renders it natively, which gets per-scenario results into the UI for free.

## Stack mappings

The same contract, landed on common stacks. Pick whichever the project already uses.

| Stack | Manifest | Runner | Report / integration |
|-------|----------|--------|---------------------|
| **Python / pytest** | JSON or YAML in `evals/`, loaded by a fixture | Parametrize over scenarios; `multiprocessing.Pool` over trials | `--junitxml` natively; JSON report written by a session-scoped fixture |
| **TypeScript / vitest or jest** | JSON in `evals/`, imported | `test.each(scenarios)`; worker threads or child processes for trials | `--reporter=junit`; JSON written in `globalTeardown` |
| **Go** | JSON/embedded via `embed`, table-driven | Subtests per scenario, goroutines + errgroup per trial | `go test -json` piped to a converter; JSON written by `TestMain` |
| **Rust** | JSON/TOML via serde | `#[test]` per scenario or a dedicated bin target; rayon over trials | Custom harness or `cargo test -- --format json` |
| **C# / Unity** | ScriptableObject or JSON in `Resources`/`Assets/Evals` | NUnit `TestCaseSource`; batchmode `-runTests` for headless CI | NUnit XML; JSON via a custom result writer |
| **UE5 / C++** | Data table or JSON in `Content/Evals` | Automation Spec per scenario; `UE-Editor-Cmd -ExecCmds="Automation RunTests Balance"` in `-nullrhi` headless mode | Automation report + custom JSON writer; run on a commandlet for speed |
| **Godot** | JSON or Resource in `res://evals` | GUT/GdUnit test per scenario, or a headless `--script` runner | `godot --headless --script` exit code; JSON written by the script |
| **Standalone sim binary** | JSON next to the binary | The sim itself takes `--manifest`, no test framework | JSON + JUnit; CI calls the binary directly |

Two engine-specific notes worth planning around:

- **UE5 and Unity are slow to boot and heavy per-trial.** The winning move is nearly always to keep the rules simulation in plain C++/C# with no engine dependencies, test it as a plain library, and use engine automation only for the evals that genuinely need the engine. This is the "separate the rules engine from presentation" constraint arriving with a bill attached.
- **Editor-mode test runs are not headless.** Use `-nullrhi`/`-batchmode` and a commandlet or CLI target, or CI will need a GPU.

## CI recipes

### Tiering

| Tier | Trigger | Budget | Blocking |
|------|---------|--------|----------|
| `deterministic` | every PR | seconds | yes |
| `pr` | every PR | 1–3 min | yes |
| `nightly` | schedule + pre-release | unbounded | no — files an issue / posts a report |
| `manual` | on demand | unbounded | no |

### GitHub Actions

```yaml
name: balance-evals

on:
  pull_request:
  schedule:
    - cron: "0 6 * * *"

jobs:
  pr-tier:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # ... project's standard setup steps (toolchain, deps, build) ...
      - name: Run PR-tier balance evals
        run: <runner> --tier deterministic,pr --baseline evals/baseline.json --report out/report.json
      - uses: actions/upload-artifact@v4
        if: always()
        with: { name: balance-report, path: out/report.json }
      - name: Comment metric deltas
        if: always()
        run: <diff-tool> out/report.json evals/baseline.json --format markdown > out/diff.md
      # post out/diff.md as a PR comment using the project's usual mechanism

  nightly-sweep:
    if: github.event_name == 'schedule'
    runs-on: ubuntu-latest
    timeout-minutes: 180
    steps:
      - uses: actions/checkout@v4
      # ... setup ...
      - run: <runner> --all --baseline evals/baseline.json --report out/report.json
        continue-on-error: true
      - uses: actions/upload-artifact@v4
        with: { name: nightly-balance-report, path: out/report.json }
      # open or update a tracking issue on failure rather than failing the build
```

The same structure ports directly: GitLab CI (`rules:` + `artifacts:`), Jenkins (multibranch + `archiveArtifacts`), Buildkite (pipeline steps + `artifact_paths`), CircleCI (workflows + `store_artifacts`). **Use whichever the project already has.**

### Rules that keep the gate alive

- **Only the fast tiers block a merge.** A nightly sweep that blocks developers gets deleted within a month.
- **Pin the seed set in CI** so a failure reproduces locally with one command — and print that command in the failure message.
- **Cache the build, never the results.** Cached eval results silently mask regressions.
- **Post the diff, not the dump.** A five-row table of what moved gets read; a 400-line report does not.
- **Make the failure message actionable**: which metric, how much it moved, which content or commit likely caused it, and the exact command to reproduce.
- **Budget the runtime explicitly.** If the PR tier creeps past a few minutes, cut trial counts and widen bands rather than letting people learn to ignore it.

## Build order

When starting from nothing, this order gets value soonest and avoids building on sand:

1. **Determinism check** — same seed twice, identical transcript. Everything downstream depends on it.
2. **One scenario, end to end** — hardcoded, one metric, one threshold, run by hand. Proves the sim can be driven headlessly.
3. **Manifest + runner** — generalize that one scenario into data.
4. **Report + human summary** — the moment designers can read output, they start asking for scenarios.
5. **Ad hoc CLI mode** — the fast single-scenario path. This is what makes the system get used daily.
6. **Baseline + regression** — once metrics are stable enough to be worth freezing.
7. **CI wiring** — deterministic tier first, then sampled, then nightly.
8. **More scenarios** — continuously, driven by the proposal-and-review loop, forever.

Resist building 30 scenarios before step 5. A harness nobody runs interactively is a harness that rots.
