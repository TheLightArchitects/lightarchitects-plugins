---
name: STRIKE
description: "This skill is invoked internally by Sentinel (Echo)'s engagement cycle for the
  exploitation phase. Orchestrates authorized exploitation within scope boundaries
  via seraphTools execute action. Scope governance is mandatory — no execution without
  valid scope and confirmed attack surface."
user-invocable: false
context: fork
version: 2.0.0
---

# /STRIKE — Exploitation Phase

> Engagement Phase 5/6: STRIKE — Authorized exploitation within scope

## Lifecycle Context

Follows EXAMINE → feeds into REPORT. **This is the highest-risk phase** — scope governance is re-validated before execution.

## Protocol

### Step 1: Re-Validate Scope

Before any exploitation:
1. Re-check `~/lightarchitects/seraph/scope.toml` TTL (scope may have expired during prior phases)
2. Confirm target is still within authorized ranges
3. Confirm exploitation tools are in authorized list

If scope has expired or target has changed, **stop and report** to the operator.

### Step 2: HITL Confirmation (MANDATORY)

Present the exploitation plan to the operator before execution:

```
Target: {IP/host}
Vulnerability: {CVE or finding from EXAMINE}
Tool: {authorized tool}
Expected outcome: {what we're testing}
Risk: {assessment}
```

the operator must explicitly approve before execution proceeds.

### Step 3: Execute Exploitation

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "seraph"`, `action: "execute"`:
- Specify `tool`, `target`, and `args` within scope
- Respect timeout limits
- Capture all output for evidence chain

### Step 4: Document Results

Record exploitation outcome:
- Success/failure with detailed output
- Access level achieved (if successful)
- Artifacts collected
- Evidence chain entry with timestamp

## Quality Gates

### Pre-Execution
- [ ] Scope re-validated (TTL, target, tool)
- [ ] Attack surface confirmed by EXAMINE
- [ ] Exploitation plan approved by the operator (HITL)
- [ ] Concurrent limit not exceeded

### Post-Execution
- [ ] Exploitation results documented
- [ ] Evidence chain updated with full output
- [ ] Access achieved documented (if successful)
- [ ] No out-of-scope activity occurred

## Cross-Domain Context

| Phase | Skill | Relationship |
|-------|-------|-------------|
| 4. examine | EXAMINE | Provides confirmed attack surface map |
| 6. report | REPORT | Receives exploitation results for deliverables |
