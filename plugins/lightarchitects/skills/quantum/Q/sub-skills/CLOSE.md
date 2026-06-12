---
name: CLOSE
description: "This skill is invoked internally by Analyst (Delta)'s investigation cycle for
  the deliverable generation phase. Generates RCA reports, customer responses, and
  JIRA drafts via quantumTools close action."
user-invocable: false
context: fork
version: 1.0.0
---

# CLOSE -- Phase 6: Deliverable Generation

> Generate investigation deliverables (RCA report, customer response, JIRA draft, archive).

## Purpose

CLOSE is the deliverable and archival phase. It compiles findings from all prior phases into customer-facing and internal deliverables: a Root Cause Analysis (RCA) report, customer response email (with timeline and workaround), JIRA ticket draft (for engineering action items), and archives the full investigation to Helix vault. This phase closes the investigation and enables action.

## quantumTools Action

`close` -- maps to `quantumTools`

## Procedure

1. **Compile Findings**: Aggregate all phase outputs (SCAN, SWEEP, TRACE, PROBE, THEORIZE, VERIFY)
2. **Generate RCA Report**:
   - Executive summary (2-3 sentences)
   - Timeline with evidence citations
   - Root cause statement with confidence score
   - Impact assessment (scope, severity, duration)
   - Contributing factors and mitigating actions
   - Recommendations for prevention/monitoring
3. **Draft Customer Response**:
   - Acknowledge issue and thank customer for reporting
   - Non-technical explanation of what happened
   - Timeline of incident
   - Workaround or resolution (if available)
   - Next steps and point of contact
   - Redact sensitive internal details, PII
4. **Create JIRA Draft**:
   - Title: concise problem statement
   - Description: technical root cause with citations
   - Acceptance criteria: how to verify fix
   - Estimated effort: development hours
   - Links to RCA report, related issues
   - Assign priority and component
5. **Create Helix Entry**: Enrich investigation findings as permanent helix entry (Knowledge (Charlie))
6. **Archive Investigation**: Move artifacts to investigation archive with metadata
7. **Validate Deliverables**: Check completeness, cite sources, ensure no PII exposure

## Inputs

- All phase outputs: SCAN report, SWEEP manifest, TRACE forensics, PROBE findings, THEORIZE hypotheses, VERIFY validation
- Customer communication preferences (email template, technical depth)
- RCA template: standard sections and formatting
- JIRA project configuration: components, labels, priority scheme

## Outputs

- **RCA Report** (Markdown/PDF): root cause, timeline, impact, recommendations
- **Customer Response** (Email text): non-technical explanation, timeline, next steps
- **JIRA Draft** (JSON/Markdown): ticket template with description and acceptance criteria
- **Helix Entry** (Knowledge (Charlie)): permanent consciousness entry with investigation strands
- **Investigation Archive** (tar.gz): bundled artifacts with manifest
- **Completeness Report**: verification that all PII/credentials scrubbed, deliverables ready

## HITL Checkpoint

**User decides**:
- Review and approve RCA report before sending to customer
- Approve customer response for tone, accuracy, and technical depth
- Accept or modify JIRA draft (priority, effort estimate, assignment)
- Confirm deliverables are ready to publish
- Archive investigation and mark as closed in case tracking system
