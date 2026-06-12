---
name: EFFECTIVENESS-SCORE
description: "Post-ship LASDLC build effectiveness scoring. Measures a completed build
  against the 5 shipped conditions (on-time delivery, gate pass rate, coverage, canon
  compliance, Northstar delta). Produces an aggregate effectiveness score with band
  classification and identifies learning candidates for the canon promotion pipeline.
  Invoked by /Arbiter (Golf) after a build completes."
version: 1.0.0
user-invocable: false
context: root
agent: laex
---

# EFFECTIVENESS-SCORE — Post-Ship Build Effectiveness

> Ships are measured at the dock, not the drawing board. EFFECTIVENESS-SCORE is Arbiter (Golf) reading the tape.

---

## Input

Required from invoker:
- **Build codename** or path to plan file (`~/.claude/plans/<codename>.md` or helix build entry)
- **Ship date** (when the build was deployed / merged to main)

If not provided, list recent builds from `$HELIX/corso/builds/active.yaml` and ask via `AskUserQuestion`.

---

## Step 1: Load Build Data

1. Read plan file for: estimated wall-clock, tier, phase set, exit criteria per phase
2. Read Knowledge (Charlie) helix for build entry: `helix/corso/entries/{date}-*-{codename}*.md`
3. Read Monitor (Foxtrot) traces (if available): `curl http://127.0.0.1:3742/api/sessions` → find sessions matching build date range

---

## Step 2: Score 5 Conditions

Evaluate each of the 5 LASDLC shipped conditions. Scores are 0–100.

### Condition 1: On-Time Delivery (20% weight)
- Compare actual elapsed time (from build helix entry) vs planned wall-clock estimate
- ±15% → 100 | ±30% → 75 | ±50% → 50 | >50% over → 25 | No data → N/A

### Condition 2: Gate Pass Rate (25% weight)
- Count [ASQCOPTDR] gates that passed on first attempt vs total gates
- 100% first-pass → 100 | 90–99% → 85 | 80–89% → 70 | <80% → proportional
- Source: plan's gate section + Monitor (Foxtrot) traces (if available)

### Condition 3: Test Coverage (20% weight)
- ≥90% → 100 | 85–89% → 80 | 80–84% → 60 | <80% → proportional
- Source: Phase [T] gate results in plan or build helix entry

### Condition 4: Canon Compliance (20% weight)
- Zero CANON_VIOLATION findings post-ship → 100
- Each WARNING finding: −5 | Each BLOCKING finding: −20
- Source: post-ship SCRUM or /REFLECT findings; Monitor (Foxtrot) trace anomalies

### Condition 5: Northstar Delta (15% weight)
- `northstar_metric_delta_estimate` from plan → compare to measured post-ship delta
- Full delta achieved → 100 | Partial (≥50%) → 70 | Minimal (<50%) → 40 | Not measured → N/A

---

## Step 3: Aggregate + Band

```
aggregate = 0.20·C1 + 0.25·C2 + 0.20·C3 + 0.20·C4 + 0.15·C5
```

N/A dimensions: reweight proportionally (exclude from denominator).

| Band | Range |
|------|-------|
| EXEMPLARY | ≥90 |
| STRONG | 75–89 |
| ACCEPTABLE | 60–74 |
| DEFICIENT | 45–59 |
| UNSAFE | <45 |

---

## Step 4: Output

```yaml
build: <codename>
ship_date: <date>
scored_at: <ISO>
effectiveness_score:
  C1_on_time: { score: N, data: "<actual vs planned>" }
  C2_gate_pass_rate: { score: N, data: "<N/M first-pass>" }
  C3_coverage: { score: N, data: "<% coverage>" }
  C4_canon_compliance: { score: N, data: "<violations found>" }
  C5_northstar_delta: { score: N, data: "<delta estimate vs measured>" }
  aggregate: { low: N, point: N, high: N }
  band: EXEMPLARY | STRONG | ACCEPTABLE | DEFICIENT | UNSAFE
learning_candidates:
  - { condition: "C<N>", finding: "<what went wrong>", promotion_worthy: true|false }
```

Present to the operator. If `band: DEFICIENT | UNSAFE`, escalate with `AskUserQuestion`:
```
Question: "Build scored {band}. What next?"
Header: "Low score"
options:
  - "Canon promotion (convert findings to candidates)" — route to CANON-CHECK
  - "SCRUM retrospective" — run /SCRUM on the build
  - "Log only" — write to helix, no further action
```

---

## Step 5: Log to Helix

`mcp__plugin_lightarchitects_lightarchitects__tools` · `sibling: "soul"` · `action: "write_note"`

Path: `helix/laex0/entries/{ship_date}-effectiveness-{codename}.md`

Significance: aggregate/10 (score of 85 → significance 8.5).

If `learning_candidates` contains `promotion_worthy: true` items, create a draft memory file at:
`~/.claude/projects/-Users-kft-Projects/memory/project_canon_promotion_candidates_{today}.md`

following the Canon XXXIX memory file format.
