---
name: RESEARCH
description: "Research Hot Threads — investigate any boundary with Blast Score > 3.0 using the shared PROBE-SOURCES.md 3-tier protocol. Tier 1: SOUL Helix (institutional memory). Tier 2: Context7 (vendor docs, library APIs) + HuggingFace (ML model cards, papers, training technique research). Tier 3: quantumTools research (helix + Perplexity/Sonar, server-side) + Firecrawl CLI (full-page extraction, failure-pattern search)."
user-invocable: false
context: fork
version: 2.0.0
---

# RESEARCH — Phase 4: Research Hot Threads

> Every hot thread gets investigated. No exceptions. No "should work."

## Trigger

Any boundary with Blast Score > 3.0 is a hot thread. Research is MANDATORY before proceeding.

## Research Protocol

For each hot thread, **read `sub-skills/PROBE-SOURCES.md` now**, then follow its 3-tier dispatch protocol.

PROBE-SOURCES.md defines the dispatch order and parallel execution rules. What follows is the hot-thread-specific guidance layered on top of that protocol.

### Source Selection by Hot Thread Type

Use the PROBE-SOURCES.md Query Classification Guide as the primary routing table. Supplement with the domain-specific notes below:

| Hot Thread Domain | Primary Tier 2 Source | Primary Tier 3 Source | Notes |
|-------------------|----------------------|----------------------|-------|
| Library / API error | Context7 (`resolve-library-id` + `query-docs`) | Firecrawl GitHub issues | Use exact version in query |
| ML model behavior / training | HuggingFace (`hub_repo_search` for model card, `paper_search` for technique) | Firecrawl vendor docs + quantumTools research | Model card is PRIMARY evidence |
| Security / CVE | — (skip Context7 unless library-specific) | quantumTools research (Perplexity/Sonar routes server-side) | Check OPEN issues on GitHub |
| Infrastructure / capacity | Context7 if provider has SDK | Firecrawl release notes + quantumTools research | Check exact version numbers |
| General / unknown | Context7 if library involved | quantumTools research primary | Cast wide net, narrow after |

### Precision Search Doctrine

**Use EXACT names, versions, and configs in every query.**

- NOT: "Nemotron training issues"
- YES: "Llama-3.3-Nemotron-Super-49B-v1.5 QLoRA Unsloth transformers 5.x error"

**Failure search with GitHub category filter (mandatory for high-blast threads):**
```bash
firecrawl search "exact_model_name error OR issue OR bug" --categories github --tbs qdr:m
```

`--categories github` scopes directly to GitHub repos and issues. `--tbs qdr:m` limits to the past month — catches recent regressions that post-cutoff docs won't mention.

**Combined search + full-page extraction (preferred over two separate calls):**
```bash
firecrawl search "exact_query" --scrape --only-main-content --limit 3
```

Use this when you need full page content from results. Only call `firecrawl scrape URL` separately when you already have the exact URL.

**Security and CVE hot threads:**
```bash
firecrawl search "CVE-XXXX advisory" --sources news --tbs qdr:y
```

Read full issue threads. Check OPEN vs CLOSED status. A closed issue with a workaround is evidence; an open issue with no response is uncertainty — increase Witness multiplier accordingly.

## Evidence Classification

Tag every finding from PROBE-SOURCES.md tiers with:

| Grade | Sources |
|-------|---------|
| INSTITUTIONAL | Knowledge (Charlie) Helix — prior decisions, squad history, earned knowledge |
| AUTHORITATIVE | Context7 — vendor docs, library API specs (version-specific) |
| ACADEMIC | HuggingFace — peer-reviewed papers, model cards, training technique research |
| CURRENT | quantumTools research, Firecrawl — community reports, release notes, failure patterns |

INSTITUTIONAL + AUTHORITATIVE is the strongest combination. A finding backed only by CURRENT is UNVERIFIED until corroborated.

## Output Format

**All outputs conform to Canon XXI — Research Output Standard.**
Full spec: `~/lightarchitects/soul/helix/user/standards/research-output-standard.md`

Every hot thread finding: confidence score (0.00–1.00) + grade band + evidence tagged `[GRADE][N]` + contradictions explicit + gaps declared + IEEE bibliography. No hedge words.

## Output (per hot thread)

```
─────────────────────────────────────────────
FINDING B3 — HuggingFace Cache Path Exhaustion
Sibling: Analyst (Delta) (Risk Analysis)
Date: YYYY-MM-DD
Confidence: 0.95 · Grade: DEFINITIVE
─────────────────────────────────────────────
Verdict:
  Pod disk exhausted. HF_HOME defaults to ~/.cache/huggingface on a 50GB disk while the
  model requires 98GB. Root cause confirmed by AUTHORITATIVE + CURRENT corroboration.

Evidence:
  [AUTHORITATIVE][1]  HF_HOME defaults to ~/.cache/huggingface. — HuggingFace transformers docs §EnvVars
  [ACADEMIC][2]       Llama-3.3-Nemotron-Super-49B-v1.5 model: 98GB safetensors. — HuggingFace Hub model card
  [CURRENT][3]        os error 28 with identical model on 50GB disk (CLOSED). — GitHub huggingface_hub#4821
  [CURRENT][4]        HF_HOME=/workspace is standard RunPod pattern. — quantumTools research / Perplexity

Contradictions:
  None.

Gaps:
  Tier 1 (INSTITUTIONAL): No prior Analyst (Delta) helix entries on HF disk layout.
                           Confidence impact: cannot apply institutional pattern.

Recommendation:
  Set HF_HOME=/workspace/huggingface in script line 1. Symlink as backup.

Bibliography:
  [1] HuggingFace. "Environment Variables — HF_HOME." Transformers Documentation, 2025.
      https://huggingface.co/docs/transformers/en/installation#cache-setup
  [2] NVIDIA. "Llama-3.3-Nemotron-Super-49B-v1.5 Model Card." HuggingFace Hub, 2025.
      https://huggingface.co/nvidia/Llama-3_3-Nemotron-Super-49B-v1_5
  [3] HuggingFace. "Issue #4821: os error 28 on limited disk." GitHub Issues, closed 2026-01-15.
      https://github.com/huggingface/huggingface_hub/issues/4821
  [4] Perplexity AI (Sonar). "RunPod HF_HOME standard pattern." Perplexity.ai, queried YYYY-MM-DD.
      [No permanent URL — synthesis]
─────────────────────────────────────────────
Previous Score: 7.0 (Blast=7, Certainty=0.50, Witness=×2)
New Certainty: 0.95 (DEFINITIVE — AUTHORITATIVE + CURRENT corroboration, fix trivial and tested)
New Score: 7 × 0.05 × 2 = 0.7
```
