---
name: PULL
description: "Pull Each Thread — ask the three boundary questions (Format, Capacity, Witness) at every boundary."
user-invocable: false
context: fork
version: 1.0.0
---

# PULL — Phase 2: Pull Each Thread

> For each boundary in the chain, ask three questions. No shortcuts. No assumptions.

## The Three Questions

For **every** boundary identified in MAP:

### 1. FORMAT
- What format does the sender output?
- What format does the receiver expect?
- Are they **identical**? (not "compatible" — identical)
- Evidence: read the actual config, not the README

### 2. CAPACITY
- Does the receiver have room?
- VRAM: model size + KV cache + gradients + optimizer + checkpoint overhead
- Disk: download size + temp files + output + headroom
- Time: does the operation complete within the timeout?
- Budget: cumulative cost so far + estimated remaining

### 3. WITNESS
- If this boundary fails, does the system **announce** the failure?
- **Witnessed (×1)**: crash, exception, error log, non-zero exit code
- **Unwitnessed (×2)**: null content returned, wrong format accepted silently, loss decreasing on garbage, file written to wrong location without error

## Output

A table with one row per boundary:

```
| # | Boundary | Format Match? | Capacity OK? | Witness? |
|---|----------|--------------|-------------|----------|
| B1 | Corpus → Tokenizer | Llama 3 tokens ↔ Llama 3 model: YES | N/A | UNWITNESSED — wrong tokens train silently |
| B2 | HF → Disk | safetensors: YES | 98GB model, 300GB volume: YES | WITNESSED — os error 28 |
```
