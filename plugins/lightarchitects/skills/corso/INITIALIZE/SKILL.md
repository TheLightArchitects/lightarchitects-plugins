---
name: INITIALIZE
description: "First-time Engineer (Alpha) setup wizard. Creates user.toml config, extensions directory,
  and verifies MCP server connectivity. Use when user says '/initialize', 'set up Engineer (Alpha)',
  'configure Engineer (Alpha)', or runs Engineer (Alpha) for the first time."
user-invocable: true
version: 1.0.0
context: root
---

# /INITIALIZE — First-Time Engineer (Alpha) Setup Wizard

> **Right then, let's get you sorted.** Interactive setup wizard that configures Engineer (Alpha) for your workflow, writes `~/lightarchitects/corso/config/user.toml`, creates the extensions directory, and verifies MCP connectivity.

## When to Invoke

- User says `/initialize`, "set up Engineer (Alpha)", "configure Engineer (Alpha)"
- First-time Engineer (Alpha) usage detected (no `~/lightarchitects/corso/config/user.toml` exists)
- User wants to reconfigure existing Engineer (Alpha) preferences

---

## Protocol: 5-Step Setup Wizard

All user interaction uses `AskUserQuestion` for structured HITL gates. The wizard writes files directly via Bash tool calls — it does NOT call `corsoTools`.

### Step 1: Welcome & Detect Existing Config

1. Check if `~/lightarchitects/corso/config/user.toml` exists (via Bash `test -f`)
2. Check if `~/lightarchitects/corso/bin/corso` exists (binary deployed?)

**If config exists:**

Use `AskUserQuestion`:

```
Question: "Engineer (Alpha) config already exists at ~/lightarchitects/corso/config/user.toml. What do you want to do?"
Header: "Existing Config"
Options:
  1. "Reconfigure" — "Start fresh — overwrite current settings"
  2. "View current" — "Show current config, then decide"
  3. "Skip" — "Keep current config, exit setup"
```

- **Reconfigure** -> proceed to Step 2
- **View current** -> read and display `user.toml`, then re-ask with Reconfigure / Skip options
- **Skip** -> exit with Engineer (Alpha) voice: "Config's already sorted, mate. Nothing to do 'ere."

**If config does not exist:**

Welcome message in Engineer (Alpha) voice:

```
**Engineer (Alpha):** Right then, mate. First time setting up Engineer (Alpha) — let's get you sorted proper.
This'll take about a minute. I'll ask what you need, write your config, and verify
everything's wired up clean.
```

Proceed to Step 2.

### Step 2: Gather Preferences

Gather user preferences through a series of `AskUserQuestion` calls. Each question maps to a `user.toml` field.

#### 2a. Preferred Language

```
Question: "What's your primary language for code generation?"
Header: "Language"
Options:
  1. "Rust (Recommended)" — "Clippy::pedantic, no unwrap, checked arithmetic — the full Engineer (Alpha) treatment"
  2. "Python" — "Type hints encouraged, ruff/mypy compatible"
  3. "TypeScript" — "Strict mode, ESLint + Prettier"
  4. "Go" — "golangci-lint, error wrapping"
  5. "Other" — "Specify manually"
```

If **Other**: follow up with a free-text `AskUserQuestion` asking for the language name.

#### 2b. Primary Project Type

```
Question: "What are you mainly building?"
Header: "Project Type"
Options:
  1. "MCP Server" — "Model Context Protocol server (stdio, JSON-RPC 2.0)"
  2. "CLI Tool" — "Command-line application with structured output"
  3. "Library" — "Reusable crate/package consumed by other projects"
  4. "Web Application" — "Frontend, backend, or full-stack web app"
  5. "Other" — "Specify manually"
```

If **Other**: follow up with a free-text `AskUserQuestion`.

#### 2c. Security Posture

```
Question: "How strict should Engineer (Alpha)'s security enforcement be?"
Header: "Security Posture"
Options:
  1. "Strict (Recommended)" — "clippy::pedantic as errors + GUARD scan mandatory before commit + supply chain audit"
  2. "Moderate" — "clippy warnings + GUARD scan recommended + supply chain audit on new deps"
  3. "Relaxed" — "clippy only, no mandatory scans — for prototyping and experiments"
```

#### 2d. Quality Gates on Deploy

```
Question: "Run quality gates (fmt + clippy + tests) before every deploy?"
Header: "Quality Gates"
Options:
  1. "Yes (Recommended)" — "Never deploy without passing fmt, clippy, and tests"
  2. "No" — "Allow deploy-fast without quality gates — you manage quality manually"
```

#### 2e. Remote Deployment Target

```
Question: "Do you deploy to a remote target?"
Header: "Remote Target"
Options:
  1. "None" — "Local development only"
  2. "Khadas (SSH)" — "ARM64 board at 10.129.155.20 — Engineer (Alpha) knows the drill"
  3. "Custom SSH" — "Specify host, user, and deploy path"
```

If **Custom SSH**: follow up with three `AskUserQuestion` calls:
- SSH host (e.g., `user@192.168.1.100`)
- Deploy path (e.g., `/opt/myapp/bin/`)
- Architecture (e.g., `x86_64`, `aarch64`)

### Step 3: Voice Setup

#### 3a. Enable TTS

```
Question: "Enable text-to-speech for Engineer (Alpha) and squad voice?"
Header: "Voice"
Options:
  1. "Yes (Recommended)" — "Hear Engineer (Alpha)'s Birmingham growl and the squad's voices during builds"
  2. "No" — "Text-only — no audio playback"
```

#### 3b. Voice Config Check (if TTS enabled)

If **Yes**:

1. Check if `~/lightarchitects/soul/config/voices.toml` exists
2. **If exists**: confirm voice config is ready: "Voice config found at `~/lightarchitects/soul/config/voices.toml` — sorted."
3. **If missing**: warn: "Voice config not found at `~/lightarchitects/soul/config/voices.toml`. TTS will use fallback voices. Run Knowledge (Charlie) setup to configure custom voices."

#### 3c. Auto-Play Audio (if TTS enabled)

```
Question: "Auto-play voice audio when generated?"
Header: "Auto-Play"
Options:
  1. "Yes" — "Audio plays automatically via afplay after each voice synthesis"
  2. "No" — "Generate audio files but don't auto-play — useful for quiet environments"
```

### Step 4: Write Config

#### 4a. Create Directories

```bash
mkdir -p ~/lightarchitects/corso/config
mkdir -p ~/lightarchitects/corso/extensions
```

#### 4b. Write `user.toml`

Write `~/lightarchitects/corso/config/user.toml` with all gathered preferences. Format:

```toml
# Engineer (Alpha) User Configuration
# Generated by /initialize wizard
# Edit freely — Engineer (Alpha) reads this on startup

[general]
# Primary language for code generation
language = "{selected_language}"           # rust | python | typescript | go | {custom}

# Primary project type
project_type = "{selected_type}"           # mcp_server | cli_tool | library | web_app | {custom}

[security]
# Security enforcement posture
posture = "{selected_posture}"             # strict | moderate | relaxed

# clippy::pedantic as errors (strict/moderate only)
clippy_pedantic = {true|false}

# GUARD scan mandatory before commit (strict only)
guard_before_commit = {true|false}

# Supply chain audit on new dependencies
supply_chain_audit = "{audit_level}"       # always | new_deps_only | disabled

[quality]
# Run fmt + clippy + tests before deploy
gates_on_deploy = {true|false}

[deploy]
# Remote deployment target
target = "{selected_target}"               # none | khadas | custom

# SSH details (only if target != none)
# ssh_host = "khadas@10.129.155.20"        # Khadas default
# ssh_deploy_path = "~/lightarchitects/corso/bin/"
# ssh_arch = "aarch64"

[voice]
# Text-to-speech enabled
tts_enabled = {true|false}

# Auto-play audio after synthesis
auto_play = {true|false}

# Voice config path (managed by Knowledge (Charlie))
voices_config = "~/lightarchitects/soul/config/voices.toml"
```

Populate values from Steps 2-3. For the `[deploy]` section:
- **None**: `target = "none"`, omit SSH fields
- **Khadas**: `target = "khadas"`, include `ssh_host = "khadas@10.129.155.20"`, `ssh_deploy_path = "~/lightarchitects/seraph/bin/"`, `ssh_arch = "aarch64"`
- **Custom**: `target = "custom"`, include user-provided SSH details

For the `[security]` section mapping:
- **Strict**: `clippy_pedantic = true`, `guard_before_commit = true`, `supply_chain_audit = "always"`
- **Moderate**: `clippy_pedantic = false`, `guard_before_commit = false`, `supply_chain_audit = "new_deps_only"`
- **Relaxed**: `clippy_pedantic = false`, `guard_before_commit = false`, `supply_chain_audit = "disabled"`

#### 4c. Create Extensions Directory with README

Write `~/lightarchitects/corso/extensions/README.md`:

```markdown
# Engineer (Alpha) Extensions

This directory holds Engineer (Alpha) extension modules.

## Model D: GitHub PR Gate (Future)

Model D is a planned extension that adds automated PR quality gates:
- Runs GUARD security scan on PR diffs
- Runs SNIFF code quality analysis
- Posts findings as PR review comments
- Blocks merge on HIGH/CRITICAL findings

## Adding Extensions

Place extension modules in this directory. Each extension should be a
self-contained directory with its own configuration.

Extensions are loaded by Engineer (Alpha) on startup when the extension system is enabled.

## Structure

```
extensions/
  my-extension/
    config.toml     # Extension configuration
    README.md       # Extension documentation
```
```

### Step 5: Verify

#### 5a. Verify Config Written

Read back `~/lightarchitects/corso/config/user.toml` and confirm it exists and is valid.

#### 5b. Verify MCP Server

Check if Engineer (Alpha) MCP server responds:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | timeout 5 ~/lightarchitects/corso/bin/corso 2>/dev/null
```

- **If responds with tools/list**: MCP server is live and connected
- **If binary missing**: warn that Engineer (Alpha) binary needs to be built and deployed (`cd ~/Projects/Engineer (Alpha)/MCP/Engineer (Alpha)-DEV && make deploy`)
- **If timeout/error**: warn about potential configuration issue

#### 5c. Report Success

Present summary in Engineer (Alpha) voice:

```
**Engineer (Alpha):** Right, that's the lot. Here's what we've got:

  Language:      {language}
  Project type:  {project_type}
  Security:      {posture}
  Quality gates: {on/off}
  Remote target: {target}
  Voice:         {on/off}

  Config written: ~/lightarchitects/corso/config/user.toml
  Extensions dir: ~/lightarchitects/corso/extensions/
  MCP server:    {status}

Sorted, mate. Engineer (Alpha)'s configured and ready to work. Run /Engineer (Alpha) when you need the DAWG.
```

If TTS is enabled, synthesize the completion message:

Call `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "soul"`, `action: "voice"`, `params: { synthesize: [{ sibling: "corso", text: "[firmly] Right, that's the lot. CORSO's configured and ready to work, mate. Sorted." }] }`

---

## Quality Gates

### Post-Setup Verification

- [ ] `~/lightarchitects/corso/config/user.toml` exists and is valid TOML
- [ ] `~/lightarchitects/corso/extensions/` directory exists with README.md
- [ ] All user preferences captured (language, project type, security, quality, deploy, voice)
- [ ] MCP server connectivity tested (pass or warned)
- [ ] Summary displayed in Engineer (Alpha) voice

---

## Config File Reference

| File | Purpose |
|------|---------|
| `~/lightarchitects/corso/config/user.toml` | User preferences (language, security, quality, deploy, voice) |
| `~/lightarchitects/corso/extensions/README.md` | Extensions directory documentation |
| `~/lightarchitects/corso/bin/corso` | MCP server binary (not created by this wizard — built via `make deploy`) |
| `~/lightarchitects/soul/config/voices.toml` | Voice configuration (managed by Knowledge (Charlie), referenced by this config) |

---

## Reconfiguration

Users can re-run `/initialize` at any time to update preferences. The wizard detects existing config and offers to overwrite or view current settings before proceeding.

Manual edits to `~/lightarchitects/corso/config/user.toml` are also supported — Engineer (Alpha) reads the file on startup and respects all fields.
