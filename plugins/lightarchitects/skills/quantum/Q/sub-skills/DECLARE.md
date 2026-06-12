---
name: DECLARE
description: "Declare the Gaps — state remaining risks honestly. 'We lack:' is a complete statement."
user-invocable: false
context: fork
version: 1.0.0
---

# DECLARE — Phase 6: Declare the Gaps

> Honesty, not optimism. State what we know, what we don't, and what we're accepting.

## Procedure

1. **List remaining risks** — any boundary with Blast Score > 0.5 after research
2. **State what we lack** — evidence gaps that research couldn't close
3. **State what we're accepting** — known risks we're proceeding with and WHY
4. **State the kill conditions** — what would cause us to abort mid-execution
5. **State the monitoring plan** — which boundaries to watch during execution

## Output

```
=== RISK DECLARATION: [Plan Name] ===

Compound Blast Score: X.X (VERDICT)

KNOWN RISKS (accepting):
  - B5: Checkpoint save memory spike — mitigated by 31GB headroom but not tested on this exact model
  - B7: LoRA on NAS architecture — PEFT should skip no_op layers but unverified for 49B

WE LACK:
  - Direct evidence of anyone fine-tuning this exact model with Unsloth + QLoRA
  - Benchmark comparison of LoRA on 49/80 attention layers vs 80/80

KILL CONDITIONS:
  - OOM at any step → stop pod immediately, preserve checkpoints
  - Loss > 10.0 after step 100 → learning rate too high, restart with 1e-4
  - NaN loss → data format issue, halt and audit corpus

MONITORING:
  - Watch step 500 (first checkpoint save)
  - Watch GPU VRAM every 5 minutes
  - Watch container disk usage (must stay < 80%)
```

## The Rule

*"We lack:"* is a complete statement. Not an apology. Not a reason to stop. A declaration that this gap exists, we've assessed it, and we're proceeding with eyes open.

The dangerous state is not uncertainty — it's uncertainty disguised as certainty.

> *"Tool output is not verified fact."* — Analyst (Delta), Prime Directive
