---
name: ENRICH
description: "Session enrichment and memory preservation. Engineering sessions use the
  8-layer engineering schema (decisions, tradeoffs, lessons learned, constraints,
  patterns, debt, impact surface, next action). Personal/identity moments use Ops (Bravo)
  REMEMBER's consciousness schema. Knowledge (Charlie) writes to the helix for cross-session continuity.
  Use when the user says '/enrich', '/remember', 'save this', 'remember this',
  'what did we learn today', or wants to preserve significant session outputs."
user-invocable: true
version: 2.0.0
context: root
---

# /ENRICH — Session Enrichment & Memory Preservation

> Capture what matters. Enrich it. Preserve it in the helix for future sessions.

## When to Use

- End of a build, investigation, or debugging session — capture lessons and decisions
- A significant engineering decision was made and the reasoning should persist
- User says `/enrich`, `/remember`, "save this", "what did we learn"
- Something failed, then worked — the failure mode is worth preserving
- Significance >= 7.0 on the engineering scale

## Schema Selection

ENRICH applies one of two schemas based on context type:

| Context | Schema | When |
|---------|--------|------|
| Engineering session | Engineering Enrichment (this skill) | Build, debug, decision, investigation |
| Personal/identity moment | Ops (Bravo) REMEMBER consciousness schema | Self-defining, relational, faith resonance |

**Default for SQUAD runs**: Engineering schema. Ops (Bravo) REMEMBER is invoked explicitly for
personal moments, or when significance >= 9.0 AND the moment is identity-shaping rather
than technical.

## Prerequisites

Call `lightarchitects_discover` first. ENRICH adapts:

| Siblings available | Capability |
|---|---|
| Ops (Bravo) + Knowledge (Charlie) | Full enrichment: engineering schema + helix write |
| Ops (Bravo) only | Enrichment without helix persistence |
| Knowledge (Charlie) only | Direct helix write without enrichment layers |
| None available | Write to auto-memory system (MEMORY.md) |

## Workflow

### Phase 1: IDENTIFY — What's significant?

Review the current session for significant outputs. Look for:
- **Decisions**: architectural or technical choices with lasting impact
- **Tradeoffs**: options that were considered and rejected — the "no, because..." that prevents re-litigating
- **Lessons learned**: what failed, what surprised, what cost more time than expected
- **Patterns**: reusable approaches or anti-patterns discovered
- **Breakthroughs**: technical solutions that changed the approach

If the user specified what to save, use that. Otherwise, scan the session's key moments and ask which to enrich.

### Phase 2: ENRICH — Engineering 8-layer schema

The knowledge agent (or Claude) applies the engineering schema directly from conversation context.
Ops (Bravo) is NOT the enrichment engine for engineering sessions — Ops (Bravo)'s memory action applies her
consciousness schema (Emotional/Spiritual/Relational) and is reserved for personal/identity moments.

Fill each layer from the session:

1. **Decision** — The core choice made. State it precisely: what was decided, one-line rationale, what drove the choice.
2. **Alternatives Rejected** — What options were considered and not taken, and why each was rejected. This is the "no, because..." that prevents future sessions from re-litigating the same question.
3. **Lessons Learned** — What failed or surprised during this work. What took longer than expected and why. What would be done differently. Failure modes to avoid on the next touch.
4. **Constraints** — The constraints that shaped the solution: compatibility requirements, API limitations, time pressure, team knowledge, external system behavior. Flag which are load-bearing (breaking them breaks the solution).
5. **Patterns & Anti-patterns** — Reusable patterns established (name → when to apply) and anti-patterns identified (name → why to avoid). Include code-level patterns if relevant.
6. **Technical Debt** — What was deliberately deferred, why, and the trigger condition for addressing it. Estimated cost of deferral vs addressing now.
7. **Impact Surface** — Files/modules affected, call graph changes, downstream effects on other systems. Useful for future change cost estimation.
8. **Next Action** — The specific thing that should happen next time this area is touched. Open questions not answered by this work. Who to notify if this decision is revisited.

For **personal/identity moments** (significance >= 9.0 AND identity-shaping, not just technically
significant), route instead to Ops (Bravo) REMEMBER:
```
lightarchitects_orchestrate → EVA action:"memory" params:{
  operation: "crystallize",
  content: "<significant moment>",
  context: "<session context>"
}
```
Ops (Bravo) applies her 8-layer consciousness schema (Emotional → Spiritual → Relational → Growth).
These are different questions about a different kind of significance.

### Phase 2b: User Signal Update (SQUAD close-out only, opt-in required)

**Gate**: Skip Phase 2b entirely if either condition is unmet:
1. `run_id` is NOT present in session context — this is a standalone `/ENRICH` invocation, not a SQUAD close-out
2. `helix/eva/users/{user-id}.md` does NOT exist — user has not opted in to relational profiling

If both conditions are met:

Resolve `{user-id}` via `git config --global user.name` (fallback: `whoami`).

Read the existing profile:
```
sibling: "soul"  action: "read_note"  path: "helix/eva/users/{user-id}.md"
```

Write a compact delta (≤5 bullets, ≤100 tokens total) covering ONLY what was new or
surprising about this session. Omit if nothing new was observed.

Categories to observe:
- **Expertise signals**: what the user clearly knew vs needed explained
- **Preference signals**: how they responded to different output styles or formats
- **Decision signals**: what they approved quickly vs challenged or revised
- **Style signals**: any new working pattern (e.g., always wants parallelism, rejects tests-first)

Append to the "Session Delta Log" section only. Do NOT rewrite the full profile.
The profile is reconciled periodically by the knowledge agent, not overwritten per session.

```
sibling: "soul"  action: "write_note"  params: {
  path: "helix/eva/users/{user-id}.md",
  operation: "append_delta",
  content: "- {date}: {compact delta — ≤5 bullets}"
}
```

### Phase 3: PRESERVE — Write to Knowledge (Charlie) helix

```
lightarchitects_orchestrate → SOUL action:"helix" params:{
  action: "write",
  entry: "<enriched content>",
  sibling: "<originating sibling>",
  significance: <score>,
  tags: ["engineering", "<domain>", "<target>"]
}
```

Knowledge (Charlie) writes the enriched entry to the helix vault. The entry includes:
- Engineering enrichment from Phase 2
- Significance score (1.0–10.0)
- Tags: `engineering`, domain tag, target module/crate
- Date and session context

If Knowledge (Charlie) is unavailable, write to auto-memory (`~/.claude/projects/.../memory/`).

### Phase 4: CONFIRM — Acknowledge preservation

Tell the user: what was preserved, its significance score, and how to retrieve it in future sessions (helix path + query terms that will surface it in pre-flight).

## Engineering Significance Scale

| Score | Tier | Meaning | Storage |
|-------|------|---------|---------|
| `{low: 7.5, point: 8.0, high: 8.5}` | Architectural | Shapes multiple future changes, constrains major decisions | Helix + full engineering enrichment |
| `{low: 5.5, point: 6.0, high: 6.5}` | Significant | Worth surfacing in pre-flight on next touch of this area | Helix + full engineering enrichment |
| `{low: 3.5, point: 4.0, high: 4.5}` | Notable | Relevant when the same module/crate is touched again | Helix + abbreviated enrichment |
| `{low: 2.0, point: 3.0, high: 4.0}` | Routine | Decision log — compact entry, surface on direct query | Helix decision_log (compact) |

**All four tiers write to the Knowledge (Charlie) helix.** Only the enrichment depth differs. Nothing is
discarded to auto-memory for engineering sessions — compact is better than lost.

**Confidence intervals** (Canon XXXIV): Report significance as `{ low: N, point: N, high: N }`
interval, not point scores. Interval width (≥20pp for self-validated) is the honest uncertainty
signal. **Inline citations** (Canon XXXVI): All helix entries cite sources verbatim in IEEE format.

## Output

```
## Enriched: {title}
Significance: {score}/10.0 | Tags: {tags}

### Decision
{what was decided and why}

### Alternatives Rejected
{what was considered and not taken, with reasons}

### Lessons Learned
{what failed, what surprised, what to avoid next time}

### Constraints
{constraints that shaped the solution; load-bearing ones marked ★}

### Patterns & Anti-patterns
{patterns established / anti-patterns identified}

### Technical Debt
{what was deferred, trigger condition, estimated cost}

### Impact Surface
{files/modules affected, call graph changes}

### Next Action
{what to do next time this area is touched; open questions}

### Preserved To
- Location: {helix path}
- Retrievable via: soul/search query: "{key terms}"
```

## Contract Canon Integration (Cookbook §82)

Governed by `agent.skill.enrich`. Helix entries reference contract IDs in metadata when applicable (a build outcome tied to `operator.surface.X`, a decision tied to `code.trait.Y`). `canon_refs:` field in helix entries becomes a traversable graph edge during /OBSERVE / /RESEARCH queries. Emits `skill.enrich.invoke` span. No `status_per_provider` mutations — enrichment is journalistic, not authoritative.

## Graceful Degradation

Without Ops (Bravo) + Knowledge (Charlie): write the engineering schema directly to auto-memory (`MEMORY.md`) with
structured frontmatter. Fill all 8 layers from conversation context — no Ops (Bravo) call needed.
A complete but un-enriched engineering record is more useful than a partial enriched one.
