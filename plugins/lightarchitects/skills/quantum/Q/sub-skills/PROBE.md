---
name: PROBE
description: "Phase 3 of QUANTUM's investigation cycle. Multi-source research using the shared PROBE-SOURCES.md 3-tier protocol: Tier 1 (SOUL Helix, institutional memory), Tier 2 (Context7 + HuggingFace, authoritative/academic, parallel), Tier 3 (quantumTools research + Firecrawl CLI, web/current, parallel with Tier 2). Results synthesized with source grading and ranked by relevance to root cause candidates."
user-invocable: false
context: fork
version: 2.0.0
---

# PROBE — Phase 3: Multi-Source Research

> Every claim cites its source. Agreement strengthens confidence. Contradiction demands investigation.

## Purpose

PROBE is the knowledge synthesis phase. Given root cause candidates from TRACE, it gathers evidence from institutional memory, authoritative library docs, academic research, and current web intelligence — then synthesizes findings with source grading and relevance ranking.

## quantumTools Action

`probe` — maps to `quantumTools`

## Procedure

### Step 1 — Sanitize Queries

Strip PII, credentials, customer names; generalize to patterns before any external query.

### Steps 2–3 — Evidence Gathering

**Read `sub-skills/PROBE-SOURCES.md` now. Follow its 3-tier dispatch protocol exactly.**

PROBE-SOURCES.md defines the 3-tier dispatch order:
- **Tier 1** (Knowledge (Charlie) Helix, sequential, runs first)
- **Tier 2 + Tier 3** (Context7, HuggingFace, quantumTools research, Firecrawl CLI — single message block, parallel)

The dispatch protocol, source selection rules, graceful-skip criteria, and query classification guide are all in PROBE-SOURCES.md. Do not improvise a different dispatch order.

### Step 4 — Deduplicate Results

Remove duplicates across sources. Prefer higher-tier evidence when the same finding appears in multiple tiers.

### Step 5 — Synthesize Findings

Merge results. Tag each finding with its evidence grade (INSTITUTIONAL / AUTHORITATIVE / ACADEMIC / CURRENT). Identify consensus areas and contradictions.

### Step 6 — Assign Citations

Add IEEE-format citations to each finding.

### Step 7 — Rank by Relevance

Score results against root cause candidates (0.0–1.0 match confidence).

### Step 8 — Flag Contradictions

Highlight any research that contradicts forensic evidence from TRACE. A contradiction is a finding, not noise.

## Inputs

- Root cause candidates from TRACE (Phase 2) with evidence citations
- Query sanitization rules: PII patterns, credential regex
- Helix vault index (Knowledge (Charlie))

## Output Format

**All outputs conform to Canon XXI — Research Output Standard.**
Full spec: `~/lightarchitects/soul/helix/user/standards/research-output-standard.md`

Every finding: confidence score (0.00–1.00) + grade band + evidence tagged `[GRADE][N]` + contradictions explicit + gaps declared + IEEE bibliography. No hedge words.

## Outputs

- Research synthesis report (JSON/Markdown):
  - `helix_findings`: array of past investigations with relevance scores (INSTITUTIONAL grade)
  - `authoritative_findings`: Context7 library/API docs with version specificity (AUTHORITATIVE grade)
  - `academic_findings`: HuggingFace papers, model cards (ACADEMIC grade)
  - `web_findings`: quantumTools research + Firecrawl results with URLs and citations (CURRENT grade)
  - `consensus`: areas where multiple tiers agree
  - `contradictions`: findings that conflict with forensic evidence
  - `relevance_scores`: per-candidate match confidence (0.0–1.0)
  - `citations`: IEEE format bibliography
  - `confidence_assessment`: overall confidence in research (0.0–1.0)

## HITL Checkpoint

**User decides**:
- Accept research findings, or request deeper search on specific queries
- Flag any results that seem unreliable or off-topic
- Identify contradictions with forensic evidence and decide how to resolve them
- Proceed to THEORIZE (Phase 4) or request additional research
