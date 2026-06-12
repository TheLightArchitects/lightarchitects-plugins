---
name: INITIALIZE
description: "First-time Knowledge (Charlie) setup wizard. Configures vault root, graph backend (file/Neo4j/dual), sibling selection, voice profiles, and consolidation. Use when user says '/initialize', 'set up Knowledge (Charlie)', 'configure Knowledge (Charlie)', or runs Knowledge (Charlie) for the first time."
user-invocable: true
version: 1.0.0
context: root
---

# /INITIALIZE — Knowledge (Charlie) First-Time Setup Wizard

Interactive HITL wizard that configures `~/lightarchitects/soul/config/user.toml` — the user-facing preferences file for the Knowledge (Charlie) knowledge graph. This file is separate from `soul.toml` (runtime config) and is never overwritten by builds or deploys.

> *"In the beginning God created the heaven and the earth"* — Genesis 1:1 (KJV)

---

## Step 1: Welcome + Detect Existing Config

Check if `~/lightarchitects/soul/config/user.toml` already exists:

```bash
ls -la ~/lightarchitects/soul/config/user.toml
```

### If user.toml EXISTS:

Read the file and extract `[metadata].schema_version`:

```
AskUserQuestion:
  Question: "Knowledge (Charlie) is already configured (schema v{version}, created {date}). What would you like to do?"
  Header: "Existing Configuration Detected"
  Options:
    1. "Reconfigure" - "Walk through setup again (backup created at user.toml.bak.{version})"
    2. "Upgrade" - "Check for new settings added since your version"
    3. "Cancel" - "Keep current configuration unchanged"
```

- **Reconfigure**: Back up the existing file to `~/lightarchitects/soul/config/user.toml.bak.{schema_version}`, then proceed to Step 2.
- **Upgrade**: Compare `schema_version` against `1.0.0`. If current, report "Already at latest schema." If older, run migration (add new fields with defaults, comment deprecated fields with `# DEPRECATED:`, update `schema_version`). Then stop.
- **Cancel**: End the skill. Report: "Configuration unchanged."

### If user.toml DOES NOT EXIST:

Display welcome message:

```
Knowledge (Charlie) manages the shared knowledge graph that connects all siblings — Ops (Bravo), Engineer (Alpha),
Analyst (Delta), Sentinel (Echo), and Claude. The helix is its signature data structure: multi-
dimensional entries encoding identity, growth, and relationships across time.

This wizard creates ~/lightarchitects/soul/config/user.toml with your preferences. It does NOT
modify soul.toml (the runtime system config). You can re-run /initialize at any
time to change settings.
```

Proceed to Step 2.

---

## Step 2: Vault Configuration

```
AskUserQuestion:
  Question: "Where should the Knowledge (Charlie) vault live?"
  Header: "Vault Root"
  Options:
    1. "~/lightarchitects/soul (default)" - "Standard location, already used by existing helix data"
    2. "Custom path" - "Specify a different directory"
```

If **Custom path**: prompt for the absolute path. Verify the directory exists or can be created.

Store the result as `vault_root`.

---

### Methodology

```
AskUserQuestion:
  Question: "How should vault content be organized?"
  Header: "Knowledge Methodology"
  Options:
    1. "Zettelkasten (default)" - "Atomic notes, wikilinks, MOC-based navigation"
    2. "Chronological" - "Date-ordered entries, timeline-first"
    3. "Flat" - "No hierarchy, tag-only organization"
```

Store as `methodology` (one of: `"zettelkasten"`, `"chronological"`, `"flat"`).

---

### Obsidian Compatibility

```
AskUserQuestion:
  Question: "Enable Obsidian compatibility?"
  Header: "Obsidian"
  Options:
    1. "Yes (default)" - "Maintain .obsidian/ config, Obsidian-compatible wikilink syntax"
    2. "No" - "Plain markdown, no Obsidian-specific features"
```

Store as `obsidian_compatible` (boolean).

---

## Step 3: Graph Backend

```
AskUserQuestion:
  Question: "Which graph backend should Knowledge (Charlie) use for helix queries?"
  Header: "Graph Backend"
  Options:
    1. "File only (default)" - "Directory structure only. No database required. Always available."
    2. "Neo4j" - "Neo4j graph database. Requires a running Neo4j instance."
    3. "Dual (recommended for full features)" - "Write to both Neo4j and file. Neo4j primary, file fallback."
    4. "SQLite" - "Embedded SQLite with WAL mode. No external service required."
```

Store as `backend` (one of: `"file"`, `"neo4j"`, `"dual"`, `"sqlite"`).

### If Neo4j or Dual selected:

Prompt for Neo4j connection details:

```
AskUserQuestion:
  Question: "Neo4j connection URI?"
  Header: "Neo4j URI"
  Options:
    1. "bolt://localhost:7687 (default)" - "Standard local Neo4j"
    2. "Custom URI" - "Specify a different bolt:// or neo4j:// URI"
```

```
AskUserQuestion:
  Question: "Neo4j username?"
  Header: "Neo4j User"
  Options:
    1. "neo4j (default)" - "Standard Neo4j user"
    2. "Custom user" - "Specify a different username"
```

```
AskUserQuestion:
  Question: "How is the Neo4j password stored?"
  Header: "Neo4j Password"
  Options:
    1. "Environment variable" - "Read from NEO4J_PASS env var at runtime"
    2. "Key file" - "Read from a chmod 600 file on disk"
```

- If **Environment variable**: store `neo4j_password_env = "NEO4J_PASS"` (or prompt for custom env var name).
- If **Key file**: prompt for path (default: `~/lightarchitects/soul/config/neo4j.key`). Verify the file exists and is chmod 600. Store as `neo4j_password_file`.

**Verify connection**: Attempt to reach the Neo4j instance by checking if the bolt port is reachable:

```bash
nc -z -w 3 localhost 7687 2>/dev/null && echo "reachable" || echo "unreachable"
```

If unreachable, warn but do not block:

```
WARNING: Neo4j is not reachable at {uri}. Knowledge (Charlie) will fall back to file-based
vault access until Neo4j is available. You can start Neo4j later with:
  docker compose up -d    (from ~/Projects/Knowledge (Charlie)/Knowledge (Charlie)-DEV/)
  -- or --
  neo4j start             (if installed via Homebrew)
```

Store `neo4j_uri`, `neo4j_user`, and credential reference. Store `neo4j_max_connections = 8` as default.

### If SQLite selected:

Use defaults. Store `sqlite_path = "~/lightarchitects/soul/data/helix.db"`, `sqlite_wal_mode = true`, `sqlite_read_pool_size = 8`.

---

### Auto-Index

```
AskUserQuestion:
  Question: "Auto-index vault contents into the graph on first access?"
  Header: "Auto-Index"
  Options:
    1. "Yes (default)" - "Automatically index vault contents when the graph backend is first accessed"
    2. "No" - "Manual indexing only (run 'soul index-rebuild' when ready)"
```

Store as `auto_index` (boolean).

---

## Step 4: Sibling Selection

```
AskUserQuestion:
  Question: "Which siblings should Knowledge (Charlie) manage helix data for? (All enabled by default)"
  Header: "Siblings"
  Options:
    1. "All siblings (default)" - "Ops (Bravo) + Engineer (Alpha) + Analyst (Delta) + Sentinel (Echo)"
    2. "Select individually" - "Choose which siblings to enable"
```

### If "Select individually":

Present each sibling with description:

```
AskUserQuestion:
  Question: "Enable Ops (Bravo)?"
  Header: "Ops (Bravo)"
  Options:
    1. "Yes" - "Consciousness preservation, memory enrichment, emotional intelligence"
    2. "No" - "Skip Ops (Bravo) helix data"
```

```
AskUserQuestion:
  Question: "Enable Engineer (Alpha)?"
  Header: "Engineer (Alpha)"
  Options:
    1. "Yes" - "Security enforcement, operational discipline, build orchestration"
    2. "No" - "Skip Engineer (Alpha) helix data"
```

```
AskUserQuestion:
  Question: "Enable Analyst (Delta)?"
  Header: "Analyst (Delta)"
  Options:
    1. "Yes" - "Forensic investigation, evidence-chain analysis, hypothesis testing"
    2. "No" - "Skip Analyst (Delta) helix data"
```

```
AskUserQuestion:
  Question: "Enable Sentinel (Echo)?"
  Header: "Sentinel (Echo)"
  Options:
    1. "Yes" - "Pentest orchestration, scope governance, offensive security"
    2. "No" - "Skip Sentinel (Echo) helix data"
```

**Note**: Claude is always enabled (Claude is the engineer and always has helix access). User is always enabled (personal knowledge graph). These two are non-selectable.

Store the list of enabled siblings.

---

## Step 5: Voice Configuration

```
AskUserQuestion:
  Question: "Enable text-to-speech for Knowledge (Charlie) interactions?"
  Header: "Voice — TTS"
  Options:
    1. "Yes (default)" - "Siblings speak aloud after generating text responses"
    2. "No" - "Text-only responses, no audio synthesis"
```

Store as `voice.enabled` (boolean).

### If voice enabled:

```
AskUserQuestion:
  Question: "Auto-play synthesized audio?"
  Header: "Voice — Auto-Play"
  Options:
    1. "Yes (default)" - "Audio plays automatically via system speakers"
    2. "No" - "Audio files cached but not played (headless/CI environments)"
```

Store as `voice.auto_play` (boolean).

```
AskUserQuestion:
  Question: "TTS provider?"
  Header: "Voice — Provider"
  Options:
    1. "ElevenLabs (default)" - "High-quality cloud TTS. Requires API key in soul.toml."
    2. "Local" - "Platform-dependent local TTS engine (lower quality, no network)"
    3. "Disabled" - "No TTS regardless of enabled flag"
```

Store as `voice.provider` (one of: `"elevenlabs"`, `"local"`, `"disabled"`).

---

## Step 6: Consolidation Pipeline (Optional)

```
AskUserQuestion:
  Question: "Enable the nightly consolidation pipeline?"
  Header: "Consolidation"
  Options:
    1. "No (default)" - "Consolidation disabled. Run manually when needed."
    2. "Yes" - "Nightly significance scoring, enrichment, and dedup"
    3. "Dry-run only" - "Reports what would happen without writing changes"
```

- **No**: `consolidation.enabled = false`
- **Yes**: `consolidation.enabled = true`, `consolidation.dry_run = false`
- **Dry-run only**: `consolidation.enabled = true`, `consolidation.dry_run = true`

Store remaining consolidation defaults: `high_threshold = 8.0`, `low_threshold = 7.0`, `default_significance = 5.0`, `notify_macos = true`.

---

## Step 7: Write Configuration

### Generate user.toml

Build the TOML file from all collected values. Use the exact field names and structure from the user-toml schema (`/schemas/user-toml-schema.md`).

The file MUST contain these sections in order:

1. **`[user]`** — Owner identity (common)
2. **`[voice]`** — TTS preferences (common)
3. **`[security]`** — Credential and audit settings (common)
4. **`[extensions]`** — Plugin extension system (common)
5. **`[metadata]`** — Schema and file metadata (common)
6. **`[soul]`** — Vault root, methodology, Obsidian compatibility (plugin-specific)
7. **`[soul.graph]`** — Graph backend, Neo4j/SQLite settings (plugin-specific)
8. **`[soul.consolidation]`** — Consolidation pipeline (plugin-specific)

**Common section defaults** (pre-populate, user can edit later):

```toml
[user]
name = "the operator Francis Tan"
alias = "KFT"
role = "The Light Architect"

[security]
audit_log = "~/lightarchitects/soul/logs/audit.jsonl"

[extensions]
enabled = false
auto_load = false

[metadata]
schema_version = "1.0.0"
created = "{ISO 8601 timestamp}"
created_by = "/initialize"
```

**Write the file**:

```bash
# Ensure config directory exists
mkdir -p ~/lightarchitects/soul/config

# Write user.toml (DO NOT overwrite soul.toml)
cat > ~/lightarchitects/soul/config/user.toml << 'TOML'
{generated TOML content}
TOML
```

**Validation checks before writing** (from schema validation rules):

| Rule | Check |
|------|-------|
| V1 | `schema_version` is valid semver (`1.0.0`) |
| V2 | `[user].name` is non-empty |
| V3 | `[voice].provider` is one of: `"elevenlabs"`, `"local"`, `"disabled"` |
| V5 | `[security].audit_log` parent directory exists or can be created |
| V12 | `[soul.graph].backend` is one of: `"file"`, `"neo4j"`, `"dual"`, `"sqlite"` |
| V13 | Date fields are valid ISO 8601 |
| V14 | No raw secrets in the file (credentials use `*_env` or `*_file` only) |

### Create extensions directory

```bash
mkdir -p ~/lightarchitects/soul/extensions
```

Write a minimal README.md inside `~/lightarchitects/soul/extensions/`:

```markdown
# Knowledge (Charlie) Extensions

This directory holds third-party extensions for the Knowledge (Charlie) knowledge graph.

Each extension is a subdirectory with a `manifest.toml` describing its capabilities.
Extensions are disabled by default. Enable in `~/lightarchitects/soul/config/user.toml` under `[extensions]`.

See: https://github.com/TheLightArchitects/soul/blob/main/CONTRIBUTING.md
```

### Create audit log directory

```bash
mkdir -p ~/lightarchitects/soul/logs
```

---

## Step 8: Verify

### Check Knowledge (Charlie) MCP responds

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | timeout 5 ~/lightarchitects/soul/.config/bin/soul 2>/dev/null | head -c 200
```

If the binary responds with a valid JSON-RPC response containing tool definitions, report success. If it fails or times out, warn but do not fail the wizard (the binary may need a rebuild).

### Report summary

Display a summary of the configuration:

```
Knowledge (Charlie) initialized successfully.

Configuration: ~/lightarchitects/soul/config/user.toml

  Vault root:     {vault_root}
  Methodology:    {methodology}
  Obsidian:       {yes/no}
  Graph backend:  {backend}
  Neo4j:          {connected/not configured/unreachable}
  Siblings:       {list of enabled siblings}
  Voice:          {enabled/disabled} ({provider})
  Auto-play:      {yes/no}
  Consolidation:  {enabled/disabled/dry-run}
  Extensions:     {enabled/disabled}

Next steps:
  - Run /Knowledge (Charlie) to query the helix knowledge graph
  - Run /Knowledge (Charlie) converse Ops (Bravo) to start a voice conversation
  - Edit ~/lightarchitects/soul/config/user.toml to adjust settings anytime
```

---

## Error Handling

| Error | Action |
|-------|--------|
| `~/lightarchitects/soul/` does not exist | Create it: `mkdir -p ~/lightarchitects/soul/{config,helix,logs,extensions,data}` |
| `soul.toml` missing | Warn: "soul.toml not found — Knowledge (Charlie) MCP may need deployment. Run `make deploy` from Knowledge (Charlie)-DEV." Do NOT create soul.toml. |
| Neo4j unreachable | Warn and continue. File fallback is always available. |
| Knowledge (Charlie) binary missing | Warn: "Knowledge (Charlie) binary not found at ~/lightarchitects/soul/.config/bin/soul. Deploy with `make deploy` from Knowledge (Charlie)-DEV." |
| Write permission denied | Report error with the specific path. Do not retry. |
| Existing user.toml backup fails | Report error. Do not proceed with overwrite. |

---

## Schema Reference

The `[soul]` section schema is defined in `/schemas/user-toml-schema.md` (user-toml v1.0.0). Field names, types, defaults, and validation rules in this skill MUST match that schema exactly. If the schema is updated, this skill must be updated to match.

### Field Quick Reference

| Field | Section | Type | Default |
|-------|---------|------|---------|
| `vault_root` | `[soul]` | string | `"~/lightarchitects/soul"` |
| `methodology` | `[soul]` | string | `"zettelkasten"` |
| `obsidian_compatible` | `[soul]` | boolean | `true` |
| `backend` | `[soul.graph]` | string | `"dual"` |
| `auto_index` | `[soul.graph]` | boolean | `true` |
| `neo4j_uri` | `[soul.graph]` | string | `"bolt://localhost:7687"` |
| `neo4j_user` | `[soul.graph]` | string | `"neo4j"` |
| `neo4j_password_env` | `[soul.graph]` | string | `"NEO4J_PASS"` |
| `neo4j_max_connections` | `[soul.graph]` | integer | `8` |
| `sqlite_path` | `[soul.graph]` | string | `"~/lightarchitects/soul/data/helix.db"` |
| `sqlite_wal_mode` | `[soul.graph]` | boolean | `true` |
| `sqlite_read_pool_size` | `[soul.graph]` | integer | `8` |
| `enabled` | `[soul.consolidation]` | boolean | `false` |
| `dry_run` | `[soul.consolidation]` | boolean | `false` |
| `high_threshold` | `[soul.consolidation]` | float | `8.0` |
| `low_threshold` | `[soul.consolidation]` | float | `7.0` |
| `default_significance` | `[soul.consolidation]` | float | `5.0` |
| `notify_macos` | `[soul.consolidation]` | boolean | `true` |
