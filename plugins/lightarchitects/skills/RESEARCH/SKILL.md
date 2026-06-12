---
name: RESEARCH
description: "Multi-source investigation pipeline via SQUAD. Formulates the research
  question, selects sources, checks helix for prior work, then delegates to SQUAD
  research. Equivalent to the full Analyst (Delta) investigation cycle + Knowledge (Charlie) helix context +
  Ops (Bravo) creative synthesis. Use when the user says '/research', 'research X', 'investigate
  X', 'how does X work', 'deep dive into X'. For runtime issues, use /observe instead."
user-invocable: true
version: 2.0.0
context: root
---

# /RESEARCH — Multi-Source Investigation Pipeline

> Thin wrapper: query formulation + helix check + source selection → SQUAD research.

## When to Use

- User needs to understand how something works (library, API, protocol, design decision)
- User wants to investigate a codebase pattern or prior art
- User says `/research`, "research X", "investigate", "how does X work"
- Before a BUILD when the domain is unfamiliar

## Accepted Flags

None. `/RESEARCH` accepts only the topic argument.

Rejected flags (return error + guidance): `--then`, `--watch`, `--drain`, `--fix`, `--research`.

```
ERROR: /RESEARCH does not accept {flag}.
/RESEARCH has no modifier flags. Use /SQUAD directly for pipeline control:
  /SQUAD research "topic"
```

## Step 1: Argument Validation (SAFEGUARD #24)

Validate the topic argument: `^[a-zA-Z0-9_/. -]+$`. Reject SQUAD control flags and shell metacharacters.

## Step 2: Query Formulation

Before invoking SQUAD, sharpen the research question:

- What is the specific question? (narrow "how does X work" to "what is X's behavior when Y")
- Are there sub-questions that need parallel investigation?
- Which sources are most likely authoritative? (code, docs, web, helix)

## Step 3: Prior Work Check

Check Knowledge (Charlie) helix for existing research on the topic before launching full investigation:

```
mcp__plugin_lightarchitects_lightarchitects__tools sibling:"soul" action:"search" query:"<topic>"
```

If prior research is found, present the helix entries and ask:
- "Build on existing findings?" — continue with SQUAD using the prior context
- "Start fresh?" — proceed with a clean investigation

## Step 4: SQUAD Invocation

```
/SQUAD research "<topic>"
```

No HITL write-path disclosure needed — the research preset has no write operations.

SQUAD agents in the `research` preset run the full Analyst (Delta) investigation cycle (SCAN→SWEEP→TRACE→PROBE→THEORIZE→VERIFY→CLOSE) across Context7 docs, Firecrawl web, HuggingFace papers, GitHub issues, and the Knowledge (Charlie) helix. Ops (Bravo) adds creative pattern recognition and cross-domain synthesis. All claims cite an evidence tier (VERIFIED / MULTI-SOURCE / SINGLE-SOURCE / INFERRED). Full cycle instructions are in `references/presets.md`.

## Contract Canon Integration (Cookbook §82)

Governed by `agent.skill.research`. Adds `standards/canon/contracts/` as a prior-art corpus before drafting new contracts: scans existing kinds + per-kind exemplars to identify reusable shape patterns. Each citation has `evidence_tier`; contract refs in citations carry `contract_id`. Emits `skill.research.invoke` span with `contract_prior_art_count` metadata. No `status_per_provider` mutations.

## Graceful Degradation

If SQUAD is unavailable:

1. QUANTUM research: `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "quantum"` action:`research` query:`"<topic>"`
2. Skip Ops (Bravo) creative synthesis and Knowledge (Charlie) helix context enrichment

Report: "Running Analyst (Delta)-only research."
