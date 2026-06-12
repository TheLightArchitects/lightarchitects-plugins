# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Plugin marketplace aggregator for the lightarchitects platform. All skills, agents, and hooks for the squad.

GitHub: [`TheLightArchitects/light-architects-plugins`](https://github.com/TheLightArchitects/light-architects-plugins)

---

## Directory Structure

```
plugins/lightarchitects/
├── skills/                    # User-invocable skills (meta-skills + domain skills)
│   ├── BUILD/SKILL.md         # Feature build pipeline
│   ├── SQUAD/SKILL.md         # Universal multi-agent orchestrator
│   ├── SCRUM/SKILL.md         # Squad review & discussion
│   ├── SECURE/SKILL.md        # Security scanning
│   ├── OBSERVE/SKILL.md       # Runtime debugging
│   ├── VERIFY/SKILL.md        # Test execution
│   ├── DEPLOY/SKILL.md        # Deploy pipeline
│   ├── REVIEW/SKILL.md        # Code review
│   ├── OPTIMIZE/SKILL.md      # Performance optimization
│   ├── ONBOARD/SKILL.md       # Developer onboarding
│   ├── ENRICH/SKILL.md        # Helix enrichment
│   ├── PLAN/SKILL.md          # Draft build plans
│   ├── RESEARCH/SKILL.md      # Investigation
│   ├── REFLECT/SKILL.md       # Retrospective
│   ├── CODE-VERIFY/SKILL.md   # Post-generation critic gate
│   ├── RISK-ANALYSIS/SKILL.md # QUANTUM risk scoring
│   ├── USING-SKILLS/SKILL.md  # Skill usage guide
│   ├── khadas-ops/SKILL.md    # Khadas ARM64 operations
│   ├── ml-training-preflight/SKILL.md  # ML training pre-flight
│   ├── corso/                 # CORSO domain skills (deprecated, use lightarchitects:*)
│   ├── soul/                  # SOUL domain skills
│   └── seraph/                # SERAPH domain skills
├── agents/                    # Agent definitions and presets
│   └── squad/                 # SQUAD team compositions
├── hooks/                     # Git hooks and automation
│   ├── pre-commit-build-registry.sh
│   ├── auto-play-voice.sh
│   └── ...
└── references/                # Skill reference documentation
    ├── presets.md             # Preset-to-team mapping
    ├── pipelines.md           # Phase transition registry
    └── ...
```

---

## Skill Creation Workflow

### 1. Create Skill Skeleton

```bash
mkdir -p plugins/lightarchitects/skills/{SKILL_NAME}
touch plugins/lightarchitects/skills/{SKILL_NAME}/SKILL.md
```

### 2. Add Frontmatter (Mandatory)

```yaml
---
name: {SKILL_NAME}
description: "{One-line description — appears in skill discovery}"
user-invocable: true|false
version: 1.0.0
context: root|fork
---
```

| Field | Values | Purpose |
|-------|--------|---------|
| `user-invocable` | `true`/`false` | Can user call via `/SKILL_NAME` or internal only |
| `context` | `root` (full context) / `fork` (isolated context) | Agent context isolation |
| `agent` | Agent name (if fork context) | Which agent owns this skill |

### 3. Define Protocol

Skills follow a step-based protocol. Each step:
- Has clear entry/exit criteria
- Uses MCP tools via `mcp__plugin_lightarchitects_lightarchitects__tools`
- Includes HITL gates (`AskUserQuestion`) for user decisions
- Logs to SOUL vault if significance ≥7.0

### 4. Domain Agent Routing

All skills route through the lightarchitects gateway. Use `Agent` tool with `subagent_type`:

| Domain Agent | `subagent_type` | LASDLC Gate | Industry Baselines |
|-------------|-----------------|-------------|-------------------|
| engineer | `lightarchitects:engineer` | [A] Architecture | `helix/corso/industry-baselines.md` |
| quality | `lightarchitects:quality` | [Q] Quality + [C] Canon | `helix/corso/` + `helix/laex0/industry-baselines.md` |
| security | `lightarchitects:security` | [S] Security | `helix/seraph/industry-baselines.md` |
| ops | `lightarchitects:ops` | [O+P] Ops+Perf | `helix/eva/` + `helix/ayin/industry-baselines.md` |
| researcher | `lightarchitects:researcher` | [R] Research | `helix/quantum/industry-baselines.md` |
| knowledge | `lightarchitects:knowledge` | [K+D] Knowledge+Docs | `helix/soul/industry-baselines.md` |
| testing | `lightarchitects:testing` | [T] Testing | `helix/corso/industry-baselines.md` |
| squad | `lightarchitects:squad` | [SQ] Router | All siblings via gateway |

**Industry Baseline Requirement**: Every agent dispatch MUST include instructions to read the domain's `industry-baselines.md` file and cite per Canon XXXV (verbatim quotes from primary sources).

### 5. Validate Skill

Run the plugin validator:

```bash
# Via skill
/plugin-dev:plugin-validator

# Or manual checks
- Frontmatter complete (name, description, user-invocable, version, context)
- Protocol steps defined
- MCP tool routing correct (all via lightarchitects gateway)
- Industry baselines referenced for domain agents
- HITL gates present for user decisions
- Logging protocol defined (when to write to SOUL vault)
```

---

## Plugin Cache

Skills are cached at `~/.claude/plugins/cache/light-architects/lightarchitects/1.0.0/skills/`.

Symlinks from plugin marketplace to cache:
```
~/.claude/plugins/cache/light-architects → ../../../../Projects/light-architects-plugins/
```

After editing skills, the cache auto-syncs via git hooks. No manual sync needed.

---

## Git Hooks

| Hook | Purpose | Location |
|------|---------|----------|
| `pre-commit-build-registry.sh` | Validates skill changes against build registry | `hooks/` |
| `auto-play-voice.sh` | Plays TTS audio from soul:voice/soul:speak responses | `hooks/` |

Hooks are registered in `~/.gitconfig` or project `.git/config`.

---

## Relationship to lightarchitects Plugin

This plugin marketplace (`light-architects-plugins/`) provides the skill definitions that the `lightarchitects` MCP plugin (`mcp__plugin_lightarchitects_lightarchitects__tools`) executes.

**Flow**:
```
User invokes /SKILL → lightarchitects MCP gateway → reads skill from cache → executes protocol
```

The gateway binary (`~/.lightarchitects/bin/lightarchitects`) serves skills from the cache directory.

---

## Key Conventions

1. **No direct sibling tool calls** — All sibling invocations route through `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling:` + `action:` params
2. **Industry baselines mandatory** — Domain agents must read their `industry-baselines.md` and cite per Canon XXXV
3. **HITL for decisions** — Use `AskUserQuestion` for all user-facing decisions (never assume)
4. **Log significant work** — Write to SOUL vault via `sibling: "soul"`, `action: "write_note"` when significance ≥7.0
5. **Parallel dispatch** — Launch independent agents in one message for parallel execution
6. **Ground-truth verification** — After multi-agent runs, Read canonical output files directly before reporting

---

## Testing Skills

Skills are tested via execution. For new skills:

1. **Dry run**: `/SKILL_NAME --dry-run` (if supported) to validate protocol without mutations
2. **Test invocation**: Run on a safe target (e.g., test file, sandbox directory)
3. **Verify logging**: Check SOUL vault for helix entry at `helix/{sibling}/entries/`
4. **Verify gates**: Confirm HITL gates trigger correctly

---

## Deployment

Skills deploy automatically when committed to the `light-architects-plugins` repo. The gateway pulls from the cache on next invocation.

To force cache refresh:
```bash
# Clear cache
rm -rf ~/.claude/plugins/cache/light-architects/

# Reconnect MCP
/mcp
```

---

## Per-project documentation

Each MCP server has its own CLAUDE.md. Consult when working in that project:

**Core MCP**: `../CORSO/MCP/CORSO-DEV/CLAUDE.md` · `../EVA/MCP/EVA-DEV/eva/CLAUDE.md` · `../SOUL/SOUL-DEV/CLAUDE.md` · `../QUANTUM/MCP/QUANTUM-DEV/README.md` · `../SERAPH/MCP/SERAPH-DEV/CLAUDE.md` · `../AYIN/AYIN-DEV/CLAUDE.md`

**SDK**: `../SERAPH/SDK/SERAPH-SDK-DEV/CLAUDE.md` · `../lightarchitects-sdk/CLAUDE.md`

**Standards**: `~/lightarchitects/soul/helix/user/standards/` (Builders Cookbook, Platform Canon, etc.)
