---
name: VERIFY
description: "This skill is invoked internally by Analyst (Delta)'s investigation cycle for
  the solution validation phase. Validates top hypothesis against evidence using
  N-MultiPass verification via quantumTools verify action."
user-invocable: false
context: fork
version: 1.0.0
---

# VERIFY -- Phase 5: Solution Validation

> Validate top hypothesis against evidence using N-MultiPass verification framework.

## Purpose

VERIFY is the validation phase. It takes top hypotheses from THEORIZE and rigorously tests them against forensic evidence using N-MultiPass verification (multiple independent passes scoring consistency). Each claim in the hypothesis is validated against raw evidence, contradictions are resolved, and a validation report confirms or rejects the hypothesis.

## quantumTools Action

`verify` -- maps to `quantumTools`

## Procedure

1. **Define Verification Criteria**: Extract testable claims from hypothesis (e.g., "Error X preceded Error Y")
2. **Decompose into Assertions**: Break hypothesis into atomic claims
3. **Run Multi-Pass Validation** (N passes, typically N=3):
   - **Pass 1**: Direct evidence match (claim appears in logs/evidence)
   - **Pass 2**: Correlation check (supporting events occur within expected time window)
   - **Pass 3**: Contradiction analysis (no contradicting evidence in full dataset)
4. **Score Each Assertion**: Assign validation status (confirmed|contradicted|unverifiable)
5. **Resolve Contradictions**: Revisit conflicting signals, document reasoning
6. **Calculate Hypothesis Score**: Aggregate assertion scores into final validation score (0-100)
7. **Produce Validation Report**: Document each assertion, its validation status, evidence citations
8. **Rank Verified Hypotheses**: Sort by validation score descending

## Inputs

- Top hypotheses from THEORIZE (Phase 4) with supporting evidence
- Raw forensic evidence: logs, timeline, clusters, causal chains
- Multi-pass scoring rules: how to weight direct vs. correlation vs. contradiction checks
- Assertion decomposition templates: breaking hypotheses into testable claims

## Outputs

- Validation report (JSON/Markdown):
  - `verified_hypotheses`: ranked by validation score (0-100)
  - `assertion_matrix`: each claim with validation status (confirmed|contradicted|unverifiable)
  - `evidence_citations`: links to raw logs/evidence supporting each assertion
  - `contradiction_resolutions`: how conflicting evidence was handled
  - `final_hypothesis_score`: confidence after validation (0-100)
  - `remaining_gaps`: unverifiable claims or missing evidence
  - `confidence_after_validation`: adjusted confidence (typically lower than pre-validation)

## HITL Checkpoint

**User decides**:
- Accept validated hypothesis as root cause, or request re-verification
- Review any "unverifiable" assertions and decide if additional evidence is needed
- Confirm top hypothesis passes validation threshold for proceeding to CLOSE
- Request deeper investigation into specific assertions if validation seems weak
- Escalate if top hypothesis fails validation (contradiction count too high)
