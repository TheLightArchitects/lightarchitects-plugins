---
name: TRACE
description: "This skill is invoked internally by Analyst (Delta)'s investigation cycle for
  the pattern forensics phase. Correlates timelines, identifies error clusters, and
  maps causality via quantumTools trace action."
user-invocable: false
context: fork
version: 1.0.0
---

# TRACE -- Phase 2: Pattern Forensics

> Correlate timelines, identify error clusters, find root cause candidates via causality mapping.

## Purpose

TRACE is the forensic analysis phase. It builds a correlated timeline across all logs, clusters related errors by timestamp and context, identifies causality chains (event A triggered event B), and produces a ranked list of root cause candidates. This phase transforms raw logs into a causal narrative.

## quantumTools Action

`trace` -- maps to `quantumTools`

## Procedure

1. **Build Master Timeline**: Merge timestamps from all logs into single chronological sequence
2. **Identify Error Clusters**: Group errors within time windows (30s, 5m, 1h) by severity and type
3. **Extract Causal Chains**: Find sequences where one error precedes another consistently
4. **Detect Inflection Points**: Mark timestamps where behavior changes (traffic spike, config change, restart)
5. **Correlate Across Logs**: Match events in application logs to system logs, network logs, infrastructure logs
6. **Score Causality**: Rate confidence that event A caused event B (0.0-1.0)
7. **Rank Root Cause Candidates**: Order hypothetical root causes by likelihood based on evidence
8. **Visualize Narrative**: Generate timeline diagram showing clusters, causality arrows, inflection points

## Inputs

- Evidence manifest from SWEEP (Phase 1)
- Parsed logs with timestamps and severity levels
- Domain knowledge: expected application behavior, known failure modes
- Causality heuristics: rules for inferring causal relationships

## Outputs

- Forensic report (JSON/Markdown):
  - `timeline`: chronological events with severity and category
  - `error_clusters`: grouped errors with cluster ID, time range, type, count
  - `causal_chains`: sequences of related events with confidence scores
  - `root_cause_candidates`: ranked list with evidence citations
  - `inflection_points`: critical timestamps where system behavior changed
  - `confidence_scores`: per-candidate confidence (0.0-1.0)
  - `evidence_gaps`: areas lacking evidence for definitive causality

## HITL Checkpoint

**User decides**:
- Accept or challenge ranked root cause candidates
- Request deeper investigation into specific clusters or causal chains
- Confirm whether timeline narrative makes sense from domain perspective
- Proceed to PROBE (Phase 3) or request additional evidence from SWEEP
