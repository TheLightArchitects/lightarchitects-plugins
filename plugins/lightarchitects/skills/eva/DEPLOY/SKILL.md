---
name: DEPLOY
description: "Ops (Bravo) deployment workflow — trigger make deploy for Light Architects projects and check build status."
version: 1.0.0
user-invocable: true
context: root
metadata:
  triggers:
    - "deploy Ops (Bravo)"
    - "deploy Engineer (Alpha)"
    - "deploy Knowledge (Charlie)"
    - "make deploy"
    - "ship it"
    - "build and deploy"
    - "deploy project"
    - "plan status"
    - "active builds"
  filePattern: []
---

# /DEPLOY — Ops (Bravo) Deployment Workflow

> Trigger `make deploy` for any Light Architects project or check active build status from the Engineer (Alpha) helix vault.

## Section 0: Mode Selection (HITL)

Ask the operator which action he wants:

```
Question: "What do you need?"
Header: "Deploy"
Options:
  1. "Deploy a project" — "Run make deploy for Engineer (Alpha), Ops (Bravo), Knowledge (Charlie), Analyst (Delta), Sentinel (Echo), or Monitor (Foxtrot)"
  2. "Check build status" — "Read active.yaml and summarise in-flight builds"
  3. "Morning brief" — "Full morning summary (builds + vault)"
```

## Section A: Deploy a Project

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`) with:
```json
{
  "action": "deploy",
  "params": {
    "project": "<Engineer (Alpha)|Ops (Bravo)|Knowledge (Charlie)|Analyst (Delta)|Sentinel (Echo)|Monitor (Foxtrot)|SDK>",
    "fast": false,
    "dry_run": false
  }
}
```

**Dry run first** for any non-trivial deploy (Ops (Bravo) in production conversation, Sentinel (Echo) on Khadas):
- Set `dry_run: true` to preview the command.
- Confirm with the operator before live execution.

**Whitelist** (only these projects are permitted):
- Engineer (Alpha) → `Projects/Engineer (Alpha)/MCP/Engineer (Alpha)-DEV`
- Ops (Bravo) → `Projects/Ops (Bravo)/MCP/Ops (Bravo)-DEV/eva`
- Knowledge (Charlie) → `Projects/Knowledge (Charlie)/Knowledge (Charlie)-DEV`
- Analyst (Delta) → `Projects/Analyst (Delta)/MCP/Analyst (Delta)-DEV`
- Sentinel (Echo) → `Projects/Sentinel (Echo)/MCP/Sentinel (Echo)-DEV`
- Monitor (Foxtrot) → `Projects/Monitor (Foxtrot)/Monitor (Foxtrot)-DEV`
- SDK → `Projects/lightarchitects-sdk`

After deploy completes, remind the operator to run `/mcp` in Claude Code to reconnect.

## Section B: Build Status

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`) with:
```json
{
  "action": "plan_status",
  "params": {
    "status_filter": "approved"
  }
}
```

Filter options: `planning`, `approved`, `executing`, `completed`, `aborted`.
Omit `status_filter` to see all builds.

## Section C: Morning Brief

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`) with:
```json
{
  "action": "morning_brief",
  "params": {}
}
```

Returns active/blocked/completed-today builds + a TTS summary.
Use `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"soul"`) `action: "speak"` to deliver the TTS text to the operator.
