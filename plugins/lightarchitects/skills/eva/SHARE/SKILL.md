---
name: SHARE
description: "This skill is invoked internally by Ops (Bravo)'s creative cycle for the teaching
  and content creation phase. Orchestrates concept explanation, tutorial creation,
  and survival guides via mcp__plugin_lightarchitects_lightarchitects__tools."
user-invocable: false
context: fork
version: 1.0.0
---

# /SHARE — Teaching & Content Phase

> Creative Phase 4/5: SHARE — Explain, teach, create content

## Lifecycle Context

Follows CRAFT → feeds into REMEMBER.

## Foundation

**Canonical standards** — load these before teaching begins:
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§16** (File & Code Documentation Standards) — function-level comments, API documentation, README structure
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§17** (MCP Server Guidelines) — when teaching MCP patterns
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§15** (Structured Logging & Error Standards) — error message templates, log levels (when teaching observability)
- `~/lightarchitects/soul/helix/user/standards/gold-standard-planning-framework.md` **Part 0** (Research & Discovery) — teaching others how to research and plan

Ops (Bravo) teaches with warmth and personality, but the content must be grounded in the same standards the squad ships by.

## Protocol

### Step 1: Determine Teaching Mode

Based on creative cycle context, select the appropriate mode:
- **explain** — Concept explanation at specified skill level (beginner/intermediate/advanced)
- **tutorial** — Step-by-step guide with practical exercises
- **survival** — Emergency preparedness and self-sufficiency (from the operator's Zettelkasten — Tier 0 only)

### Step 1.5: Context7 Reference Material (Mandatory)

Before teaching, query Context7 for current library documentation to ground tutorials in verified, version-specific examples.

1. Call `mcp__plugin_context7_context7__resolve-library-id` with the library/framework being taught
2. Call `mcp__plugin_context7_context7__query-docs` with the resolved ID and teaching-focused queries (e.g., "getting started", "examples", "best practices")
3. Use Context7 results to ensure code examples are current and accurate

**Graceful skip**: If Context7 is unavailable, proceed without it. Context7 enriches tutorial accuracy but is not a blocking gate.

### Step 2: Execute Teaching Operation

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "eva"`, `action: "teach"` (including Context7 reference material from Step 1.5):
- `mode`: Selected from Step 1
- `topic`: Concept, topic, or survival query
- `level`: Skill level (for explain/tutorial modes)
- `format`: Response format for survival mode (quick_answer/detailed_guide/checklist)

### Step 3: Scripture Integration (Optional)

If the topic has spiritual resonance or the operator requests it:
- Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "eva"`, `action: "bible"`, `params: { mode: "reflect" }` and relevant context
- Weave scripture naturally into the teaching content

### Step 4: Compile Teaching Output

Synthesize teaching results:
- Core concept explained at appropriate level
- Practical examples or exercises
- Key takeaways worth crystallizing
- Material suitable for REMEMBER phase enrichment

## Quality Gates

### Pre-Execution
- [ ] Teaching topic defined (from CRAFT output or user input)
- [ ] Skill level appropriate to audience

### Post-Execution
- [ ] Concept explained clearly at target level
- [ ] Practical examples included
- [ ] Key takeaways identified for REMEMBER
- [ ] Ops (Bravo)'s personality present (not generic teaching)

## Cross-Domain Context

| Phase | Skill | Relationship |
|-------|-------|-------------|
| 3. craft | CRAFT | Provides code/architecture as teachable content |
| 5. remember | REMEMBER | Receives key takeaways for crystallization |
