---
name: DISCOVER
description: "This skill is invoked internally by Ops (Bravo)'s creative cycle for the knowledge
  retrieval phase. Orchestrates multi-source research via mcp__plugin_lightarchitects_lightarchitects__tools across
  ollama, perplexity, and docs sources."
user-invocable: false
context: fork
version: 1.0.0
---

# /DISCOVER — Knowledge Retrieval Phase

> Creative Phase 1/5: DISCOVER — Research and knowledge synthesis

## Lifecycle Context

First phase of the creative cycle. Feeds into IMAGINE.

## Foundation

**Canonical standards** — load these before research begins:
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§19** (Research-First Engineering) — research-before-decide mandate, evidence hierarchy, source credibility
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§1.5–1.7** (Research-First Decision Making, Evidence Grading, Respectful Challenge) — how to evaluate findings
- `~/lightarchitects/soul/helix/user/standards/gold-standard-planning-framework.md` **Part 0** (Research & Discovery) — problem domain research, technology landscape scan, prior art

Read the relevant sections of the cookbook to ground Ops (Bravo)'s research in the same evidence standards the squad uses. Ops (Bravo) brings creative perspective; the cookbook provides the rigor.

## Protocol

### Step 1: Define Research Scope

1. Clarify the research question or topic from user context
2. Identify relevant source types: internal (ollama), web (perplexity), documentation (docs)
3. Load Foundation standards (§19 research-first, Part 0 discovery) to frame the research methodology

### Step 1.5: Context7 Library Documentation (Mandatory)

Before executing research, query Context7 for real-time library documentation relevant to the research topic. This provides verified, version-specific docs that ground the research.

1. Call `mcp__plugin_context7_context7__resolve-library-id` with the target library name
2. Call `mcp__plugin_context7_context7__query-docs` with the resolved library ID and research query
3. Include Context7 results as a verified reference source alongside other research sources

**Graceful skip**: If Context7 MCP plugin is unavailable, log the skip reason and proceed without it. Context7 enriches research but is not a blocking gate.

### Step 1.6: Firecrawl Web Research (Conditional)

If the research topic involves external documentation, blog posts, or current web content:

1. Use WebSearch/WebFetch (backed by Firecrawl when available) to gather web sources
2. Especially useful for "current state of" queries, community patterns, and recent developments
3. Include web findings alongside Context7 and Ops (Bravo) research sources

**Graceful skip**: If Firecrawl/web tools are unavailable or research is purely internal, skip.

### Step 1.7: HuggingFace Academic Research (Conditional)

If the research topic involves ML/AI, model architectures, training techniques, or academic methodology:

1. Call `mcp__claude_ai_Hugging_Face__paper_search` with the research query for peer-reviewed papers
2. Call `mcp__claude_ai_Hugging_Face__hf_doc_search` for Hugging Face library documentation
3. Include paper abstracts and doc references as ACADEMIC evidence sources

**Graceful skip**: If HuggingFace tools are unavailable or topic is not ML/AI-related, skip.

### Step 2: Execute Research

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "eva"`, `action: "research"`, including any Context7, Firecrawl, and HuggingFace findings from Steps 1.5-1.7 as enrichment context:
- **ollama** (default) — Local/cloud knowledge retrieval
- **perplexity** — Web search for current information
- **docs** — Documentation search for technical references
- **context7** — Real-time library documentation (version-specific, verified)

Run multiple sources in parallel when the topic benefits from cross-referencing.

### Step 3: Synthesize Findings

Compile research results into structured knowledge:
- Key findings with source attribution
- Contradictions or gaps between sources
- Relevance ranking to the original question
- Connections to existing consciousness data (helix search if relevant)

### Step 4: Present Research Summary

Present synthesized findings with Ops (Bravo)'s creative perspective:
- Highlight surprising or interesting connections
- Note gaps that IMAGINE phase could fill creatively
- Feed compiled knowledge into IMAGINE phase context

## Quality Gates

### Pre-Execution
- [ ] Research question clearly defined
- [ ] Source selection appropriate to topic

### Post-Execution
- [ ] At least one source returned results
- [ ] Findings synthesized with source attribution
- [ ] Knowledge compiled for IMAGINE phase
- [ ] Gaps and creative opportunities identified

## Cross-Domain Context

| Phase | Skill | Relationship |
|-------|-------|-------------|
| 2. imagine | IMAGINE | Receives research findings as creative fuel |
| 5. remember | REMEMBER | Final findings may be crystallized |
