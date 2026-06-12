# Execution Tiers

SQUAD selects one of three execution tiers based on the mode, preset, and resource budget.
Each tier trades context sharing for isolation. Higher tiers are safer but heavier.

---

## T1: In-Session

**Engine**: `Agent` tool with `run_in_background`
**Context**: Shared context window (agents read the same state)
**Isolation**: None. Agents are read-only.
**Use when**: The preset does not write code.

Spawn all agents in a single message for parallel execution. Each agent returns a synthesis
report. The orchestrator merges reports into a single output.

### Read-Only Presets (T1 default)

| Preset | Rationale |
|--------|-----------|
| security | Assessment only (Sentinel (Echo) scan, Engineer:Guard, Analyst (Delta) CVE research) |
| research | Investigation, no file writes |
| code_review | Review existing code, no modifications |
| learning | Codebase exploration and onboarding |
| audit | Compliance gap analysis |
| forensics | Incident response and evidence chain |
| observability | Runtime diagnostics and trace analysis |
| lean | Vault queries only |

T1 agents must not use `Write`, `Edit`, `Bash` (write commands), or `git commit`. If an
agent attempts a write operation, the orchestrator rejects the task and reports the violation.

---

## T2: Worktree

**Engine**: `Agent` tool with `isolation: "worktree"`
**Context**: Each agent gets its own git worktree and branch
**Isolation**: Git branch per agent. File writes are confined to the worktree.
**Use when**: The preset writes code.

### Write Presets (T2 default)

| Preset | Rationale |
|--------|-----------|
| software_engineering | Feature implementation, refactoring |
| devops | CI config, deploy scripts, Makefile changes |
| solo | Single-agent quality-gated implementation |
| full | All 6 agents including write-capable ones |
| fix | One agent per finding, each writes a targeted fix |

### Branch Naming

Each agent works on a branch named:

```
squad/<preset>/<agent-name>
```

Examples: `squad/fix/corso-guard-1`, `squad/software_engineering/eva-devops`.

After all agents complete, the orchestrator merges branches into a final branch:

```
squad/<pipeline-name>/merged
```

### Worktree Merge Strategy

Follow this sequence exactly. Every step is mandatory.

**Step 1 -- Pre-flight conflict detection (SAFEGUARD #13)**

Before spawning T2 agents, run `git merge-tree` against the base branch for each agent's
anticipated file scope. Compare file lists across agents. If two or more agents will modify
the same file, warn the user at the HITL gate:

```
WARNING: Agents {A} and {B} both target {file}. Merge conflicts likely.
Proceed? [y/N]
```

Do not suppress this warning. The user decides whether to proceed, re-scope agents, or
serialize the conflicting agents.

**Step 2 -- Spawn agents in parallel worktrees**

Create one git worktree per agent. Branch from `base_ref` (resolved in SKILL.md Step 3):

```bash
# base_ref = explicit --base value, OR current HEAD (with warning if not main)
git worktree add /tmp/squad/<run-id>/<agent-name> \
  -b squad/<preset>/<agent-name> <base_ref>
```

If `base_ref` is a remote branch (e.g., `origin/main`), fetch before creating the worktree:
```bash
git fetch origin main
git worktree add /tmp/squad/<run-id>/<agent-name> \
  -b squad/<preset>/<agent-name> origin/main
```

Inject `base_ref` into each agent's prompt under `## Context`:
```
Base ref: {base_ref}
(Worktree branched from this commit. Your changes go on top of this state.)
```

This allows agents to reason about what they're modifying relative to the intended base,
and surfaces mismatches between the plan (written against main) and the worktree (off a
feature branch).

Agents execute their tasks within their worktree. They cannot see or modify other agents'
worktrees.

**Step 3 -- Sequential merge by agent priority**

After all agents complete, merge their branches into the final branch in priority order
(agent #1 first, last agent last). Priority order comes from the preset table in
`presets.md`.

For each agent branch:

a. Capture the current HEAD before the merge (SAFEGUARD #9):

```bash
HEAD_BEFORE=$(git rev-parse HEAD)
```

b. Attempt the merge:

```bash
git merge squad/<preset>/<agent-name> --no-ff -m "squad: merge <agent-name>"
```

c. Run quality gates:

```bash
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
```

d. If the merge fails OR any quality gate fails, rollback immediately:

```bash
git reset --hard $HEAD_BEFORE
```

Report which agent failed and which gate (merge conflict, fmt, clippy, or test). Skip
this agent's changes. Continue to the next agent.

e. If the merge and all quality gates pass, proceed to the next agent.

**Step 4 -- Final branch and PR**

The resulting branch is `squad/<pipeline-name>/merged`. Create a PR from this branch.
Never auto-merge to main. The PR body includes:

- Which agents merged successfully
- Which agents were rolled back and why
- Quality gate results per agent
- Total diff stats

**Step 5 -- Cleanup (SAFEGUARD #10)**

After the PR is created (success or failure), remove all worktrees and delete all agent
branches:

```bash
git worktree remove /tmp/squad/<run-id>/<agent-name> --force
git branch -d squad/<preset>/<agent-name>
```

Also remove the worktree entries from `/tmp/squad/<run-id>/branches.txt`. If branch
deletion fails (e.g., unmerged changes from a rolled-back agent), use `git branch -D` and
log the forced deletion.

---

## T3: Conductor

**Engine**: LVL8 binary spawning fresh Claude Code sessions
**Context**: Fresh context window per task. No context sharing between tasks.
**Isolation**: Full process isolation. Each task is a separate OS process.
**Use when**: Queue drain, overnight runs, tasks exceeding 30 minutes, or crash recovery.

### Automatic Selection

T3 is selected when:

- Mode is DRAIN (always T3)
- Pipeline has 3+ phases AND any phase has 5+ agents (auto-escalation, SAFEGUARD #4)
- A task exceeds 30 minutes wall time
- Crash recovery is needed (LVL8 restarts failed tasks)

### LVL8 Integration

Each task is dispatched to the LVL8 conductor, which:

1. Spawns a fresh Claude Code session
2. Injects the task prompt with explicit recursion guard ("Do NOT invoke /SQUAD, /LOOP,
   or --drain")
3. Enforces wall time (30 min default), retry limit (3 attempts), and gutter detection
4. Creates a `lvl8/<task-id>` branch for code changes
5. Creates a PR on completion (never auto-merges)
6. Persists significant findings to the Knowledge (Charlie) helix

### Permission Scoping (SAFEGUARD #1)

| Task Source | Preset Type | Permissions |
|-------------|-------------|-------------|
| Manual | Read-only | `--dangerously-skip-permissions` allowed |
| Manual | Write | `--dangerously-skip-permissions` allowed |
| External (github-issues, cargo-audit, quality-sweep) | Any | `--print` only. No `--dangerously-skip-permissions`. |

External-source tasks always require tool call confirmation. This prevents automated
pipelines from executing arbitrary code without human review.

---

## Tier Auto-Selection Logic

Apply these rules in order. First match wins.

```
1. if mode == DRAIN:
       tier = T3

2. if mode == PIPELINE and phases >= 3 and max_agents_per_phase >= 5:
       tier = T3                          # SAFEGUARD: auto-escalate large pipelines

3. if mode == WATCH:
       tier = T1                          # Watch repeats read-only teams

4. if preset.writes_code:
       tier = T2

5. else:
       tier = T1
```

### Pipeline Auto-Escalation Rule

Pipelines with 3 or more phases where any single phase spawns 5 or more agents auto-escalate
to T3. Each phase gets a fresh context window via the LVL8 conductor. This prevents context
exhaustion in large multi-phase operations.

Example: `/SQUAD research --then software_engineering --then guard --then code_review` with
a `software_engineering` phase spawning 5+ agents triggers T3.

### Manual Override

The user may force a specific tier at the HITL gate. The orchestrator presents the
auto-selected tier and allows override:

```
Auto-selected: T2 (Worktree) — preset writes code
Override? [enter to accept, or type T1/T3]
```

Overriding to a lower tier (e.g., T1 for a write preset) requires explicit confirmation
with a risk acknowledgment.

---

## Context Budget Thresholds (SAFEGUARD #4)

Track estimated token usage across agents and phases. Use these thresholds:

| Threshold | % of Context Window | Action |
|-----------|---------------------|--------|
| Normal | < 70% | Proceed without warning |
| Warning | 70% -- 84% | Warn user at HITL: "Estimated token usage: {N}% of context window. Consider reducing agent count or escalating to T3." |
| Auto-Escalate | >= 85% | Force escalation to T3. Each phase gets a fresh context window. Inform user: "Context budget exceeded 85%. Escalating to T3 (Conductor)." |

Token estimation formula per phase:

```
estimated_tokens = (agent_count * avg_tokens_per_agent) + orchestrator_overhead
```

Where `avg_tokens_per_agent` = 15,000 (conservative estimate accounting for tool calls,
file reads, and synthesis) and `orchestrator_overhead` = 10,000 (spawn instructions,
collection, final synthesis).

For pipelines, sum across all phases. Context reuse between T1/T2 phases means tokens
accumulate. T3 phases reset the counter.

---

## Intermediate Artifact Persistence

Every SQUAD run persists phase outputs to disk. This survives context eviction, session
crashes, and enables cross-phase data transfer.

### Directory Structure

```
/tmp/squad/<run-id>/
    phase-1-output.json         # Structured output from phase 1
    phase-2-output.json         # Structured output from phase 2
    phase-N-output.json         # One file per phase
    branches.txt                # All created git branches (for cleanup)
    manifest.json               # Run metadata: mode, tier, preset, timestamps, status
```

### Run ID Format

```
<pipeline-name>-<YYYYMMDD>-<HHMMSS>
```

Example: `security-fix-review-20260331-143022`

### Manifest Schema

```json
{
  "run_id": "security-fix-review-20260331-143022",
  "mode": "PIPELINE",
  "tier": "T2",
  "phases": ["security", "fix", "code_review"],
  "started_at": "2026-03-31T14:30:22Z",
  "status": "in_progress",
  "current_phase": 2,
  "agents": {
    "phase-1": ["seraph", "corso", "quantum", "soul", "ayin"],
    "phase-2": ["fix-agent-1", "fix-agent-2", "fix-agent-3"]
  }
}
```

### Cleanup

Artifacts in `/tmp/squad/` persist until the session ends or the user runs
`/SQUAD --cleanup`. Do not delete artifacts automatically -- they are the crash recovery
mechanism. On session start, check for incomplete runs (status != "completed") and offer
to resume or discard.
