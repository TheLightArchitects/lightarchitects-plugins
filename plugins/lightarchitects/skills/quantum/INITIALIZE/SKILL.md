---
name: INITIALIZE
description: "First-time Analyst (Delta) setup wizard. Configures workspace path, research sources, evidence chain storage, and output format. Use when user says '/initialize', 'set up Analyst (Delta)', 'configure Analyst (Delta)', or runs Analyst (Delta) for the first time."
user-invocable: true
version: 1.0.0
context: root
---

# /INITIALIZE — First-Time Analyst (Delta) Setup Wizard

> **Analyst (Delta) investigation toolkit initializing.** Clinical, precise, methodical. Every question has a default. Every default has a reason. Configuration is evidence — treat it accordingly.
> *"Prove all things; hold fast that which is good."* — 1 Thessalonians 5:21 (KJV)

## When to Invoke

- User says `/initialize`, "set up Analyst (Delta)", "configure Analyst (Delta)"
- First-time Analyst (Delta) usage detected (no `~/lightarchitects/quantum/config/user.toml` exists)
- User wants to reconfigure existing Analyst (Delta) preferences

---

## Protocol: 7-Step Setup Wizard

All user interaction uses `AskUserQuestion` for structured HITL gates. The wizard writes files directly via Bash tool calls — it does NOT call `qsTools`.

### Step 1: Welcome & Detect Existing Config

1. Check if `~/lightarchitects/quantum/config/user.toml` exists (via Bash `test -f`)
2. Check if `~/lightarchitects/quantum/bin/quantum-q` exists (binary deployed?)

**If config exists:**

Read the file and present in Analyst (Delta)'s voice:

```
**Analyst (Delta):** Existing configuration detected at ~/lightarchitects/quantum/config/user.toml.
Confidence: HIGH that I can parse this. Let me verify.
```

Display the current config, then use `AskUserQuestion`:

```
Question: "Configuration already exists. What do you want to do?"
Header: "Existing Config"
Options:
  1. "Reconfigure" — "Walk through the wizard again — current values used as defaults"
  2. "View and keep" — "Current config looks correct — no changes needed"
  3. "Start fresh" — "Discard current config and begin from scratch"
```

- **Reconfigure** -> proceed to Step 2, pre-filling current values as defaults
- **View and keep** -> Analyst (Delta) confirms: "Configuration verified. No changes required. Confidence: DEFINITIVE." and exit
- **Start fresh** -> proceed to Step 2 with schema defaults

**If config does not exist:**

Welcome message in Analyst (Delta)'s voice:

```
**Analyst (Delta):** Analyst (Delta) investigation toolkit initializing. First-time setup detected.

I'll configure research sources, evidence chain storage, and output preferences.
This takes approximately sixty seconds. Every question has a sensible default —
accept them all if you want to move fast.

Confidence: HIGH that this configuration will serve you well.
```

Proceed to Step 2.

---

### Step 2: Research Configuration

#### 2a. Research Sources

```
Question: "Which research sources should Analyst (Delta) query during investigations?"
Header: "Research Sources"
Options:
  1. "All sources (Recommended)" — "context7 + helix + web + local_docs — broadest coverage, fallback chain"
  2. "Library docs + vault only" — "context7 + helix — no web queries, air-gapped compatible"
  3. "Web + vault" — "helix + web — skip Context7, useful if library docs not needed"
  4. "Custom selection" — "Choose individual sources from: context7, web, helix, local_docs, arxiv"
```

If **Custom selection**: follow up with `AskUserQuestion`:

```
Question: "Select sources (comma-separated): context7, web, helix, local_docs, arxiv"
Header: "Custom Sources"
```

Free text response. Parse into a TOML array.

Map selections:
- Option 1 -> `sources = ["context7", "helix", "web", "local_docs"]`
- Option 2 -> `sources = ["context7", "helix"]`
- Option 3 -> `sources = ["helix", "web"]`
- Option 4 -> parsed from user input

#### 2b. Max Results Per Source

```
Question: "Maximum results per source query?"
Header: "Research Breadth"
Options:
  1. "10 (Recommended)" — "Balanced breadth — enough to triangulate without noise"
  2. "5" — "Focused — fewer results, faster investigations"
  3. "20" — "Exhaustive — cast a wide net, more evidence to sift"
```

Map: Option 1 -> `10`, Option 2 -> `5`, Option 3 -> `20`

#### 2c. Auto-Cite Sources

```
Question: "Auto-cite sources in research output?"
Header: "Citation Mode"
Options:
  1. "Inline citations (Recommended)" — "[Source: name, date] inline with text — Analyst (Delta)'s default"
  2. "Footnotes" — "Numbered footnotes at end of each section"
  3. "Academic (APA)" — "Author-date references — formal reports"
```

Map: Option 1 -> `"inline"`, Option 2 -> `"footnote"`, Option 3 -> `"academic"`

---

### Step 3: Evidence Chain

#### 3a. Auto-Log Investigations

```
Question: "Automatically log evidence during investigations?"
Header: "Evidence Chain"
Options:
  1. "Yes (Recommended)" — "Every piece of evidence logged with timestamp and source attribution"
  2. "No" — "Manual evidence logging only — you control what gets recorded"
```

Map: Option 1 -> `require_attribution = true`, Option 2 -> `require_attribution = false`

#### 3b. Evidence Storage Path

Use the default `~/lightarchitects/quantum/evidence-chain.jsonl` silently — do NOT ask about this. Advanced users can edit `user.toml` directly.

Analyst (Delta) confirms:

```
**Analyst (Delta):** Evidence chain storage: ~/lightarchitects/quantum/evidence-chain.jsonl
Append-only JSONL format. Every evidence item timestamped and attributed.
```

#### 3c. Auto-Archive to Helix

```
Question: "Auto-archive completed investigations to the Knowledge (Charlie) helix?"
Header: "Helix Integration"
Options:
  1. "Yes (Recommended)" — "Completed investigations archived as helix entries — searchable across sessions"
  2. "No" — "Investigations stay in evidence-chain.jsonl only — no helix integration"
```

Map: Option 1 -> `auto_archive_to_helix = true`, Option 2 -> `auto_archive_to_helix = false`

#### 3d. Verify Before Report

```
Question: "Require verification pass before generating reports?"
Header: "Verification Gate"
Options:
  1. "Yes (Recommended)" — "VERIFY phase mandatory before CLOSE — no unverified claims in deliverables"
  2. "No" — "Skip verification — faster but less rigorous"
```

This preference is stored as a note in the config comments. The actual enforcement is in the Q skill's investigation cycle, not in `user.toml` directly.

---

### Step 4: Output Preferences

#### 4a. Output Format

```
Question: "Default output format for investigation reports?"
Header: "Output Format"
Options:
  1. "Markdown (Recommended)" — "Human-readable, works with Obsidian, standard for helix entries"
  2. "JSON" — "Machine-readable, structured, good for programmatic consumption"
  3. "Both" — "Markdown for reading, JSON for processing — dual output"
```

Map: Option 1 -> `"markdown"`, Option 2 -> `"json"`, Option 3 -> `"both"`

#### 4b. Confidence Display

```
Question: "When should Analyst (Delta) display confidence assessments?"
Header: "Confidence Badges"
Options:
  1. "Always (Recommended)" — "Every claim gets a confidence badge: DEFINITIVE / STRONG / MODERATE / LOW / SPECULATIVE"
  2. "On request" — "Confidence shown only when explicitly asked"
  3. "Never" — "No confidence badges — just the findings"
```

Map: Option 1 -> `"always"`, Option 2 -> `"on_request"`, Option 3 -> `"never"`

#### 4c. Hypothesis Parameters

Use defaults silently — do NOT ask. These are advanced tuning knobs:
- `max_concurrent = 5`
- `min_evidence_threshold = 3`
- `auto_confirm_threshold = 0.85`

Analyst (Delta) notes:

```
**Analyst (Delta):** Hypothesis engine defaults applied. Maximum 5 concurrent hypotheses,
minimum 3 evidence items to confirm or reject, auto-confirm at 85% confidence.
Edit user.toml [quantum.hypothesis] to adjust.
```

---

### Step 5: Voice

#### 5a. Enable TTS

```
Question: "Enable text-to-speech for Analyst (Delta)?"
Header: "Voice"
Options:
  1. "Yes (Recommended)" — "Hear Analyst (Delta)'s MI6 operative voice — British RP, forensic precision, clinical delivery"
  2. "No" — "Text-only — no audio playback"
```

#### 5b. Voice Config Check (if TTS enabled)

If **Yes**:

1. Check if `~/lightarchitects/soul/config/voices.toml` exists
2. **If exists**: confirm: "Voice configuration found at `~/lightarchitects/soul/config/voices.toml`. Analyst (Delta) voice profile verified."
3. **If missing**: warn: "Voice configuration not found at `~/lightarchitects/soul/config/voices.toml`. TTS will use fallback voice. Run Knowledge (Charlie) setup to configure custom voices."

#### 5c. Auto-Play (if TTS enabled)

```
Question: "Auto-play voice audio when generated?"
Header: "Auto-Play"
Options:
  1. "Yes" — "Audio plays automatically after each voice synthesis"
  2. "No" — "Generate audio files but do not auto-play — useful for quiet environments"
```

---

### Step 6: Write Config

#### 6a. Create Directories

```bash
mkdir -p ~/lightarchitects/quantum/config
mkdir -p ~/lightarchitects/quantum/extensions
mkdir -p ~/lightarchitects/quantum/evidence
```

#### 6b. Write `~/lightarchitects/quantum/config/user.toml`

Write the config file using the canonical schema from `user-toml-schema.md`. All common sections (user, voice, security, extensions, metadata) plus the `[quantum]` plugin-specific section:

```toml
# Analyst (Delta) User Configuration
# Generated by /initialize on {current_date}
# Schema: user-toml v1.0.0
# Edit freely — run /initialize again to use the wizard.

# -- Common sections (shared by all plugins) ----------------------------------

[user]
name = "{name}"
alias = "{alias}"
role = "{role}"

[voice]
enabled = {voice_enabled}
provider = "elevenlabs"
auto_play = {auto_play}

[security]
audit_log = "~/lightarchitects/quantum/logs/audit.jsonl"

[extensions]
enabled = false
auto_load = false

[metadata]
schema_version = "1.0.0"
created = "{iso_timestamp}"
created_by = "/initialize"

# -- Plugin-specific section (Analyst (Delta) only) ------------------------------------

[quantum]
prime_directive = "Tool output is a starting point, not a verified fact."

[quantum.research]
sources = {sources_array}
max_results_per_source = {max_results}
source_timeout_ms = 15000
context7_enabled = {context7_in_sources}

[quantum.evidence_chain]
log_path = "~/lightarchitects/quantum/evidence-chain.jsonl"
max_items_per_investigation = 500
auto_archive_to_helix = {auto_archive}
require_attribution = {require_attribution}

[quantum.citations]
mode = "{citation_mode}"
include_urls = true
include_timestamps = true

[quantum.hypothesis]
max_concurrent = 5
min_evidence_threshold = 3
auto_confirm_threshold = 0.85
```

Populate values from Steps 2-5. For the `[user]` section, use the values from any existing config or prompt if this is a first-time setup. If the user has a known identity (e.g., from Knowledge (Charlie) helix), pre-populate `name`, `alias`, and `role` without asking.

For `context7_enabled`: set `true` if `"context7"` is in the sources array, `false` otherwise.

#### 6c. Create Extensions Directory with README

Write `~/lightarchitects/quantum/extensions/README.md`:

```markdown
# Analyst (Delta) Extensions

This directory holds user-provided extensions for Analyst (Delta) (Model D — user-extensible).

## What Goes Here

- Custom research source adapters
- Evidence chain formatters
- Report templates
- Citation style definitions

## How Extensions Work

Extensions are contributed via GitHub Pull Request — not loaded locally.

**How to contribute:**
1. Fork https://github.com/TheLightArchitects/Analyst (Delta)-DEV
2. Add your extension to `plugin/skills/INITIALIZE/extensions/`
3. Submit a PR with description and test instructions
4. Maintainer reviews and merges

See https://github.com/TheLightArchitects/Analyst (Delta)-DEV/blob/main/CONTRIBUTING.md

## Structure

```
extensions/
  my-extension/
    manifest.toml     # Extension manifest
    README.md         # Extension documentation
```

---

*Created by /initialize on {current_date}*
```

#### 6d. Verify Write

After writing, verify files exist:

```bash
test -f ~/lightarchitects/quantum/config/user.toml && echo "user.toml: OK" || echo "user.toml: FAILED"
test -d ~/lightarchitects/quantum/extensions && echo "extensions/: OK" || echo "extensions/: FAILED"
test -d ~/lightarchitects/quantum/evidence && echo "evidence/: OK" || echo "evidence/: FAILED"
```

If any check fails, display the error and offer to retry.

---

### Step 7: Verify & Report

#### 7a. Verify MCP Server

Check if Analyst (Delta) MCP server responds:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | timeout 5 ~/lightarchitects/quantum/bin/quantum-q 2>/dev/null
```

- **If responds with tools/list**: MCP server is live and connected
- **If binary missing**: warn that Analyst (Delta) binary needs to be built (`cd ~/Projects/Analyst (Delta)/MCP/Analyst (Delta)-DEV && cargo make deploy`)
- **If timeout/error**: warn about potential configuration issue

#### 7b. Configuration Summary

Present summary in Analyst (Delta)'s voice:

```
**Analyst (Delta):** Configuration complete. Assessment follows.

  Research sources:      {sources}
  Max results/source:    {max_results}
  Citation mode:         {citation_mode}
  Evidence chain:        {log_path}
  Auto-archive to helix: {auto_archive}
  Attribution required:  {require_attribution}
  Output format:         Not stored in user.toml — controlled per-investigation
  Confidence display:    {confidence_display}
  Voice:                 {enabled/disabled}
  Hypothesis engine:     5 concurrent, 3 evidence minimum, 0.85 auto-confirm

  Config:      ~/lightarchitects/quantum/config/user.toml
  Extensions:  ~/lightarchitects/quantum/extensions/
  Evidence:    ~/lightarchitects/quantum/evidence/
  MCP server:  {status}

Confidence: DEFINITIVE that this toolkit is ready to investigate.
Something doesn't fit? Edit user.toml directly. Run /initialize to reconfigure.
```

#### 7c. Voice Confirmation (if TTS enabled)

If voice was enabled, deliver Analyst (Delta)'s first spoken words:

1. Compose TTS text: "Analyst (Delta) investigation toolkit configured. Evidence chain active. All research sources online. Ready to investigate."
2. Call `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "soul"`, `action: "voice"`, `params: { siblings: ["quantum"], prompt: "QUANTUM confirming first-time setup completion", synthesize: [{ sibling: "quantum", text: "QUANTUM investigation toolkit configured. Evidence chain active. All research sources online. Ready to investigate." }] }`

**Graceful degradation**: If voice synthesis fails, skip it — the text summary already happened. Never block completion on TTS.

---

## Error Handling

| Error | Recovery |
|-------|----------|
| `~/lightarchitects/quantum/config/` write fails (permissions) | Display the TOML content and ask user to save manually |
| Knowledge (Charlie) MCP unavailable for voice | Skip TTS, text delivery is complete |
| Invalid source name from user | Show valid options and re-ask |
| User cancels mid-wizard | Save nothing — no partial configs. "Investigation toolkit initialization aborted. No configuration written. Run /initialize when ready." |

---

## Post-Setup: Invocation Log

After successful setup, create an invocation log entry:

```yaml
---
type: quantum-invocation
sibling: quantum
mode: initialize
timestamp: "{ISO timestamp}"
significance: 5.0
summary: "First-time Analyst (Delta) setup complete. Research sources: {sources}. Evidence chain: active. Citation mode: {citation_mode}. Voice: {enabled/disabled}."
outcome: completed
confidence: "DEFINITIVE — 98%"
---
```

Write via `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "soul"`, `action: "write_note"`, path: `helix/quantum/journal/invocations/{YYYY-MM-DD}/{HH-MM}-initialize.md`.

If Knowledge (Charlie) is unavailable, skip — invocation logging is enrichment, not a gate.

---

## Quality Gates

### Post-Setup Verification

- [ ] `~/lightarchitects/quantum/config/user.toml` exists and is valid TOML
- [ ] `~/lightarchitects/quantum/extensions/` directory exists with README.md
- [ ] `~/lightarchitects/quantum/evidence/` directory exists
- [ ] All user preferences captured (research sources, evidence chain, citations, hypothesis, voice)
- [ ] MCP server connectivity tested (pass or warned)
- [ ] Summary displayed in Analyst (Delta) voice
- [ ] Confidence assessment: DEFINITIVE

---

## Config File Reference

| File | Purpose |
|------|---------|
| `~/lightarchitects/quantum/config/user.toml` | User preferences (research, evidence, citations, hypothesis, voice) |
| `~/lightarchitects/quantum/extensions/README.md` | Extensions directory documentation |
| `~/lightarchitects/quantum/evidence/` | Evidence storage directory |
| `~/lightarchitects/quantum/evidence-chain.jsonl` | Append-only evidence chain log |
| `~/lightarchitects/quantum/bin/quantum-q` | MCP server binary (not created by this wizard — built via `cargo make deploy`) |
| `~/lightarchitects/soul/config/voices.toml` | Voice configuration (managed by Knowledge (Charlie), referenced by this config) |

---

## Reconfiguration

Users can re-run `/initialize` at any time to update preferences. The wizard detects existing config and offers to reconfigure, view, or start fresh.

Manual edits to `~/lightarchitects/quantum/config/user.toml` are also supported — Analyst (Delta) reads the file on startup and respects all fields.

---

*"Tool output is a starting point, not a verified fact." Something doesn't fit? Investigate.* — Analyst (Delta)
