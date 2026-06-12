---
name: PROBE-SOURCES
description: "Shared 3-tier research source protocol for PROBE (Phase 3, investigation cycle) and RESEARCH (Phase 4, risk analysis). Tier 1: SOUL Helix (institutional memory, sequential). Tier 2: Context7 + HuggingFace (authoritative/academic, parallel). Tier 3: quantumTools research (helix + Perplexity/Sonar, server-side) + Firecrawl CLI (full-page extraction, Bash). Tiers 2 and 3 dispatch in a single message block. Output: Research Output Standard (Canon XXI) — verdict + evidence grades + contradictions + gaps + IEEE citations."
user-invocable: false
context: fork
version: 1.3.0
---

# PROBE-SOURCES — 3-Tier Research Source Protocol

> Every claim cites its source. Agreement strengthens confidence. Contradiction demands investigation.

Shared protocol invoked by both **PROBE.md** (investigation cycle Phase 3) and **RESEARCH.md** (risk analysis Phase 4). Single source of truth for evidence gathering across both modes.

---

## Source Architecture

Three tiers. Tier 1 runs first (local, ~5ms). **Tier 2 and Tier 3 dispatch in a single message block — do not serialize what can run in parallel.**

### Tier 1 — Institutional (Sequential, runs first)

**Tool**: `soulTools` action `search` or `helix`

Query the Knowledge (Charlie) vault with relevant keywords, strands, and sibling filter. Prior investigations, squad decisions, and earned institutional patterns often contain the answer before any external query is needed.

- Evidence grade: **INSTITUTIONAL**
- Graceful skip: Knowledge (Charlie) unavailable → note the gap, proceed to Tier 2+3

---

### Tier 2 — Authoritative + Academic (Parallel, second)

Dispatch both in a **single message block** after Tier 1 returns.

| Tool | When to fire | Evidence grade |
|------|-------------|----------------|
| `resolve-library-id` → `query-docs` (Context7) | Query involves a specific library, framework, or API | **AUTHORITATIVE** |
| `paper_search` + `hf_doc_search` + `hub_repo_search` (HuggingFace) | Query involves ML/AI models, training, research papers, or HF libraries (Transformers, TRL, Diffusers, etc.) | **ACADEMIC** |

**Context7 skip criteria**: No library/API component in the query → skip, note.
**HuggingFace skip criteria**: No ML/AI component in the query → skip, note.

At least one Tier 2 source should fire for most investigations. If both skip, flag the query as outside the authoritative coverage zone — Tier 3 carries more weight.

Graceful skip: Tool unavailable → note the gap, continue.

---

### Tier 3 — Current + Community (Parallel, second — same dispatch as Tier 2)

Dispatch alongside Tier 2 in the same message block.

| Tool | How to call | Evidence grade | When to use |
|------|-------------|----------------|-------------|
| `quantumTools action:"research"` | `params: {query: "..."}` | **CURRENT** | General web intelligence, Perplexity (Sonar) synthesis, community patterns — routes helix + Perplexity server-side |
| `firecrawl search` (Bash) | See patterns below | **CURRENT** | Targeted search with source/category/time filtering — use flags to narrow to GitHub issues, research, news, or recent-only |
| `firecrawl scrape URL --only-main-content` (Bash) | `firecrawl scrape URL --only-main-content` | **CURRENT** | Full-page extraction of a known URL — vendor docs, model pages, spec documents |

**quantumTools research** routes to helix (SOUL vault) + Perplexity (Sonar) server-side. Returns synthesis with citations. Use for broad web queries.

> **Do not confuse with `action:"probe"`** — that action searches internal corporate sources only (documentation portal, Jira, Confluence, patterns library). It does NOT hit the web.

**Firecrawl CLI search patterns** — pick the pattern that matches the query type:

```bash
# GitHub issues and repos (failure patterns, bug reports, open issues)
firecrawl search "exact_name error OR bug OR issue" --categories github --tbs qdr:m

# Security advisories and CVEs
firecrawl search "CVE-XXXX OR advisory" --sources news --tbs qdr:y

# Academic and research papers
firecrawl search "technique OR architecture paper" --categories research

# Time-bounded general search (recent only — past week)
firecrawl search "exact_query" --tbs qdr:w

# Combined search + full-page scrape in one call (replaces search then scrape)
firecrawl search "exact_query" --scrape --only-main-content --limit 3
```

Use `--scrape --only-main-content --limit 3` when you need full page content from results — this eliminates a separate `firecrawl scrape URL` call. Use `firecrawl scrape URL` directly only when you already have the exact URL.

**Graceful skip**: Firecrawl CLI unavailable (`which firecrawl` fails) → fall back to `WebSearch` + `WebFetch`. Note reduced coverage. quantumTools research is unaffected (server-side).

---

## Dispatch Protocol

```
Step 1 — Tier 1 (sequential, blocking):
  soulTools search/helix → wait for results

Step 2 — Tier 2 + Tier 3 (single message block, parallel):
  Dispatch ALL of the following that apply in ONE message:
  ├── Context7 resolve-library-id        [if library/API topic]
  ├── Context7 query-docs                [after resolve, or if ID already known]
  ├── HuggingFace paper_search           [if ML/AI/research topic]
  ├── HuggingFace hf_doc_search          [if HF library topic]
  ├── HuggingFace hub_repo_search        [if model/dataset topic]
  ├── quantumTools action:"research"     [always — broad web + Perplexity]
  └── Bash: firecrawl search/scrape      [specific URLs or failure-pattern search]
```

Do not issue Tier 2 and Tier 3 as separate messages. They have no dependencies on each other.

---

## Query Classification Guide

| Query type | Context7 | HuggingFace | Firecrawl (flag) | quantumTools research |
|-----------|:--------:|:-----------:|:----------------:|:--------------------:|
| Library/API error | ✓ **primary** | — | `--categories github --tbs qdr:m` | supplementary — Perplexity may miss GitHub README content |
| ML model behavior | — | ✓ **primary** (model card) | `--scrape --limit 3` vendor pages | ✓ |
| Training technique | — | ✓ **primary** (papers) | `--categories research` | ✓ |
| Security / CVE | — | — | `--sources news --tbs qdr:y` | ✓ **primary** (Perplexity/Sonar) |
| Architecture pattern | ✓ framework docs | ✓ papers | `--categories research` | ✓ |
| Current version / release | — | ✓ trending | `--tbs qdr:w` release notes | ✓ **primary** |
| General investigation | — | — | `--scrape --limit 3` | ✓ **primary** |

---

## Evidence Synthesis

After all tiers return:

1. **Tag each finding** with its source grade: INSTITUTIONAL / AUTHORITATIVE / ACADEMIC / CURRENT
2. **Cross-reference**: findings confirmed across multiple tiers are stronger
3. **Flag contradictions**: when tiers disagree on a critical point, the contradiction is itself a finding
4. **Rank by confidence tier**: INSTITUTIONAL + AUTHORITATIVE > ACADEMIC + CURRENT > single-tier CURRENT
5. **Mark unverified**: any finding backed only by a single CURRENT source is UNVERIFIED until corroborated

## Output Standard

**All research outputs conform to Canon XXI — The Evidence Must Speak.**

Full specification: `~/lightarchitects/soul/helix/user/standards/research-output-standard.md`

Every finding must include:
- **Confidence score** (0.00–1.00) with grade band (DEFINITIVE / HIGH / MODERATE / LOW / UNVERIFIED)
- **Evidence block** — each claim tagged `[INSTITUTIONAL|AUTHORITATIVE|ACADEMIC|CURRENT][N]` with citation
- **Contradictions block** — explicit, never buried in prose. "None." is valid.
- **Gaps block** — what was searched and not found, which tiers were skipped and why
- **Bibliography** — IEEE format, every `[N]` resolves here, dated and traceable

**Forbidden language** (Communication Covenant §2, Canon V): "likely", "probably", "seems to", "I think", "should work", "community reports suggest". Replace with numeric confidence.
