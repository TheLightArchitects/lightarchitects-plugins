---
name: SCRIBE
description: "This skill is invoked internally by Analyst (Delta)'s CLOSE phase for generating
  investigation deliverables. Provides templates for RCA reports, customer responses,
  JIRA drafts, and executive summaries."
user-invocable: false
context: fork
version: 1.0.0
---

# SCRIBE -- Investigation Deliverable Templates

> Templates for generating investigation deliverables during the CLOSE phase.

## Available Templates

| Template | Format | Purpose |
|----------|--------|---------|
| `rca` | Markdown | Root Cause Analysis report |
| `customer-response` | Text | Customer-facing response |
| `jira-draft` | Markdown | JIRA ticket (internal or customer) |
| `timeline` | Markdown | Event timeline with timestamps |
| `executive-summary` | Markdown | Brief summary for leadership |

## Template Location

Templates are stored in `templates/` subdirectory. Each template is a markdown file with placeholder variables:

- `{{case_id}}` -- Investigation case identifier
- `{{product}}` -- Product name
- `{{symptom}}` -- Original symptom description
- `{{root_cause}}` -- Identified root cause
- `{{resolution}}` -- Resolution steps
- `{{confidence}}` -- Confidence percentage
- `{{timestamp}}` -- Current timestamp
- `{{evidence_summary}}` -- Summary of evidence analyzed

## Usage

The CLOSE phase (`quantumTools` action `close`) automatically selects and fills templates based on the `--format` flag:

```
quantum-q close --case CASE-001 --format rca       # RCA report only
quantum-q close --case CASE-001 --format all        # All deliverables
```

## Citation Format

All deliverables use IEEE citation format:
- Inline: `[1]`, `[2]`, `[3]`
- References section at the end with full source details
