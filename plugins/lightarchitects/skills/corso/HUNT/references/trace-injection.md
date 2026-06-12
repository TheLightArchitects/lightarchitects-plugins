# Trace Injection — Monitor (Foxtrot) Runtime Evidence for Bug Fix Builds

## Purpose

Condition code generation on actual runtime evidence. When HUNT executes a
bug fix build, the `trace-inject.sh` hook queries Monitor (Foxtrot) for recent execution
traces and injects them as a `<runtime_evidence>` block into the coding
agent's context. The model sees what actually happened at runtime — not a
description of it.

## When It Fires

All three conditions must be true:

1. **Tool matcher**: The gateway tool (`mcp__plugin_lightarchitects_lightarchitects__tools`)
   is being called.
2. **Action**: The action is `sniff`, `generate_code`, or `code_review` (code
   generation or remediation actions used during HUNT phases).
3. **Bug fix context**: The tool parameters contain keywords indicating a bug
   fix — `fix`, `bug`, `error`, `failing`, `broken`, `panic`, `crash`,
   `regress`, or `defect`.

If any condition is false, the hook exits silently (no injection, no block).

## What Gets Injected

A structured `<runtime_evidence>` block containing up to three sections:

### FAILING TRACES
Recent spans (last 24 hours) where the outcome was `Error`, `Block`, or
contained failure keywords. Each entry shows:
- Timestamp, actor, action, outcome type + detail, duration
- Metadata excerpt (first 120 chars) when available

### HEALTHY BASELINE
Recent successful spans (outcome = `Continue`, no failure keywords) from the
same actors/actions. Provides the "what it looked like when it was working"
reference.

### DIFF
Summary analysis comparing failures to healthy baseline:
- Failing actor/action distribution
- Average duration comparison (fail vs healthy)

### Example Output

```xml
<runtime_evidence source="ayin" query_time="2026-04-21T14:30:00Z">
FAILING TRACES (last 24h, 3 found):
  [2026-04-21T14:22:00Z] actor=corso action=guard outcome=Error — unsafe code detected in src/lib/auth.rs:42 duration=1200ms
  [2026-04-21T14:18:00Z] actor=quantum action=verify outcome=Block — evidence chain broken at validation step duration=3400ms
  [2026-04-21T13:55:00Z] actor=corso action=sniff outcome=Error — type mismatch: expected &str, found String duration=800ms

HEALTHY BASELINE (prior successful runs):
  [2026-04-21T12:00:00Z] actor=corso action=guard outcome=PASS duration=800ms
  [2026-04-21T11:45:00Z] actor=corso action=code_review outcome=PASS duration=2100ms

DIFF: 3 failure(s) detected across actors=[corso, quantum] actions=[guard, verify, sniff], avg_fail_duration=1800ms vs avg_healthy=1450ms
</runtime_evidence>
```

## How It Helps the Coding Agent

1. **Root cause visibility**: The agent sees the actual error messages and
   stack traces from failed runs, not a human's paraphrase of them.
2. **Regression context**: The healthy baseline shows the duration and
   behavior of the same actions when they were passing — the agent can
   identify what changed.
3. **Targeted fixes**: When the params include a file path, traces are
   filtered for relevance to that specific module, reducing noise.
4. **Duration signals**: Duration spikes between healthy and failing states
   can indicate resource contention, deadlocks, or algorithmic regression.

## Monitor (Foxtrot) API Integration

The hook uses the Monitor (Foxtrot) HTTP API at `localhost:3742`:

| Endpoint | Purpose |
|----------|---------|
| `GET /api/sessions` | List actor/date session pairs to know which data exists |
| `GET /api/spans/:actor/:date` | Load all spans for a specific actor on a date |

### Span Schema (TraceSpan)

```json
{
  "id": "uuid",
  "parent_id": "uuid|null",
  "session_id": "string|null",
  "actor": "corso|eva|soul|quantum|claude|seraph|ayin",
  "action": "guard|sniff|verify|...",
  "timestamp": "ISO 8601",
  "duration_ms": 1200,
  "decision_points": [],
  "strand_activations": [],
  "outcome": { "type": "Error", "detail": "description" },
  "metadata": {}
}
```

Outcome types: `Continue` (success), `Block` (gate rejection), `Skip`
(intentional skip), `Error` (failure with detail string).

## Failure Handling

- Monitor (Foxtrot) offline: hook exits 0 silently (no injection, no block)
- No sessions for today/yesterday: exits 0
- No failing traces found: exits 0 (empty evidence is worse than none)
- Timeout budget: 5s total (3s for Monitor (Foxtrot) queries, remainder for jq processing)

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `Monitor (Foxtrot)_BASE_URL` | `http://localhost:3742` | Override Monitor (Foxtrot) endpoint |

## File Locations

| File | Purpose |
|------|---------|
| `hooks/trace-inject.sh` | PreToolUse hook script |
| `hooks/lib/ayin-query.sh` | Reusable Monitor (Foxtrot) API helper functions |
| `hooks/hooks.json` | Hook registration (PreToolUse matcher) |
