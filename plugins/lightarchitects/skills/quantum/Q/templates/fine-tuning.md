---
name: fine-tuning
description: "Domain template for LLM fine-tuning chain maps. Pre-identified boundaries from real training sessions."
version: 1.0.0
validated: 2026-03-25
validated_against: "Arbiter (Golf) Nemotron 49B training + GPT-OSS Exodus (failure case)"
---

# Fine-Tuning Chain Map Template

> Pre-built boundary chain for LLM fine-tuning workflows. Every boundary validated against real sessions.

## Standard Fine-Tuning Chain

```
CORPUS → [B1] → TOKENIZER → [B2] → MODEL_LOAD → [B3] → GPU_VRAM
  → [B4] → LORA_APPLY → [B5] → TRAINER_CONFIG → [B6] → TRAINING_LOOP
  → [B7] → CHECKPOINT_SAVE → [B8] → MERGE → [B9] → UPLOAD
  → [B10] → SERVE → [B11] → API → [B12] → CLIENT
```

## Pre-Scored Boundaries

| # | Boundary | Default Blast | Default Witness | Known Silent Failures | Research Checklist |
|---|----------|--------------|----------------|----------------------|-------------------|
| B1 | Corpus → Tokenizer | 9 | ×2 UNWITNESSED | Wrong chat template trains silently. Loss decreases but model learns garbage. ChatML on Harmony model. Llama tokens on GPT-OSS. | Compare corpus tokens with model's `tokenizer_config.json`. Check `chat_template` field. Verify EOS token matches. |
| B2 | HuggingFace → Local Disk | 7 | ×2 UNWITNESSED | Cache writes to container disk (50GB) not volume (300GB). Fills silently until `os error 28`. | Set `HF_HOME` in script line 1. Check `df -h` before download. Symlink `~/.cache/huggingface → /workspace/huggingface`. |
| B3 | Model → GPU VRAM | 8 | ×1 WITNESSED | OOM crash (loud). But OOM during checkpoint save at step N wastes ALL prior compute. | Calculate: model_size + LoRA + optimizer + gradients + activations + checkpoint_overhead < VRAM × 0.85 |
| B4 | Framework → Model Architecture | 7 | ×1 WITNESSED | Import errors (custom code, deprecated APIs). `trust_remote_code` required. transformers version mismatch. | Read `config.json` → check `architectures` field. Test `import` before full run. Check for `custom_code` tag on HF. |
| B5 | LoRA → Model Layers | 6 | ×2 UNWITNESSED | NAS models: some layers have no attention (no_op). PEFT skips silently — trains fewer layers than expected. | Read `block_configs` in config.json. Count which layers have which modules. Verify target modules exist. |
| B6 | Trainer Config → Data Format | 5 | ×1 WITNESSED | `train_on_responses_only` requires explicit markers. Wrong format → ValueError. Missing EOS → model won't learn to stop. | Test on 10 examples first. Verify EOS at end of every output. Check response marker format. |
| B7 | Training → Checkpoint Save | 8 | ×1 WITNESSED | OOM spike during save (step 499). Checkpoint saves to wrong disk. | Verify output_dir is on volume. Calculate VRAM headroom for save operation. Use `save_total_limit`. |
| B8 | LoRA → Merged Model | 7 | ×2 UNWITNESSED | Broken tokenizer in merged output (Unsloth GPT-OSS: `TokenizersBackend`). Config.json not preserved. | Test merge on small checkpoint. Verify `config.json` and `tokenizer_config.json` in output. |
| B9 | Merged Model → HuggingFace | 4 | ×1 WITNESSED | Upload timeout for 98GB. Auth failure. | Verify HF token has write access. Check upload bandwidth estimate. |
| B10 | vLLM → Merged Model | 8 | ×2 UNWITNESSED | Architecture not recognized. Custom renderer returns null content. Wrong vLLM version. | Pin vLLM to vendor-recommended version. Test BASE model serving before testing fine-tune. Check for custom renderers. |
| B11 | vLLM → Tool Parser | 5 | ×1 WITNESSED | Custom tool parser plugin not found. Wrong parser name. | Clone base model repo for parser file. Verify parser filename and flag. |
| B12 | API → Client (IronClaw) | 3 | ×1 WITNESSED | URL format mismatch. Timeout too short for cold start. Auth header not needed but sent. | Test curl to endpoint. Verify URL construction in client code. Check timeout setting. |

## Lessons Learned (from real failures)

| Session | Failure | Boundary | Root Cause |
|---------|---------|----------|-----------|
| GPT-OSS Exodus | content:null from vLLM | B10 | Harmony renderer + fine-tune format mismatch |
| GPT-OSS Exodus | Broken tokenizer after merge | B8 | Unsloth wrote `TokenizersBackend` class that doesn't exist |
| GPT-OSS Exodus | H100 OOM | B3 | MXFP4 72GB model + 32K KV cache exceeded 80GB |
| Nemotron v1 | OOM at step 499 | B7 | Single GPU, checkpoint save memory spike |
| Nemotron v2 | Disk full (os error 28) | B2 | HF cache on container disk, not volume |
| Nemotron v2 | transformers import error | B4 | `NEED_SETUP_CACHE_CLASSES_MAPPING` removed in v5.x |
| Nemotron v2 | train_on_responses ValueError | B6 | Explicit `instruction_part`/`response_part` required |
