---
name: GATE
description: "Cross-phase governance for ALL Analyst (Delta) modes. Defines checkpoint thresholds,
  HITL confirmations, and escalation triggers for both Investigation and Risk Analysis cycles."
user-invocable: false
context: fork
version: 2.0.0
---

# GATE — Cross-Phase Governance

> Every phase transition requires explicit user confirmation. No automatic progression. This applies to Investigation AND Risk Analysis.

## Purpose

GATE establishes mandatory checkpoints at every phase boundary. Each gate has: success criteria, user decision point (HITL), escalation triggers, and phase-back conditions.

---

## Investigation Phase Gates

**SCAN → SWEEP**
- Criteria: severity assigned, input format detected
- HITL: accept triage or override?
- Escalate if: severity = critical → skip to Full Investigation
- Phase-back if: input undetectable → request context, re-SCAN
- Threshold: confidence ≥ 0.70

**SWEEP → TRACE**
- Criteria: evidence manifest created, ≥80% parseable
- HITL: accept evidence completeness?
- Escalate if: data quality < 0.60
- Phase-back if: manifest gaps → request additional data
- Threshold: data_quality ≥ 0.80

**TRACE → PROBE**
- Criteria: timeline built, error clusters identified, ≥3 root cause candidates
- HITL: accept causal narrative?
- Escalate if: no clear candidates
- Phase-back if: timeline inconsistencies → re-examine SWEEP
- Threshold: ≥3 candidates, confidence ≥ 0.40

**PROBE → THEORIZE**
- Criteria: helix + web sources searched, findings synthesized with citations
- HITL: accept research findings?
- Escalate if: research contradicts forensics severely
- Phase-back if: contradictions unresolved → additional research
- Threshold: ≥1 corroborating finding

**THEORIZE → VERIFY**
- Criteria: ≥3 ranked hypotheses, evidence mapped, falsifiability defined
- HITL: accept hypothesis rankings?
- Escalate if: top confidence < 0.40
- Phase-back if: new evidence suggests missed causal chain → re-TRACE
- Threshold: top hypothesis confidence ≥ 0.50

**VERIFY → CLOSE**
- Criteria: top hypothesis validated, validation score ≥ 0.75
- HITL: accept validated root cause?
- Escalate if: no hypothesis achieves 0.75
- Phase-back if: validation reveals contradictions → re-THEORIZE
- Threshold: validation ≥ 0.75, < 2 unresolved contradictions

---

## Risk Analysis Phase Gates

**MAP → PULL**
- Criteria: all boundaries identified, chain drawn end-to-end
- HITL: "Did I miss any boundaries? Any implicit handoffs?"
- Phase-back if: the operator identifies missing boundary → re-MAP
- Threshold: chain covers input to final output with no gaps

**PULL → SCORE**
- Criteria: all three questions answered for every boundary (Format, Capacity, Witness)
- HITL: review the answers — any corrections?
- Phase-back if: question unanswerable → needs research before scoring
- Threshold: all boundaries have all three answers

**SCORE → RESEARCH**
- Criteria: Blast Scores calculated for all boundaries
- HITL: "Are the ratings honest? Any score feel wrong?"
- Escalate if: compound score > 10.0 → HALT immediately
- Threshold: scores must cite evidence for Certainty ratings

**RESEARCH → PROVE**
- Criteria: all hot threads (score > 3.0) researched from primary sources
- HITL: review research findings
- Phase-back if: research reveals new boundaries → re-MAP
- Threshold: every hot thread has primary source evidence

**PROVE → DECLARE**
- Criteria: all boundaries re-scored, compound score calculated
- HITL: **THIS IS THE PROCEED/HALT DECISION**
  - GREEN (< 2.0): proceed
  - YELLOW (2.0-5.0): proceed with monitoring
  - RED (5.0-10.0): more research required
  - HALT (> 10.0): redesign
- Threshold: the operator approves the verdict

---

## Universal Escalation Triggers

| Trigger | Condition | Action |
|---------|-----------|--------|
| **Confidence Stall** | Confidence unchanged across 2+ phases | Escalate depth (QIC → Full, or research more) |
| **Evidence Exhaustion** | All sources searched, still < 0.50 | Declare gap, escalate, or accept risk |
| **Contradiction Spike** | > 3 contradictions in top hypothesis or risk assessment | Phase-back to re-examine evidence |
| **Scope Expansion** | Issue or risk affects more systems than initially assessed | Re-MAP, expand the boundary chain |
| **Cost Threshold** | Cumulative spend approaching budget limit | HITL: continue or halt? |
| **Silent Failure Detected** | Boundary that was scored ×1 Witness turns out to be ×2 | Re-SCORE all related boundaries |

## HITL Options (same for all modes)

At every gate, user chooses:
1. **Proceed** — move to next phase
2. **Revise** — redo current phase with modifications
3. **Escalate** — increase investigation/research depth
4. **Halt** — stop and document decision
