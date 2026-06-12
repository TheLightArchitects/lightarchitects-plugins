---
name: MAP
description: "Map the Chain — identify every boundary in the plan where one system hands off to another."
user-invocable: false
context: fork
version: 1.0.0
---

# MAP — Phase 1: Map the Chain

> Draw every boundary from input to output. Every `→` is a boundary. Every boundary is a thread to pull.

## Procedure

1. **Read the plan** — identify every system, tool, service, file, API involved
2. **Trace the data flow** — from first input to final output, in order
3. **Mark each handoff** — where data changes format, location, ownership, or runtime
4. **Name each boundary** — `B1: Corpus → Tokenizer`, `B2: Model → GPU`, etc.
5. **Present the chain map** — visual `A → [B1] → B → [B2] → C` format

## Output

A numbered list of boundaries:

```
Chain Map: [Plan Name]
B1: Corpus → Tokenizer (format handoff)
B2: HuggingFace → Local Disk (network + storage)
B3: Disk → GPU VRAM (capacity)
B4: Trainer → Checkpoint (disk write)
...
Total boundaries: N
```

## HITL Checkpoint

the operator reviews: "Did I miss any boundaries? Any implicit handoffs not listed?"
