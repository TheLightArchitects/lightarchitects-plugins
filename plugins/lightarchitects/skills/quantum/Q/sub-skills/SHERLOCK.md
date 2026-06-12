---
name: SHERLOCK
description: "Cross-phase evidence integrity for ALL Analyst (Delta) modes. Enforces hypothesis
  consistency (Investigation) and Certainty score integrity (Risk Analysis). Every claim
  — whether a root cause hypothesis or a Blast Score Certainty rating — must cite evidence."
user-invocable: false
context: fork
version: 2.0.0
---

# SHERLOCK — Cross-Phase: Evidence Integrity

> Rules for maintaining evidence-backed integrity across Investigation AND Risk Analysis.

## Purpose

SHERLOCK defines the coherence rules that govern hypothesis evolution across SCAN → CLOSE. Each hypothesis must remain logically consistent, rooted in evidence, and falsifiable. When evidence contradicts a hypothesis, the contradiction must be explicitly addressed—not ignored. Confidence must reflect the evidence quality, not user preference.

## Rules

**Evidence Backing**
1. Every hypothesis must cite at least one piece of forensic evidence from TRACE
2. No hypothesis may rely solely on research findings; PROBE findings amplify, not substitute
3. Contradicting evidence must be explicitly acknowledged in the hypothesis (e.g., "Hypothesis: X caused Y, despite finding Z which seems contradictory because...")

**Contradiction Handling**
4. When evidence contradicts a hypothesis, confidence drops (typically by 20-40 points)
5. A hypothesis with >2 unresolved contradictions should be deprioritized or rejected
6. Contradictions must be logged in hypothesis matrix with resolution reasoning
7. If contradiction cannot be resolved, hypothesis is marked "unverifiable" (not "true")

**Confidence Integrity**
8. Confidence scores must reflect evidence quality, not investigator preference
9. Confidence floor: hypothesis with no supporting evidence = 0 points
10. Confidence ceiling: hypothesis with all assertions verified and no contradictions = 95 points (never 100% unless all possible evidence examined)
11. Confidence decay: as contradictions accumulate, score cannot increase
12. Multiple passes of the same evidence don't increase confidence (diminishing returns)

**Falsifiability**
13. Every hypothesis must define conditions under which it would be disproven
14. Unfalsifiable hypotheses (e.g., "ghosts caused it") are rejected immediately
15. Falsification criteria must be testable within the evidence set or explicitly noted as "outside investigation scope"

**Coherence Across Phases**
16. Hypothesis ranking must not reverse between THEORIZE and VERIFY without explicit reasoning
17. If top hypothesis from THEORIZE fails validation in VERIFY, document why pre-validation confidence was misaligned
18. Hypotheses generated in THEORIZE that receive zero supporting evidence in PROBE should be deprioritized
19. New evidence discovered in CLOSE phase should trigger VERIFY re-run, not ad-hoc acceptance

**Meta-Coherence**
20. The set of accepted hypotheses must be mutually compatible (no two hypotheses that contradict each other can both be accepted)
21. If multiple hypotheses are equally viable after VERIFY, final decision rests with user (HITL), not system
22. Investigation narrative (timeline + causal chains) must be coherent—events must occur in sequence that makes logical sense

## Risk Analysis Extension (BCRA)

These evidence rules apply equally to Boundary Chain Risk Analysis:

**Certainty Scores ARE Claims**
23. Every Blast Score Certainty rating is a claim. It must cite evidence (primary source, test result, or community report).
24. A Certainty of STRONG (0.80+) without a primary source citation is a SHERLOCK violation.
25. "Should work" is not a Certainty rating. "SPECULATIVE (0.30) — no evidence found" is honest.
26. When research changes a Certainty score, the CHANGE must be attributed to specific evidence, not vibes.

**Witness Classification IS a Claim**
27. Classifying a boundary as Witnessed (×1) is a claim that the system self-reports failures. Cite HOW it reports (error code, exception, log line).
28. Classifying as Unwitnessed (×2) is a claim that failure is silent. Cite what a silent failure looks like (null content, wrong format accepted, no error logged).
29. If uncertain whether failure is witnessed or unwitnessed, default to ×2 (silent). Overconfidence on detection is the most dangerous error.

## Non-Negotiable (ALL modes)

- No hypothesis or Certainty rating may be stated as fact without evidence
- Confidence/Certainty scores must be defensible — every point must be attributed to specific evidence
- Deliverables must include confidence ranges and caveats, not false certainty
- "I don't know" and "We lack:" are valid, honest answers. Fabricated certainty is not.
