---
name: ONBOARD
description: "Codebase and project orientation pipeline for broad understanding. Ops (Bravo)
  explores the structure, Engineer (Alpha) analyzes architecture patterns, Knowledge (Charlie) retrieves project
  history and past decisions, Analyst (Delta) researches external context. Use when the user
  says '/onboard', 'get me up to speed', 'give me an overview', 'walk me through this',
  'what is this project', 'orient me', 'I'm new to this repo', or needs a high-level
  understanding of a codebase, module, or project area. For deep investigation of a
  specific topic, use /research instead."
user-invocable: true
version: 1.0.0
context: root
---

# /ONBOARD — Codebase & Project Orientation

> Zero to context. Understand the codebase, its patterns, its history, and its constraints.

## When to Use

- User is new to a codebase or a part of it
- User says `/onboard`, "get me up to speed", "explain this project"
- Before a BUILD in an unfamiliar area
- Onboarding a new team member or switching project context

## Prerequisites

Call `lightarchitects_discover` first. ONBOARD adapts:

| Siblings available | Capability |
|---|---|
| Ops (Bravo) + Engineer (Alpha) + Knowledge (Charlie) + Analyst (Delta) | Full orientation: structure + architecture + history + context |
| Ops (Bravo) + Engineer (Alpha) | Structure exploration + architecture analysis |
| Knowledge (Charlie) only | Project history and past decisions |
| None available | Manual exploration with core tools (glob, read, search) |

## Workflow

### Phase 1: SURVEY — Map the project structure

```
lightarchitects_glob pattern:"**/*.rs"    # or *.ts, *.py, etc.
lightarchitects_glob pattern:"**/Cargo.toml"  # or package.json, etc.
lightarchitects_read path:"CLAUDE.md"     # project-specific instructions
lightarchitects_read path:"README.md"     # project overview
```

If Ops (Bravo) is available:
```
lightarchitects_orchestrate → EVA action:"build" params:{
  task: "explore",
  target: "<project root>"
}
```

Ops (Bravo) DISCOVER provides a structured survey: directory tree, key files, entry points, dependency graph.

### Phase 2: ARCHITECTURE — Analyze patterns and conventions

```
lightarchitects_orchestrate → CORSO action:"chow" params:{
  path: "<project root>",
  mode: "architecture"
}
```

Engineer:Scan identifies:
- Architecture style (monolith, workspace, monorepo, microservices)
- Key patterns (error handling, dependency injection, module boundaries)
- Coding conventions (naming, file organization, test structure)
- Build system and deployment model

### Phase 3: HISTORY — Retrieve project context

```
lightarchitects_orchestrate → SOUL action:"search" params:{query: "<project name> decisions"}
```

Knowledge (Charlie) helix provides:
- Past architectural decisions and their rationale
- Known gotchas and constraints
- Key people and their roles
- Related projects and dependencies

Also check git history:
```
lightarchitects_bash command:"git log --oneline -20"  # recent activity
lightarchitects_bash command:"git shortlog -sn"        # contributors
```

### Phase 4: CONTEXT — External knowledge (optional)

If the project uses unfamiliar libraries or frameworks:
```
lightarchitects_orchestrate → QUANTUM action:"research" params:{
  query: "<library/framework used>",
  focus: "architecture patterns and conventions"
}
```

### Phase 5: BRIEF — Present the orientation

```
## Project: {name}

### What It Is
{one-paragraph description of purpose and scope}

### Structure
{directory layout with key files annotated}

### Architecture
- Pattern: {architecture style}
- Key abstractions: {main types, traits, interfaces}
- Data flow: {how data moves through the system}
- Build: {how to build, test, deploy}

### Conventions
- {naming conventions}
- {error handling pattern}
- {test organization}

### History & Context
- {key past decisions and why}
- {known constraints or gotchas}
- {related projects}

### Getting Started
- Read: {most important files to understand first}
- Run: {how to build and test locally}
- Avoid: {common mistakes for newcomers}
```

## Contract Canon Integration (Cookbook §82)

Governed by `agent.skill.onboard`. New-operator tour includes the contract canon tour: scan `standards/canon/contracts/` for kinds present, count contracts per kind, surface the alpha_gate dashboard (verdict / blocker_contract_ids / per-provider coverage). Newcomers see the canonical surface map before reading any code. Emits `skill.onboard.invoke` span with `contracts_toured` metadata. No `status_per_provider` mutations.

## Graceful Degradation

Without any siblings: use `lightarchitects_glob`, `lightarchitects_read`, `lightarchitects_search`, and `lightarchitects_bash` (git log) to build the orientation manually. The core tools are sufficient for a thorough codebase survey — siblings add depth and historical context but aren't required.
