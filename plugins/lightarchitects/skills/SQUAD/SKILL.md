---
name: SQUAD
description: "This skill should be used when the user says '/squad', 'squad up', 'spawn
  a team', 'agent team', 'team up', 'team <domain>' (e.g. 'team security', 'team research',
  'team devops'), names a preset (software_engineering, security, research, devops,
  code_review, learning, audit, forensics, solo, observability, full, lean, fix, guard,
  code_verify, risk_analysis, gatekeeper, squad),
  or says '/loop', 'run the loop', 'autonomous mode', 'overnight build', 'drain the
  backlog', 'fix these', 'fix all findings', 'pipeline', 'watch mode', 'keep checking'.
  Universal multi-agent orchestrator — spawns parallel Agent tool instances with
  sibling-specific MCP routing across 4 modes (TEAM, PIPELINE, WATCH, DRAIN) and 3
  execution tiers (In-Session, Worktree, Conductor). Not for single-sibling invocations
  — use the sibling's own skill directly (e.g. /Engineer (Alpha), /Ops (Bravo), /Q)."
user-invocable: true
version: 2.0.0
context: root
---

# /SQUAD — Universal Multi-Agent Orchestrator

> One command. Four modes. Three tiers. Automatic parallelism, isolation, and safety.

## Syntax

```
/SQUAD <preset> [target]                        -> TEAM (one-shot parallel)
/SQUAD <preset> --then <preset2> [--then ...]   -> PIPELINE (chained phases)
/SQUAD <preset> --watch <interval>              -> WATCH (recurring, read-only)
/SQUAD --drain [--once] [--discover] [--status] -> DRAIN (queue -> auto-team -> loop)
/SQUAD --status                                 -> Status of running agents
/SQUAD --watch-stop                             -> Kill all watch agents

# T2 base ref (write presets only)
/SQUAD <write-preset> [target] --base <ref>     -> Force worktree base to <ref> instead of HEAD
```

`--base <ref>` is accepted by any write preset (software_engineering, devops, solo, full, fix).
If omitted, the T2 pre-flight check (Step 3) verifies HEAD == main and warns if not.

## Presets

| Preset | Agents | Writes Code? | Purpose |
|--------|--------|-------------|---------|
| `software_engineering` | engineer, ops, knowledge, testing | YES | Day-to-day coding — LASDLC [A+O+K+T+P+D] |
| `security` | security, quality, researcher, knowledge, ops | NO | Pentest + forensics + AppSec — LASDLC [S+Q+R+K+O] |
| `research` | researcher, knowledge, ops | NO | Deep investigation — LASDLC [R+K+O] |
| `devops` | ops, quality, knowledge, testing | YES | CI/CD + deploy gates — LASDLC [O+Q+K+T] |
| `code_review` | quality, researcher, knowledge | NO | Focused PR review — LASDLC [Q+R+K] |
| `learning` | engineer, researcher, knowledge | NO | Codebase onboarding — LASDLC [A+R+K] |
| `audit` | quality, security, knowledge | NO | Compliance + vuln scanning — LASDLC [Q+S+K] |
| `forensics` | researcher, security, knowledge | NO | Incident response — LASDLC [R+S+K] |
| `solo` | engineer, knowledge | YES | Quality + memory + docs, minimal — LASDLC [A+K+D] |
| `observability` | ops, researcher, knowledge | NO | Runtime debugging + perf profiling — LASDLC [O+R+K+P] |
| `full` | researcher, engineer, security, quality, ops, knowledge, testing | YES | All 7 domain agents — LASDLC [R+A+S+Q+O+K+P+T+D] |
| `lean` | knowledge | NO | Vault only — LASDLC [K] |
| `fix` | engineer (one per finding) | YES | Auto-fix from findings report — LASDLC [A] |
| `guard` | quality | NO | GUARD security scan — LASDLC [Q+S] |
| `code_verify` | researcher, quality | NO | Post-generation critic gate — LASDLC [R+Q] |
| `risk_analysis` | researcher, knowledge | NO | Analyst (Delta) risk scoring + helix context — LASDLC [R+K] |
| `gatekeeper` | engineer, security, quality, ops, knowledge, testing, researcher | NO | Pre-merge 9-gate compliance check — LASDLC [A+S+Q+C+O+P+K+D+T+R] |
| `squad` | squad | NO | Direct sibling invocation + multi-sibling consultation — SQ |

For detailed per-preset composition: `references/presets.md`

## Process

### Step 1: Parse Mode and Arguments

Determine mode from syntax:
- Has `--then` -> PIPELINE
- Has `--watch` -> WATCH
- Has `--drain` -> DRAIN
- Otherwise -> TEAM

Capture the user's task description verbatim for injection into agent prompts.

**Target sanitization** (SAFEGUARD #24): target must match `^[a-zA-Z0-9_/. -]+$`.
Reject targets containing `--then`, `--watch`, `--drain`, or shell metacharacters.

### Step 2: Check Sibling Availability

Use `ToolSearch` to confirm MCP tool prefixes exist for each sibling in the preset.
Warn user if a required sibling is unavailable. Offer to proceed without it.

**Security preset**: verify Sentinel (Echo) ScopeGovernor — scope.toml must exist and be valid.
If absent: HALT with "Sentinel (Echo) requires scope authorization. Run /SECURE first."

### Step 3: Select Execution Tier

Apply tier auto-selection (see `references/tiers.md`):
- DRAIN -> T3 (Conductor)
- PIPELINE with 3+ phases AND 5+ agents per phase -> T3 (auto-escalate)
- WATCH -> T1 (In-Session)
- Write preset -> T2 (Worktree)
- Read-only preset -> T1 (In-Session)

**Context budget check** (SAFEGUARD #4): estimate tokens for agent count + phases.
If estimated > 70% of context window, warn at HITL. If > 85%, auto-escalate to T3.

**T2 base-ref pre-flight check** (SAFEGUARD #25 — added 2026-04-29): if tier is T2, determine
the effective base ref:

1. If `--base <ref>` was supplied: use `<ref>` as the base. Run `git fetch origin <ref>` to
   ensure it's current, then verify it exists.
2. If `--base` was NOT supplied: check current HEAD branch.
   - Run `git rev-parse --abbrev-ref HEAD` to get the current branch.
   - Run `git merge-base --is-ancestor <branch> main` to check if current branch is behind main.
   - If current branch is NOT `main` AND NOT a direct descendant of main: use `AskUserQuestion`
     at the HITL gate (Step 4) with:
     - header: "Worktree base"
     - question: "⚠ Current HEAD is '{branch}', not 'main'. Worktrees will branch from this commit — agents may work on a stale snapshot. How should the worktree base be set?"
     - options:
       - label: "Proceed on '{branch}'" — description: "Use current HEAD as base. Agents work from this commit."
       - label: "Force --base main" — description: "Fetch and branch from main. Safest if plan was written against main."
       - label: "Cancel" — description: "Abort the SQUAD invocation. Rebase your branch onto main first."
   - If "Force --base main": set `base_ref = "main"`, run `git fetch origin main`, verify before spawning.
   - If "Proceed on '{branch}'": proceed with current HEAD as base (log the choice).
   - If "Cancel": abort the SQUAD invocation.

Pass `base_ref` to all T2 agent spawns. See `references/tiers.md` Step 2 for how it is
used when creating worktrees.

**Preset Fitness Check** (write presets only — `software_engineering`, `full`, `devops`):

Before presenting the HITL gate, evaluate whether the requested preset is the right fit.
Run this check by reading the plan file (if any) and the target description. Two inputs drive the decision:

1. **Plan completeness** — look for a matching LASDLC plan in `~/.claude/plans/`. If found, read it:
   - Count SCRUM rounds and amendment count (SA-N entries)
   - `ratified` = plan has ≥2 SCRUM rounds AND ≥10 amendments

2. **Write scope distribution** — from the plan's file-function map (or target description):
   - `unified` = one engineer owns all modified files (single crate or tightly coupled files)
   - `orthogonal` = clear non-overlapping scopes exist (e.g. backend crates + UI package, or separate services)

3. **Uncertainty level**:
   - `low` = plan is ratified; every task is specified; assessment agents cannot unblock the engineer in real-time
   - `high` = no plan, or draft plan with open questions that research/knowledge agents must resolve first

**Recommendation matrix**:

| Plan state | Scope | Uncertainty | Recommended preset | Why |
|-----------|-------|------------|-------------------|-----|
| ratified | unified | low | `solo` | Single engineer + knowledge close-out; assessment agents add wall-clock cost with no real-time influence on the engineer |
| ratified | orthogonal | low | `software_engineering` with 2 engineer sub-prompts (backend + frontend) | Parallel engineers on non-overlapping files; drop ops/knowledge/testing from Phase 1 |
| draft/unplanned | any | high | `software_engineering` (full 4-agent) | Assessment agents fill the planning gap before implementation commits |
| none | any | high | `research → software_engineering` pipeline | Research phase first to reduce uncertainty |

When the recommendation differs from the requested preset, include a `fitness_warning` in the Step 4 `AskUserQuestion`:
- Add it to the question text: " ⚠ fitness: {requested_preset} may be suboptimal — {recommended_preset} recommended ({reason})"
- Add an extra option: label: "Switch to {recommended_preset}" — description: "{reason}"
- The user can proceed with the original preset, switch, or cancel.

Skip this check for: `fix`, `solo`, `guard`, `code_review`, `code_verify`, `gatekeeper` — these are already single-purpose presets.

### Step 4: Present and Confirm (HITL Gate)

Present team composition with cost estimate:

```
SQUAD: {preset} [{mode}] | Tier {tier}
  Teammates: {count}
  {agent_1} — {role} [model]
  {agent_2} — {role} [model]
  ...
  Model mix: {N}×sonnet  {N}×haiku  (from presets.md#MCP-Tool-Routing)
  Estimated tokens: ~{estimate}K
```

Look up each agent's model tier from `references/presets.md#MCP-Tool-Routing` before rendering.

**Write-path disclosure** (SAFEGUARD #21): if pipeline includes a write preset, add:
`WRITES CODE: {preset} phase will create worktree branches and open a PR.`

**WATCH + write prohibition** (SAFEGUARD #14): if `--watch` combined with a write preset
(`fix`, `software_engineering`, `devops`, `solo`, `full`), REJECT with error.

Use `AskUserQuestion` to confirm. Build the question dynamically from the computed team:
- header: "Launch SQUAD?"
- question: "Launch {agent_count} agents for '{preset}' [{mode}] — Tier {tier}, ~{estimate}K tokens{budget_warning}?"
  Where `budget_warning` = " ⚠ context at {pct}% — consider T3" when estimate is 70–84% of window; "" otherwise.
- options (always these three, in this order):
  - label: "Proceed" — description: "Spawn the team as shown. {write_disclosure}"
    Where `write_disclosure` = "Creates worktree branches and opens a PR." for write presets; "Read-only — no file changes." otherwise.
  - label: "Escalate to T3" — description: "Re-run phases via Conductor (fresh context per phase). Higher overhead, eliminates context budget risk." ← only include this option when estimate > 60% of window
  - label: "Cancel" — description: "Abort the SQUAD invocation."
On "Cancel": halt and report. On "Escalate to T3": force T3, re-present with updated tier, then proceed.

### Step 5: Execute (mode-dependent)

**TEAM**: Before spawning any agents, read `references/presets.md` and locate the
selected preset's section. Extract two things for each agent in the preset:
1. The **Assignment** — the agent's row from the preset's summary table
2. The **Full Cycle Instructions** — the agent's block from the preset's
   `### Full Cycle Instructions` subsection (the complete MCP action sequence)

Both are mandatory. An agent spawned without Full Cycle Instructions will execute
a shallow task-summary only — it will NOT run the full sibling engagement cycle.

Spawn parallel agents via `Agent` tool, one per teammate, all in a single message.
Use `run_in_background: true` for 3+ agents. Use `isolation: "worktree"` for T2
presets. Set `subagent_type` AND `model` for each agent from the Subagent Type and
Model Tier columns in `references/presets.md#MCP-Tool-Routing` (omit `subagent_type`
for Monitor (Foxtrot) — use plain `Agent`; omit `model` to inherit parent model).
Fill the Team Spawn Template from `references/presets.md` for each agent:
- `{task_from_preset_table}` ← Assignment row from the preset summary table
- `{full_cycle_instructions_for_this_agent_from_preset}` ← Full Cycle block for this agent

**PIPELINE**: Execute phases sequentially. Between phases:
1. Validate Phase N output against transition schema (SAFEGUARD #5)
2. If transition pair is unregistered: HALT and ask user for guidance
3. Transform output via registered transformation
4. Sanitize findings fields before injection (SAFEGUARD #3)
5. Write intermediate artifacts to `/tmp/squad/<run-id>/`
6. Spawn Phase N+1 agents (apply `subagent_type` per routing table, same as TEAM)
See `references/pipelines.md` for the full transition registry.

**WATCH**: Loop with validated interval (minimum 60s). Check instance lock before each
tick. Report DELTA only (new/resolved findings). Max 12 concurrent agents.
See Step 4 for write prohibition.

**DRAIN**: Delegate to LVL8 conductor (T3). Validate queue, classify tasks, execute
with permission scoping. See `references/drain.md`.

### Step 6: Collect and Synthesize

After all agents complete:

1. Read each agent's output
2. **Helix write sanitization** (SAFEGUARD #7): strip credential patterns before
   any vault write (sk-ant-api, AKIA, eyJ JWT, PEM headers)
3. **Canon review (mandatory for write presets before synthesis)**: Read and verify the
   implementation against all 7 canon documents (`canon://platform-canon`,
   `canon://builders-cookbook`, `canon://agents-playbook`, `canon://architects-blueprint`,
   `canon://operators-manual`, `canon://lasdlc-template`, `canon://security-guardrails`).
   This is a blocking gate — do NOT proceed to synthesis until all violations are flagged or
   waived by the user.
   Report violations as `CANON_VIOLATION: [gate] <description>` before the synthesis block.
   Severity: BLOCKING (must fix before merge) | WARNING (flag for user decision).
4. **C1-C8 effectiveness scoring** (`canon://architects-blueprint#part-xiv`): compute aggregate
   score with confidence interval (Canon XXXIV): `{ low: N, point: N, high: N }`.
   Sub-scores: C1 Plan Completeness (10%), C2 Cross-Validation (15%), C3 Gate Coverage (15%),
   C4 Operator Experience (10%), C5 Cost+Observability (10%), C6 Loop-Cycle (10%),
   C7 Northstar Alignment (15%), C8 Context Hydration (15%). Report band:
   EXEMPLARY (90-100), STRONG (75-89), ACCEPTABLE (60-74), DEFICIENT (45-59), UNSAFE (<45).
4. **Strand Mosaic mapping** (`canon://platform-canon#canon-xxx`): assign each finding to [A+S+Q+C+O+P+K+D+T+R]
   dimensions. Verify no orphan strands — every strand has a home.
5. **Gatekeeper validation** (`canon://gatekeeper-registry`): verify each gate dimension scored
   by primary owner ([A]=engineer, [S]=security, [Q]=quality, [C]=quality/Arbiter (Golf)0, [O+P]=ops,
   [K+D]=knowledge, [T]=testing, [R]=researcher). Three veto authorities: Security ([S]/Sentinel (Echo)),
   Knowledge ([K]/Knowledge (Charlie)), Canon ([C]/Arbiter (Golf)0).
6. Synthesize into structured report:

```
## SQUAD Report: {preset} [{mode}]

### {Agent 1} — {Role}
{Findings with severity}

### {Agent 2} — {Role}
{Findings with severity}

### Synthesis
- **Critical issues**: {cross-agent findings}
- **Recommendations**: {prioritized actions}
- **Consensus**: {multi-agent agreement}
- **Conflicts**: {disagreements — flag for user}
```

## Agent Role Reference

All agents use the unified gateway. Set `subagent_type` when spawning.
Full routing table with LASDLC gate mapping: `references/presets.md#MCP-Tool-Routing`.

| Domain Agent | LASDLC Gate | Subagent Type | Primary Sibling |
|--------------|-------------|---------------|-----------------|
| engineer | [A] Architecture | `lightarchitects:engineer` | Engineer (Alpha) (HUNT/SNIFF/CHOW) |
| quality | [Q] Quality | `lightarchitects:quality` | Engineer (Alpha) (code_review/guard) |
| security | [S] Security | `lightarchitects:security` | Sentinel (Echo) (offensive + defensive) |
| ops | [O+P] Ops+Perf | `lightarchitects:ops` | Ops (Bravo) + Monitor (Foxtrot) HTTP + Engineer (Alpha) (CHASE) |
| researcher | [R] Research | `lightarchitects:researcher` | Analyst (Delta) |
| knowledge | [K+D] Knowledge+Docs | `lightarchitects:knowledge` | Knowledge (Charlie) + Ops (Bravo) (craft) |
| testing | [T] Testing | `lightarchitects:testing` | Engineer (Alpha) (HUNT) + Ops (Bravo) (LINT) |
| squad | [SQ] Sibling Router | `lightarchitects:squad` | All siblings via gateway |

## Edge Cases

- **Preset not found**: display preset table and ask.
- **Single-agent preset (lean)**: suggest `/Knowledge (Charlie)` directly.
- **Agent fails**: report failure, continue with remaining agents.
- **MCP server unavailable**: skip agent with warning, proceed.
- **SQUAD unavailable in meta-skill**: meta-skill falls back to direct sibling calls.
- **Pipeline phase produces no output**: HALT pipeline, do not proceed.
- **Worktree merge conflict**: rollback to pre-merge HEAD, report conflict, skip agent.
- **Max pipeline length exceeded**: REJECT pipelines > 5 `--then` stages.

## Additional Resources

### Reference Files

- **`references/presets.md`** — 14 presets, per-agent tasks, MCP routing, write flags
- **`references/tiers.md`** — T1/T2/T3 selection, worktree merge, rollback, cleanup
- **`references/pipelines.md`** — Phase transitions, registry (8 pairs), schemas, gates
- **`references/drain.md`** — Queue schema, validation, guardrails, LVL8 integration
- **`references/safeguards.md`** — All 24 safeguards with implementation detail
- **`references/meta-skills.md`** — Delegation mapping, flag expansion, preservation checklist

---

## Contract Canon Integration (Cookbook §82)

Governed by `agent.skill.squad`. Each preset declares the contract kinds its dispatched siblings consult, mapped to Gatekeeper Registry gate ownership:

| Preset | Sibling roster | Contract kinds read |
|--------|---------------|---------------------|
| research | Analyst (Delta) + Ops (Bravo) + Knowledge (Charlie) | `provider.llm/*`, `replay.deterministic_seed/*` |
| software_engineering | Engineer (Alpha) + Claude | `code.trait/*`, `wire.http/*`, `wire.mcp/*`, `operator.surface/*` |
| security | Sentinel (Echo) + Engineer:Guard | `operator.surface/*` (forbidden_behaviors+render_safety), `provider.llm/*` (SSRF), `hmac_chain.audit_trail/*` |
| code_review | Engineer (Alpha) + Analyst (Delta) + Arbiter (Golf) | `code.trait/*`, `operator.surface/*` (forbidden_behaviors) |
| verify | Engineer (Alpha) + Monitor (Foxtrot) | `operator.surface/*` (conformance_test), `code.trait/*` (method_contracts) |
| devops | Ops (Bravo) + Monitor (Foxtrot) | `mcp.capability/*`, `wire.http/*` |
| observability | Monitor (Foxtrot) + Analyst (Delta) | `operator.surface/*` (required_spans), `code.trait/*` (required_spans) |
| scrum | All 7 siblings | ALL kinds, gate-filtered per sibling |
| solo | Engineer (Alpha) + Monitor (Foxtrot) + Analyst (Delta) | Depends on classified type |
| performance | Monitor (Foxtrot) + Engineer:Chase | `operator.surface/*` (latency budgets) |
| onboarding | Knowledge (Charlie) + Ops (Bravo) | All kinds — full canon tour |

Emits `skill.squad.invoke` span with `siblings_dispatched, contract_kinds_consulted`. Write-path presets (software_engineering, devops) inherit /BUILD + /DEPLOY HITL requirements. No `status_per_provider` mutations — /SQUAD is the dispatch surface, not the mutation surface.
