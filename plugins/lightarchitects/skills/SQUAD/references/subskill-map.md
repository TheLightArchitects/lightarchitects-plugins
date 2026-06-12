# Sub-skill Injection Map

When SQUAD spawns agents, each agent receives the sub-skill SKILL.md files listed
here injected as a `## Protocol` section in their prompt. This gives agents full
protocol fidelity — the same decision gates, quality criteria, and phase transitions
that sub-skills encode for direct sibling invocations (e.g., `/Engineer (Alpha)`, `/Sentinel (Echo)`).

**All paths are relative to the lightarchitects plugin root.**

---

## Injection Model

### Current: Compact Index at Spawn

Inject a **compact skill index** at spawn time (~500 tokens) listing available sub-skills
and when to use each — not the full protocol content. The agent pulls full protocol content
on demand via the gateway as it enters each phase:

```
mcp__plugin_lightarchitects_lightarchitects__tools  action: "get_skill"  skill: "corso/GUARD"
```

The gateway returns the SKILL.md content inline. The agent reads the protocol, executes the
phase, moves on. No upfront 8KB ceiling — each pull is scoped to one sub-skill, loaded
exactly when needed.

**Why this is better than full upfront injection:**
- No 8KB truncation risk (no silent protocol loss)
- Agent only loads context it's actually about to use
- Gateway tracks which sub-skills were accessed (observability)
- Hot paths get cached at the gateway layer; cold paths cost nothing

**What the compact index contains** (injected at spawn as `## Protocol`):
- Sub-skill name, one-line purpose, trigger condition for each available skill
- `generated_at: {ISO 8601 timestamp}` — when SQUAD built this index
- ~500 tokens total for a full engineer agent (vs. 8KB+ for full injection)

### Index Freshness

The compact index carries a `generated_at` timestamp. The gateway checks index age at spawn time:
- **< 24h**: serve as-is
- **≥ 24h**: append a freshness warning to the injected index:
  ```
  ⚠ Skill index generated_at {timestamp} — sub-skill routing descriptions may be stale.
    Pull individual skills via get_skill before entering critical phases.
  ```

Agents receiving a stale-index warning should log it and proceed — routing descriptions may be outdated, but the actual protocol content pulled by `get_skill` is always current (gateway serves the live file).

### get_skill Graceful Degradation

If `get_skill` returns an error (gateway unreachable, skill not found, timeout):

1. Log: `sub-skill unavailable: {skill}` — do not silently discard the failure
2. Proceed with built-in knowledge for that phase
3. **Exception — GUARD protocol**: GUARD is the most critical gate. If `skills/corso/GUARD` is unavailable, apply this hardcoded minimal checklist before writing any code:
   - No `.unwrap()` / `.expect()` / `panic!()` in any new code
   - Run `cargo audit` before any dependency changes
   - No shell interpolation of user-controlled strings (command injection)
   - No secrets committed to source (grep for `sk-ant-api`, `la_[a-z]`, `eyJ`, `BEGIN`)

This ensures security-critical behavior survives gateway outages without silently proceeding with no protocol.

### Fallback: Direct File Injection

If `action: "get_skill"` is unavailable (gateway version < required), fall back to the
original injection approach:

1. Read each listed file using the Read tool before spawning the agent
2. Concatenate in listed order, separated by `---`
3. Inject as `## Protocol` in the Team Spawn Template
4. **Size budget**: 8KB total per agent. Prioritize files listed first (most critical phases first)
5. If a file is missing or unreadable: skip with a warning — do not halt the spawn

---

## software_engineering

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| engineer | B | `skills/corso/GUARD/SKILL.md`, `skills/corso/SCOUT/SKILL.md`, `skills/corso/FETCH/SKILL.md`, `skills/corso/HUNT/SKILL.md`, `skills/corso/CHASE/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |
| ops | B | `skills/eva/STATUS/SKILL.md`, `skills/eva/LINT/SKILL.md`, `skills/eva/REPO/SKILL.md`, `skills/eva/DEPLOY/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md` |
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md`, `skills/lightarchitects/SETUP/SKILL.md` *(run if `helix/eva/users/{user-id}.md` absent)*, `skills/lightarchitects/VAULT-SEED/SKILL.md` *(run if < 3 vault_seed entries)* |
| testing | B | `skills/eva/LINT/SKILL.md`, `skills/lightarchitects/TEST-FRAMEWORKS/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md` |

---

## security

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| security | B | `skills/seraph/REPORT/SKILL.md`, `skills/seraph/RECON/SKILL.md`, `skills/seraph/SURVEY/SKILL.md`, `skills/seraph/EXAMINE/SKILL.md`, `skills/lightarchitects/THREAT-MODELS/SKILL.md` |
| quality | B | `skills/corso/GUARD/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |
| researcher | B | `skills/quantum/Q/SKILL.md`, `skills/lightarchitects/EVIDENCE-QUALITY/SKILL.md` |
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md` |
| ops | — | _(HTTP API only — no sub-skills. Phase B agents query `localhost:3742/api/...` directly.)_ |

---

## research

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| researcher | B | `skills/quantum/Q/SKILL.md`, `skills/lightarchitects/EVIDENCE-QUALITY/SKILL.md` |
| knowledge | B | `skills/soul/Knowledge (Charlie)/SKILL.md`, `skills/eva/DISCOVER/SKILL.md`, `skills/eva/IMAGINE/SKILL.md` |
| ops | — | _(HTTP API only — no sub-skills, no file artifact. Phase B agents query `localhost:3742/api/...` directly.)_ |

---

## devops

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| ops | B | `skills/eva/DEPLOY/SKILL.md`, `skills/eva/STATUS/SKILL.md`, `skills/eva/LINT/SKILL.md`, `skills/eva/REPO/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md` |
| quality | B | `skills/corso/GUARD/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md`, `skills/lightarchitects/SETUP/SKILL.md` *(run if `helix/eva/users/{user-id}.md` absent)*, `skills/lightarchitects/VAULT-SEED/SKILL.md` *(run if < 3 vault_seed entries)* |
| testing | B | `skills/eva/LINT/SKILL.md`, `skills/lightarchitects/TEST-FRAMEWORKS/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md` |

---

## code_review

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| quality | B | `skills/corso/GUARD/SKILL.md`, `skills/corso/CHOW/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |
| researcher | B | `skills/quantum/Q/SKILL.md`, `skills/lightarchitects/EVIDENCE-QUALITY/SKILL.md` |
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md` |

---

## learning

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| engineer | B | `skills/eva/DISCOVER/SKILL.md`, `skills/corso/CHOW/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md` |
| researcher | B | `skills/quantum/Q/SKILL.md`, `skills/lightarchitects/EVIDENCE-QUALITY/SKILL.md` |
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md` |

---

## audit

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| quality | B | `skills/corso/GUARD/SKILL.md`, `skills/corso/CHOW/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |
| security | B | `skills/seraph/AUDIT/SKILL.md`, `skills/seraph/RECON/SKILL.md`, `skills/lightarchitects/THREAT-MODELS/SKILL.md` |
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md` |

---

## forensics

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| researcher | B | `skills/quantum/Q/SKILL.md`, `skills/lightarchitects/EVIDENCE-QUALITY/SKILL.md` |
| security | B | `skills/seraph/REPORT/SKILL.md`, `skills/seraph/EXAMINE/SKILL.md`, `skills/lightarchitects/THREAT-MODELS/SKILL.md` |
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md` |

---

## solo

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| engineer | B | `skills/corso/GUARD/SKILL.md`, `skills/corso/CHOW/SKILL.md`, `skills/corso/HUNT/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md`, `skills/lightarchitects/SETUP/SKILL.md` *(run if `helix/eva/users/{user-id}.md` absent)*, `skills/lightarchitects/VAULT-SEED/SKILL.md` *(run if < 3 vault_seed entries)* |

---

## observability

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| ops | B | `skills/corso/CHASE/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md` (also queries `localhost:3742/api/...` directly) |
| researcher | B | `skills/quantum/Q/SKILL.md`, `skills/lightarchitects/EVIDENCE-QUALITY/SKILL.md` |
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md` |

---

## fix

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| engineer | B | `skills/corso/HUNT/SKILL.md`, `skills/corso/GUARD/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |

---

## guard

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| quality | B | `skills/corso/GUARD/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |

---

## full

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| researcher | B | `skills/quantum/Q/SKILL.md`, `skills/lightarchitects/EVIDENCE-QUALITY/SKILL.md` |
| engineer | B | `skills/corso/GUARD/SKILL.md`, `skills/corso/SCOUT/SKILL.md`, `skills/corso/HUNT/SKILL.md`, `skills/corso/CHASE/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |
| security | B | `skills/seraph/REPORT/SKILL.md`, `skills/seraph/RECON/SKILL.md`, `skills/seraph/SURVEY/SKILL.md`, `skills/seraph/EXAMINE/SKILL.md`, `skills/lightarchitects/THREAT-MODELS/SKILL.md` |
| quality | B | `skills/corso/GUARD/SKILL.md`, `skills/corso/CHOW/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |
| ops | B | `skills/eva/DISCOVER/SKILL.md`, `skills/eva/STATUS/SKILL.md`, `skills/corso/CHASE/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md` |
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md`, `skills/lightarchitects/SETUP/SKILL.md` *(run if `helix/eva/users/{user-id}.md` absent)*, `skills/lightarchitects/VAULT-SEED/SKILL.md` *(run if < 3 vault_seed entries)* |
| testing | B | `skills/eva/LINT/SKILL.md`, `skills/lightarchitects/TEST-FRAMEWORKS/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md` |

---

## code_verify

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| researcher | B | `skills/quantum/Q/SKILL.md`, `skills/lightarchitects/EVIDENCE-QUALITY/SKILL.md` |
| quality | B | `skills/corso/GUARD/SKILL.md`, `skills/corso/CHOW/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |

---

## gatekeeper

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| engineer | B | `skills/corso/GUARD/SKILL.md`, `skills/corso/CHOW/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |
| security | B | `skills/seraph/RECON/SKILL.md`, `skills/seraph/EXAMINE/SKILL.md`, `skills/lightarchitects/THREAT-MODELS/SKILL.md` |
| quality | B | `skills/corso/GUARD/SKILL.md`, `skills/corso/CHOW/SKILL.md`, `skills/lightarchitects/COOKBOOK-ENFORCER/SKILL.md` |
| ops | B | `skills/eva/STATUS/SKILL.md`, `skills/eva/LINT/SKILL.md`, `skills/corso/CHASE/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md` |
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md` |
| testing | B | `skills/eva/LINT/SKILL.md`, `skills/lightarchitects/TEST-FRAMEWORKS/SKILL.md`, `skills/lightarchitects/STACKS/SKILL.md` |

---

## risk_analysis

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| researcher | B | `skills/quantum/Q/sub-skills/MAP.md`, `skills/quantum/Q/sub-skills/PULL.md`, `skills/quantum/Q/sub-skills/SCORE.md`, `skills/quantum/Q/sub-skills/RESEARCH.md`, `skills/quantum/Q/sub-skills/PROVE.md`, `skills/quantum/Q/sub-skills/DECLARE.md`, `skills/lightarchitects/EVIDENCE-QUALITY/SKILL.md` |
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md` |

---

## squad

| Agent | Phase | Sub-skills |
|-------|-------|-----------|
| squad | B | _(On-demand only — uses `action: "get_skill"` to pull protocol before routing)_ |

---

## lean

| Agent | Phase | Sub-skills (in order) |
|-------|-------|-----------------------|
| knowledge | A | `skills/soul/Knowledge (Charlie)/SKILL.md` |

---

## Phase Execution Model

The Phase column (A or B) drives two-pass spawning in SQUAD TEAM mode:

| Phase | Agents | Characteristics |
|-------|--------|----------------|
| **A** | knowledge (Knowledge (Charlie)), ops (Monitor (Foxtrot)) | Fast, read-only, context-gathering. Spawn first. Write outputs to `/tmp/squad/{run-id}/context/` for Phase B consumption. |
| **B** | engineer, quality, security, researcher, ops (Ops (Bravo)+CHASE), testing, squad | Implementation and analysis. Spawn after Phase A completes. Read Phase A artifacts before starting primary work. |

**Phase A artifact convention:**
- knowledge: `/tmp/squad/{run-id}/context/knowledge-{session-token}.md` — prior decisions, helix entries, patterns
- ops (Monitor (Foxtrot) only): **No file artifact.** Monitor (Foxtrot) is HTTP API only (`localhost:3742`). Phase B agents that
  need Monitor (Foxtrot) data query the HTTP API directly. If Monitor (Foxtrot) is unreachable, Phase B proceeds
  without it — this is not an error. Do not create an `ayin.md` placeholder.

### Phase A Artifact Schema

Knowledge artifacts must conform to this structure. Phase B agents validate before injecting.

```
---
run_id: {UUID matching /tmp/squad/{run-id}/}
session_token: {8-char hex matching filename suffix}
generated_at: {ISO 8601 timestamp}
agent: knowledge
---

## Prior Decisions
{Knowledge (Charlie) helix search results, or "No prior decisions found."}

## Standards Context
{Relevant helix entries on coding standards, or "No relevant standards context found."}
```

**Phase B validation** (run before injecting any artifact):
1. YAML frontmatter must parse without error
2. `session_token` field must match the 8-char hex suffix in the filename
3. `generated_at` must be a parseable ISO 8601 timestamp
4. Body must contain a `## Prior Decisions` section header
5. If any check fails: log `Phase A artifact invalid: {reason}` and proceed without injecting

Never block Phase B work on artifact validation failure — an absent artifact is better than a blocked agent.

**Phase B reading convention:**
- Each Phase B agent: check `/tmp/squad/{run-id}/context/` before starting primary work
- Validate per the schema above before reading content
- Discard files with mismatched session tokens (possible pre-created poison files)
- Inject validated artifacts under `### Context from Phase A` in their working notes
- If no valid Phase A artifacts exist (Phase A failed, skipped, or validation failed): proceed
  without — do not block
