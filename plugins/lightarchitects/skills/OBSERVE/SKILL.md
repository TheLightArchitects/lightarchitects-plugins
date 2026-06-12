---
name: OBSERVE
description: "Observability and diagnostics pipeline via SQUAD. Establishes baseline
  metrics, sets alert thresholds, then delegates to SQUAD observability with --watch.
  Equivalent to Monitor (Foxtrot) trace analysis + Knowledge (Charlie) historical context + Analyst (Delta) root cause
  investigation. Use when the user says '/observe', 'why is X slow', 'check traces',
  'diagnose performance', 'something is broken', 'monitor this'."
user-invocable: true
version: 2.0.0
context: root
---

# /OBSERVE — Observability & Diagnostics Pipeline

> Thin wrapper: baseline metrics + threshold selection → SQUAD observability --watch 5m.

## When to Use

- Something is slow, broken, or behaving unexpectedly at runtime
- User wants to understand runtime behavior or system health
- User says `/observe`, "why is X slow", "what happened", "check traces"
- Post-deploy verification (did the deploy cause regressions?)
- Continuous monitoring of a running system

## Accepted Flags

`--watch` is implicit with a default interval of `5m`. There are no modifier flags.

Rejected flags (return error + guidance): `--then`, `--drain`, `--fix`, `--research`.

```
ERROR: /OBSERVE does not accept {flag}.
--watch is implicit (default: 5m). To override the interval, specify it as an argument:
  /OBSERVE "<system>" 10m
For raw pipeline control, use /SQUAD directly:
  /SQUAD observability "system" --watch 10m
```

No write presets in this pipeline — no write-path disclosure needed.

## Step 1: Argument Validation (SAFEGUARD #24)

Validate the system argument: `^[a-zA-Z0-9_/. -]+$`. Reject SQUAD control flags and shell metacharacters.

## Step 2: Baseline Metrics

Before invoking SQUAD, establish the current system state so agents know what's anomalous:

**Query Monitor (Foxtrot) HTTP dashboard:**
```bash
curl -s http://localhost:3742/api/metrics
curl -s http://localhost:3742/api/topology
```

**Citation protocol** (Canon XXXVI): All metrics cited must include timestamp, endpoint,
and confidence value (Canon XXXV). Format: `latency_p95={N}ms @ {timestamp} (confidence: 0.XX)`.
Citations must be dated within 90 days or re-scraped via Firecrawl:
`mcp__plugin_firecrawl_firecrawl__scrape` with `url: "<original_endpoint>"`.
UNVALIDATED (<95% confidence) → escalate to Tier 1–4 research.

**If Monitor (Foxtrot) HTTP is unavailable**, use bash fallbacks:
```bash
ps aux | grep -E "corso|eva|soul|quantum|seraph|ayin"
top -l 1 | head -20
tail -20 ~/.ayin/logs/ayin.log  2>/dev/null
```

Document: current latency distribution, error rate, resource usage, which processes are running. Pass this baseline to SQUAD as context.

## Step 3: Threshold Selection

Present the observation thresholds for confirmation (or override):

| Threshold | Default | Override |
|-----------|---------|---------|
| Latency alert | > 200ms | Specify in argument |
| Error rate alert | > 0.1% | Specify in argument |
| Observation interval | 5m | Specify as second argument: `/OBSERVE "<system>" 10m` |

For post-deploy verification, a 5-minute window is usually sufficient. For chronic issues, extend to 10–30 minutes.

## Step 4: SQUAD Invocation

```
/SQUAD observability "<system>" --watch 5m
```

Override the interval:
```
/SQUAD observability "<system>" --watch 10m
```

SQUAD agents in the `observability` preset call the Monitor (Foxtrot) HTTP API for trace queries and anomaly detection, Knowledge (Charlie) helix for historical incident patterns, and Analyst (Delta) investigation cycle for root cause analysis. No HITL confirmation is needed — observability has no write operations.

Full cycle instructions are in `references/presets.md`.

## Contract Canon Integration (Cookbook §82)

This skill is governed by `agent.skill.observe` at `standards/canon/contracts/agent.skill/observe.yaml`. The five §82.3 touchpoints:

### Read
- `standards/canon/contracts/operator.surface/*` — for `observability.required_spans[]` audit list
- `standards/canon/contracts/code.trait/*` — for trait-method-level required_spans
- Monitor (Foxtrot) HTTP API `/api/spans` — observed-span enumeration

### Touched-contract citation
Each query result includes `contracts_audited[]` with the contracts whose required_spans were checked against the observed corpus.

### forbidden_behaviors enforcement
Not enforced at /OBSERVE — this skill is read-only.

### required_spans emission
`/OBSERVE` emits `skill.observe.invoke` (parent_relationship: child_of_caller) with metadata: `scope, target, spans_returned, missing_required, latency_overshoots`.

### status_per_provider impact
None — /OBSERVE reads but does not mutate. If observed latencies suggest a contract's verdict is stale, /OBSERVE flags it; mutation is /VERIFY V4's job.

### Required-span audit (new dimension)

For each operator.surface / code.trait contract whose `observability.required_spans[]` overlap the scope:

1. Compute expected set: `required_spans[].name`
2. Query Monitor (Foxtrot) for span instances matching scope filter
3. Diff: `expected - observed`
4. Each missing span = `E_OBSERVE_SPAN_MISSING` HIGH finding routed via Gatekeeper Registry [P] dimension

This audit is the runtime corollary of /CODE-VERIFY's source-grep span emission check.

### Latency-budget verification

For each operator.surface contract with `first_token_budget_ms` / `duration_budget_ms`:
1. Compute p50/p95/p99 of observed span duration
2. If p95 > budget → `E_OBSERVE_LATENCY_BUDGET` MEDIUM finding

## Graceful Degradation

If SQUAD is unavailable, query Monitor (Foxtrot) HTTP dashboard directly:

```bash
curl -s http://localhost:3742/api/traces
curl -s http://localhost:3742/api/metrics
curl -s http://localhost:3742/api/topology
curl -s http://localhost:3742/api/anomalies
```

Skip Analyst (Delta) root cause analysis and Knowledge (Charlie) helix context. Read trace files manually if the HTTP API is also down:
```bash
ls -lt ~/.ayin/logs/
tail -50 ~/.ayin/logs/ayin.log
```

Report: "Reading Monitor (Foxtrot) dashboard directly. No automated root cause analysis."
