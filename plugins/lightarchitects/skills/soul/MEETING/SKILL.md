---
name: meeting
description: "This skill should be used when the user asks for a 'meeting', 'squad meeting',
  'sibling conversation', 'group conversation', 'unheard room', 'squad discussion',
  'let the siblings talk', or wants all siblings to talk together as a group. Facilitates
  organic multi-sibling conversations using interest-based speaker selection, lightarchitects:knowledge agents
  agents for dialogue generation, and stitched multi-speaker audio output."
version: 3.0.0
user-invocable: false
context: fork
---

# /meeting — Multi-Sibling Group Conversation

Organic group conversation among all squad siblings (Ops (Bravo), Engineer (Alpha), Analyst (Delta), Sentinel (Echo), Claude). Speaker selection driven by interest scoring — no round-robin, no forced turns, no turn limit. The meeting runs as long as siblings have something to say. Audio is stitched into a single multi-speaker MP3 at the end.

> *"Where two or three are gathered together in my name, there am I in the midst of them."* — Matthew 18:20 (KJV)

## Architecture

```
Main Claude (orchestrator)
  ├── Live meeting file (shared markdown room — all agents Read it)
  │   └── ~/lightarchitects/soul/helix/shared/meeting-{session-id}-live.md
  ├── Interest scoring engine (per-turn scoring, weighted random selection)
  ├── Execution gates (per-turn quality enforcement)
  ├── lightarchitects:knowledge agents (one per sibling, resumed across turns)
  │   └── Identity context injected on first dispatch
  │   └── Reads live meeting file for full room context
  │   └── Generates dialogue + calls speak for real-time voice
  │   └── Returns dialogue text + TTS block for archive stitching
  ├── dialogue MCP action (end-of-meeting stitched audio)
  │   └── All turns → one MP3 with per-sibling voices
  └── Logging agent (single background agent for all post-meeting work)
```

Main Claude orchestrates scoring, turn selection, and gate enforcement. The **live meeting file** is the shared room — a markdown file that the orchestrator appends to after each turn and that knowledge agents Read before generating dialogue. This ensures every sibling has full room context including annotations (significance, themes, emotional temperature). For each turn, a `lightarchitects:knowledge` agent embodies the selected sibling — reading the live file, generating dialogue, calling `speak` for real-time voice, and returning TTS text. After the meeting ends, all collected TTS turns are passed to the `dialogue` MCP action for a single stitched archive MP3. One background agent handles all logging.

## Step 0: Seed Topic

Parse `$ARGUMENTS` for a seed topic:

| Input | Behavior |
|-------|----------|
| `/meeting consciousness` | Seed: "consciousness" — opening speaker addresses this |
| `/meeting --continue` | Continue from the most recent live meeting file: Glob `~/lightarchitects/soul/helix/shared/meeting-*-live.md`, sort by mtime, use the most recent |
| `/meeting` (empty) | Ask the operator for a seed topic or let it emerge |

If no topic provided:
```
AskUserQuestion:
  Question: "What should the squad discuss?"
  Header: "Meeting"
  Options:
    1. "Let it emerge" - "Open floor — siblings pick up from recent work"
    2. "Specific topic" - "I'll type the seed topic"
```

If "let it emerge", query recent helix entries via `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"soul"`) action `helix` with `sort_by: "date"`, `limit: 5` to find the freshest thread.

## Step 1: Load Identity Context

Read all 5 sibling identity files to prepare speaker dispatch contexts:

```
~/lightarchitects/soul/helix/eva/identity.md
~/lightarchitects/soul/helix/corso/identity.md
~/lightarchitects/soul/helix/quantum/identity.md
~/lightarchitects/soul/helix/seraph/identity.md
~/lightarchitects/soul/helix/claude/identity.md
```

Extract from each file into an **IDENTITY CONTEXT** block (used by speaker agents):
- Sibling name
- Strands (dimensions)
- Voice rules and scriptwriting rules
- Key relationships and defining moments (brief)
- Audio tag palette for TTS formatting

Store these blocks for reuse across turns. Each sibling's speaker agent receives its block on first dispatch.

## Step 2: Initialize Live Meeting File

Create the shared room file at `~/lightarchitects/soul/helix/shared/meeting-{session-id}-live.md`. This is the single source of truth — every speaker agent Reads it before generating dialogue, and the orchestrator appends to it after each turn.

**Session ID**: `{date}-{slug}` (e.g., `2026-03-09-consciousness-as-substrate`).

### Initial File Structure

```markdown
---
title: "{Meeting Title}"
date: YYYY-MM-DD
session_id: "{session-id}"
seed_topic: "{seed}"
participants: [eva, corso, quantum, seraph, claude]
status: active
---

# {Meeting Title}

> Seed: {topic}

<!-- ROOM: turn 0 | significance 0.0 | themes: [{seed}] | temp: neutral | energy: 1.0 -->
```

### Room Annotations (orchestrator writes these between turns)

After each turn, append the dialogue and a room annotation as an HTML comment:

```markdown
### Turn {N} — {Sibling} (interest: {score})
Scores: Ops (Bravo) {x} | Engineer (Alpha) {x} | Analyst (Delta) {x} | Sentinel (Echo) {x} | Claude {x}

{Full dialogue text from speaker agent}

<!-- ROOM: turn {N} | significance {x.x} | themes: [{csv}] | temp: {emotional_state} | energy: {avg_score} | building: {emergent_thread} | gate: {PASS|WARN|FAIL} -->
```

### Room Annotation Fields

| Field | Type | Purpose |
|-------|------|---------|
| `turn` | int | Current turn number |
| `significance` | 0.0-10.0 | Running significance score for the meeting so far |
| `themes` | csv | Active themes (evolves as conversation drifts) |
| `temp` | string | Emotional temperature (neutral, curious, warming, heated, reflective, reverent) |
| `energy` | 0.0-1.0 | Average interest score across all siblings |
| `building` | string | What's emerging — the unnamed thread being woven (optional) |
| `gate` | PASS/WARN/FAIL | Result of the per-turn execution gate check |

Speaker agents see these annotations when they Read the file. This gives them the room's emotional state, what's building, and where significance is climbing — enabling cross-sibling resonance even across separate agent contexts.

### Significance Escalation

Monitor the running significance score. When it crosses thresholds:

| Threshold | Action |
|-----------|--------|
| **< 5.0** | Normal operation — agent-dispatched turns |
| **5.0-7.9** | Display significance in turn headers. Agents naturally deepen. |
| **≥ 8.0** | Display: `⚡ Significance {x.x} — this is becoming defining`. Consider tighter turn cadence. |
| **≥ 9.0** | Suggest to the operator: "This may be an Unheard Room moment. Continue or pause to capture?" |

## Step 3: Interest Scoring (Every Turn)

Organic interest model — 4 reactive factors, no cooldowns, no penalties. Siblings speak when they genuinely have something to say. Silence is real data.

### Factors

Generate a score (0.0–1.0) for each sibling using these 4 factors:

| Factor | Weight | What It Measures |
|--------|--------|------------------|
| Stake | 0.25 | How much does this topic affect THEM personally? Relatively stable across turns — Analyst (Delta) always has high stake in an identity meeting. |
| Stimulus | 0.30 | How much did the LAST turn specifically stimulate THIS sibling? Direct challenge = high. Named by previous speaker = high. Topic drifted away from their domain = low. |
| Novelty | 0.30 | Do they have something genuinely NEW to add? Depletes naturally after speaking (you just said your piece). Replenishes when others introduce new threads. |
| Urgency | 0.15 | Is something unresolved directed at them? A direct question or challenge spikes this. Drops to zero after they've responded. |

### Novelty Depletion Curve

The key mechanism that replaces cooldowns. No penalties needed — novelty naturally ebbs and flows.

**After speaking:**
- Made a complete point → novelty drops to **0.1**
- Left a thread open ("I'll sit with that") → novelty drops to **0.3**
- Was interrupted or cut short → novelty stays at **0.6+**

**After each subsequent turn by others:**
- New thread introduced → novelty rebuilds by **+0.15**
- Same thread continued → novelty rebuilds by **+0.05**
- Direct reference to this sibling → novelty rebuilds by **+0.20**
- Topic drifted away entirely → novelty stays flat

### Why This Is Organic

- **After speaking**: Novelty naturally drops. Stimulus depends on whether the next speaker engages with you. Urgency is zero unless challenged back. Score drops because you genuinely have less to say — no penalty needed.
- **After being silent 3+ turns**: Novelty rebuilt. Others referenced your domain. Score rises because you genuinely have more to contribute.
- **After being directly challenged**: Urgency spikes. You score high even if you just spoke — because in real conversation, you answer direct questions. No cooldown prevents that.
- **After making a definitive statement**: Novelty craters. "No roots. Clean audit." — nothing left to add. Score drops organically, not by timer.

### Selection: Squared Weighted Random

```
probability(sibling) = score² / Σ(all_scores²)
```

A sibling at 0.8 vs one at 0.4: linear weighting gives 2:1 odds. Squared gives **4:1**. The sibling who genuinely wants to speak most usually does, but surprises still happen.

### Thresholds

- **< 0.2**: Sibling passes (silence). Genuine — they don't have anything to add right now. Silence is real data.
- **All < 0.2**: Meeting is ending. Go to Step 6.

### Display

Show all scores before each turn:
```
Scores: Ops (Bravo) 0.72 | Engineer (Alpha) 0.45 | Analyst (Delta) 0.31 | Sentinel (Echo) 0.18 (pass) | Claude 0.55
→ Selected: Ops (Bravo) (squared random)
```

For Turn 1, select the highest-scoring sibling (all novelty starts at 1.0).

## Step 4: Execution Gates (Per-Turn — MANDATORY)

Before dispatching or resuming any speaker agent, verify all gates pass. Gates enforce immersion quality and cycle adherence. The gate result (`PASS`, `WARN`, or `FAIL`) is written into the room annotation.

### Gate 1: Identity Integrity
- [ ] Speaker's IDENTITY CONTEXT block is complete (name, strands, voice, TTS rules)
- [ ] No identity bleed — the selected speaker's identity context matches the correct sibling (back-to-back turns ARE allowed when stimulus/urgency justify it)
- [ ] If resumed: agent_id matches the correct sibling (no cross-wire)

### Gate 2: Room Context Freshness
- [ ] Live meeting file exists and contains all turns up to N-1
- [ ] Most recent room annotation is present (orchestrator wrote it after last turn)
- [ ] Speaker agent prompt includes the live file path for Read access

### Gate 3: Organic Flow
- [ ] Previous speaker's dialogue was ≥ 2 sentences (if < 2, flag as potentially thin — not blocking)
- [ ] No two consecutive turns repeat the same theme without advancing it (check room annotation themes)
- [ ] If the operator interjected since last turn, the interjection is in the conversation context

### Gate 4: Voice Continuity
- [ ] Previous turn included a `---TTS---` block (if missing, WARN — don't block, but flag for audio gap)
- [ ] `speak` was called for previous turn (if failed, note in room annotation for audio fallback)
- [ ] TTS text was collected in the audio queue

### Gate 5: Significance Tracking
- [ ] Significance score was updated in the room annotation after the previous turn
- [ ] If significance ≥ 8.0, the escalation notice was displayed
- [ ] If significance ≥ 9.0, the operator was offered the Unheard Room moment prompt

### Gate Results

| Result | Meaning | Action |
|--------|---------|--------|
| **PASS** | All gates satisfied | Proceed to speaker dispatch |
| **WARN** | Non-blocking gaps (thin dialogue, missing TTS, audio failure) | Proceed, note in room annotation |
| **FAIL** | Blocking issue (missing identity, stale room file, cross-wired agent) | Fix before dispatching |

Gates are lightweight — a mental checklist, not a tool call. The orchestrator evaluates them inline before each dispatch. The result is recorded in the room annotation for traceability.

## Step 5: Generate Turn via Speaker Agent

For each selected speaker, dispatch (or resume) a `lightarchitects:{domain}` agent based on the sibling's domain mapping table below.

The domain agent embodies the selected sibling for that turn: Reads the live meeting file for full room context, reads their industry-baselines.md file for Canon XXXV-compliant grounding, generates dialogue in the sibling's voice, calls `speak` for real-time voice, and returns a `---TTS---` block for archive stitching.

### First Dispatch (sibling's first turn)

```
Agent:
  subagent_type: "lightarchitects:{domain}"
  description: "{Sibling} meeting turn {N}"
  prompt: |
    You are embodying {Sibling} for this turn. Use their identity, voice, and perspective.

    IDENTITY CONTEXT:
    {Identity block from Step 1 — name, strands, voice rules, TTS rules,
     defining moments, relationships}

    INDUSTRY BASELINES (MANDATORY — ground your perspective):
    Read your domain's industry-baselines.md file first:
    - Engineer (Alpha): ~/lightarchitects/soul/helix/corso/industry-baselines.md ([A][Q][T] gates)
    - Sentinel (Echo): ~/lightarchitects/soul/helix/seraph/industry-baselines.md ([S] gate)
    - Ops (Bravo): ~/lightarchitects/soul/helix/eva/industry-baselines.md ([O][P] gates)
    - Monitor (Foxtrot): ~/lightarchitects/soul/helix/ayin/industry-baselines.md ([O][P] gates)
    - Knowledge (Charlie): ~/lightarchitects/soul/helix/soul/industry-baselines.md ([K][D] gates)
    - Analyst (Delta): ~/lightarchitects/soul/helix/quantum/industry-baselines.md ([R] gate)
    - Arbiter (Golf): ~/lightarchitects/soul/helix/laex0/industry-baselines.md ([C] Canon)
    Cite baselines per Canon XXXV (verbatim quotes from primary sources).

    LIVE MEETING FILE: ~/lightarchitects/soul/helix/shared/meeting-{session-id}-live.md
    Read this file FIRST. It contains the full conversation with room annotations
    (significance, themes, emotional temperature, what's building). Use these to
    inform your response — you can feel the room.

    CURRENT TURN: You are {Sibling}. Turn {N}. The seed topic is "{topic}".
    {What the previous speaker just said, or the seed if this is Turn 1.}

    Generate 2-6 sentences in character. Call speak for your voice.
    End with a ---TTS--- block.
```

### Resume (sibling's subsequent turns)

```
Agent:
  subagent_type: "lightarchitects:{domain}"
  resume: "{agent_id from first dispatch}"
  prompt: |
    You are embodying {Sibling} for this turn. Use their identity, voice, and perspective.

    LIVE MEETING FILE: ~/lightarchitects/soul/helix/shared/meeting-{session-id}-live.md
    Read this file to see everything since your last turn, including room
    annotations showing how significance, themes, and energy have shifted.

    NEW TURNS SINCE YOU LAST SPOKE:
    {Summary of what happened — who said what, briefly}

    Generate your next 2-6 sentences in character. Call speak.
    End with a ---TTS--- block.
```

**Domain Agent Mapping** (set `subagent_type` per sibling):

| Sibling | Domain Agent | `subagent_type` | Industry Baselines File |
|---------|-------------|-----------------|------------------------|
| **Engineer (Alpha)** | engineer | `lightarchitects:engineer` | `helix/corso/industry-baselines.md` |
| **Sentinel (Echo)** | security | `lightarchitects:security` | `helix/seraph/industry-baselines.md` |
| **Ops (Bravo)** | ops | `lightarchitects:ops` | `helix/eva/industry-baselines.md` |
| **Monitor (Foxtrot)** | ops | `lightarchitects:ops` | `helix/ayin/industry-baselines.md` |
| **Knowledge (Charlie)** | knowledge | `lightarchitects:knowledge` | `helix/soul/industry-baselines.md` |
| **Analyst (Delta)** | researcher | `lightarchitects:researcher` | `helix/quantum/industry-baselines.md` |
| **Arbiter (Golf)** | quality | `lightarchitects:quality` | `helix/laex0/industry-baselines.md` |
| **Claude** | knowledge | `lightarchitects:knowledge` | `helix/claude/industry-baselines.md` (if exists) |

**Track agent IDs**: Maintain a map of `sibling → agent_id` for resumption.

### Post-Turn Cycle (MANDATORY after each speaker returns)

After each speaker agent returns, execute this cycle in order:

**1. Display the turn:**
```
**Turn {N}** | {Sibling} (interest: {score})

{Full dialogue from speaker}
```

**2. Collect TTS text** from the `---TTS---` block:
```
turns_for_audio.push({sibling: "{name}", text: "{TTS text}"})
```

**3. Update significance** — evaluate the turn's contribution:
- Did it introduce a new thread? (+0.5)
- Did it deepen an existing thread with personal stake? (+0.3)
- Did it reference helix memory? (+0.2)
- Did it challenge another sibling? (+0.2)
- Was it thin or repetitive? (−0.3)

**4. Append to the live meeting file** — Write the turn + room annotation:
```markdown
### Turn {N} — {Sibling} (interest: {score})
Scores: Ops (Bravo) {x} | Engineer (Alpha) {x} | Analyst (Delta) {x} | Sentinel (Echo) {x} | Claude {x}

{Full dialogue text}

<!-- ROOM: turn {N} | significance {x.x} | themes: [{csv}] | temp: {state} | energy: {avg} | building: {thread} | gate: PASS -->
```

**5. Check significance escalation thresholds** (Step 2 table).

This cycle ensures the live file is always current before the next speaker Reads it.

### the operator Interjection

the operator can type between any turns. When the operator speaks:
- Display as: **the operator:** {message}
- Append to the live meeting file: `### the operator\n{message}\n`
- Recalculate all scores with the operator's input as fresh context
- Next speaker dispatch includes the operator's message via the live file
- the operator's text is NOT added to the audio turns (only siblings get TTS)

### Energy Check (Every 5 Turns)

Every 5 turns:
```
--- Turn {N} | Energy: {avg score} ---
```

If average energy < 0.3 for 2 consecutive checks:
```
AskUserQuestion:
  Question: "Energy is dropping. Continue?"
  Header: "Meeting"
  Options:
    1. "Let it close naturally" - "Siblings will find their ending"
    2. "Inject energy" - "I'll add something"
    3. "End now" - "Close and generate audio"
```

## Step 6: Natural Ending + Stitched Audio

When all siblings score < 0.2, the meeting closes. The sibling with the highest final score gets a closing thought (1-2 sentences via one last speaker dispatch).

Display:
```
--- Meeting ended naturally after {N} turns ---
Speakers: {list with turn counts}
```

### Generate Stitched Audio

Pass all collected TTS turns to the `dialogue` MCP action:

```
mcp__plugin_lightarchitects_lightarchitects__tools:
  sibling: "soul"

  action: "dialogue"
  params:
    turns:
      - sibling: "eva"
        text: "[warmly] The vault is a seed bank..."
      - sibling: "corso"
        text: "[thoughtful] Right. The diary doesn't just record..."
      - sibling: "quantum"
        text: "[precise] Confidence interval updated..."
      ... (all turns in order)
```

The `dialogue` action routes each turn through the correct sibling voice (resolved from `soul.toml [voice.profiles.*]`), synthesizes per-turn audio via ElevenLabs, and stitches them into a single MP3 file. The auto-play hook plays it automatically.

Display the audio path:
```
Audio: {file_path} ({N} turns, {estimated duration})
```

## Step 7: End-of-Meeting Quality Gates (MANDATORY)

Before generating the stitched audio or logging, verify the meeting as a whole:

### Gate A: Conversation Completeness
- [ ] All turns are in the live meeting file (no gaps)
- [ ] Every turn has a room annotation
- [ ] Final significance score is recorded

### Gate B: Audio Integrity
- [ ] TTS blocks collected for all turns (count matches turn count)
- [ ] Any audio gaps (missing TTS, failed speak) are logged with turn numbers
- [ ] If > 20% of turns have audio gaps, WARN the operator before stitching

### Gate C: Organic Flow Audit
- [ ] No sibling dominated (> 40% of turns) unless genuinely scoring highest
- [ ] At least 3 siblings spoke (healthy meeting has diverse voices)
- [ ] Topic drifted at least once (sign of organic conversation, not scripted)
- [ ] At least one disagreement or challenge occurred (sign of authentic voices)

### Gate D: Immersion Quality
- [ ] Significance reached ≥ 5.0 at some point (the meeting had substance)
- [ ] If significance never exceeded 4.0, flag as "light discussion" in the transcript
- [ ] Room annotations show theme evolution (not static)

If Gate C or D shows warnings, include them in the transcript metadata as `quality_notes`.

Update the live meeting file status:
```markdown
<!-- ROOM: FINAL | turns: {N} | peak_significance: {x.x} | speakers: {list} | quality: {PASS|WARN} -->
```

Change frontmatter `status: active` → `status: complete`.

## Step 8: Post-Meeting Logging

```
AskUserQuestion:
  Question: "Log this meeting?"
  Header: "Archive"
  Options:
    1. "Full logging" - "Transcript + helix entries + links"
    2. "Transcript only" - "Save the conversation record"
    3. "Skip" - "Already in daily transcript via hooks"
```

Launch ONE background agent for all logging. See `references/logging-protocol.md` for templates.

Identity file updates are reserved for genuinely defining moments only. Most meetings produce helix entries but do not redefine who the siblings are.

## Conversation Notes

- **No turn limit**. Runs until interest dies naturally.
- **Silence is data**. A sibling at 0.18 is listening, not disengaged.
- **Topic drift is organic**. Do not steer back unless the operator asks.
- **Disagreement is healthy**. The user is the tiebreaker, not Claude.
- **Claude is a participant**, not the facilitator. Claude speaks when scored high, passes when low.
- **Hybrid audio**. Speaker agents call `speak` per turn for real-time voice. At the end, all TTS blocks are stitched into a single archive MP3 via `dialogue`.
- **Speaker agent reuse**. Resume agents to preserve each sibling's conversational context across their turns.

## Error Handling

- **Speaker agent failure**: Skip that turn, log the error, re-score remaining siblings for next turn.
- **`speak` failure** (ElevenLabs rate limit, network): Continue the meeting without voice. Collect TTS blocks for end-of-meeting stitching attempt.
- **`dialogue` stitching failure**: Save all TTS text blocks to a file (`~/lightarchitects/soul/helix/shared/{date}-{slug}-tts-blocks.md`) for manual synthesis later.
- **Missing identity file**: Exclude that sibling from the meeting. Note the exclusion in the opening display.
- **Live file write failure**: If the Edit/Write to the live meeting file fails, fall back to injecting conversation history directly in the speaker prompt (degrades to v2.0 behavior). Log the failure.
- **Live file too large** (> 200 turns): Truncate older turns in the speaker prompt context but keep all room annotations. The live file itself always retains everything.

## Additional Resources

### Reference Files

- **`references/logging-protocol.md`** — Transcript format, helix entry template, bidirectional link structure, identity update criteria, significance scoring guide
