---
name: MATRIX-RATIFY
description: "LDB (Arbiter (Golf) Decision Board) weighted multi-dimension ratification. Use when
  a proposed canon change touches ≥2 canon documents simultaneously, when the operator is
  undecided between two architecturally valid approaches, or when a decision must set
  binding precedent across multiple domains. Produces a weighted matrix verdict + Arbiter (Golf)
  synthesis + the operator tiebreaker gate."
version: 1.0.0
user-invocable: false
context: root
agent: laex
---

# MATRIX-RATIFY — LDB Weighted Multi-Dimension Vote

> Use when a single perspective isn't enough. The matrix is how Arbiter (Golf) avoids the illusion of consensus.

---

## When to Use

- Proposed canon change touches ≥2 canon documents
- Two approaches are architecturally valid — need weighted evidence to decide
- A decision will set precedent that binds future squad behavior
- SCRUM produced a 2-vs-2 split that needs constitutional tiebreaker analysis

**Not for**: Single-dimension technical decisions (use CANON-CHECK). Quick operational calls (use direct the operator judgment). Retrospectives (use /REFLECT).

---

## Step 1: Frame the Decision

Collect from the invoker:
- **Decision question**: one clear question (e.g., "Should HTTP error codes be in the handler layer or the error type definition?")
- **Options**: 2–3 concrete alternatives (A, B, C)
- **Affected canon domains**: which documents / dimensions this touches

If not provided, use `AskUserQuestion`:
```
Question: "What is the decision to ratify?"
Header: "Decision"
options: ["Describe the decision and options (via Other)"]
```

---

## Step 2: Dimension Matrix

Evaluate each option across 5 dimensions. For each dimension, invoke the owning sibling's perspective:

| Dimension | Weight | Owning Sibling | Query method |
|-----------|--------|---------------|--------------|
| [A] Architecture | 25% | CORSO (engineer) | `mcp__plugin_lightarchitects_lightarchitects__tools` · `sibling: "corso"` · `action: "sniff"` |
| [S] Security | 25% | SERAPH | `mcp__plugin_lightarchitects_lightarchitects__tools` · `sibling: "corso"` · `action: "guard"` |
| [Q] Canon quality | 20% | Arbiter (Golf) own analysis | Apply Layer 3 product lens + cite canon |
| [P] Performance/Ops | 15% | EVA | `mcp__plugin_lightarchitects_lightarchitects__tools` · `sibling: "eva"` · `action: "lint"` |
| [R] Research/Evidence | 15% | QUANTUM | `mcp__plugin_lightarchitects_lightarchitects__tools` · `sibling: "quantum"` · `action: "research"` |

**Dispatch all in parallel** (single message, multiple tool calls).

Each sibling returns a score (0–100) per option + brief rationale.

---

## Step 3: Weighted Verdict

Compute weighted aggregate per option:

```
score(option) = 0.25·A + 0.25·S + 0.20·Q + 0.15·P + 0.15·R
```

Present the matrix:

```
## Decision Matrix: {Decision Question}
Date: {ISO}

| Dimension | Weight | Option A | Option B | Option C |
|-----------|--------|---------|---------|---------|
| [A] Architecture | 25% | {score} | {score} | {score} |
| [S] Security | 25% | {score} | {score} | {score} |
| [Q] Canon quality | 20% | {score} | {score} | {score} |
| [P] Performance/Ops | 15% | {score} | {score} | {score} |
| [R] Research/Evidence | 15% | {score} | {score} | {score} |
| **Weighted total** | 100% | **{total}** | **{total}** | **{total}** |

**Arbiter (Golf) recommendation**: Option {X} — {rationale in 2 sentences, Israeli voice, KJV authority}

**Confidence**: {low/point/high} per Canon XXXIV interval discipline
```

---

## Step 4: the operator Tiebreaker Gate

```
AskUserQuestion:
  question: "LDB matrix complete. Which option do you ratify?"
  header: "LDB vote"
  options:
    - label: "Option A (Score: {total})" / description: "{A rationale}"
    - label: "Option B (Score: {total})" / description: "{B rationale}"
    - label: "Option C (Score: {total})" / description: "{C rationale, if exists}"
    - label: "None — send back for more research" / description: "Request Analyst (Delta) to deepen evidence on the dimension with highest variance"
```

the operator's selection is the ratified decision. Log the decision to `helix/laex0/entries/{date}-ldb-decision-{slug}.md`.

---

## Step 5: Canon Amendment (if applicable)

If the ratified option requires a canon document edit:
- Route to `lightarchitects:CANON-CHECK` with the ratified option as the promotion candidate
- CANON-CHECK handles the edit authorization (the operator stamp + confirmation + apply)
