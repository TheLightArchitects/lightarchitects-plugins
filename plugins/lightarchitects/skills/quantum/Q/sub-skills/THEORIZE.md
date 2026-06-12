---
name: THEORIZE
description: "This skill is invoked internally by Analyst (Delta)'s investigation cycle for
  the hypothesis generation phase. Generates ranked hypotheses from evidence and research
  using Bayesian reasoning via quantumTools theorize action."
user-invocable: false
context: fork
version: 1.0.0
---

# THEORIZE -- Phase 4: Hypothesis Generation

> Generate ranked hypotheses from evidence + research, assign confidence scores using Bayesian reasoning.

## Purpose

THEORIZE is the hypothesis generation phase. It takes evidence (timeline, clusters, causal chains), research findings (Helix, web), and synthesizes them into ranked hypotheses about root cause. Each hypothesis is scored using Bayesian confidence (0-100), mapped to supporting evidence, and marked as falsifiable. Contradictions are explicitly noted.

## quantumTools Action

`theorize` -- maps to `quantumTools`

## Procedure

1. **Correlate Evidence with Research**: Link forensic findings to supporting research
2. **Generate Hypotheses**: Create candidate explanations from evidence clusters and causal chains
3. **Map Evidence to Hypotheses**: For each hypothesis, cite supporting evidence + research
4. **Identify Contradictions**: Flag evidence that contradicts each hypothesis
5. **Assign Confidence Scores**: Use Bayesian scoring (prior × likelihood) for each hypothesis
6. **Define Falsifiability**: For each hypothesis, define what evidence would disprove it
7. **Rank by Confidence**: Sort hypotheses descending by confidence score
8. **Create Hypothesis Matrix**: Table showing each hypothesis, supporting evidence, contradictions, falsifiability

## Inputs

- Forensic report from TRACE (Phase 2)
- Research synthesis from PROBE (Phase 3)
- Bayesian scoring rules: prior probabilities, likelihood heuristics
- Falsifiability criteria: what would disprove each hypothesis

## Outputs

- Hypothesis report (JSON/Markdown):
  - `hypotheses`: array of ranked candidates (confidence 0-100)
  - `hypothesis_matrix`: table with evidence, contradictions, falsifiability
  - `supporting_evidence`: per-hypothesis citations to forensics and research
  - `contradicting_evidence`: per-hypothesis conflicting signals
  - `confidence_reasoning`: explanation for each score
  - `next_verification_steps`: what evidence would validate/invalidate each hypothesis
  - `top_3_candidates`: most likely hypotheses for VERIFY phase

## HITL Checkpoint

**User decides**:
- Accept or challenge hypothesis rankings
- Identify if top candidate hypothesis seems reasonable from business perspective
- Request deeper investigation into specific hypothesis
- Confirm readiness to proceed to VERIFY (Phase 5) with top hypotheses
- Request hypothesis revision if confidence scores seem misaligned with evidence
