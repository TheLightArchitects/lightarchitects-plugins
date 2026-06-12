# /Q Quick Reference

## Commands

| Command | Mode | Description |
|---------|------|-------------|
| `/Q` | Quick | Start Quick Investigation (default) |
| `/Q "symptom"` | Quick | QIC with symptom |
| `/Q full "symptom"` | Full | Full 7-phase investigation |
| `/Q scan ...` | Single | Phase 0: Scene assessment |
| `/Q sweep ...` | Single | Phase 1: Evidence collection |
| `/Q trace ...` | Single | Phase 2: Pattern forensics |
| `/Q probe "query"` | Probe | Multi-source research |
| `/Q theorize ...` | Single | Phase 4: Hypothesis generation |
| `/Q verify ...` | Single | Phase 5: Solution validation |
| `/Q close ...` | Single | Phase 6: Deliverable generation |

## Investigation Lifecycle

```
SCAN → SWEEP → TRACE → PROBE → THEORIZE → VERIFY → CLOSE
 (0)    (1)     (2)     (3)      (4)       (5)     (6)
```

## Quick Investigation Cycle (QIC)

```
ASSESS → DIAGNOSE → MODERATE → APPLY → CONFIRM → HITL
 (Q)      (Q)       (Claude)   (Claude) (Claude)  (User)
```

## quantumTools Actions

| Action | Maps To | CLI |
|--------|---------|-----|
| `scan` | triage-case | `quantum-q scan` |
| `sweep` | analyze-evidence | `quantum-q sweep` |
| `trace` | analyze-evidence | `quantum-q trace` |
| `probe` | research-topic | `quantum-q probe` |
| `theorize` | quantum-synthesis | `quantum-q theorize` |
| `verify` | validate-solution | `quantum-q verify` |
| `close` | generate-deliverables | `quantum-q close` |
| `quick` | triage-case (QIC) | `quantum-q quick` |
| `discover` | tool discovery | `quantum-q discover` |

## Research Sources — 3-Tier Protocol (PROBE-SOURCES.md)

| Tier | Source | Grade | Dispatch |
|------|--------|-------|---------|
| 1 | SOUL Helix (`soulTools search/helix`) | INSTITUTIONAL | Sequential, runs first |
| 2 | Context7 (`resolve-library-id` + `query-docs`) | AUTHORITATIVE | Parallel with Tier 3 — if library/API topic |
| 2 | HuggingFace (`paper_search`, `hf_doc_search`, `hub_repo_search`) | ACADEMIC | Parallel with Tier 3 — if ML/AI topic |
| 3 | quantumTools `research` | CURRENT | Parallel with Tier 2 — helix + Perplexity (Sonar), server-side |
| 3 | Firecrawl CLI via Bash | CURRENT | Parallel with Tier 2 — `--categories github`, `--sources news`, `--scrape` |

Tiers 2 and 3 dispatch in a **single message block**. Never serialize them.
