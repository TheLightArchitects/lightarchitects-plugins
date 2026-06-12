---
name: CURATOR
description: "This skill is invoked internally by Analyst (Delta)'s investigation cycle as a
  cross-phase governance module. Manages claim registration, tracking, and verification
  throughout the investigation lifecycle."
user-invocable: false
context: fork
version: 1.0.0
---

# CURATOR -- Cross-Phase: Claim Registration

> Rules for registering, tracking, and verifying claims throughout investigation lifecycle.

## Purpose

CURATOR defines how claims (assertions of fact) are registered, cited, verified, and tracked across investigation phases. Every claim that appears in a deliverable must have a source citation and verification status. Unverified claims must be flagged with confidence level in customer-facing documents. No claim may be stated as fact without evidence backing.

## Claim Lifecycle

**Registration (SCAN → THEORIZE)**
1. When a claim is made (e.g., "Error X occurred at timestamp T"), register it immediately
2. Record source: which log file, line number, evidence ID
3. Assign claim ID for tracking (e.g., "CLAIM-001")
4. Claim status: "unverified" until passing verification rules (below)
5. Note: even obvious claims (e.g., "log file contains error") must be registered

**Verification (VERIFY Phase)**
6. Claim verification status: "verified" = assertion passed ≥2 independent checks
7. "Contradicted" = evidence explicitly refutes claim
8. "Unverifiable" = no evidence available to confirm or deny (data gap)
9. Multiple sources confirming same claim = higher verification confidence

**Tracking**
10. Maintain claim matrix throughout investigation: ID, assertion, source, status, confidence
11. Flag any claim status changes between phases (e.g., "unverifiable" → "verified" when new evidence found)
12. When claim status downgrades, document reasoning explicitly

**Deliverable Inclusion Rules**
13. RCA Report may include only "verified" claims and statements of established fact
14. Customer Response may include "unverifiable" claims only if labeled as such (e.g., "We believe X may have caused Y, but cannot confirm with available evidence")
15. JIRA ticket may include "unverifiable" claims in background context, but must not be acceptance criteria
16. All claims with confidence <0.80 must include caveats: "based on limited evidence" or "one interpretation of logs"

## Claim Types

| Type | Example | Verification Requirement |
|------|---------|------------------------|
| **Factual** | "Error log contains 'connection timeout'" | Direct quote + timestamp |
| **Temporal** | "Error X occurred before Error Y" | Both timestamps confirmed, Y-X ≥ 0 |
| **Causal** | "X caused Y" | X precedes Y, no alternative explanation, ≥0.70 confidence |
| **Inferential** | "System was overloaded" | Indirect evidence: high error rate, CPU/memory spikes, slow response times |
| **Counterfactual** | "If X hadn't occurred, Y wouldn't have happened" | Causality ≥0.80, or explicitly marked as hypothesis |

## Verification Rules by Claim Type

**Factual Claims** (Highest confidence)
- Verify: exact match in original log file
- Confidence baseline: 0.95 (subject to contradictions)
- Can drop to <0.50 if contradicted by other evidence

**Temporal Claims**
- Verify: both timestamps confirmed from same log format
- Account for clock skew across systems
- Confidence baseline: 0.85 (timestamps are reliable)
- Drop to <0.50 if timestamps from different systems (e.g., one is client-side, one is server)

**Causal Claims** (Highest scrutiny)
- Verify: precedence (X before Y) + no alternative explanation
- Confidence baseline: 0.40 (causality is hardest to prove)
- Increase to 0.70+ only if multiple independent chains lead to same conclusion
- Bayesian update: prior probability (base rate of X → Y) × likelihood (evidence strength)

**Inferential Claims**
- Verify: multiple supporting signals (not just one log line)
- Example: "overload" = high error rate + CPU high + memory high, all in same time window
- Confidence baseline: 0.50
- Require ≥2 independent signals to reach 0.70+

**Counterfactual Claims** (Rarely verified in QIC)
- Mark as "hypothesis" not "fact"
- Confidence baseline: 0.30
- Explicitly state: "This would require additional testing to verify"

## Claim Confidence Scoring

```
Confidence = (Evidence Strength × Source Reliability × Corroboration) × (1.0 - Contradiction Factor)

Evidence Strength:   0.0-1.0 (how directly evidence supports claim)
Source Reliability:  0.0-1.0 (is the source trustworthy?)
Corroboration:       0.0-1.0 (how many independent sources confirm?)
Contradiction Factor: 0.0-1.0 (severity of contradicting evidence; 0 = no contradictions)
```

Example: Claim "Error X at 14:05" = (1.0 direct quote × 1.0 trusted log × 1.0 confirmed in 3 places) × (1.0 - 0) = 1.0 confidence → "verified"

Example: Claim "X caused system failure" = (0.6 temporal precedence × 0.8 research backing × 0.5 one source) × (1.0 - 0.3 contradictions) = 0.21 → "low confidence hypothesis"

## Deliverable Rules

**In RCA Report**
- Every factual claim must have source citation: "[1, log-app-001:234]"
- Include confidence range: "Root cause: X (verified, 0.92 confidence)"
- Unverified claims must be marked: "Contributing factors may have included Y (unverifiable with available evidence)"

**In Customer Response**
- Factual claims only: "Your system experienced a connection timeout at 2:45 PM UTC"
- Hide technical uncertainty: don't say "we're 70% sure"; say "we found that..."
- Acknowledge unknowns: "Some details of the incident remain unclear due to incomplete logs"

**In JIRA Ticket**
- Engineering acceptance criteria must be based on "verified" claims only
- Background/context may include "unverifiable" claims marked with confidence level

## Contradiction Handling

When contradicting evidence emerges:
1. Note contradiction immediately (don't suppress it)
2. Calculate confidence drop: (1.0 - Contradiction_Severity) where Severity = 0.0-1.0
3. Revisit claim: can it be refined or narrowed?
4. Example: "Error X" contradicted by "no Error X in main log" → confidence drops to 0.50 (conflicting logs)
5. Document: "CLAIM-001 confidence adjusted from 0.95 to 0.50 due to contradicting log source"

## Claim Matrix Maintenance

Maintain throughout investigation:

| Claim ID | Assertion | Source | Status | Confidence | Phase Discovered | Last Updated |
|----------|-----------|--------|--------|------------|------------------|--------------|
| CLAIM-001 | Error X at 14:05 | app.log:234 | verified | 0.95 | SWEEP | VERIFY |
| CLAIM-002 | X caused Y | inference | unverifiable | 0.55 | TRACE | THEORIZE |
| CLAIM-003 | System overloaded | metrics + logs | verified | 0.80 | SWEEP | VERIFY |

This matrix becomes appendix to RCA report.
