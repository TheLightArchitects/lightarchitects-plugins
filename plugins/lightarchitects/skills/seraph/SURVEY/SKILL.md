---
name: SURVEY
description: "This skill is invoked internally by Sentinel (Echo)'s engagement cycle for the
  deep scanning and traffic capture phase. Orchestrates vulnerability scanning and
  packet capture via seraphTools scan and capture actions."
user-invocable: false
context: fork
version: 2.0.0
---

# /SURVEY — Deep Scan + Traffic Capture Phase

> Engagement Phase 3/6: SURVEY — Vulnerability scanning + packet capture

## Lifecycle Context

Follows RECON → feeds into EXAMINE.

## Protocol

### Step 1: Load Reconnaissance Data

1. Load target list from RECON phase output
2. Prioritize targets by interest: unusual ports, non-standard services, web-facing assets

### Step 2: Execute Deep Vulnerability Scan

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "seraph"`, `action: "scan"`:
- Targeted vulnerability scanning on prioritized hosts
- Service-specific probes (HTTP, SSH, SMB, etc.)
- NSE script execution where authorized

### Step 3: Execute Traffic Capture

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "seraph"`, `action: "capture"`:
- Targeted packet capture on interesting interfaces/hosts (tcpdump, tshark)
- Filter by relevant protocols
- Time-bounded capture (respect `max_concurrent` limits)

### Step 4: Compile Vulnerability Assessment

Synthesize scan + capture findings:
- Identified vulnerabilities with severity ratings
- Anomalous traffic patterns
- Attack surface map for EXAMINE phase

## Quality Gates

### Pre-Execution
- [ ] RECON target list available
- [ ] Scope still valid (TTL check)
- [ ] Concurrent scan limit not exceeded

### Post-Execution
- [ ] Vulnerability scan results collected
- [ ] Packet captures saved with timestamps
- [ ] Attack surface map compiled for EXAMINE
- [ ] Evidence chain updated

## Cross-Domain Context

| Phase | Skill | Relationship |
|-------|-------|-------------|
| 2. recon | RECON | Provides target list for SURVEY |
| 4. examine | EXAMINE | Receives vulnerability findings + captures |
