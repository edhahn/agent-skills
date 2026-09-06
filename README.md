# Agent Skills

A collection of opinionated skills for AI coding agents. Built for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and compatible with [OpenClaw](https://github.com/anthropics/claude-code).

These are practical, production-tested skills covering game development, game balance evaluation, software architecture, executive analysis, product illustration, and more. They encode real workflows and domain expertise — not generic advice.

## Skills

| Skill | Description |
|-------|-------------|
| [concept-art](concept-art/) | Iterative concept art generation using ComfyUI (FLUX models, prompt engineering, batch workflows) |
| [corporate-vp](corporate-vp/) | Executive cabinet advisor — analyzes decisions through six C-suite lenses (CEO, COO, CFO, CMO, CPO, CTO) |
| [eval-driven-game-development](eval-driven-game-development/) | Eval-driven game balance — scenario proposals, simulation harnesses, CI balance gates, instrumentation (digital + tabletop) |
| [game-designer](game-designer/) | Professional game design — mechanics, systems, GDDs, feature specs, balancing |
| [multi-agent-chat](multi-agent-chat/) | Coordination protocol for AI agents sharing group chat channels (anti-loop, routing, token efficiency) |
| [product-illustrator](product-illustrator/) | Product renders from CAD files (CadQuery, OpenSCAD) + ComfyUI for ecommerce, manuals, and marketing |
| [software-architecture](software-architecture/) | Software architecture partner — system design, ADRs, tech specs, code review, security |
| [ue5-character](ue5-character/) | UE5 character pipeline — modeling, rigging, AnimBP, IK, Control Rig, morph targets |
| [ue5-cinematics](ue5-cinematics/) | UE5 cinematography — Sequencer, cameras, cutscenes, MRQ rendering |
| [ue5-gamedev](ue5-gamedev/) | UE5 game development — C++ coding standards, Blueprints, Remote Control API, Python bridge |
| [ue5-level-design](ue5-level-design/) | UE5 level design — world building, landscape, lighting, World Partition, streaming |
| [zenstack-v3](zenstack-v3/) | ZenStack v3 ORM — schema language, access control, CRUD API, server adapters, migrations |

## Installation

### Claude Code

Clone this repo (or add as a submodule) into your project's skills directory:

```bash
# As a git submodule (recommended — stays updated)
git submodule add https://github.com/edhahn/agent-skills.git skills/agent-skills

# Or clone directly
git clone https://github.com/edhahn/agent-skills.git skills/agent-skills
```

Claude Code discovers skills from `skills/` directories automatically. Once installed, skills trigger based on their `description` field in the YAML frontmatter — no additional configuration needed.

### OpenClaw

Same approach — clone or submodule into your workspace's `skills/` directory:

```bash
git submodule add https://github.com/edhahn/agent-skills.git skills/agent-skills
```

OpenClaw uses the same skill discovery mechanism as Claude Code.

### Linking into your agent skills folder

To use these skills globally rather than per-project, `link.sh` symlinks them into your agent skill directories — by default `~/.claude/skills` and `~/.codex/skills`. Symlinks mean edits in your clone take effect immediately, with no re-copying.

```bash
./link.sh                                   # link every skill in the repo
./link.sh game-designer software-architecture   # link only these
./link.sh --dry-run                         # print what would happen, change nothing
./link.sh --force                           # replace existing real directories
./link.sh --targets ~/.claude/skills        # override the destinations
```

Existing symlinks are repointed, so re-running is safe. Existing *real* directories are left alone unless you pass `--force`, which moves them aside to `<name>.bak.<timestamp>` rather than deleting them. Override the defaults with `CLAUDE_SKILLS_DIR` / `CODEX_SKILLS_DIR` or `--targets`.

### Cherry-picking individual skills

If you only want specific skills, copy the skill's directory into your `skills/` folder:

```bash
# Example: just the software-architecture skill
cp -r agent-skills/software-architecture skills/software-architecture
```

Skills with `references/` subdirectories need the entire directory — the main `SKILL.md` references those files.

## Customization

Many skills have sections marked for customization (infrastructure config, team roles, tool references). Look for:

- Environment variable patterns (`${COMFYUI_BASE_URL}`, `UE5_REMOTE_CONTROL_HOST`)
- Placeholder tables with generic roles
- Comments suggesting you fill in your own setup

Fork the repo and customize these for your team, or override them in your project's `CLAUDE.md`.

## Skill structure

Each skill follows the Claude Code skill format:

```
skill-name/
  SKILL.md              # Main skill file with YAML frontmatter
  references/           # Optional deeper reference docs
    topic.md
```

The `SKILL.md` frontmatter defines when the skill triggers:

```yaml
---
name: skill-name
description: >
  When to trigger this skill. Claude Code matches this against
  the current task to decide whether to invoke the skill.
---
```

## Contributing

1. **Fork** this repo
2. **Create a branch** for your skill or improvement
3. **Follow the structure**: `skill-name/SKILL.md` with YAML frontmatter (`name`, `description`)
4. **Keep it generic**: No personal infrastructure, machine names, agent names, or org-specific details. Use environment variables or placeholder comments for configurable values.
5. **Include references**: For complex skills, break deep content into `references/` files and reference them from the main `SKILL.md`
6. **Write good descriptions**: The `description` field in frontmatter is how Claude Code decides when to trigger the skill. Be specific about trigger conditions.
7. **Submit a PR** with a brief explanation of what the skill does and why it's useful

### What makes a good skill

- Encodes **real domain expertise**, not generic advice you'd find in a tutorial
- Has a clear **trigger condition** — when should Claude use this skill vs. not?
- Is **actionable** — provides workflows, templates, code patterns, and decision frameworks
- Works **standalone** — doesn't depend on proprietary tools or infrastructure
- Includes **reference files** for deep dives without bloating the main skill

### What to avoid

- Skills that are just documentation dumps (link to docs instead)
- Skills tied to a specific company's infrastructure
- Overly broad skills that try to cover everything ("programming best practices")
- Skills that duplicate Claude's built-in capabilities without adding domain expertise

## License

MIT
