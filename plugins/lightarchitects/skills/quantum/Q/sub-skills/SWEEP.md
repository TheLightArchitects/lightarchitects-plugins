---
name: SWEEP
description: "This skill is invoked internally by Analyst (Delta)'s investigation cycle for
  the evidence collection phase. Extracts bundles, parses log files, and builds evidence
  manifest via quantumTools sweep action."
user-invocable: false
context: fork
version: 1.0.0
---

# SWEEP -- Phase 1: Evidence Collection

> Extract bundles, parse log files, build evidence manifest with environment detection.

## Purpose

SWEEP is the evidence collection phase. It extracts archives (tar.gz, zip), catalogs all files, parses log content, detects environment info (OS, application versions, timestamps), and builds a structured evidence manifest. This manifest becomes the foundation for all subsequent analysis phases.

## quantumTools Action

`sweep` -- maps to `quantumTools`

## Procedure

1. **Extract Archives**: Decompress bundles (tar.gz, zip, rar) to temp directory, verify integrity
2. **Catalog Files**: List all files, sizes, timestamps, permissions, relationships
3. **Parse Log Headers**: Extract metadata from first N lines (version, environment, date range)
4. **Detect Environment Info**: Extract OS, application version, configuration details, system metadata
5. **Build Event Timeline**: Parse timestamps across all logs, sort chronologically
6. **Detect Correlations**: Flag files that reference each other or share timestamps
7. **Create Evidence Manifest**: Structured index of all evidence with metadata
8. **Validate Completeness**: Check for missing or truncated files, note data gaps

## Inputs

- Raw artifact: file path or bundle location
- Extraction rules: known archive formats, compression methods
- Log parsing schemas: templates for different log types
- Environment detection patterns: regex for version strings, config keys

## Outputs

- Evidence manifest (JSON):
  - `files`: array of cataloged files with size, timestamp, hash
  - `environment`: detected OS, app versions, configuration
  - `timeline`: chronological range (earliest, latest timestamp)
  - `data_quality`: completeness percentage, truncation flags, data gaps
  - `log_types_found`: detailed list with line counts
  - `extractable_facts`: high-confidence facts extracted (versions, hostnames, etc.)

## HITL Checkpoint

**User decides**:
- Accept evidence catalog, or request re-extraction if data seems incomplete
- Flag any data that should be redacted or anonymized (PII, credentials)
- Confirm readiness to proceed to TRACE (Phase 2)
