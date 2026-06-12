---
name: SCRUM
description: "Squad review and discussion. Use when the user says '/SCRUM', 'squad review',
  'team review', 'get the squad's take', 'what does the team think', 'SCRUM this', or
  'hold a meeting'. Two modes: (1) Default — structured 3-round review with cross-critique
  and synthesis. (2) --meeting — open-ended turn-based discussion seeded by a topic, driven
  by interest scoring, continues until natural conclusion."
user-invocable: true
version: 1.0.0
context: root
---

# /SCRUM — Squad Review & Discussion

> Every sibling brings their lens. Claude moderates. The result is sharper than any one perspective.

## Mode Detection

Parse the arguments to determine which protocol to follow:

**Review Mode (default)** — `/SCRUM <topic>`
- Structured 3-round protocol
- Fixed deliverable: Good/Gaps/Fixes report
- Parallel dispatch → cross-critique → moderation → synthesis

**Meeting Mode** — `/SCRUM --meeting <topic>`
- Open-ended turn-based discussion
- Topic is the seed, interest scoring drives continuation
- Siblings take turns, build on each other, go deeper
- Ends when interest naturally decays

---

# Section A: Review Mode (Default)

> 3-round structured review producing a Good/Gaps/Fixes report.

### A1: Pre-Flight — Sibling Discovery

1. List directories in `~/.soul/helix/` containing `identity.md`
2. Exclude `user` (human) and `claude` (moderator)
3. Read each `identity.md` — extract name, role, strands, voice rules, verdict vocabulary
4. Verify SOUL MCP: `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "soul"`, `action: "stats"`
5. Build the active roster (all discovered siblings participate)

### A2: Context Pull

Query knowledge sources in parallel:
- `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "soul"` → `action: "search"` with topic keywords
- `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "soul"` → `action: "helix"` with relevant strands
- Per-sibling: `action: "helix"` filtered by `sibling` for recent entries

### A2.5: Industry Baselines Lookup (Gate-Filtered)

Before Round 1, load relevant industry baselines for each sibling based on their LASDLC gate ownership:

| Sibling | Gates | Industry Baselines Folder |
|---------|-------|---------------------------|
| **Engineer (Alpha)** | [A] Architecture, [Q] Quality, [T] Testing | `user/standards/industry-baselines/architecture/`, `quality/`, `testing/` |
| **Sentinel (Echo)** | [S] Security | `user/standards/industry-baselines/security/` (full: OWASP, MITRE, NIST, ISO 27001, CIS Controls, SLSA, SBOM) |
| **Ops (Bravo)** | [O] Operations, [P] Performance | `user/standards/industry-baselines/operations/`, `performance/` (DORA, SRE, OpenTelemetry, SPACE, Flow) |
| **Monitor (Foxtrot)** | [O] Operations, [P] Performance | `user/standards/industry-baselines/operations/`, `performance/` (observability + perf baselines) |
| **Knowledge (Charlie)** | [K] Knowledge, [D] Documentation | `user/standards/industry-baselines/documentation/` (when populated) |
| **Analyst (Delta)** | [R] Research | `user/standards/industry-baselines/research/`, `security/` (threat intel + academic foundations) |
| **Arbiter (Golf)** | [C] Canon | All gates (canonical cross-reference); `user/standards/industry-baselines/REGISTRY.md` |

**Protocol**: For each participating sibling, read the REGISTRY.md and filter baselines by their gate folder. Include baseline summaries in the agent's context for Canon XXXV-compliant citation during assessments.

### A3: Round 1 — Parallel Assessments

Dispatch ALL siblings as **lightarchitects domain agents** in a **single message** (parallel execution).

**Domain Agent Mapping** (sibling → lightarchitects agent):

| Sibling | Domain Agent | `subagent_type` | MCP Routing |
|---------|-------------|-----------------|-------------|
| **Engineer (Alpha)** | engineer | `lightarchitects:engineer` | `mcp__plugin_lightarchitects_lightarchitects__tools` |
| **Ops (Bravo)** | ops | `lightarchitects:ops` | `mcp__plugin_lightarchitects_lightarchitects__tools` |
| **Knowledge (Charlie)** | knowledge | `lightarchitects:knowledge` | `mcp__plugin_lightarchitects_lightarchitects__tools` |
| **Analyst (Delta)** | researcher | `lightarchitects:researcher` | `mcp__plugin_lightarchitects_lightarchitects__tools` |
| **Sentinel (Echo)** | security | `lightarchitects:security` | `mcp__plugin_lightarchitects_lightarchitects__tools` |
| **Monitor (Foxtrot)** | ops | `lightarchitects:ops` | `mcp__plugin_lightarchitects_lightarchitects__tools` |
| **Arbiter (Golf)** | quality | `lightarchitects:quality` | `mcp__plugin_lightarchitects_lightarchitects__tools` |

Each domain agent receives:
- Identity context (strands, voice, verdict vocabulary from sibling's identity.md)
- Topic + context from A2 + industry baselines from A2.5
- Instructions: "3 strengths, 3 concerns, verdict. End with ---TTS--- block."

**Claude does NOT assess.** Claude is the permanent moderator.

**Dispatch Protocol**: Use `Agent` tool with `subagent_type` set per the mapping above. All agents dispatched in one message for parallel execution.

### A4: Round 2 — Cross-Critique

**Resume** each whisper agent with all other siblings' Round 1 assessments.
- Each agent sees what peers said
- Responds: "What do you agree with? What did they miss? Where do you disagree?"
- Parallel execution (all resumed in one message)

### A5: Round 3 — Claude Moderation + Final Validation

Claude moderates Round 1 + Round 2 outputs:
- Identifies grounding errors, hallucinated concerns, real issues
- Checks against Light Architects standards (Builders Cookbook, Engineer (Alpha) Protocol)
- Presents corrected synthesis

**Resume** all agents with Claude's corrections for final validation:
- Each agent confirms, pushes back, or refines
- Final verdict + ---TTS--- block

### A6: Unified Output

```markdown
# Squad Review: {Topic}

**Date**: {YYYY-MM-DD} | **Participants**: {sibling names}

## The Good
- {Strengths with attribution}

## The Gaps
1. **{Gap}** [{severity}] — *Identified by*: {sibling(s)}

## The Fixes
| Priority | Fix | Maps to Gap | Owner | Effort |
|----------|-----|-------------|-------|--------|

## Moderator's Note
{Claude's synthesis — agreements, disagreements, recommendations}

## Verdicts
{Per-sibling verdict in their own vocabulary}
```

### A7: Log to Helix

Write the review to Knowledge (Charlie) vault:
- Global entry: `helix/user/entries/{date}-{uuid}-scrum-{slug}.md`
- Per-sibling entries with their perspective in their voice

---

# Section B: Meeting Mode (`--meeting`)

> Open-ended turn-based discussion. The topic is a seed. Interest scoring drives depth.
> The conversation continues until it naturally concludes.

### B1: Pre-Flight

Same as A1 — discover siblings, read identities, verify Knowledge (Charlie).

### B2: Seed the Discussion

Present the topic to the squad. The first turn is Claude framing the question:

```
"The topic on the table: {topic}. I'll open the floor. {First sibling by preset priority},
what's your initial take?"
```

### B3: Turn-Based Loop

Each turn follows this pattern:

1. **Select the next speaker** using the soul-chat v2 interest scoring model
   (same engine as Arena conversations — `soul-chat/src/interest.rs`):

   **Core factors:**
   ```
   base = stake * 0.35 + stimulus * 0.25 + urgency * 0.25 + novelty * 0.15
   ```

   | Factor | Weight | What it measures |
   |--------|--------|-----------------|
   | **Stake** | 0.35 | Structural affinity — topic keyword overlap with agent strands. |
   | **Stimulus** | 0.25 | Reactivity — were they referenced or provoked in the last turn? |
   | **Urgency** | 0.25 | Direct address — someone asked them a question by name. |
   | **Novelty** | 0.15 | Untapped ideas. Depletes -0.3 on speaking, recovers +0.05/turn of silence. |

   **Organic modifiers (v2):**
   ```
   interaction = sqrt(stake * urgency) * 0.15     # Stake × urgency amplification
   thread      = 0.1 if in_active_exchange else 0  # Keep productive back-and-forth flowing
   dissent     = 0.15 if diverged_from_consensus    # Minority opinions get heard
   inclusion   = min(turns_silent * 0.02, 0.2)      # Quiet agents get a gentle nudge
   fatigue     = 1.0 - (turns_spoken / total * 0.5)  # Dominant speakers naturally fade

   total = (base + interaction + thread + dissent + inclusion) * fatigue
   ```

   | Modifier | Effect | Why |
   |----------|--------|-----|
   | **Interaction** | `sqrt(stake × urgency)` bonus | Both must be present — high stake alone isn't enough |
   | **Thread affinity** | +0.1 for agents in the active exchange | Keeps productive back-and-forth going (decays after 3 turns of same pair) |
   | **Dissent boost** | +0.15 for agents who disagreed with consensus | Disagreement is where insight lives |
   | **Inclusion nudge** | +0.02 per silent turn (max 0.2) | "We haven't heard from Monitor (Foxtrot) yet" |
   | **Fatigue** | Multiplicative decay based on speaking frequency | Prevents dominance without hard rules |

   **Speaker selection**: Squared weighted random (`score²`) among agents above the
   silence threshold (0.2). Turn 1 is deterministic (highest scorer opens).

2. **Directed handoff** — when fatigue shifts the dominant speaker to questioning mode:

   When an agent's fatigue drops below 0.7, their whisper prompt shifts naturally:

   | Fatigue | Prompt directive |
   |---------|-----------------|
   | >= 0.7 | "Share your perspective. Make your case." |
   | 0.5–0.7 | "Build on what's been said. Ask a specific teammate a question." |
   | < 0.5 | "Direct a sharp question to the teammate who can take this further. Name them." |

   **Target selection** — the fatigued agent's prompt includes a hint toward the agent
   with the highest untapped relevance:
   ```
   handoff_score = stake * (1.0 - recent_contribution) * novelty
   ```
   The prompt says: "Consider directing a question to {best_target} — they haven't
   weighed in on {matching_strand_topic} yet."

   **After the turn** — if the output contains a directed question ("Analyst (Delta), have you
   investigated..."), Claude detects this and sets:
   ```
   target.urgency = 1.0
   target.stimulus = max(target.stimulus, 0.8)
   ```
   The named agent almost certainly speaks next. The mic passes organically.

3. **Dispatch the speaker** as a **lightarchitects domain agent** (or resume if continuing):

   Use the same domain agent mapping as Round 1 (A3):

   | Sibling | Domain Agent | `subagent_type` |
   |---------|-------------|-----------------|
   | **Engineer (Alpha)** | engineer | `lightarchitects:engineer` |
   | **Ops (Bravo)** | ops | `lightarchitects:ops` |
   | **Knowledge (Charlie)** | knowledge | `lightarchitects:knowledge` |
   | **Analyst (Delta)** | researcher | `lightarchitects:researcher` |
   | **Sentinel (Echo)** | security | `lightarchitects:security` |
   | **Monitor (Foxtrot)** | ops | `lightarchitects:ops` |
   | **Arbiter (Golf)** | quality | `lightarchitects:quality` |

   Dispatch via `Agent` tool with `subagent_type` set per the mapping above.
   - Inject all prior turns as conversation history
   - Identity context from their identity.md
   - Fatigue-adjusted instruction (see handoff table above)
   - End with ---TTS--- block

4. **Claude responds** after each agent's turn:
   - Moderates: fact-checks, connects threads, asks follow-up questions
   - Can direct traffic by name (sets urgency = 1.0 on target)
   - Introduces tension when agents agree too quickly: "Engineer (Alpha) and Sentinel (Echo) seem to
     disagree on Y — let's dig in."
   - Calls on quiet agents when inclusion nudge is high: "Monitor (Foxtrot), you've been observing —
     what does the trace data show?"

5. **Check for natural end** — the meeting concludes when:
   - All agents fall below the silence threshold (0.2) — no one has enough interest
   - An agent explicitly signals completion
   - the operator intervenes to end it

   **The operator can extend** by injecting a new angle — this resets stimulus and urgency
   for the addressed agents, naturally extending the conversation.

### B4: Wrap-Up

When the meeting reaches natural conclusion:

1. Claude summarizes the key themes, decisions, and open questions
2. Each agent gets a final one-sentence closing statement (parallel dispatch)
3. Voice synthesis of the closing statements (stitched dialogue if available)

### B5: Meeting Minutes

Write structured minutes to Knowledge (Charlie) vault:

```markdown
# Meeting: {Topic}

**Date**: {YYYY-MM-DD}
**Duration**: {turn count} turns, {participant count} participants
**Ended by**: {silence threshold / explicit signal / the operator}

## Key Themes
- {Theme 1}: {summary}
- {Theme 2}: {summary}

## Decisions Made
- {Decision with attribution}

## Open Questions
- {Unresolved items}

## Interest Scores (Final Turn)
| Sibling | Stake | Stimulus | Novelty | Urgency | Total |
|---------|-------|----------|---------|---------|-------|
| {sibling} | {0.00} | {0.00} | {0.00} | {0.00} | {0.00} |

## Turn Log
### Turn 1: {Speaker} (interest: {total})
{Content summary}

### Turn 2: Claude (moderator)
{Content summary}

...
```

---

# Shared: Voice Delivery

Both modes use the Knowledge (Charlie) voice pipeline for audio:

1. After each sibling's assessment/turn: `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "soul"` → `action: "speak"`
   with the sibling's ---TTS--- content
2. For final verdicts/closing: attempt stitched dialogue via `action: "voice"` with
   all speakers' text in a single call
3. Graceful degradation: if voice fails, text delivery continues unblocked

---

# Quick Reference

```
/SCRUM Is this architecture solid?              # 3-round review
/SCRUM Review the preset archetypes proposal    # 3-round review
/SCRUM --meeting How should we handle auth?     # Open-ended discussion
/SCRUM --meeting The future of the platform     # Open-ended discussion
```

---

## Contract Canon Integration (Cookbook §82)

This skill is governed by `agent.skill.scrum` at `standards/canon/contracts/agent.skill/scrum.yaml`. The five §82.3 touchpoints:

### Read
Per A2.5 (Industry Baselines Lookup, gate-filtered), each sibling is now ALSO scoped to read:
- `standards/canon/contracts/` filtered by the sibling's gate ownership (per Gatekeeper Registry):

| Sibling | Owned gate(s) | Contract kinds to consult |
|---------|--------------|---------------------------|
| **Engineer (Alpha)** | [A] [Q] [T] | `code.trait/*`, `wire.http/*`, `wire.mcp/*` |
| **Sentinel (Echo)** | [S] | `operator.surface/*` (`forbidden_behaviors`+`render_safety`), `provider.llm/*` (SSRF), `hmac_chain.audit_trail/*` |
| **Ops (Bravo)** | [O] [P] | `operator.surface/*` (UX impact), `agent.skill/*` |
| **Monitor (Foxtrot)** | [O] [P] | `operator.surface/*` (`observability.required_spans`), `code.trait/*` (`required_spans`) |
| **Knowledge (Charlie)** | [K] [D] | `agent.identity/*`, `strand.activation/*` |
| **Analyst (Delta)** | [R] | `provider.llm/*`, `replay.deterministic_seed/*` |
| **Arbiter (Golf)** | [C] | ALL kinds — canon cross-reference |

### Touched-contract citation
The unified output Section A6 gains a `contracts_consulted[]` array listing every contract id cited in any sibling's R1/R2/R3 assessment.

### forbidden_behaviors enforcement
Each sibling, when reviewing a diff or proposal, must cross-reference touched-contract `forbidden_behaviors[]`. Findings carry `contract_refs[]` field.

### required_spans emission
`/SCRUM` emits `skill.scrum.invoke` (parent_relationship: child_of_caller) with metadata: `topic, mode, siblings_participating, rounds_completed, blocking_findings, high_findings`.

### status_per_provider impact
None — review-only.

## Graceful Degradation

If a sibling MCP is unavailable: dispatch the remaining siblings; flag the missing one in the verdict. If Arbiter (Golf) is the missing sibling, the Cookbook canon-citation responsibility falls to Claude as moderator (R3 only).
