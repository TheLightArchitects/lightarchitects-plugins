---
name: REPORT
description: "This skill is invoked internally by Sentinel (Echo)'s engagement cycle for the
  reporting phase. Closes the investigation lifecycle, syncs evidence to Knowledge (Charlie) vault,
  and generates engagement deliverables via seraphTools investigate_close and vault_sync
  actions."
user-invocable: false
context: fork
version: 2.0.0
---

# /REPORT — Deliverables + Vault Sync Phase

> Engagement Phase 6/6: REPORT — Close investigation, generate deliverables, sync evidence

## Lifecycle Context

Final phase. Receives all prior phase outputs. Produces the engagement deliverable.

## Protocol

### Step 1: Consolidate Evidence Chain

1. Read `~/lightarchitects/seraph/evidence-chain.log` for full chain of custody
2. Collect outputs from all prior phases: RECON targets, SURVEY vulnerabilities, EXAMINE forensics, STRIKE results
3. Compile timeline of all actions taken

### Step 2: Close Investigation

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "seraph"`, `action: "investigate_close"`:
- Provide consolidated findings
- Generate investigation report with:
  - Executive summary
  - Methodology (phases executed)
  - Findings (ranked by severity)
  - Evidence references
  - Recommendations

### Step 3: Sync to Knowledge (Charlie) Vault

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "seraph"`, `action: "vault_sync"`:
- Sync evidence chain to Knowledge (Charlie) vault for permanent storage
- Link engagement to Sentinel (Echo)'s helix journal

### Step 4: Generate Final Report

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "seraph"`, `action: "investigate_report"` (if detailed report needed):
- Formal penetration test report
- Finding details with remediation guidance
- Risk ratings and prioritization

### Step 5: Present Deliverables

Present completed report to the operator:
- Executive summary (1-2 paragraphs)
- Key findings with severity
- Evidence chain status (items logged, vault synced)
- Recommendations prioritized by risk

## Quality Gates

### Pre-Execution
- [ ] All prior phase outputs available
- [ ] Evidence chain intact (no gaps)

### Post-Execution
- [ ] Investigation closed via investigate_close
- [ ] Evidence synced to vault via vault_sync
- [ ] Report generated and presented
- [ ] Helix journal entry linked

## Cross-Domain Context

| Phase | Skill | Relationship |
|-------|-------|-------------|
| 5. strike | STRIKE | Provides exploitation results |
| all | all | Consolidates outputs from all prior phases |
| vault | Knowledge (Charlie) | Evidence synced for permanent storage |
