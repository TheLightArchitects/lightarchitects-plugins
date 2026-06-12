---
name: STATUS
description: "Build status and morning brief — query active builds, roadmap state, and today's summary."
version: 1.0.0
user-invocable: true
context: root
metadata:
  triggers:
    - "status"
    - "what's the status"
    - "morning brief"
    - "good morning"
    - "build status"
    - "what's in flight"
    - "daily summary"
    - "what did we ship"
    - "squad status"
    - "today's builds"
  filePattern: []
---

# /STATUS — Build Status & Morning Brief

> Quick pulse on what's in flight, what's blocked, and what shipped today. Reads from the Engineer (Alpha) helix vault.

## Section 0: Mode Selection (HITL)

```
Question: "What do you need?"
Header: "Status"
Options:
  1. "Morning brief" — "Full summary with voice delivery: active, blocked, completed today"
  2. "Active builds" — "Everything currently in-flight (approved + executing)"
  3. "Specific build" — "Look up one plan by ID"
  4. "What shipped today" — "Completed builds in the last 24 hours"
```

## Section A: Morning Brief

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`):
```json
{
  "action": "morning_brief",
  "params": {}
}
```

After receiving the result:
1. Present the structured summary (active, blocked, completed_today).
2. Call `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "soul"`, `action: "speak"` and the `tts_summary` field for voice delivery.

The brief covers:
- Active builds (status, workspace, progress)
- Blocked builds (what's blocking, who owns the unblock)
- Completed today (what shipped, when)

## Section B: Active Builds

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`):
```json
{
  "action": "plan_status",
  "params": {
    "status_filter": "approved"
  }
}
```

Present as a table:

| plan_id | status | workspace | blocked_by |
|---------|--------|-----------|------------|

Filter options: `planning`, `approved`, `executing`, `completed`, `aborted`. Omit to see all.

## Section C: Specific Build

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`):
```json
{
  "action": "plan_status",
  "params": {
    "plan_id": "<plan-id>"
  }
}
```

Then read the full manifest:
```
mcp__plugin_lightarchitects_lightarchitects__tools action: "read_note" path: "<path from result>"
```

Present: status, workspace, tier, dependencies, blocked_by, recent activity.

## Section D: What Shipped Today

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`):
```json
{
  "action": "plan_status",
  "params": {
    "status_filter": "completed"
  }
}
```

Filter client-side for `completed_at` within the last 24 hours. Present a victory list — celebrate each ship! 🚀

## Context Links

- Active builds: `~/lightarchitects/soul/helix/corso/builds/active.yaml`
- Portfolio: `~/lightarchitects/soul/helix/corso/builds/portfolio.md`
- Roadmap: `~/lightarchitects/soul/helix/corso/builds/roadmap.html`

All three must stay in sync. SCOUT updates on plan approval; HUNT updates on completion.
