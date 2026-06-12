---
name: PROVE
description: "Prove the Chain — re-score all boundaries after research and determine if the plan meets the threshold."
user-invocable: false
context: fork
version: 1.0.0
---

# PROVE — Phase 5: Prove the Chain

> Re-score with evidence. The arithmetic must pass. ≥99.9% target.

## Procedure

1. **Re-score every boundary** using updated Certainty from RESEARCH phase
2. **Recalculate compound Blast Score** (sum of all individual scores)
3. **Calculate compound probability**: P(success) = product of all (Certainty) values
4. **Apply verdict thresholds**:

| Compound Score | Compound Probability | Verdict |
|----------------|---------------------|---------|
| < 2.0 | ≥ 95% | **GREEN — Proceed** |
| 2.0 - 5.0 | 85-95% | **YELLOW — Proceed with monitoring** |
| 5.0 - 10.0 | 60-85% | **RED — More research needed** |
| > 10.0 | < 60% | **HALT — Redesign** |

5. **If any single boundary** still has Blast Score > 5.0 → that boundary alone is a HALT regardless of compound

## Output

```
=== CHAIN PROOF: [Plan Name] ===

| # | Boundary | Before | After Research | Evidence |
|---|----------|--------|---------------|----------|
| B1 | Corpus → Tokenizer | 0.8 | 0.3 | Verified: Llama 3 tokens match model |
| B3 | HF → Disk | 7.0 | 0.7 | Fixed: HF_HOME set to volume |

Compound Blast Score: X.X (was Y.Y before research)
Compound Probability: XX.X%
Verdict: GREEN / YELLOW / RED / HALT
```

## HITL Checkpoint

the operator decides: proceed, research more, or redesign.

This is the gate. No plan passes without the operator seeing the numbers.
