# SQUAD Drain Reference

> DRAIN mode: queue → classify → team-per-task → loop. Absorbs `/LOOP`. T3 (Conductor via LVL8).

---

## Overview

DRAIN mode delegates to the LVL8 autonomous conductor (T3). Each task gets a fresh Claude Code session — full process isolation, independent context window, crash recovery. This is the right tool for: overnight runs, backlog drains, long-running builds (>30 min), and any autonomous write operations.

```
/SQUAD --drain              # Process entire queue
/SQUAD --drain --once       # Process one task and stop
/SQUAD --drain --discover   # Run discovery scripts, then drain
/SQUAD --drain --status     # Show queue state (pending, running, done, failed)
```

**Why DRAIN ≠ WATCH**: WATCH runs the same read-only team repeatedly in-session (T1). DRAIN runs write operations with full T3 isolation per task. Mixing `--watch` + write presets is prohibited (SAFEGUARD #14). Autonomous write loops go through DRAIN.

---

## Task Queue Schema

Tasks live in LVL8's `queue.json` file, governed by `allowed_projects` in `~/.lightarchitects/config.toml`.

```json
{
  "id": "gh-soul-42",
  "title": "Fix helix query timeout on large vaults",
  "project": "Knowledge (Charlie)/Knowledge (Charlie)-DEV",
  "prompt": "The helix query times out when the vault exceeds 5000 entries...",
  "status": "pending",
  "source": "github-issues",
  "priority": "high",
  "preset": "software_engineering",
  "pipeline": null,
  "depth": 0
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique task identifier |
| `title` | string | Human-readable summary |
| `project` | string | Project path (must match `allowed_projects` in config) |
| `prompt` | string | Task instructions (max 4096 chars) |
| `status` | enum | `pending \| running \| done \| failed \| quarantined` |
| `source` | enum | `manual \| github-issues \| cargo-audit \| quality-sweep \| helix` |
| `priority` | enum | `critical \| high \| medium \| low` |
| `preset` | string | SQUAD preset to use (whitelist-validated) |
| `pipeline` | array or null | Optional `--then` chain (e.g. `["guard", "code_review"]`) |
| `depth` | u8 | Recursion depth counter — default 0, max 2 |

### Valid Preset Whitelist

Only these values are accepted in the `preset` field:

```
software_engineering, security, research, devops, code_review,
learning, audit, forensics, solo, observability, full, lean, fix, guard
```

Any other value: task is rejected as `INVALID_PRESET`.

---

## Task Validation (SAFEGUARD #2)

Every task must pass all validation checks before entering the execution queue. Validation happens at:
1. Task ingestion time (when `--discover` runs or tasks are added manually)
2. Execution time (re-validated immediately before LVL8 spawns the session)

### Validation Rules

**1. Preset whitelist check**
```
preset: "software_engineering"  ✅ VALID
preset: "hack_everything"       ❌ REJECTED — not in whitelist
```

**2. Project allowlist check**
```
project: "Knowledge (Charlie)/Knowledge (Charlie)-DEV"        ✅ VALID (in allowed_projects)
project: "/etc/passwd"          ❌ REJECTED — not in allowlist
project: "../../../secret"      ❌ REJECTED — path traversal
```

**3. Prompt length check**
```
prompt.len() <= 4096  ✅ VALID
prompt.len() > 4096   ❌ REJECTED — exceeds cap
```

**4. Recursion pattern check** (SAFEGUARD #6)
```
prompt contains "/SQUAD"   ❌ REJECTED
prompt contains "--drain"  ❌ REJECTED
prompt contains "/LOOP"    ❌ REJECTED
```

These patterns indicate a task that would spawn another DRAIN session, creating a recursion loop.

**5. Depth check**
```
depth == 0  ✅ VALID (normal task)
depth == 1  ✅ VALID (sub-task)
depth == 2  ✅ VALID (final allowed depth — cannot spawn further)
depth >= 3  ❌ REJECTED
```

**Rejection behavior**: Invalid tasks are reported to the user with a specific error code. They are NOT silently dropped. They are marked as `failed` with the validation error stored in `failure_reason`.

---

## Discovery (--discover)

Discovery scripts populate the task queue from external sources. Each script produces tasks conforming to the queue schema.

| Source | Discovery Mechanism | Auto-Preset |
|--------|--------------------|----|
| `github-issues` | `gh issue list --label bug,feature` | `bug` → `solo`, `feature` → `software_engineering` |
| `cargo-audit` | `cargo audit --json` | Any CVE → `security` |
| `quality-sweep` | `cargo clippy --message-format json` | Any warning → `code_review` |
| `helix` | Knowledge (Charlie) helix pending tasks | As tagged in helix entry |
| `manual` | User-added directly | As specified |

Discovery does NOT auto-execute. After `--discover`, SQUAD shows the populated queue at the HITL gate before any execution begins.

---

## Permission Scoping (SAFEGUARD #1)

LVL8 selects the Claude Code invocation mode based on task source AND preset:

| Source | Preset | Permission Mode |
|--------|--------|----------------|
| `manual` | read-only (security, research, code_review, audit, etc.) | `--dangerously-skip-permissions` allowed |
| `manual` | write (software_engineering, fix, devops, etc.) | Standard (tool confirmations enabled) |
| `github-issues` | any | `--print` only — NO `--dangerously-skip-permissions` |
| `cargo-audit` | any | `--print` only — NO `--dangerously-skip-permissions` |
| `quality-sweep` | any | `--print` only — NO `--dangerously-skip-permissions` |

**Rationale**: External sources (GitHub, cargo audit, quality sweep) are outside the user's direct control. A crafted issue title or advisory description could inject instructions into the task prompt. Requiring tool confirmation for all external-source tasks limits the blast radius.

---

## Queue Mutation Lock (SAFEGUARD #8)

LVL8 acquires an exclusive lock on `queue.json` for the duration of each task execution using `fs2::FileExt::try_lock_exclusive()`.

**What this prevents**: An executing session from modifying the queue (e.g., adding new tasks as a side effect of running `/SQUAD --drain` internally).

**Post-execution diff**: After each task completes, LVL8 diffs `queue.json` against a pre-execution snapshot. Any new tasks that appeared during execution are:
1. Moved to `status: "quarantined"`
2. Reported to the user with: "Task {id} was added during execution of {parent-task-id}. Approve to add to queue."

The user must explicitly approve quarantined tasks before they can execute.

---

## Recursion Prevention (SAFEGUARD #6)

Four interlocking layers prevent recursive DRAIN loops:

### Layer 1: Depth Counter

Every task carries a `depth` field (default: 0). If a task spawns a sub-task, the sub-task inherits `depth + 1`. Maximum depth: 2. Tasks at `depth >= 2` cannot create new tasks.

```
Task A (depth=0) → spawns Task B (depth=1) → spawns Task C (depth=2)
Task C cannot spawn further tasks (depth limit reached).
```

### Layer 2: Queue Mutation Lock

The `flock()` on `queue.json` during execution prevents executing sessions from adding tasks to the queue directly (see above).

### Layer 3: Pattern Rejection

The prompt validation step rejects any prompt containing `/SQUAD`, `--drain`, or `/LOOP`. Even if Layer 2 is bypassed, a task that tries to spawn another drain session will fail validation.

### Layer 4: LVL8 Prompt Template

The LVL8 orchestrator prompt injected into every Claude Code session explicitly states:

```
"Do NOT invoke /SQUAD, /LOOP, or --drain. Execute the task directly using
available tools. If you need to spawn agents, use the Agent tool with
run_in_background: true."
```

---

## Execution Loop

```
for each task in queue (sorted by priority):
    1. Re-validate task (schema + patterns)
    2. Acquire queue lock (flock)
    3. Snapshot queue.json
    4. Mark task status: "running"
    5. Spawn LVL8 session:
         - Fresh Claude Code process
         - Branch: lvl8/{task-id}
         - Permission mode: per scoping table above
         - Wall time: 30 min max
         - Retries: 3 attempts on failure
         - Gutter detection: same error 3× → auto-skip
    6. Session runs: /SQUAD {preset} {target}
       OR: /SQUAD {preset} --then {pipeline[0]} --then ...
    7. Session completes (success or failure)
    8. Post-execution queue diff → quarantine new tasks
    9. Release queue lock
   10. Mark task status: "done" or "failed"
   11. If significant findings (significance >= 7.0): write to Knowledge (Charlie) helix
       (apply helix write sanitization — SAFEGUARD #7)
   12. Pick next task
```

**`--once` flag**: Stops after step 12 (one task only). Does not loop.

---

## Guardrails

Inherited from `/LOOP`, hardened with new safeguards:

| Guardrail | Mechanism |
|-----------|-----------|
| Wall time | 30 min max per task (configurable in `lvl8.toml`) |
| Retry limit | 3 attempts before marking `failed` |
| Gutter detection | Same error signature 3× → auto-skip, mark `failed` |
| Guardrails.md | Failed task lessons persist in `~/.lightarchitects/guardrails.md` |
| Branch isolation | `lvl8/{task-id}` — never touches main |
| PR only | Creates PR from task branch, never auto-merges |
| Permission scoping | External-source: NO `--dangerously-skip-permissions` |
| Queue lock | `flock()` during execution |
| Schema validation | Re-validated immediately before execution |
| Recursion guard | depth counter + prompt pattern + queue lock + LVL8 template |

---

## LVL8 Integration Requirements

The following changes are needed in `~/Projects/LVL8/` to support DRAIN mode:

### 1. Task Schema Extension

Add to the `Task` struct:
```rust
pub preset: Option<String>,       // auto-classified or user-specified
pub pipeline: Option<Vec<String>>, // --then chain (e.g. ["guard", "code_review"])
pub depth: u8,                    // recursion counter, default 0, max 2
```

### 2. Auto-Classification Logic

In `executor.rs`, match on `task.source` to assign preset when not already set:
```
source == "cargo-audit"       → preset = "security"
source == "quality-sweep"     → preset = "code_review"
source == "github-issues" AND label == "bug"     → preset = "solo"
source == "github-issues" AND label == "feature" → preset = "software_engineering"
```

### 3. Permission Scoping

In `build_claude_invocation()`:
- Check `task.source`. If external (github-issues, cargo-audit, quality-sweep): use `--print` only
- Only add `--dangerously-skip-permissions` for `source == "manual"` AND read-only preset

### 4. Queue Lock

```rust
use fs2::FileExt;
let queue_file = File::open(&queue_path)?;
queue_file.try_lock_exclusive()
    .map_err(|_| LvlError::QueueLocked)?;
// ... execute task ...
queue_file.unlock()?;
```

### 5. Prompt Template Update

Add to the orchestrator prompt injected by LVL8:
```
Do NOT invoke /SQUAD, /LOOP, or --drain. Execute the task directly.
```

### 6. Post-Execution Queue Diff

```rust
let before = read_queue(&queue_path)?;
execute_task(&task)?;
let after = read_queue(&queue_path)?;
let new_tasks = diff_queue(&before, &after);
for task in new_tasks {
    quarantine_task(&task, &task.id)?;
}
```

---

## Status Display (--status)

`/SQUAD --drain --status` shows:

```
DRAIN Queue Status
  Pending:      12 tasks
  Running:       1 task  (gh-soul-42 — 8m elapsed)
  Done:         47 tasks
  Failed:        2 tasks (review with --drain --status --failed)
  Quarantined:   0 tasks

Next: gh-soul-43 (high priority, software_engineering, Knowledge (Charlie)/Knowledge (Charlie)-DEV)
```
