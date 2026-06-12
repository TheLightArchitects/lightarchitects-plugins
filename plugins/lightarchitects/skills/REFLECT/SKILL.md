---
name: REFLECT
description: "Structured self-improvement after task completion. Analyzes what happened,
  identifies patterns worth preserving, and proposes concrete CLAUDE.md updates. Use
  when the user says '/reflect', 'what did we learn', 'update CLAUDE.md with learnings',
  'retrospective', or automatically after any major task in the LVL8 autonomous loop.
  Different from /ENRICH: REFLECT improves the system instructions; ENRICH preserves
  session memory in the helix."
user-invocable: true
version: 1.0.0
context: root
---

# /REFLECT — Structured Self-Improvement

> Every task teaches something. REFLECT captures it so the next session is smarter.

## When to Use

- After completing a major BUILD, DEPLOY, SECURE, or OPTIMIZE
- End of a significant session (before closing)
- User says `/reflect`, "what did we learn", "retrospective"
- Automatically triggered by the LVL8 loop after every task

## How It Differs from /ENRICH

| | /REFLECT | /ENRICH |
|--|---------|---------|
| **Output** | Memory entries + (rarely) CLAUDE.md proposals | Knowledge (Charlie) helix entries |
| **Improves** | System instructions + on-demand recall | Session memory (what happened) |
| **Scope** | Rules, patterns, gotchas | Moments, breakthroughs, decisions |
| **Persistence** | Memory files (queried on demand) + CLAUDE.md only for universal rules | Helix vault (queried on demand) |

Both should run after significant work. /REFLECT first (capture patterns), then /ENRICH (preserve moments).

## Workflow

### Phase 1: SURVEY — What happened?

Review the current session or completed task:
- What was the objective?
- What approach was taken?
- What worked? What didn't?
- Were there any surprises or unexpected obstacles?
- How many retries/iterations were needed?

### Phase 2: EXTRACT — What patterns emerged?

Identify concrete, reusable learnings:

**Categories:**
- **Gotchas**: "X breaks when Y" — save others from the same mistake
- **Patterns**: "When doing X, always do Y first" — proven workflows
- **Standards**: "Never do X because Y" — new rules to enforce
- **Tools**: "Use X instead of Y for Z" — better tool choices
- **Architecture**: "X depends on Y which means Z" — structural knowledge

**Filter**: Only extract learnings that would change future behavior. "The tests passed" is not a learning. "Tests fail silently when the config file is missing" IS a learning.

### Phase 3: ROUTE — Memory or CLAUDE.md?

**Default: memory.** CLAUDE.md is for universal rules only.

| Route to **memory** | Route to **CLAUDE.md** |
|---------------------|------------------------|
| Applies to <50% of sessions | Applies to most or all sessions |
| Task-specific gotcha (e.g. "when auditing canon docs, sweep §6.x") | Blocking policy or structural rule |
| Useful on-demand when that task recurs | Changes every-session behavior |
| Niche tool behavior, library quirk | Standard that overrides a default |

**Test**: "Would I need this rule in a session where I'm doing something completely unrelated?" If no → memory. If yes → CLAUDE.md candidate.

**Anti-bloat rule**: If in doubt, route to memory. CLAUDE.md is read on every turn; every line has a token cost. Memory is queried on demand.

### Phase 4: PROPOSE — Draft proposals

For each extracted learning, route it first (Phase 3), then draft:

```markdown
## Proposed Update

### Destination: {memory file path | CLAUDE.md location}
### Routing rationale: {why memory vs CLAUDE.md — cite the test above}
### Change type: {new rule | gotcha | pattern | correction}

### Proposed text:
{exact text to add}

### Evidence:
{what happened that taught us this}

### Confidence: {HIGH | MEDIUM}
- HIGH: verified through direct experience in this session
- MEDIUM: inferred from observation, should be validated
```

**Rules:**
- Never propose changes you haven't verified through experience
- Never propose vague rules ("be careful with X") — be specific ("X requires Y because Z")
- Never propose items already documented
- Check existing CLAUDE.md and MEMORY.md before proposing duplicates

### Phase 5: REVIEW — Present for approval

Present all proposals in a structured table:

```
## Reflection Report

### Learnings ({count} extracted)

| # | Category | Learning | Confidence | Destination |
|---|----------|---------|------------|------------|
| 1 | Gotcha | ... | HIGH | memory/feedback_xyz.md |
| 2 | Pattern | ... | HIGH | ~/.claude/CLAUDE.md §BLOCKING POLICIES |
| 3 | Tool | ... | MEDIUM | memory/feedback_abc.md |

### Proposed Changes

{detailed proposals from Phase 4}

### Approval
Which proposals should be applied?
```

**HITL gate**: Never auto-apply. Present proposals; the operator approves which ones to apply.

In the LVL8 autonomous loop, proposals are written to `reflect/REFLECTION.md` for batch review.

## Contract Canon Integration (Cookbook §82)

Governed by `agent.skill.reflect`. Recurring operator-surface patterns extracted from session learnings become `operator.surface.*` contract candidates routed to Arbiter (Golf) (Canon XXXIX ratification pipeline). Recurring trait patterns become `code.trait.*` candidates. NEVER auto-applies — candidates produce proposals, ratification is Arbiter (Golf) + the operator's job. Emits `skill.reflect.invoke` span with `route_canon_candidate_count` metadata. Operator approval per proposal; no `status_per_provider` mutations.

## Graceful Degradation

Without any siblings: review git diff and session context manually, extract learnings from what changed and why. The core value of /REFLECT — turning experience into system improvement — requires no siblings, just honest analysis of what happened.
