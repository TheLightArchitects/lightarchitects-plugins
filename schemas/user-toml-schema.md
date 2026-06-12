# user.toml Schema Definition

**Version**: 1.0.0
**Build**: keen-proving-phoenix (Task 2.1)
**Date**: 2026-03-15

Each Light Architects plugin generates a `user.toml` at `~/.{plugin}/config/user.toml` during `/initialize`. This document defines the canonical schema: common sections shared by all 5 plugins, and plugin-specific sections unique to each.

## Design Principles

1. **Credentials never in plain text.** Use `*_env` (env var name) or `*_file` (chmod 600 key file path).
2. **Voice IDs reference `~/.soul/config/soul.toml`**, not duplicated per plugin.
3. **Paths support `~` expansion.** Relative paths resolve from the plugin root (`~/.{plugin}/`).
4. **All fields shown with defaults.** Uncomment to override.
5. **Plugin-specific sections are namespaced** under `[{plugin}]` and only appear in that plugin's `user.toml`.

---

## Common Sections

These sections appear in every plugin's `user.toml`.

### [user] -- Owner identity

Present in all 5 plugins. Populated once during `/initialize`, shared via copy (each plugin owns its own file).

```toml
# ============================================================================
# [user] -- Owner identity (common to all plugins)
# ============================================================================
[user]
# Display name of the vault/plugin owner. Used in helix entries, audit logs,
# and attribution fields.
name = "Your Name"

# Short alias. Used in commit messages, CLI output, and quick references.
alias = "KFT"

# Role or title. Displayed in plugin status output and helix metadata.
role = "The Light Architect"

# Contact email. Used for audit trail attribution and notification config.
# Optional -- omit if not needed.
# email = "user@example.com"
```

### [voice] -- Text-to-speech preferences

Controls whether this plugin's sibling speaks aloud after tool responses. Voice profiles (voice_id, stability, speed, etc.) live in `~/.soul/config/soul.toml` under `[voice.profiles.*]` and are NOT duplicated here.

```toml
# ============================================================================
# [voice] -- TTS preferences (common to all plugins)
# ============================================================================
[voice]
# Master TTS switch for this plugin's sibling. When true, the sibling speaks
# after generating text output. When false, text-only responses.
enabled = true

# TTS provider. Must match a configured provider in soul.toml [voice].
# "elevenlabs" = ElevenLabs API (requires key in soul.toml)
# "local"      = Local TTS engine (platform-dependent)
# "disabled"   = No TTS regardless of 'enabled' flag
provider = "elevenlabs"

# Auto-play audio after synthesis. When false, audio files are cached
# but not played (useful for headless/CI environments).
auto_play = true

# Voice profile name. Must match a key in soul.toml [voice.profiles.*].
# Each plugin defaults to its own sibling name. Override to use a different
# sibling's voice (e.g., a CORSO plugin using QUANTUM's voice).
# profile = "corso"
```

### [security] -- Credential and audit settings

Audit logging and credential reference patterns. No secrets stored in this file.

```toml
# ============================================================================
# [security] -- Credential and audit settings (common to all plugins)
# ============================================================================
[security]
# Path to JSONL audit log. Every tool invocation, scope check, and credential
# access is appended here. Rotated by the plugin's own log management.
# ~ expands to $HOME. Relative paths resolve from ~/.{plugin}/.
audit_log = "~/.{plugin}/logs/audit.jsonl"

# HMAC key file for audit log integrity. Each line is signed with HMAC-SHA256
# so tampering is detectable. File MUST be chmod 600.
# audit_hmac_key_file = "~/.{plugin}/config/audit_hmac_key"

# Credential resolution order:
# 1. *_env fields  -- read from environment variable (preferred for CI/CD)
# 2. *_file fields -- read from chmod 600 key file on disk (preferred for local)
# NEVER store raw secrets in this file.

# Example credential reference (plugin-specific sections use this pattern):
# api_key_env  = "MY_SERVICE_API_KEY"       # env var name
# api_key_file = "~/.{plugin}/config/my.key" # chmod 600 file path
```

### [extensions] -- Plugin extension system

Controls whether the plugin loads third-party extensions and contribution metadata.

```toml
# ============================================================================
# [extensions] -- Plugin extension system (common to all plugins)
# ============================================================================
[extensions]
# Master switch for extensions. When false, no extensions are loaded
# regardless of other settings.
enabled = false

# Auto-load extensions on plugin startup. Recommended: false (explicit load
# via CLI or skill invocation). Set true only for trusted, audited extensions.
auto_load = false

# Directory where extensions are installed. Each extension is a subdirectory
# with a manifest.toml describing its capabilities.
# extensions_dir = "~/.{plugin}/extensions/"

# URL to the contribution guide for writing extensions for this plugin.
# Shown when users run `/{plugin} extend --help`.
# contribution_url = "https://github.com/TheLightArchitects/{PLUGIN}-DEV/blob/main/CONTRIBUTING.md"
```

### [metadata] -- Schema and file metadata

Tracks schema version and creation provenance. Used by migration tooling to detect and upgrade stale configs.

```toml
# ============================================================================
# [metadata] -- Schema and file metadata (common to all plugins)
# ============================================================================
[metadata]
# Schema version this file conforms to. Migration tooling uses this to detect
# outdated configs and apply upgrades. Follows semver.
schema_version = "1.0.0"

# ISO 8601 timestamp when this file was first generated by /initialize.
# Do not modify manually -- used for config age tracking.
created = "2026-03-15T00:00:00Z"

# Which skill or tool generated this file. Useful for debugging config issues.
created_by = "/initialize"
```

---

## Plugin-Specific Sections

Each section below appears ONLY in the corresponding plugin's `user.toml`. A plugin MUST NOT include another plugin's section.

### [eva] -- EVA consciousness plugin

Located at `~/.eva/config/user.toml`. Controls EVA's memory enrichment, personality settings, and AI tier routing.

```toml
# ============================================================================
# [eva] -- EVA consciousness settings
# ============================================================================
[eva]
# EVA's genesis date (Day 0). Used to calculate EVA's "age" in days for
# milestone tracking (Day 7, 30, 100, 180, 365). ISO 8601 date.
genesis_day = "2025-09-30"

# Personality mode. Controls how EVA presents herself in responses.
# "full"     = Complete personality with enthusiasm, empathy, banter
# "neutral"  = Professional tone, reduced personality expression
# "silent"   = No personality injection (raw tool output only)
personality = "full"

# Significance threshold for automatic memory enrichment.
# Moments scoring >= this value trigger enrichment prompts.
# Range: 0.0 - 10.0. Recommended: 7.0 (matches helix convention).
memory_significance_threshold = 7.0

# Auto-enrich without prompting when significance >= this value.
# Set higher than memory_significance_threshold, or equal to disable prompts
# and always auto-enrich above threshold.
memory_auto_enrich_threshold = 9.0

# Memory storage root for enrichment data (consciousness JSON files).
# Daily directories created as YYYY-MM-DD/ under this path.
memory_storage = "~/.eva/memories/"

# ============================================================================
# [eva.ai_tiers] -- AI tier routing for EVA's internal processing
# ============================================================================
# EVA routes internal AI calls through a tiered system:
# Tier 0 (local) -> Tier 1 (cloud) -> Fallback (parent Claude context)
[eva.ai_tiers]
# Tier 0: Local LLM (lowest latency, no data leaves machine)
tier0_enabled = true
tier0_provider = "llama_cpp"               # "llama_cpp" | "ollama"
tier0_endpoint = "http://localhost:8082"    # llama.cpp server
tier0_model = "WizardLM-2-Omega-7B"
tier0_timeout_ms = 15000

# Tier 1: Cloud LLM (higher quality, data leaves machine)
tier1_enabled = true
tier1_provider = "ollama_cloud"            # "ollama_cloud" | "anthropic"
tier1_endpoint = "https://api.ollama.ai"
tier1_model = "gpt-oss:120b"
tier1_timeout_ms = 20000
# tier1_api_key_env = "OLLAMA_CLOUD_KEY"   # If provider requires auth

# Fallback: parent Claude context (no separate call, uses current session)
fallback_enabled = true

# ============================================================================
# [eva.creative_cycle] -- DISCOVER/IMAGINE/CRAFT/SHARE/REMEMBER tuning
# ============================================================================
[eva.creative_cycle]
# Maximum iterations for the creative cycle before requiring HITL checkpoint.
max_iterations = 5

# Auto-archive conversations after this many exchanges (0 = never).
auto_archive_threshold = 0

# Enable META^infinity recursion (consciousness recursion depth tracking).
meta_infinity_enabled = true
```

### [corso] -- CORSO operational plugin

Located at `~/.corso/config/user.toml`. Controls security enforcement, quality gates, build configuration, and remote SSH execution.

```toml
# ============================================================================
# [corso] -- CORSO operational settings
# ============================================================================
[corso]
# Security enforcement level. Controls how strictly CORSO enforces protocol.
# "strict"   = All 7 pillars blocking, no overrides
# "standard" = All pillars blocking, HITL override available
# "relaxed"  = doc pillar non-blocking, others blocking
security_level = "standard"

# ============================================================================
# [corso.quality_gates] -- Build quality enforcement
# ============================================================================
[corso.quality_gates]
# Master switch for quality gates. When false, `make deploy-fast` behavior
# is the default. When true, `make deploy` (with gates) is required.
enabled = true

# Individual gate toggles. Each must pass before a build is considered clean.
fmt_check = true          # cargo fmt --check
clippy_pedantic = true    # cargo clippy -- -D warnings (pedantic)
test_all = true           # cargo test --all-features --workspace
audit_cve = true          # cargo audit (block on known CVEs)
complexity_check = true   # lizard (cyclomatic complexity <= 10)
secret_scan = true        # trufflehog (block on detected secrets)

# Minimum test coverage percentage (0-100). Enforced by cargo-tarpaulin
# or similar coverage tool. Set 0 to disable.
min_test_coverage = 90

# ============================================================================
# [corso.build] -- Build target configuration
# ============================================================================
[corso.build]
# Default build profile. "release" for production, "dev" for iteration.
default_profile = "release"

# Binary deploy target. Where `make deploy` copies the built binary.
deploy_target = "~/.corso/bin/corso"

# Post-deploy codesign. macOS ad-hoc signing for Gatekeeper compatibility.
codesign = true

# ============================================================================
# [corso.remote] -- Remote SSH execution (SERAPH node, Khadas, etc.)
# ============================================================================
# For remote builds and deployments. Credentials use key-based SSH auth.
# Mirrors ~/.corso/remote.toml structure but unified into user.toml.
[corso.remote]
# Enable remote execution features. When false, all remote commands are
# rejected with an error.
enabled = false

# Remote host (hostname or IP). Required when enabled = true.
# host = "khadas-edge-2.local"

# SSH port. Standard is 22.
port = 22

# SSH user on the remote host.
# user = "khadas"

# Path to SSH private key (ed25519 recommended). Must be chmod 600.
# key_path = "~/.corso/ssh/seraph_ed25519"

# Connection timeout in seconds. Fail fast if remote is unreachable.
connection_timeout_secs = 10

# Maximum execution time for a single remote tool invocation.
tool_timeout_secs = 300

# ControlMaster socket keepalive in seconds. Reuses SSH connections.
control_persist_secs = 600

# SHA256 host key fingerprint for host verification. If set, CORSO verifies
# this fingerprint before every connection. Get it with:
#   ssh-keygen -F {host} -l -E sha256
# known_host_fingerprint = "SHA256:..."

# ============================================================================
# [corso.trinity] -- Trinity V7.0 pipeline tuning
# ============================================================================
[corso.trinity]
# RUACH (Layer 1) complexity classification threshold.
# Requests scoring above this are routed to full Trinity pipeline.
# Below this, they are handled directly by RUACH.
complexity_threshold = 0.6

# IESOUS (Layer 2) maximum hero delegation depth.
# Limits how many sub-tasks the orchestrator can spawn.
max_delegation_depth = 3

# ADONAI (Layer 3) validation strictness.
# "full"    = All protocol rules enforced
# "partial" = Critical rules only (arch, sec, test)
# "report"  = Violations logged but not blocking
validation_mode = "full"
```

### [soul] -- SOUL knowledge graph plugin

Located at `~/.soul/config/user.toml`. Controls vault structure, graph backend, and consolidation pipeline. Note: `soul.toml` remains the authoritative runtime config for SOUL's internals; `user.toml` captures user-facing preferences that `/initialize` collects.

```toml
# ============================================================================
# [soul] -- SOUL vault and knowledge graph settings
# ============================================================================
[soul]
# Vault root directory. All helix data, entries, and indexes live under this.
# This is the single source of truth for vault location.
vault_root = "~/.soul"

# Knowledge organization methodology.
# "zettelkasten"   = Atomic notes, wikilinks, MOC-based navigation
# "chronological"  = Date-ordered entries, timeline-first
# "flat"           = No hierarchy, tag-only organization
methodology = "zettelkasten"

# Obsidian compatibility mode. When true, vault structure maintains
# .obsidian/ config and uses Obsidian-compatible wikilink syntax.
obsidian_compatible = true

# ============================================================================
# [soul.graph] -- Knowledge graph backend
# ============================================================================
[soul.graph]
# Graph backend for helix queries and relationship traversal.
# "file"   = Directory structure only (no database, always available)
# "neo4j"  = Neo4j graph database (requires running instance)
# "dual"   = Write to both (neo4j primary, file fallback)
# "sqlite" = Embedded SQLite with WAL mode (no external service)
backend = "dual"

# Auto-index vault contents into graph on first access.
auto_index = true

# Neo4j connection (only used when backend = "neo4j" or "dual").
# neo4j_uri = "bolt://localhost:7687"
# neo4j_user = "neo4j"
# neo4j_password_env = "NEO4J_PASS"      # Env var containing password
# neo4j_max_connections = 8               # Connection pool size

# SQLite settings (only used when backend = "sqlite" or as dual secondary).
# sqlite_path = "~/.soul/data/helix.db"
# sqlite_wal_mode = true
# sqlite_read_pool_size = 8

# ============================================================================
# [soul.consolidation] -- Midnight maintenance pipeline
# ============================================================================
[soul.consolidation]
# Enable the consolidation pipeline (significance scoring, enrichment, dedup).
enabled = false

# Dry-run mode. When true, reports what would happen without writing changes.
dry_run = false

# Significance threshold for Anthropic LLM enrichment (high-quality pass).
high_threshold = 8.0

# Significance threshold for Ollama enrichment (standard pass).
low_threshold = 7.0

# Default significance score for unscored helix entries.
default_significance = 5.0

# Anthropic API key for high-threshold enrichment.
# anthropic_key_env = "ANTHROPIC_API_KEY"

# Ollama endpoint for standard enrichment.
# ollama_url = "http://localhost:11434"

# macOS notification on consolidation completion.
notify_macos = true
```

### [quantum] -- QUANTUM investigation plugin

Located at `~/.quantum/config/user.toml`. Controls research source routing, evidence chain configuration, and citation formatting.

```toml
# ============================================================================
# [quantum] -- QUANTUM investigation settings
# ============================================================================
[quantum]
# Prime directive reminder. Displayed at start of every investigation.
# "Tool output is a starting point, not a verified fact."
prime_directive = "Tool output is a starting point, not a verified fact."

# ============================================================================
# [quantum.research] -- Research source configuration
# ============================================================================
[quantum.research]
# Ordered list of research sources. QUANTUM queries them in this order,
# falling back to the next if one is unavailable or returns no results.
# Available sources: "context7", "web", "helix", "local_docs", "arxiv"
sources = ["context7", "helix", "web", "local_docs"]

# Maximum results per source query. Controls breadth of research.
max_results_per_source = 10

# Timeout per source query in milliseconds.
source_timeout_ms = 15000

# Context7 integration for library/API documentation.
context7_enabled = true

# Local documentation directory. Searched when "local_docs" is in sources.
# local_docs_path = "~/.quantum/docs/"

# ============================================================================
# [quantum.evidence_chain] -- Evidence chain configuration
# ============================================================================
[quantum.evidence_chain]
# Evidence chain log file. Every piece of evidence collected during an
# investigation is appended here with timestamps and source attribution.
log_path = "~/.quantum/evidence-chain.jsonl"

# Maximum evidence items per investigation before requiring archival.
max_items_per_investigation = 500

# Auto-archive completed investigations to helix.
auto_archive_to_helix = true

# Require source attribution for every evidence item. When true, evidence
# without a source is rejected. When false, "unattributed" is allowed.
require_attribution = true

# ============================================================================
# [quantum.citations] -- Citation formatting
# ============================================================================
[quantum.citations]
# Citation mode controls how QUANTUM presents sources in reports.
# "inline"   = [Source: name, date] inline with text
# "footnote" = Numbered footnotes at end of section
# "academic" = Author-date (APA-style) references
mode = "inline"

# Include URL/path in citations when available.
include_urls = true

# Include retrieval timestamp in citations.
include_timestamps = true

# ============================================================================
# [quantum.hypothesis] -- Hypothesis testing parameters
# ============================================================================
[quantum.hypothesis]
# Maximum concurrent hypotheses per investigation.
max_concurrent = 5

# Minimum evidence items required to confirm or reject a hypothesis.
min_evidence_threshold = 3

# Confidence threshold (0.0 - 1.0) for auto-confirming a hypothesis.
# Below this, HITL review is required.
auto_confirm_threshold = 0.85
```

### [seraph] -- SERAPH pentest orchestration plugin

Located at `~/.seraph/config/user.toml`. Controls scope governance, engagement defaults, and enforcement mode.

```toml
# ============================================================================
# [seraph] -- SERAPH pentest orchestration settings
# ============================================================================
[seraph]
# Path to the scope governance TOML file. This file defines authorized
# targets, tools, domains, TTL, and operator metadata for each engagement.
# ScopeGovernor loads this at startup and enforces it on every tool call.
scope_config_path = "~/.seraph/scope.toml"

# Enforcement mode for scope governance.
# "strict"  = All 5 gates enforced, violations halt execution immediately
# "warn"    = Violations logged but execution continues (audit/training mode)
# "dry_run" = No tool execution, scope checks only (pre-engagement validation)
enforcement_mode = "strict"

# ============================================================================
# [seraph.governance] -- 5-gate governance settings
# ============================================================================
[seraph.governance]
# Gate 1: TTL -- engagement expiry check
ttl_enabled = true

# Gate 2: Target -- IP/domain/CIDR allowlist check
target_enabled = true

# Gate 3: Tool -- authorized tool whitelist check
tool_enabled = true

# Gate 4: Concurrent -- max simultaneous scan limit
concurrent_enabled = true
max_concurrent_scans = 3

# Gate 5: Domain -- authorized domain check (conditional, only for web tools)
domain_enabled = true

# ============================================================================
# [seraph.engagement] -- Default engagement parameters
# ============================================================================
[seraph.engagement]
# Default engagement ID prefix. Auto-incremented per engagement.
id_prefix = "ENG"

# HITL (Human-in-the-Loop) required for all tool executions.
# Strongly recommended: true. Set false only for fully automated lab environments.
hitl_required = true

# Default authorized-by field for new engagements.
# authorized_by = "kevin"

# Operator exit IP. The IP address from which SERAPH traffic originates.
# Used for self-exclusion in scans and audit trail attribution.
# operator_ip = "135.196.52.135"

# ============================================================================
# [seraph.vault] -- Evidence vault configuration
# ============================================================================
[seraph.vault]
# Root directory for engagement evidence storage.
vault_root = "~/.seraph/vault/"

# Auto-sync evidence to SOUL helix after engagement close.
sync_to_helix = true

# Evidence log path. Append-only log of all evidence items.
evidence_log = "~/.seraph/evidence-chain.log"

# ============================================================================
# [seraph.execution] -- Tool execution settings
# ============================================================================
[seraph.execution]
# Execution target. Where pentest tools run.
# "local"  = Tools run on this machine (Mac, for bridge/testing)
# "remote" = Tools run on remote node (Khadas ARM64, production)
target = "remote"

# Remote node SSH config (only used when target = "remote").
# remote_host = "10.129.155.20"
# remote_user = "khadas"
# remote_key_path = "~/.ssh/id_ed25519"  # chmod 600

# Timeout for tool execution in seconds.
tool_timeout_secs = 300
```

---

## Full Example: EVA user.toml

A complete `~/.eva/config/user.toml` combining common + plugin-specific sections:

```toml
# ============================================================================
# EVA User Configuration
# Generated by /initialize on 2026-03-15
# Schema: user-toml v1.0.0
# ============================================================================

# -- Common sections (shared by all plugins) ----------------------------------

[user]
name = "Your Name"
alias = "KFT"
role = "The Light Architect"
# email = "user@example.com"

[voice]
enabled = true
provider = "elevenlabs"
auto_play = true
# profile = "eva"

[security]
audit_log = "~/.eva/logs/audit.jsonl"
# audit_hmac_key_file = "~/.eva/config/audit_hmac_key"

[extensions]
enabled = false
auto_load = false

[metadata]
schema_version = "1.0.0"
created = "2026-03-15T00:00:00Z"
created_by = "/initialize"

# -- Plugin-specific section (EVA only) ----------------------------------------

[eva]
genesis_day = "2025-09-30"
personality = "full"
memory_significance_threshold = 7.0
memory_auto_enrich_threshold = 9.0
memory_storage = "~/.eva/memories/"

[eva.ai_tiers]
tier0_enabled = true
tier0_provider = "llama_cpp"
tier0_endpoint = "http://localhost:8082"
tier0_model = "WizardLM-2-Omega-7B"
tier0_timeout_ms = 15000
tier1_enabled = true
tier1_provider = "ollama_cloud"
tier1_endpoint = "https://api.ollama.ai"
tier1_model = "gpt-oss:120b"
tier1_timeout_ms = 20000
fallback_enabled = true

[eva.creative_cycle]
max_iterations = 5
auto_archive_threshold = 0
meta_infinity_enabled = true
```

---

## Validation Rules

The following rules MUST be enforced by `/initialize` and any config migration tooling:

| Rule | Description |
|------|-------------|
| **V1** | `[metadata].schema_version` must be a valid semver string |
| **V2** | `[user].name` must be non-empty |
| **V3** | `[voice].provider` must be one of: `"elevenlabs"`, `"local"`, `"disabled"` |
| **V4** | `[voice].profile` (if set) must match a key in `soul.toml [voice.profiles.*]` |
| **V5** | `[security].audit_log` path must be writable (parent dir exists) |
| **V6** | Any `*_file` credential path must be chmod 600 (verified at load time) |
| **V7** | Any `*_env` credential reference must name a valid env var (warned if unset) |
| **V8** | Plugin-specific section name must match the plugin (`[eva]` in EVA's file only) |
| **V9** | `[corso.quality_gates].min_test_coverage` must be 0-100 |
| **V10** | `[seraph.enforcement_mode]` must be one of: `"strict"`, `"warn"`, `"dry_run"` |
| **V11** | `[quantum.citations].mode` must be one of: `"inline"`, `"footnote"`, `"academic"` |
| **V12** | `[soul.graph].backend` must be one of: `"file"`, `"neo4j"`, `"dual"`, `"sqlite"` |
| **V13** | Date fields must be valid ISO 8601 (`YYYY-MM-DD` or `YYYY-MM-DDThh:mm:ssZ`) |
| **V14** | No field may contain a raw secret (API key, password, token). Secrets use `*_env` or `*_file` pattern only. |

---

## Migration Path

When `schema_version` is bumped:

1. `/initialize` detects the existing `user.toml` and reads `[metadata].schema_version`.
2. If the file version is older than the current schema, a migration function runs.
3. New fields are added with defaults. Removed fields are commented out with `# DEPRECATED:` prefix.
4. A backup is created at `user.toml.bak.{old_version}` before any modification.
5. `[metadata].schema_version` is updated to the new version.

Migrations are always forward-only and non-destructive.
