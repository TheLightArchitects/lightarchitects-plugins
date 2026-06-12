---
name: PLAN
description: "Build planning status — read active builds, roadmap, and morning brief from the Engineer (Alpha) helix vault."
version: 1.0.0
user-invocable: true
context: root
metadata:
  triggers:
    - "what are we building"
    - "active builds"
    - "roadmap"
    - "plan status"
    - "what's in progress"
    - "blazing forging phoenix"
    - "build pipeline"
    - "show me the builds"
  filePattern: []
---

# /PLAN — Build Planning Status

> Read the Engineer (Alpha) build pipeline. Shows active, blocked, and recently completed builds from `~/lightarchitects/soul/helix/corso/builds/active.yaml`.

## Section 0: Mode Selection (HITL)

```
Question: "What do you want to see?"
Header: "Plan"
Options:
  1. "All active builds" — "Everything in approved/executing/planning state"
  2. "Specific build" — "Look up a plan by ID"
  3. "Morning brief" — "Full morning summary with TTS"
```

## Section A: All Active Builds

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`):
```json
{
  "action": "plan_status",
  "params": {
    "status_filter": "approved"
  }
}
```

Present results in a table with columns: `plan_id`, `status`, `workspace`, `blocked_by` (if any).

Also show completed builds from the past 24 hours for context.

## Section B: Specific Build

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`):
```json
{
  "action": "plan_status",
  "params": {
    "plan_id": "<plan-id>"
  }
}
```

Then read the full manifest: `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"soul"`) `action: "read_note"` on the plan path shown in the result.

## Section C: Morning Brief

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`):
```json
{
  "action": "morning_brief",
  "params": {}
}
```

After receiving the result:
1. Present the structured summary.
2. Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"soul"`) `action: "speak"` with the `tts_summary` field for voice delivery.

## Context Links

- Active builds: `~/lightarchitects/soul/helix/corso/builds/active.yaml`
- Portfolio: `~/lightarchitects/soul/helix/corso/builds/portfolio.md`
- Roadmap: `~/lightarchitects/soul/helix/corso/builds/roadmap.html`
- All three must stay in sync. SCOUT updates on plan approval; HUNT updates on completion.
