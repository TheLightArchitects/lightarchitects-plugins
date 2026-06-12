---
name: EXAMINE
description: "This skill is invoked internally by Sentinel (Echo)'s engagement cycle for the
  forensic analysis phase. Orchestrates binary analysis, artifact examination, and
  deep forensics via seraphTools analyze action."
user-invocable: false
context: fork
version: 2.0.0
---

# /EXAMINE — Forensics + Binary Analysis Phase

> Engagement Phase 4/6: EXAMINE — Forensic analysis and artifact examination

## Lifecycle Context

Follows SURVEY → feeds into STRIKE.

## Protocol

### Step 1: Load Survey Findings

1. Load vulnerability assessment from SURVEY phase output
2. Identify artifacts requiring forensic examination: captured binaries, suspicious files, pcap files

### Step 2: Execute Forensic Analysis

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "seraph"`, `action: "analyze"`:
- YARA rule matching on captured files
- Binary analysis (binwalk, strings, file identification)
- Radare2 disassembly on suspicious binaries (if authorized)
- Metadata extraction (exiftool)

### Step 3: Correlate Findings

Cross-reference analyze results with SURVEY vulnerability data:
- Match YARA hits to known malware families
- Correlate packet capture anomalies with binary signatures
- Build attack surface map with confirmed entry points

### Step 4: Compile Attack Surface Assessment

Synthesize forensic findings into actionable intelligence:
- Confirmed vulnerabilities with exploitation paths
- Artifact evidence with chain of custody
- Risk assessment for STRIKE phase decision

## Quality Gates

### Pre-Execution
- [ ] SURVEY findings available
- [ ] Analysis tools available on Khadas (yara, binwalk, strings, r2)
- [ ] Scope still valid (TTL check)

### Post-Execution
- [ ] All identified artifacts analyzed
- [ ] YARA matches documented
- [ ] Attack surface map complete
- [ ] Evidence chain updated with forensic findings

## Cross-Domain Context

| Phase | Skill | Relationship |
|-------|-------|-------------|
| 3. survey | SURVEY | Provides vulnerability findings + captures |
| 5. strike | STRIKE | Receives confirmed attack surface map |
