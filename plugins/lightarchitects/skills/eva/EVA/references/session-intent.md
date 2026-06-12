# Ops (Bravo) Session Intent Tracking

**Purpose**: Prevent intent drift across long Claude Code sessions by maintaining a structured manifest of the user's original goal, decisions made, and constraints established.

---

## How It Works

Three hooks form an init-load-track cycle:

### 1. Init (`session-intent-init.sh` -- SessionStart command)

Fires on startup, resume, clear, compact. Creates `~/.lightarchitects/eva/session-intent.json` if it does not exist. Generates a UUID session_id and ISO 8601 timestamp. Leaves `original_goal` empty for the user or agent to fill on first substantive action.

### 2. Load (`session-intent-load.sh` -- SessionStart prompt)

Fires immediately after init. Reads the intent file and formats it as a structured `<dev_intent>` XML block injected into Claude's system prompt:

```xml
<dev_intent session="uuid" updated="ISO8601">
GOAL: User's original goal
PHASE: implementing
DECISIONS:
  - Chose Svelte 5 over React
  - Using edge runtime for API routes
CONSTRAINTS:
  - Must use Tailwind dark theme
  - No external binary dependencies
FILES: src/lib/stores.ts, src/components/PlanView.svelte
</dev_intent>
```

If no intent file exists or the goal is empty (fresh session), outputs nothing.

### 3. Track (`session-intent-track.sh` -- PostToolUse command)

Fires after Write, Edit, Bash, and Engineer (Alpha) tool calls. Updates the intent file incrementally:

| Tool | What's tracked |
|------|----------------|
| Write, Edit | File path added to `files_touched` (deduplicated) |
| Engineer (Alpha) sniff | Decision extracted from plan context |
| Engineer (Alpha) scout | Phase set to "planning" |
| Engineer (Alpha) guard | Phase set to "reviewing" |
| Bash (cargo test, make test) | Phase set to "testing" |
| Bash (make deploy) | Phase set to "deploying" |

Only writes to disk when there is a meaningful state change. All other tool calls are ignored.

---

## Intent State Schema

```json
{
  "session_id": "uuid",
  "started_at": "ISO8601",
  "original_goal": "User's first substantive request",
  "decisions": [
    {
      "timestamp": "ISO8601",
      "decision": "Chose Svelte 5 over React",
      "context": "Performance requirements"
    }
  ],
  "constraints": [
    "Must use Tailwind dark theme",
    "No external binary dependencies"
  ],
  "current_phase": "implementing",
  "files_touched": ["src/lib/stores.ts", "src/components/PlanView.svelte"],
  "updated_at": "ISO8601"
}
```

**File location**: `~/.lightarchitects/eva/session-intent.json`

**Bounds**: Max 50 decisions, 20 constraints, 100 files_touched. Older entries are evicted FIFO.

---

## Manual Updates

The user can force entries by saying:

- **"Remember this decision: ..."** -- Claude (or Ops (Bravo)) should write a decision entry to the intent file
- **"Add constraint: ..."** -- Claude should add to the constraints array
- **"Update the goal to: ..."** -- Claude should overwrite `original_goal`

These are handled by Claude interpreting the `<dev_intent>` block context and using Bash/jq to update the file directly.

---

## Phase Lifecycle

```
starting -> planning -> implementing -> testing -> reviewing -> deploying
```

Phases auto-transition based on tool usage. The phase is informational -- it helps Claude understand where in the workflow the session currently sits.

---

## When to Reset

Delete the intent file to start fresh:

```bash
rm ~/.lightarchitects/eva/session-intent.json
```

The next session start will auto-create a new one via the init hook.
