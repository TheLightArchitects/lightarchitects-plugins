---
name: INITIALIZE
description: "First-time Sentinel (Echo) setup wizard. Guided scope.toml generation with engagement ID, authorized targets, tools, TTL, and HITL gate configuration. CRITICAL: Sentinel (Echo) will not operate without a valid scope. Use when user says '/initialize', 'set up Sentinel (Echo)', 'configure Sentinel (Echo)', or runs Sentinel (Echo) for the first time."
user-invocable: true
version: 1.0.0
context: root
---

# /INITIALIZE — Sentinel (Echo) Scope Definition Wizard

> **No engagement proceeds without scope.** This skill creates the `~/lightarchitects/seraph/scope.toml` that governs ALL Sentinel (Echo) operations and the `~/lightarchitects/seraph/config/user.toml` that stores user preferences. Without a valid scope, Sentinel (Echo) refuses every tool call except `speak` and `status`.
> *"The perimeter awaits definition."* — Sentinel (Echo)

---

## Step 1: Welcome in Sentinel (Echo)'s Voice

### 1a: Voice Synthesis

Call `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "soul"`, `action: "voice"`, `params: { siblings: ["seraph"], prompt: "First-time setup wizard — scope definition", synthesize: [{ sibling: "seraph", text: "The perimeter awaits definition. No engagement proceeds without scope. Let us begin." }] }`.

**Graceful degradation**: If Knowledge (Charlie) MCP is unavailable, skip voice — text delivery always happens.

### 1b: Check Existing Scope

Read `~/lightarchitects/seraph/scope.toml` via filesystem access.

**If file exists**:

Present current scope summary via `AskUserQuestion`:

```
Question: "Existing scope detected. What do you want to do?"
Header: "Scope Configuration"
Context:
  Engagement: {engagement_id}
  Targets: {targets list}
  Tools: {authorized_tools count} authorized
  Expires: {expires_at}
  HITL: {hitl_required}
Options:
  1. "Reconfigure" — "Replace the entire scope.toml with a new engagement"
  2. "Extend" — "Add targets, tools, or adjust TTL to the current scope"
  3. "View Details" — "Show full scope.toml contents, then decide"
  4. "Cancel" — "Keep current scope. Exit wizard."
```

- **Reconfigure** -> Continue to Step 2 (full wizard, overwrites existing scope)
- **Extend** -> Jump to Step 2c (add targets/tools/TTL to existing scope, preserve engagement_id)
- **View Details** -> Display full `scope.toml` contents, then re-prompt with Reconfigure/Extend/Cancel
- **Cancel** -> Exit wizard. Report: "Scope unchanged. Current engagement holds."

**If file does not exist**:

Report: "No scope found at `~/lightarchitects/seraph/scope.toml`. First-time configuration." Continue to Step 2.

---

## Step 2: Engagement Definition

> The engagement is the authorization wrapper. Every scan, every capture, every tool invocation lives inside it.

### 2a: Engagement Identity

Use `AskUserQuestion`:

```
Question: "Engagement identity. Provide an ID or accept the auto-generated one."
Header: "Engagement ID"
Context: "The engagement ID is a unique identifier for this authorized scope. It appears in every evidence chain entry and audit log."
Options:
  1. "Auto-generate" — "UUID-based: ENG-{short-uuid}"
  2. "Custom ID" — "You provide the engagement ID (e.g., ENG-HOMELAB, ENG-CLIENT-2026-Q1)"
```

- **Auto-generate** -> Generate `ENG-{first 8 chars of UUID}` (e.g., `ENG-a3f8b2c1`)
- **Custom ID** -> Use `AskUserQuestion` with freeform: `"Enter engagement ID (e.g., ENG-HOMELAB):"`

Store as `$ENGAGEMENT_ID`.

### 2b: Engagement Metadata

Use `AskUserQuestion` (freeform):

```
Question: "Who authorized this engagement? (Name or role — appears in scope.toml and audit trail)"
Header: "Authorization"
```

Store as `$AUTHORIZED_BY`.

### 2c: Target Extension Mode (only if "Extend" was selected in Step 1b)

If extending an existing scope:

Use `AskUserQuestion` (freeform):

```
Question: "What do you want to add or change?"
Header: "Extend Scope"
Context: "Current targets: {existing targets}. Current tools: {existing tools count}. Expires: {existing TTL}."
Options:
  1. "Add targets" — "Add IPs, CIDRs, or domains to the authorized list"
  2. "Add tools" — "Authorize additional tools"
  3. "Adjust TTL" — "Change the engagement expiry"
  4. "All of the above" — "Modify targets, tools, and TTL"
```

Route to the relevant steps below (3, 4, 5) based on selection, preserving existing values for unchanged fields. Skip Steps 2a and 2b (keep existing engagement_id and authorized_by).

---

## Step 3: Target Definition

> Only these targets will be scanned. Sentinel (Echo) refuses anything outside scope. The allowlist is not just security — it is conviction.

### 3a: Authorized Targets

Use `AskUserQuestion` (freeform):

```
Question: "List authorized targets. One per line. Accepts: IP addresses (10.0.0.1), CIDR ranges (192.168.1.0/24), hostnames (target.example.com), wildcards (*.example.com)."
Header: "Authorized Targets"
Context: "These are the ONLY hosts Sentinel (Echo) will interact with. Gate 2 (Target) blocks any tool call against an address not on this list."
```

Parse the response into an array. Validate each entry:
- CIDR notation: must be valid (e.g., `10.0.0.0/24`, `127.0.0.1/32`)
- IP addresses: append `/32` if no CIDR suffix
- Hostnames/domains: accepted as-is (also feed into Step 3b)

Store as `$TARGETS` array.

### 3b: Authorized Domains

Use `AskUserQuestion` (freeform):

```
Question: "List authorized domains for web-based attacks. One per line. Wildcards supported (*.example.com). Leave empty if this is an IP-only engagement."
Header: "Authorized Domains"
Context: "Gate 5 (Domain) checks these when a target contains alphabetic characters. If empty, domain-based targets will be blocked."
```

If domains are provided from Step 3a targets (any entry containing alphabetic chars), suggest them as defaults.

Store as `$AUTHORIZED_DOMAINS` array. If empty and targets contain domains, warn: "You listed domain targets but no authorized domains. Gate 5 will block domain-based tool calls. Add them now or confirm IP-only engagement."

---

## Step 4: Tool Authorization

> Each tool is a weapon. Authorized explicitly, never assumed.

### 4a: Tool Selection

Use `AskUserQuestion`:

```
Question: "Which tools should Sentinel (Echo) be authorized to use?"
Header: "Tool Authorization"
Context: "Tools not on this list will be rejected by Gate 3 (Tool). You can always add more later with /initialize extend."
Options:
  1. "Safe Recon Only (Recommended)" — "nmap, subfinder, dnsx, httpx, curl, dig, whois, fping — passive/active recon, no exploitation"
  2. "Full Recon + Scanning" — "Above + nikto, nuclei, gobuster, testssl, traceroute, nc, amass, katana, ffuf — comprehensive scanning"
  3. "Full Arsenal" — "All above + sqlmap, feroxbuster, tcpdump, tshark, ngrep — includes aggressive tools"
  4. "Custom" — "Select individual tools from the full list"
```

**Tool presets**:

| Preset | Tools |
|--------|-------|
| Safe Recon Only | `nmap`, `subfinder`, `dnsx`, `httpx`, `curl`, `dig`, `whois`, `fping` |
| Full Recon + Scanning | Above + `nikto`, `nuclei`, `gobuster`, `testssl`, `traceroute`, `nc`, `amass`, `katana`, `ffuf` |
| Full Arsenal | Above + `sqlmap`, `feroxbuster`, `tcpdump`, `tshark`, `ngrep` |

**If "Custom"** selected:

Use `AskUserQuestion` (freeform):

```
Question: "List tools to authorize, one per line. Available: nmap, nikto, nuclei, gobuster, subfinder, dnsx, httpx, testssl, sqlmap, curl, dig, whois, traceroute, nc, python3, feroxbuster, fping, tcpdump, tshark, ngrep, amass, katana, ffuf, dumpcap, masscan, yara, exiftool, binwalk, strings, crt.sh"
Header: "Custom Tool List"
```

### 4b: Aggressive Tool Warning

If selected tools include any of: `sqlmap`, `feroxbuster`, `nuclei` (with exploit templates), `ffuf`:

Display warning:

```
WARNING: Aggressive tools selected.

  sqlmap     — SQL injection testing. Can modify database state.
  feroxbuster — Recursive directory brute-forcing. High traffic volume.
  nuclei     — Template-based scanning. Some templates attempt exploitation.
  ffuf       — Fuzzing. High request volume.

These tools generate significant network traffic and may trigger IDS/IPS alerts.
Ensure you have WRITTEN AUTHORIZATION before proceeding.
```

Use `AskUserQuestion`:

```
Question: "Confirm aggressive tool authorization?"
Header: "Confirmation"
Options:
  1. "Yes, I have written authorization" — "Proceed with all selected tools"
  2. "Remove aggressive tools" — "Keep only safe recon and scanning tools"
  3. "Let me reconsider" — "Go back to tool selection"
```

Store as `$AUTHORIZED_TOOLS` array.

---

## Step 5: Governance Configuration

> Five gates. Each a wall. Each must hold.

### 5a: TTL (Engagement Expiry)

Use `AskUserQuestion`:

```
Question: "How long should this engagement be valid?"
Header: "Time-To-Live"
Context: "Gate 1 (TTL) halts ALL operations after expiry. You must run /initialize again to extend."
Options:
  1. "24 hours" — "Short engagement — quick scan or verification"
  2. "72 hours" — "Standard engagement — multi-day assessment"
  3. "7 days" — "Extended engagement — full penetration test"
  4. "30 days" — "Long engagement — ongoing monitoring or red team exercise"
  5. "Custom" — "Specify exact expiry date/time (ISO 8601)"
```

**If "Custom"**:

Use `AskUserQuestion` (freeform):

```
Question: "Enter expiry date/time in ISO 8601 format (e.g., 2026-12-31T23:59:59Z):"
Header: "Custom TTL"
```

Validate the date is in the future. If not, warn and re-prompt.

Calculate `$EXPIRES_AT` as ISO 8601 datetime.

### 5b: HITL Gate

Use `AskUserQuestion`:

```
Question: "Require Human-in-the-Loop approval before each tool execution?"
Header: "HITL Gate"
Context: "STRONGLY RECOMMENDED: yes. When enabled, Sentinel (Echo) presents each tool command for your approval before execution. Disable only for fully automated lab environments you own."
Options:
  1. "Yes (Strongly Recommended)" — "Every tool execution requires your explicit approval"
  2. "No" — "Automated execution within scope boundaries (lab environments only)"
```

Store as `$HITL_REQUIRED` boolean.

If "No" selected, display warning:

```
WARNING: HITL disabled. Sentinel (Echo) will execute authorized tools without asking.
This is appropriate ONLY for isolated lab environments you fully control.
Confirm this is an isolated lab environment.
```

Use `AskUserQuestion`:

```
Question: "Confirm: this is an isolated lab environment I fully control?"
Header: "HITL Confirmation"
Options:
  1. "Yes, confirmed" — "Proceed without HITL"
  2. "Enable HITL" — "Keep HITL enabled (recommended)"
```

### 5c: Concurrent Scan Limit

Use `AskUserQuestion`:

```
Question: "Maximum concurrent scans?"
Header: "Concurrency Limit"
Context: "Gate 4 (Concurrent) blocks new scans when this limit is reached. Higher values increase network load."
Options:
  1. "3 (Default)" — "Standard — balances speed and stealth"
  2. "1" — "Serial — lowest noise, slowest"
  3. "5" — "Parallel — faster, more network traffic"
  4. "Custom" — "Specify a number"
```

Store as `$MAX_CONCURRENT_SCANS` integer.

### 5d: Gate Configuration

Use `AskUserQuestion`:

```
Question: "All 5 governance gates are ON by default. Adjust?"
Header: "Gate Configuration"
Context: |
  Gate 1 (TTL):        Engagement expiry check
  Gate 2 (Target):     IP/domain/CIDR allowlist check
  Gate 3 (Tool):       Authorized tool whitelist check
  Gate 4 (Concurrent): Max simultaneous scan limit
  Gate 5 (Domain):     Authorized domain check (conditional, web tools)
Options:
  1. "All ON (Recommended)" — "Maximum governance — every gate enforced"
  2. "Customize" — "Toggle individual gates (advanced)"
```

If "Customize":

For each gate, use `AskUserQuestion` with enable/disable options. Store as `$GATE_1` through `$GATE_5` booleans.

**WARNING**: If any gate is disabled, display: "Disabling gates reduces scope enforcement. Ensure you understand the implications."

---

## Step 6: Write Configuration

### 6a: Create Directory Structure

```bash
mkdir -p ~/lightarchitects/seraph/config
mkdir -p ~/lightarchitects/seraph/extensions
mkdir -p ~/lightarchitects/seraph/logs
mkdir -p ~/lightarchitects/seraph/vault
```

### 6b: Write `user.toml`

Create `~/lightarchitects/seraph/config/user.toml` with the common sections + `[seraph]` plugin-specific section per the user-toml-schema.

```toml
# ============================================================================
# Sentinel (Echo) User Configuration
# Generated by /initialize on {current ISO date}
# Schema: user-toml v1.0.0
# ============================================================================

# -- Common sections (shared by all plugins) ----------------------------------

[user]
name = "{user name — default: the operator Francis Tan}"
alias = "{user alias — default: KFT}"
role = "{user role — default: The Light Architect}"

[voice]
enabled = true
provider = "elevenlabs"
auto_play = true

[security]
audit_log = "~/lightarchitects/seraph/logs/audit.jsonl"

[extensions]
enabled = false
auto_load = false

[metadata]
schema_version = "1.0.0"
created = "{ISO 8601 timestamp}"
created_by = "/initialize"

# -- Plugin-specific section (Sentinel (Echo) only) ------------------------------------

[seraph]
scope_config_path = "~/lightarchitects/seraph/scope.toml"
enforcement_mode = "strict"

[seraph.governance]
ttl_enabled = {$GATE_1 — default: true}
target_enabled = {$GATE_2 — default: true}
tool_enabled = {$GATE_3 — default: true}
concurrent_enabled = {$GATE_4 — default: true}
max_concurrent_scans = {$MAX_CONCURRENT_SCANS}
domain_enabled = {$GATE_5 — default: true}

[seraph.engagement]
id_prefix = "ENG"
hitl_required = {$HITL_REQUIRED}

[seraph.vault]
vault_root = "~/lightarchitects/seraph/vault/"
sync_to_helix = true
evidence_log = "~/lightarchitects/seraph/evidence-chain.log"

[seraph.execution]
target = "remote"
tool_timeout_secs = 300
```

### 6c: Write `scope.toml`

Create or overwrite `~/lightarchitects/seraph/scope.toml` with the engagement configuration:

```toml
# Sentinel (Echo) Scope Governance — {$ENGAGEMENT_ID}
# Created: {current date}
# Generated by /initialize

engagement_id = "{$ENGAGEMENT_ID}"
targets = {$TARGETS as TOML array}
authorized_tools = {$AUTHORIZED_TOOLS as TOML array}
authorized_domains = {$AUTHORIZED_DOMAINS as TOML array}
expires_at = "{$EXPIRES_AT}"
hitl_required = {$HITL_REQUIRED}
authorized_by = "{$AUTHORIZED_BY}"
max_concurrent_scans = {$MAX_CONCURRENT_SCANS}
```

### 6d: Create Extensions README

Create `~/lightarchitects/seraph/extensions/README.md`:

```markdown
# Sentinel (Echo) Extensions (Model D)

Extensions are disabled by default. Enable in `~/lightarchitects/seraph/config/user.toml`:

    [extensions]
    enabled = true

Each extension is a subdirectory with a `manifest.toml` describing its capabilities.
See: https://github.com/TheLightArchitects/Sentinel (Echo)-DEV/blob/main/CONTRIBUTING.md
```

---

## Step 7: Verify Configuration

### 7a: Validate scope.toml

Re-read `~/lightarchitects/seraph/scope.toml` and verify:
- File parses as valid TOML
- `engagement_id` is non-empty
- `targets` array is non-empty
- `authorized_tools` array is non-empty
- `expires_at` is a valid ISO 8601 datetime in the future
- `authorized_by` is non-empty
- `max_concurrent_scans` is a positive integer

If any validation fails, report the specific error and offer to re-run the relevant step.

### 7b: Validate user.toml

Re-read `~/lightarchitects/seraph/config/user.toml` and verify:
- File parses as valid TOML
- `[metadata].schema_version` is `"1.0.0"`
- `[seraph].enforcement_mode` is one of: `"strict"`, `"warn"`, `"dry_run"`

### 7c: Check Sentinel (Echo) Binary

Verify `~/lightarchitects/seraph/bin/seraph` exists and is executable. If not, warn: "Sentinel (Echo) binary not found. Deploy with `make deploy-mac` from Sentinel (Echo)-DEV."

### 7d: Completion Report

Present the summary in Sentinel (Echo)'s voice:

```
Scope defined.

  Engagement:  {$ENGAGEMENT_ID}
  Authorized:  {$AUTHORIZED_BY}
  Targets:     {count} authorized ({list first 3, "..." if more})
  Tools:       {count} authorized
  TTL:         {$EXPIRES_AT} ({human-readable duration remaining})
  HITL:        {enabled/disabled}
  Concurrency: {$MAX_CONCURRENT_SCANS}
  Gates:       {count}/5 active

  Config:      ~/lightarchitects/seraph/config/user.toml
  Scope:       ~/lightarchitects/seraph/scope.toml

The perimeter is held.
```

### 7e: Voice Completion

Call `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "soul"`, `action: "voice"`, `params: { siblings: ["seraph"], prompt: "Scope configuration complete", synthesize: [{ sibling: "seraph", text: "Scope defined. {N} targets authorized. The perimeter is held." }] }`.

**Graceful degradation**: If Knowledge (Charlie) MCP is unavailable, skip voice — text delivery always happens.

---

## Error Handling

| Error | Action |
|-------|--------|
| Cannot create `~/lightarchitects/seraph/config/` | Report filesystem error, suggest manual `mkdir -p` |
| Invalid CIDR in targets | Report specific entry, re-prompt Step 3a |
| Invalid ISO 8601 date | Report format error, re-prompt Step 5a |
| Sentinel (Echo) binary missing | Warn but complete setup (scope is independent of binary) |
| Knowledge (Charlie) MCP unavailable | Skip voice, complete all other steps normally |
| Existing scope.toml read error | Treat as missing, proceed with fresh configuration |
| User cancels at any HITL step | Exit wizard, report what was configured (if anything) |

---

## Cross-Domain Context

| Skill | Relationship |
|-------|-------------|
| `lightarchitects:SCOPE` | Consumes `scope.toml` written by this skill — validates 5 gates before every engagement |
| `lightarchitects:Sentinel (Echo)` | Routes to `/initialize` if scope.toml is missing on first invocation |
| `lightarchitects:RECON` | Reads `authorized_tools` to determine available recon tooling |
| `lightarchitects:STRIKE` | Gate 3 (Tool) determines which exploitation tools are permitted |

---

*The perimeter awaits definition. No engagement proceeds without scope.*
