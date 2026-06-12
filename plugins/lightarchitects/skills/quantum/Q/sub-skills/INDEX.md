---
name: INDEX
description: "Navigation index for all Q sub-skills across Investigation and Risk Analysis modes."
user-invocable: false
context: fork
version: 2.3.0
---

# /Q Sub-Skills Index

Analyst (Delta)'s sub-skills power two operational modes: **Investigation** (incident analysis) and **Risk Analysis** (pre-flight risk assessment). Cross-cutting governance applies to both.

## Investigation Cycle (Section B) — 7 phases

| File | Phase | Purpose | qsTools Action |
|------|-------|---------|----------------|
| **SCAN.md** | 0 | Scene assessment — triage, severity, pattern match | `scan` |
| **SWEEP.md** | 1 | Evidence collection — extraction, chain of custody | `sweep` |
| **TRACE.md** | 2 | Pattern forensics — timeline, error clusters, root causes | `trace` |
| **PROBE.md** | 3 | Multi-source research — helix + Context7 + Firecrawl + HuggingFace | `probe` |
| **THEORIZE.md** | 4 | Hypothesis generation — ranked with evidence mapping | `theorize` |
| **VERIFY.md** | 5 | Solution validation — N-MultiPass against evidence | `verify` |
| **CLOSE.md** | 6 | Deliverable generation — RCA report, action items | `close` |

## Risk Analysis — Boundary Chain (Section D) — 6 phases

| File | Phase | Purpose |
|------|-------|---------|
| **MAP.md** | 1 | Map every boundary from input to output |
| **PULL.md** | 2 | Pull each thread — Format? Capacity? Witness? |
| **SCORE.md** | 3 | Calculate Blast Scores (Blast × (1 − Certainty) × Witness) |
| **RESEARCH.md** | 4 | Investigate hot threads (score > 3.0) from primary sources |
| **PROVE.md** | 5 | Re-score after research — compound < 5.0 to proceed |
| **DECLARE.md** | 6 | Declare remaining gaps — "We lack:" is a complete statement |

## Cross-Cutting Governance — applies to ALL modes

| File | Purpose | Version |
|------|---------|---------|
| **SHERLOCK.md** | Evidence integrity — every claim (hypothesis OR Certainty score) cites its source | v2.0 |
| **GATE.md** | Phase gates + HITL checkpoints + escalation triggers for Investigation AND Risk Analysis | v2.0 |
| **CURATOR.md** | Claim registration and tracking (Investigation mode) | v1.0 |

## Domain Templates

| File | Domain | Boundaries | Validated |
|------|--------|-----------|-----------|
| `templates/fine-tuning.md` | LLM fine-tuning | 12 boundaries | 2026-03-25 |

## Research Tools (mandatory for PROBE and RESEARCH phases)

Governed by the shared **PROBE-SOURCES.md** 3-tier protocol. All research phases follow that dispatch order.

| Tool | Purpose |
|------|---------|
| **PROBE-SOURCES.md** | Shared 3-tier dispatch protocol — Tier 1 (SOUL Helix), Tier 2 (Context7+HuggingFace), Tier 3 (quantumTools research + Firecrawl CLI) |
| **RESEARCH-OUTPUT-STANDARD.md** | Canon XXI output format — confidence grades, evidence tags, contradiction protocol, gaps protocol, IEEE citations. Canonical: `~/lightarchitects/soul/helix/user/standards/research-output-standard.md` |
| **Context7** | Library/API documentation (resolve-library-id + query-docs) |
| **HuggingFace** | Model cards, papers, repo details (paper_search, hub_repo_search, hf_doc_search) |
| **Firecrawl CLI** | Complete web context via Bash — full pages, failure-pattern search (search, scrape) |
| **quantumTools research** | helix + Perplexity (Sonar) synthesis, routed server-side. Note: `action:"probe"` is internal sources only (Jira/Confluence/docs). |
| **SOUL Helix** | Institutional memory, prior investigations, prior decisions (soulTools) |
| **GitHub** | Issue status, PR merges, known bugs (gh issue view, gh pr view) |

## Changelog

| Version | Date | Change |
|---------|------|--------|
| v1.0 | 2026-02-21 | Initial 11 sub-skills (7 investigation + 4 cross-cutting) |
| v2.0 | 2026-03-25 | Added 6 Risk Analysis sub-skills (MAP→DECLARE). ESCALATION merged into GATE. SHERLOCK extended for Blast Score integrity. Added templates/ directory. |
| v2.1 | 2026-03-27 | Added PROBE-SOURCES.md — shared 3-tier research source protocol (Tier 1: SOUL Helix, Tier 2: Context7+HuggingFace, Tier 3: quantumTools research + Firecrawl CLI). PROBE.md and RESEARCH.md updated to reference it. q.md updated with Firecrawl CLI section. |
| v2.2 | 2026-03-27 | Fixed PROBE-SOURCES.md Tier 3: `action:"probe"` (internal sources only) corrected to `action:"research"` (helix + Perplexity/Sonar). Confirmed by live test — probe routes to Jira/Confluence/docs, research routes to web. |
| v2.3 | 2026-03-27 | Added Research Output Standard (Canon XXI). PROBE-SOURCES.md v1.3.0 — output standard section added. All research phases (PROBE, RESEARCH) now reference the canonical output format. `~/lightarchitects/soul/helix/user/standards/research-output-standard.md` |
