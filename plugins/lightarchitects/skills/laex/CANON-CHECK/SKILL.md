---
name: CANON-CHECK
description: "Canon XXXIX 4-step promotion pipeline sub-skill. Loads promotion candidates
  from memory, runs systematic 7-document contradiction check, produces ratification
  verdicts (RATIFIED / CONDITIONALLY_RATIFIED / REJECTED / DEFERRED), presents the operator
  stamp gate, and on approval applies canon document edits. Invoked by /Arbiter (Golf) Canon
  ratification mode. Can be invoked directly when candidates are known."
version: 1.0.0
user-invocable: false
context: root
agent: laex
---

# CANON-CHECK — Canon XXXIX Promotion Pipeline

> *Pipeline*: (a) memory entry → (b) promotion candidate → **(c) contradiction check** → **(d) Arbiter (Golf) ratification + the operator stamp**. Steps (c) and (d) run here.

---

## Step 1: Load Candidates

**From memory file** (default):
```bash
ls ~/.claude/projects/-Users-kft-Projects/memory/project_canon_promotion_candidates_*.md \
  | sort -r | head -1
```
Read the most recent file. Extract all candidates.

**From direct input**: If the invoker passed inline candidates, use those.

**From REFLECT output**: If invoked after /REFLECT, scan for proposed CLAUDE.md additions that warrant canon promotion (structural rules, not operator-layer memories).

Clarify with `AskUserQuestion` if the source is ambiguous.

---

## Step 2: Contradiction Check (7 Canon Documents)

For **each candidate**, run targeted grep + read against all 7 canon docs:

```
$HELIX = ~/lightarchitects/soul/helix
```

| Document | Path | Grep targets |
|----------|------|-------------|
| Platform Canon | `$HELIX/user/standards/canon/platform-canon.md` | Canon number referenced in candidate, constitutional principles |
| Builders Cookbook | `$HELIX/user/standards/canon/builders-cookbook.md` | §-number from candidate, domain keywords (error/HTTP/sanitiz/handler) |
| Agents Playbook | `$HELIX/user/standards/canon/agents-playbook.md` | Agent lifecycle keywords, A2A, HITL |
| Architects Blueprint | `$HELIX/user/standards/canon/architects-blueprint.md` | Part XIV (C1-C8), candidate's target section |
| Operators Manual | `$HELIX/user/standards/canon/operators-manual.md` | Platform ops keywords from candidate |
| LASDLC Template | `$HELIX/user/standards/canon/LASDLC-TEMPLATE-v1.yaml` | Section numbers, amendment protocol |
| Security Guardrails | `$HELIX/user/standards/canon/security-guardrails.md` | Security keywords, ZERO-EXCEPTION markers |

**Protocol**:
1. For each doc, `grep -n "<keywords>"` to find relevant sections (max 3 grep queries per doc)
2. `Read` only the identified sections (use `offset`/`limit`; never full-read docs >500 lines)
3. Classify each finding:
   - `CONTRADICTION` — candidate directly conflicts with existing text
   - `DUPLICATE` — candidate restates existing content; redirect to that section
   - `PLACEMENT_ERROR` — candidate's target section is wrong (identify correct section)
   - `NO_CONFLICT` — additive; gap confirmed
4. Batch all 7 docs in parallel tool calls per candidate

**Evidence quality check** (per §59 / Canon XXXV):
- N=1 evidence → `PROVISIONALLY_VALID` (must be framed as "observed pattern, N=1")
- N≥3 evidence → `VALIDATED` (can be stated as established rule)
- No primary source → `INSUFFICIENT_EVIDENCE` → route to DEFERRED

---

## Step 3: Verdict Block

For each candidate, emit the structured verdict:

```yaml
candidate_id: <N>
title: "<candidate title>"
evidence_summary: "<source build/session, date>"
proposed_for: "canon://<document>#<section>"
contradiction_check:
  checked_at: "<ISO-8601>"
  docs_checked: 7
  findings:
    - doc: "<Platform Canon | Builders Cookbook | ...>"
      section: "<§ref or Part>"
      type: CONTRADICTION | DUPLICATE | PLACEMENT_ERROR | NO_CONFLICT
      note: "<specific finding detail>"
evidence_quality: VALIDATED | PROVISIONALLY_VALID | INSUFFICIENT_EVIDENCE
verdict: RATIFIED | CONDITIONALLY_RATIFIED | REJECTED | DEFERRED
conditions: "<if CONDITIONALLY_RATIFIED: required framing changes>"
placement_correction: "<if PLACEMENT_ERROR: corrected target section>"
proposed_text: |
  <exact text to insert, with any condition-mandated framing applied>
```

**Verdict decision rules**:
| Condition | Verdict |
|-----------|---------|
| NO_CONFLICT all 7, evidence VALIDATED, placement correct | RATIFIED |
| NO_CONFLICT all 7, evidence PROVISIONALLY_VALID (N=1) | CONDITIONALLY_RATIFIED (provisional framing required) |
| NO_CONFLICT all 7, PLACEMENT_ERROR corrected | CONDITIONALLY_RATIFIED (confirm new section) |
| DUPLICATE with existing canon | REJECTED (cite existing §ref) |
| CONTRADICTION with existing canon | REJECTED (cite conflicting clause) |
| INSUFFICIENT_EVIDENCE | DEFERRED (specify what evidence is needed) |

---

## Step 4: Present to the operator (Stamp Gate — MANDATORY HITL)

Present the full verdict block in a structured report:

```
## Arbiter (Golf) Ratification Report
Date: <ISO>

### Candidates Checked: <N>

| # | Title | Proposed for | Evidence | Verdict |
|---|-------|-------------|---------|---------|
| 1 | ... | ... | N=? | RATIFIED / CONDITIONALLY_RATIFIED / ... |

### Detailed Verdicts
[per-candidate verdict blocks]
```

Then gate:

```
AskUserQuestion:
  question: "Arbiter (Golf) ratification complete. Which candidates do you approve for canon promotion?"
  header: "Canon stamp"
  multiSelect: true
  options:
    - label: "<Candidate N title> (RATIFIED)"
      description: "<one-line summary of proposed addition>"
    [... one per RATIFIED or CONDITIONALLY_RATIFIED candidate ...]
    - label: "None — return all for rework"
      description: "No canon edits this session. Candidates stay in promotion queue."
```

---

## Step 5: Apply Canon Edits (On the operator Stamp)

For each the operator-approved candidate:

1. **Read** the target section in the canon document (use the corrected placement if CONDITIONALLY_RATIFIED)
2. **Draft** the exact insertion/replacement text (apply any CONDITIONALLY_RATIFIED framing conditions)
3. **Preview** via `AskUserQuestion` with the before/after diff:
   ```
   question: "Apply this edit to <document>#<section>?"
   header: "Edit confirm"
   options:
     - label: "Apply" / description: "[preview of the exact change]"
     - label: "Skip this candidate"
   ```
4. **Apply** via `Edit` tool on confirmation
5. **Log** the promotion to Knowledge (Charlie) vault:
   ```
   mcp__plugin_lightarchitects_lightarchitects__tools
   sibling: "soul"
   action: "write_note"
   path: "helix/laex0/entries/{date}-canon-promotion-{slug}.md"
   ```
   Entry includes: candidate text, verdict, approval date, the operator's stamp, canon doc + section, final text applied.

**NEVER auto-apply.** the operator's stamp is authorization to present the edit. Confirmation is the apply trigger. Two gates, both HITL.

---

## Graceful Degradation

If a canon document is unavailable for checking:
- Log: `"[CANON-CHECK] {doc} unavailable — skipping contradiction check for this doc. Manual review required before promotion."`
- Mark the affected candidate as `DEFERRED` (cannot fully verify with incomplete check)
- Never ratify a candidate with a doc-check gap unless the operator explicitly overrides

If Knowledge (Charlie) vault is unavailable for logging (Step 5):
- Apply the edit (canon promotion is the primary deliverable)
- Log a warning: `"Knowledge (Charlie) vault unavailable — promotion not logged. Record manually at helix/laex0/entries/."`
