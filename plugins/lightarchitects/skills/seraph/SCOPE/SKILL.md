---
name: SCOPE
description: "This skill is invoked internally by Sentinel (Echo)'s engagement cycle for the scope
  governance phase. Validates ~/lightarchitects/seraph/scope.toml against 5-gate ScopeGovernor: TTL,
  target, tool, concurrent, and domain checks. No operational action proceeds without
  passing all gates."
user-invocable: false
context: fork
version: 2.0.0
---

# /SCOPE — Scope Governance Phase

> Engagement Phase 1/6: SCOPE — Validate authorization before any operational action

## Lifecycle Context

First phase of every engagement. Feeds into RECON. No operational action proceeds without SCOPE passing.

## Protocol

### Step 1: Load Scope Definition

Read `~/lightarchitects/seraph/scope.toml` via filesystem access. If file does not exist, report to the operator and **stop** — no engagement proceeds without a scope file.

### Step 2: Validate 5-Gate Governance

Check each gate in order:

| Gate | Check | Method | Failure Action |
|------|-------|--------|---------------|
| 1 | TTL | Verify `expires_at` is in the future | Report expired scope, stop |
| 2 | Target | Verify requested targets fall within `allowed` CIDRs/IPs | Report out-of-scope targets, stop |
| 3 | Tool | Verify requested tools are in `authorized_tools` list | Report unauthorized tools, stop |
| 4 | Concurrent | Verify active scan count < `max_concurrent` | Report at capacity, wait or stop |
| 5 | Domain | If target contains alphabetic chars, verify against `authorized_domains` | Report domain violation, stop |

Gate 5 fires only for domain-like targets. Pure IP/CIDR targets skip it.

### Step 3: Confirm Engagement Parameters

Present validated scope to the operator via HITL:

```
Engagement: {engagement_id}
Name: {engagement_name}
Expires: {expires_at}
Targets: {allowed list}
Tools: {authorized_tools list}
Concurrent limit: {max_concurrent}
```

Confirm before proceeding to RECON.

### Step 4: Initialize Evidence Chain

If starting a new engagement, create initial evidence chain entry:
- `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "seraph"`, `action: "investigate_start"` (if full lifecycle)
- Or note scope validation in `~/lightarchitects/seraph/evidence-chain.log`

## Quality Gates

### Pre-Execution
- [ ] `~/lightarchitects/seraph/scope.toml` exists and is readable
- [ ] All 5 governance gates defined

### Post-Execution
- [ ] All 5 gates pass
- [ ] Engagement parameters confirmed by the operator
- [ ] Evidence chain initialized (if full engagement)

## Cross-Domain Context

| Phase | Skill | Relationship |
|-------|-------|-------------|
| 2. recon | RECON | Receives validated scope and target list |
| all | all | Every subsequent phase inherits scope context |
