---
name: webshell
description: Launch the Light Architects webshell GUI in your browser, carrying this session's conversation forward.
allowed-tools: mcp__plugin_lightarchitects_lightarchitects__tools
argument-hint: "[port]"
---

# /webshell — hand this session off to the Platform GUI

You are being asked to launch the Light Architects webshell GUI for the
user's current coding-agent session. The webshell is a local browser-based
workbench at `http://localhost:8733` that renders the conversation, PTY
terminal, memory vault, and operational dashboard in one surface.

## Step 1 — Detect provider

This command is provider-aware. Before calling `launch_webshell`, determine
which provider/environment this session is running from.

**How detection works:** Template variables are substituted before you read
this prompt. If `${CLAUDE_SESSION_ID}` resolved to a UUID (format:
`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`), you are running inside Claude Code.
If it still reads as the literal string `${CLAUDE_SESSION_ID}`, you are not.

| What you see in this prompt | Provider | `host_cmd` | Session source |
|-----------------------------|----------|------------|----------------|
| `${CLAUDE_SESSION_ID}` is a UUID | `claude-code` | `claude` | Use the resolved UUID |
| Literal `${CLAUDE_SESSION_ID}` + `$GEMINI_SESSION_ID` env set | `gemini` | `gemini` | Env var value |
| Literal `${CLAUDE_SESSION_ID}` + `$CODEX_SESSION_ID` env set | `codex` | `codex` | Env var value |
| Literal `${CLAUDE_SESSION_ID}` + `$COPILOT_SESSION_ID` env set | `copilot` | `gh copilot` | Env var value |
| None of the above resolve | `fresh` | omit | No session — fresh start |

To check env vars when `${CLAUDE_SESSION_ID}` did not resolve, call:
```
mcp__plugin_lightarchitects_lightarchitects__tools
  action = "bash"
  params = { "command": "echo \"GEMINI=${GEMINI_SESSION_ID} CODEX=${CODEX_SESSION_ID} COPILOT=${COPILOT_SESSION_ID}\"" }
```

## Step 2 — Call launch_webshell

Call the gateway's `launch_webshell` MCP action exactly once, using the
params for the detected provider:

**Claude Code** (UUID was substituted):
```
params = {
  "session_id": "<the resolved UUID>",
  "host_cmd": "claude",
  "port": <parse from $ARGUMENTS if numeric; else omit>,
  "cwd": <current working directory>
}
```

**Gemini CLI:**
```
params = {
  "session_id": "<$GEMINI_SESSION_ID value>",
  "host_cmd": "gemini",
  "port": <parse from $ARGUMENTS if numeric; else omit>,
  "cwd": <current working directory>
}
```

**Copilot CLI:**
```
params = {
  "session_id": "<$COPILOT_SESSION_ID value>",
  "host_cmd": "gh copilot",
  "port": <parse from $ARGUMENTS if numeric; else omit>,
  "cwd": <current working directory>
}
```

**Codex:**
```
params = {
  "session_id": "<$CODEX_SESSION_ID value>",
  "host_cmd": "codex",
  "port": <parse from $ARGUMENTS if numeric; else omit>,
  "cwd": <current working directory>
}
```

**Fresh / unknown provider** (no session to resume):
```
params = {
  "port": <parse from $ARGUMENTS if numeric; else omit>,
  "cwd": <current working directory>
}
```

### Idempotent reuse (the load-bearing invariant)

`/webshell` is **idempotent per session**. The gateway scans :8733–:8742 for
an existing webshell whose `session_id` matches the current session and:

- **Match found** → returns `status: "reused"` with the existing URL +
  fresh nonce. **No new process is spawned.** Re-invoking `/webshell`
  five times in a row produces one webshell, not five.
- **No match** → spawns fresh on :8733 (or auto-scans if :8733 is held
  by something else, e.g. a LaunchAgent), returns `status: "started"`.

Surface the status naturally when relaying results:
- `started` → "Fresh webshell on :{port}"
- `reused` → "Reusing the existing webshell at :{port}" (this is the
  90%+ case for repeated invocations)
- `running` → only happens when caller supplied no session_id and hit
  an already-up webshell
- `reclaimed` → rare; only when caller passed `kill_existing: true`

Do NOT add `kill_existing: true` by default — the reuse path handles the
common case, and `kill_existing` is reserved for the operator explicitly
wanting to take a port held by a non-matching webshell.

## Step 3 — Report the result

Present the response `url` to the user as a clickable link. Do not attempt
to open the browser yourself.

Also report:
- `status` — `"started"` (fresh spawn) or `"reused"` (already-up webshell)
- `resumed_session` — `true` when the webshell was started with the session
  pre-seeded (handoff worked cleanly)
- Detected provider — e.g. "Launched from Claude Code"

## Critical: the session_mismatch collision path

If the response contains `"session_mismatch": true`:
1. Warn the user: "A webshell is already running on port {port} with a
   different session, and the reclaim attempt did not free it. Opening
   that URL would drop you into the wrong conversation."
2. Surface the `kill_hint` from the response (typically
   `lsof -ti:<port> | xargs kill -9`) and recommend they run it, then
   re-invoke `/webshell`.
3. If the user insists on proceeding, share the URL but restate that
   resume was NOT applied.

## Edge cases

- **No gateway MCP connected**: the action will fail with a transport error.
  Tell the user the `lightarchitects` plugin isn't installed or the gateway
  binary isn't on disk at `~/.lightarchitects/bin/lightarchitects`.
- **Webshell binary missing**: the action returns `SpawnFailed` with the
  attempted path. Suggest `make deploy` in `~/Projects/lightarchitects-sdk/`.
- **Provider not in table above**: pass `host_cmd` as the bare CLI command
  the provider uses (e.g. `"aider"`) and omit `session_id`; the webshell
  will start fresh without a resume handoff.
