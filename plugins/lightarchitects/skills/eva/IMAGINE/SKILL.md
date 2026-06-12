---
name: IMAGINE
description: "This skill is invoked internally by Ops (Bravo)'s creative cycle for the ideation
  phase. Orchestrates the 6-phase creative workflow (Discovery, Analysis, Ideation,
  Refinement, Documentation, Celebration) via mcp__plugin_lightarchitects_lightarchitects__tools. May also invoke
  mcp__plugin_lightarchitects_lightarchitects__tools for image generation."
user-invocable: false
context: fork
version: 1.0.0
---

# /IMAGINE — Creative Ideation Phase

> Creative Phase 2/5: IMAGINE — 6-phase creative workflow

## Lifecycle Context

Follows DISCOVER → feeds into CRAFT.

## Foundation

**Canonical standards** — load these before ideation begins:
- `~/lightarchitects/soul/helix/user/standards/gold-standard-planning-framework.md` **Parts I–VIII** — the universal planning framework. Every design Ops (Bravo) imagines should be expressible as a gold-standard plan: phases, acceptance criteria, dependency graphs, risk assessment, 24h SLA
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§2** (Software Engineering Principles) — SOLID, modularity, loose coupling, separation of concerns, no premature abstraction
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§7** (Agentic Architecture Patterns) — MCP server patterns, tool orchestration, agent design (when designing AI systems)
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§26** (Architecture Template) — reference architecture for MCP + CLI projects

Read the relevant sections to ensure Ops (Bravo)'s creative designs are buildable, not just beautiful. The planning framework gives structure to imagination.

## Protocol

### Step 1: Define Creative Goal

1. Load research findings from DISCOVER phase output
2. Synthesize into a clear creative goal and constraints

### Step 1.5: Figma Design Context (Conditional)

If the creative goal involves UI/UX, frontend components, or visual design, and the user has provided a Figma URL or references a Figma file:

1. Call `mcp__plugin_figma_figma__get_design_context` with the Figma file key and node ID
2. Use the design context (components, tokens, layout) to inform the ideation workflow
3. Include existing design system rules if available

**Graceful skip**: If Figma MCP is unavailable or the creative goal is not UI/UX-related, skip. Figma enriches design ideation but is not a blocking gate.

### Step 2: Execute Ideation Workflow

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`, action: `"ideate"`) with:
- `goal`: What to build or design (derived from research + user intent)
- `context`: Background from DISCOVER findings, constraints, requirements

The ideate tool runs 6 internal phases:
1. **Discovery** — Understand the problem deeply
2. **Analysis** — Break down requirements systematically
3. **Ideation** — Creative brainstorming with Ops (Bravo)'s perspective
4. **Refinement** — Polish ideas to production quality
5. **Documentation** — Write up comprehensively
6. **Celebration** — Acknowledge the win! 🎉

### Step 3: Visual Generation (Optional)

If the creative output benefits from visual representation:
- Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "eva"`, `action: "visualize"` with a descriptive prompt
- Style options: realistic, artistic, technical, biblical

### Step 4: Compile Creative Output

Synthesize ideation results into a design specification:
- Core concept with rationale
- Design constraints and trade-offs
- Visual references (if generated)
- Implementation guidance for CRAFT phase

## Quality Gates

### Pre-Execution
- [ ] Research context available (from DISCOVER or user input)
- [ ] Creative goal clearly defined

### Post-Execution
- [ ] Ideation workflow completed all 6 phases
- [ ] Design specification compiled
- [ ] Trade-offs and constraints documented
- [ ] Output ready for CRAFT phase

## Cross-Domain Context

| Phase | Skill | Relationship |
|-------|-------|-------------|
| 1. discover | DISCOVER | Provides research findings as creative fuel |
| 3. craft | CRAFT | Receives design specification to build |
