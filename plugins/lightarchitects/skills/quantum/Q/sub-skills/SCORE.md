---
name: SCORE
description: "Calculate Blast Scores — assign Blast, Certainty, and Witness to each boundary and compute compound score."
user-invocable: false
context: fork
version: 1.0.0
---

# SCORE — Phase 3: Calculate Blast Scores

> Numbers, not feelings. Every score cites its evidence.

## Procedure

For each boundary from PULL:

1. **Assign Blast (1-10)**: What do we lose if this fails?
   - 1-2: Retry with no cost (re-run a command)
   - 3-4: Minutes lost (re-download, re-configure)
   - 5-6: Hours lost (restart training from checkpoint)
   - 7-8: Significant loss (restart training from scratch, wasted GPU hours)
   - 9-10: Total loss (money burned, data corrupted, must redesign approach)

2. **Assign Certainty (0.0-1.0)**: How sure are we this works?
   - DEFINITIVE (0.95+): Primary source confirms AND we tested it ourselves
   - STRONG (0.80-0.94): Primary source confirms, no counter-evidence found
   - MODERATE (0.60-0.79): Secondary sources suggest, not directly verified
   - LOW (0.40-0.59): Assumption with some basis
   - SPECULATIVE (0.0-0.39): Guess. **Flag for mandatory research.**

3. **Assign Witness (×1 or ×2)**: Does failure self-report?
   - ×1: System crashes, throws error, logs failure
   - ×2: System continues silently with wrong output

4. **Calculate**: `Blast Score = Blast × (1 − Certainty) × Witness`

5. **Flag hot threads**: Any individual score > 3.0 = hot thread (must research)

## Output

```
| # | Boundary | Blast | Certainty | Witness | Score | Status |
|---|----------|-------|-----------|---------|-------|--------|
| B1 | Corpus → Tokenizer | 8 | 0.95 (DEFINITIVE) | ×2 | 0.8 | ✓ |
| B3 | HF → Disk | 7 | 0.50 (LOW) | ×2 | 7.0 | 🔥 HOT |

Compound Blast Score: X.X
Verdict: GREEN / YELLOW / RED / HALT
```
