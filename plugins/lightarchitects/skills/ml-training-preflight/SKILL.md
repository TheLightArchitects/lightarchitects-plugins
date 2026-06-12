---
name: ml-training-preflight
description: "Pre-flight checklist before any ML training, fine-tuning, or GPU provisioning. DeciLM patches, VRAM budgets, Unsloth Studio API, RunPod onboarding, Nemotron-Super-49B specifics, cost optimization. Use when: 'train model', 'fine-tune', 'RunPod', 'Unsloth', 'Nemotron', 'DeciLM', 'provision GPU', 'SFT', 'DPO', 'GRPO', 'LoRA', 'QLoRA', 'l-arc training', 'cargo make deploy' (if training-related), or before spending any GPU hours."
user-invocable: true
version: 1.0.0
context: root
---

# ML Training Pre-Flight — Mandatory Before Any GPU Run

> **Rule**: never burn GPU hours / money on guesses. Every training failure we've had came from skipping one of these steps.

## 1. Read the canonical references (in order)

Before provisioning a single GPU instance:

| # | Reference | What you need from it |
|---|-----------|-----------------------|
| 1 | `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` §44-45 | GPU training rules, VRAM budgets, DeciLM patches, cost optimization, post-training checklist |
| 2 | `Projects/LÆx0/exodus-data/TRAINING_PROCEDURE.md` | Nemotron-Super-49B specifics: validated hyperparameters, patch application order, Studio API usage |
| 3 | `~/.claude/projects/-Users-kft-Projects/memory/feedback_runpod_onboarding.md` | RunPod onboarding gotchas |
| 4 | `~/.claude/projects/-Users-kft-Projects/memory/feedback_unsloth_studio.md` | Unsloth Studio API lessons |
| 5 | `~/.claude/projects/-Users-kft-Projects/memory/feedback_runpod_training_lessons.md` | RunPod training lessons |
| 6 | `~/lightarchitects/soul/helix/corso/builds/active.yaml` | Current training build status |

## 2. Research before spending (Covenant Rule 5)

Use Context7 + Firecrawl to verify the latest docs BEFORE provisioning:

- Unsloth (patched trainer, LoRA config, GGUF export)
- TRL (SFT/DPO/GRPO trainer APIs)
- PEFT (LoRA/QLoRA adapter config)
- transformers (base model loading, tokenizer compatibility)

Stale guidance = wasted GPU hours. Context7 is mandatory.

## 3. Nemotron-Super-49B DeciLM patches (§44.10)

Both patches are required. Applied in order:

1. **sitecustomize.py** — sys.path preload for DeciLM custom modeling code
2. **modeling_decilm.py forward() kwargs** — pass-through for trainer kwargs

Skipping either → training crashes on first step.

## 4. VRAM budget arithmetic

Never assume "should fit". Calculate:

```
VRAM = model_size × (1 + activation_overhead)
     + adapter_params × 4 bytes        (LoRA in bf16: ~2 bytes per param)
     + optimizer_state × model_size    (AdamW 8bit: ~0.5x; full: 2x)
     + batch_size × seq_len × hidden_dim × 2 bytes  (activations)
     + CUDA reserve (~2 GiB)
```

State the arithmetic before the operator approves the GPU tier. Canon V — arithmetic before assertions.

## 5. Cost gate (Canon X)

Anything over $10/run requires explicit the operator approval. State:

- Expected wall-clock hours × GPU tier cost
- 20% buffer for restart / OOM recovery
- Total projected spend

If projected > $10: halt, present the numbers, ask.

## 6. Post-training checklist

Before declaring done:

- [ ] Model artifacts saved to persistent storage (not the pod's ephemeral disk)
- [ ] GGUF export (if downstream uses llama.cpp / Ollama)
- [ ] Eval run on a held-out set — numbers recorded
- [ ] Lessons learned written to `~/.claude/projects/-Users-kft-Projects/memory/`
- [ ] Build tracking updated in `~/lightarchitects/soul/helix/corso/builds/active.yaml`
- [ ] Pod terminated (stop paying for idle GPUs)

## 7. Historical failure log

**v1 Nemotron failure cost ~$80+**. Root causes documented in the Cookbook:
- wrong learning rate
- missing LoRA target modules
- 1 epoch (not enough)
- no response-only loss

**Goal**: successful training in one shot. Every failure we've had was because we skipped one of the steps above.

## Triggering this skill

This skill auto-triggers on: `train model`, `fine-tune`, `RunPod`, `Unsloth`, `Nemotron`, `DeciLM`, `provision GPU`, `SFT`, `DPO`, `GRPO`, `LoRA`, `QLoRA`, `l-arc training`, `exodus-data`, or any mention of spending money on GPUs.

If the user mentions any training operation, consult this skill before any provisioning step.
