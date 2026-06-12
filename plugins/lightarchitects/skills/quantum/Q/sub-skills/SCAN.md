---
name: SCAN
description: "This skill is invoked internally by Analyst (Delta)'s investigation cycle for
  the scene assessment phase. Auto-detects input type, classifies severity, and matches
  against pattern database via quantumTools scan action."
user-invocable: false
context: fork
version: 1.0.0
---

# SCAN -- Phase 0: Scene Assessment

> Auto-detect input type, classify severity, detect log types, match against pattern database.

## Purpose

SCAN is the triage phase. Given raw input (case number, log file path, or bundle), it detects the format, classifies the severity level, identifies log types present, and matches patterns against a known database. Output is a triage report that routes to appropriate investigation depth.

## quantumTools Action

`scan` -- maps to `quantumTools`

## Procedure

1. **Parse Input**: Identify input type (case ID, file path, URL, bundle path)
2. **Detect Format**: Analyze file headers/magic bytes (gzip, zip, tar, plain text)
3. **Extract Metadata**: Read timestamps, file sizes, encoding, line counts
4. **Detect Log Types**: Identify log format (JSON, syslog, stack trace, binary, custom)
5. **Run Pattern Matching**: Compare against known error patterns (regex database)
6. **Classify Severity**: Assign severity tier (critical, high, medium, low) based on patterns matched
7. **Assess Scope**: Determine if single-product or cross-product impact
8. **Generate Triage Report**: Output severity, log types, pattern matches, recommended investigation depth

## Inputs

- Input artifact: case number (string), file path (local), bundle (tar.gz/zip), or log snippet
- Pattern database: regex patterns for known issues, error signatures
- Severity scoring rules: heuristics for classifying issue impact

## Outputs

- Triage report (JSON/Markdown):
  - `severity`: critical|high|medium|low
  - `log_types`: array of detected formats
  - `patterns_matched`: array of matched error patterns with confidence scores
  - `scope`: single_product|cross_product|infrastructure
  - `recommended_depth`: quick_investigation|full_investigation
  - `estimated_effort`: hours
  - `confidence`: 0.0-1.0 (reliability of triage)

## HITL Checkpoint

**User decides**:
- Accept triage severity, or override if assessment seems incorrect
- Proceed to SWEEP (Phase 1), or escalate directly to Full Investigation if critical
- Request additional context or clarification on input
