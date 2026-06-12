---
name: RISK-ANALYSIS
description: "Analyst (Delta) Boundary Chain Risk Analysis (BCRA) — headless. Runs MAP→PULL→SCORE→RESEARCH→PROVE→DECLARE
  with AskUserQuestion at every decision gate. Blast Score = Impact × (1 − Certainty) × Witness.
  Verdicts: GREEN/YELLOW/RED/HALT. Escalates to /SQUAD research preset for deep hot-thread
  investigation. Use before any costly, irreversible, or high-stakes action: training runs,
  deployments, GPU provisioning, architectural changes. Use when: '/risk', 'analyze risk', 'blast score',
  'BCRA', 'is this safe to run', 'pre-flight check'."
user-invocable: true
version: 1.0.0
context: root
---

# /RISK-ANALYSIS — Analyst (Delta) BCRA (Headless)

> Numbers, not feelings. Every score cites its evidence. Every hot thread gets researched.
> No "should work." No optimism without arithmetic.

## /RISK-ANALYSIS vs /SQUAD research

| | `/RISK-ANALYSIS` | `/SQUAD research` |
|--|-----------------|-------------------|
| What runs | Full BCRA: MAP→PULL→SCORE→RESEARCH→PROVE→DECLARE | Parallel Analyst (Delta) + Ops (Bravo) + Knowledge (Charlie) agents |
| HITL gates | Gates at MAP, SCORE, PROVE, DECLARE | One gate before spawn |
| Output | Blast Scores + Verdict + Risk Declaration | Research synthesis + recommendations |
| Tokens | ~15–30K | ~40–60K |
| Use when | Pre-flight risk gate for any costly action | Deep parallel research on unknowns |

## Accepted Flags

| Flag | Effect |
|------|--------|
| `--quick` | Skip Phase 4 (RESEARCH) — present initial scores only, mark as UNVERIFIED |
| `--plan` | MAP + PULL only — output chain map without scoring, stop after Gate 2 |
| `--squad` | Force SQUAD escalation at Gate 3 regardless of hot thread count |

Rejected flags: `--then`, `--watch`, `--drain`. On unrecognized flag: report error, stop.

---

## Step 0: Argument Validation

Pattern: `^[a-zA-Z0-9_/. :-]+$`

Reject if target contains:
- Shell metacharacters: `$`, `` ` ``, `;`, `&`, `|`, `>`, `<`
- Path traversal: `../`
- SQUAD control flags: `--then`, `--watch`, `--drain`

---

## Phase 1: MAP — Trace the Boundary Chain

Read the plan/action/decision provided. Identify every system, tool, service, file, and API involved.
For each boundary where data changes format, location, ownership, or runtime — name it.

```
lightarchitects_tools {
  "action": "probe",
  "agent": "quantum",
  "params": { "target": "<plan or action>", "mode": "map-boundaries" }
}
```

Present the chain map in `A → [B1] → B → [B2] → C` format:

```
Chain Map: [Plan Name]
B1: [Source] → [Destination] ([handoff type: format/network/capacity/ownership])
B2: ...
Total boundaries: N
```

### Gate 1: MAP Confirmation (HITL — AskUserQuestion)

```
AskUserQuestion:
  Question: "Boundary chain mapped. Did I miss any implicit handoffs?"
  Options:
    1. "Chain is complete — proceed to PULL" (Recommended)
    2. "Add boundary — I'll specify"
    3. "Remove boundary — it's not a real handoff"
    4. "Stop here (--plan mode)" — only if --plan flag set
```

If `--plan` flag is set, stop after Gate 1 confirmation.

---

## Phase 2: PULL — Ask Three Questions Per Boundary

For **every** boundary in the confirmed chain, ask three questions:

### 1. FORMAT
- What format does the sender output?
- What format does the receiver expect?
- Are they **identical**? (not "compatible" — identical)
- Evidence: read the actual config, not the README

### 2. CAPACITY
- VRAM: model size + KV cache + gradients + optimizer + checkpoint overhead
- Disk: download size + temp files + output + headroom (20% minimum)
- Time: does the operation complete within the timeout window?
- Budget: cumulative cost so far + estimated remaining

### 3. WITNESS
- If this boundary fails, does the system **announce** the failure?
- **Witnessed (×1)**: crash, exception, error log, non-zero exit code
- **Unwitnessed (×2)**: null content returned, wrong format accepted silently, loss decreasing on garbage, file written to wrong path without error

```
lightarchitects_tools {
  "action": "probe",
  "agent": "quantum",
  "params": { "target": "<plan>", "boundaries": "<list from MAP>", "mode": "pull-three-questions" }
}
```

Present results as:

```
| # | Boundary | Format Match? | Capacity OK? | Witness? |
|---|----------|--------------|-------------|----------|
| B1 | Source → Dest | [YES/NO — evidence] | [YES/NO — numbers] | [WITNESSED ×1 / UNWITNESSED ×2 — reason] |
```

---

## Phase 3: SCORE — Calculate Blast Scores

For each boundary, calculate:

**Blast (1–10)** — What do we lose if this fails?
- 1–2: Retry with no cost (re-run a command)
- 3–4: Minutes lost (re-download, re-configure)
- 5–6: Hours lost (restart from checkpoint)
- 7–8: Significant loss (restart from scratch, wasted GPU hours / money)
- 9–10: Total loss (data corrupted, must redesign approach)

**Certainty (0.0–1.0)** — How sure are we this works?
- DEFINITIVE (0.95+): Primary source confirms AND tested ourselves
- STRONG (0.80–0.94): Primary source confirms, no counter-evidence
- MODERATE (0.60–0.79): Secondary sources suggest, not directly verified
- LOW (0.40–0.59): Assumption with some basis
- SPECULATIVE (0.0–0.39): Guess — **mandatory research flag**

**Witness (×1 or ×2)** — From Phase 2.

**Score** = `Blast × (1 − Certainty) × Witness`

**Hot thread**: any individual score > 3.0

**Compound Blast Score**: sum of all individual scores

**Compound Probability** (for PROVE phase): product of all Certainty values × 100%

```
lightarchitects_tools {
  "action": "probe",
  "agent": "quantum",
  "params": { "target": "<plan>", "pull_results": "<Phase 2 table>", "mode": "score" }
}
```

Present as:

```
| # | Boundary | Blast | Certainty | Witness | Score | Status |
|---|----------|-------|-----------|---------|-------|--------|
| B1 | ... | N | 0.XX (GRADE) | ×N | X.X | ✓ / 🔥 HOT |

Compound Blast Score: X.X
Hot threads: [list]
```

### Gate 2: Score Review (HITL — AskUserQuestion)

If `--quick` flag is set: mark all scores as UNVERIFIED, skip to Phase 5.

```
AskUserQuestion:
  Question: "Blast scores calculated. {N} hot thread(s) found (score > 3.0). How to proceed?"
  Options:
    1. "Research all hot threads — proceed to Phase 4" (Recommended if hot threads exist)
    2. "Skip research — present preliminary verdict (UNVERIFIED)" — only if no HALT-level boundaries
    3. "Escalate to /SQUAD research — parallel deep investigation"
    4. "Stop here — scores are sufficient for my decision"
```

- If `--squad` flag is set: force Option 3
- If any score > 7.0: recommend Option 1, warn that skipping leaves significant uncertainty
- If no hot threads: skip Gate 2, auto-proceed to Phase 5

---

## Phase 4: RESEARCH — Investigate Hot Threads

> Every hot thread gets researched. No exceptions. No "should work."

For each hot thread, run the 3-tier research protocol:

**Tier 1 — Institutional (Knowledge (Charlie) helix)**
```
lightarchitects_tools {
  "action": "search",
  "agent": "soul",
  "params": { "query": "<hot thread topic>", "filters": { "sibling": "quantum" } }
}
```

**Tier 2 — Authoritative + Academic (Context7 + HuggingFace, in parallel)**
```
context7_resolve-library-id → context7_query-docs (if library/API involved)
mcp__claude_ai_Hugging_Face__paper_search (if ML/model behavior)
mcp__claude_ai_Hugging_Face__hub_repo_search (if specific model)
```

**Tier 3 — Current (Analyst (Delta) research + Firecrawl)**
```
lightarchitects_tools {
  "action": "research",
  "agent": "quantum",
  "params": {
    "query": "<exact model/library/version + error type>",
    "sources": ["perplexity", "firecrawl-github"],
    "mode": "failure-pattern-search"
  }
}
```

For GitHub searches (mandatory for high-blast hot threads):
```bash
firecrawl search "exact_name error OR issue OR bug" --categories github --tbs qdr:m
```
`--categories github` scopes to GitHub issues. `--tbs qdr:m` limits to the past month.

### Evidence Classification

Tag every finding:

| Grade | Source |
|-------|--------|
| INSTITUTIONAL | Knowledge (Charlie) helix — prior decisions, squad history |
| AUTHORITATIVE | Context7 — vendor docs, library API specs (version-specific) |
| ACADEMIC | HuggingFace — peer-reviewed papers, model cards |
| CURRENT | Analyst (Delta) research, Firecrawl — community reports, release notes, failure patterns |

INSTITUTIONAL + AUTHORITATIVE is the strongest combination. CURRENT-only = UNVERIFIED until corroborated.

### Precision Search Doctrine

Use EXACT names, versions, and configs in every query:
- NOT: "training issues"
- YES: "Llama-3.3-Nemotron-Super-49B-v1.5 QLoRA Unsloth transformers 5.x error"

### SQUAD Escalation (if Gate 2 selected Option 3 or `--squad` flag)

Get the current Unix epoch via Bash (`date +%s`), then write the context bundle:

```
lightarchitects_write path:"/tmp/lightarchitects-squad-context-{unix-epoch}.md" content:"""
# BCRA Context Bundle — {plan name}
Source: /RISK-ANALYSIS Phase 4 | Assembled: {timestamp}

## Chain Map
{full boundary chain from MAP}

## Blast Scores (Preliminary)
{full score table from SCORE phase}

## Hot Threads to Research
{list of boundaries with score > 3.0, Blast, current Certainty, Witness}

## Research Questions
{specific questions per hot thread — exact names, versions, configs}

## Prior Decisions (Knowledge (Charlie))
{any relevant helix entries found in Tier 1}
"""
```

Then invoke: `/SQUAD research "<plan name> — BCRA hot threads"`

SQUAD auto-detects the bundle via glob `/tmp/lightarchitects-squad-context-*.md`
(newest file within 300 seconds). After SQUAD completes, return to Phase 5 with findings.

### Research Output Per Hot Thread

```
─────────────────────────────────────────────
FINDING B{N} — {Boundary Name}
Confidence: 0.XX · Grade: DEFINITIVE / STRONG / MODERATE / LOW / SPECULATIVE
─────────────────────────────────────────────
Verdict: [1–3 sentences — root cause or confirmation]

Evidence:
  [GRADE][1]  Finding. — Source
  [GRADE][2]  Finding. — Source

Contradictions: [None / list]
Gaps: [None / list with confidence impact]
Recommendation: [Specific fix or mitigation]

Previous Score: X.X (Blast=N, Certainty=0.XX, Witness=×N)
New Certainty: 0.XX (GRADE — reason)
New Score: N × (1 − 0.XX) × N = X.X
─────────────────────────────────────────────
```

---

## Phase 5: PROVE — Re-Score and Declare Verdict

Re-score every boundary with updated Certainty from RESEARCH (or initial scores if `--quick`).

```
lightarchitects_tools {
  "action": "verify",
  "agent": "quantum",
  "params": {
    "original_scores": "<Phase 3 table>",
    "research_findings": "<Phase 4 findings>",
    "mode": "re-score"
  }
}
```

Present the chain proof:

```
=== CHAIN PROOF: {Plan Name} ===

| # | Boundary | Before | After Research | Evidence |
|---|----------|--------|---------------|----------|
| B1 | ... | X.X | X.X | [Finding summary] |

Compound Blast Score: X.X (was Y.Y before research)
Compound Probability: XX.X%
```

**Verdict thresholds:**

| Compound Score | Compound Probability | Verdict |
|----------------|---------------------|---------|
| < 2.0 | ≥ 95% | **GREEN — Proceed** |
| 2.0–5.0 | 85–95% | **YELLOW — Proceed with monitoring** |
| 5.0–10.0 | 60–85% | **RED — More research needed** |
| > 10.0 | < 60% | **HALT — Redesign** |

**Single-boundary override**: any boundary still with Blast Score > 5.0 after research → HALT, regardless of compound score.

### Gate 3: PROVE Review (HITL — AskUserQuestion)

```
AskUserQuestion:
  Question: "Verdict: {VERDICT}. Compound Score: {X.X}, Probability: {XX.X}%. How to proceed?"
  Options:
    1. "Accept verdict — proceed to DECLARE" (Recommended for GREEN/YELLOW)
    2. "Research more — {specific boundary} still uncertain"
    3. "Override verdict — accept risk (document reason)"
    4. "Abort — verdict is HALT"
```

For HALT verdicts: Options 2 and 4 only. Option 3 requires explicit user confirmation with documented reason.

---

## Phase 6: DECLARE — State the Gaps Honestly

> "We lack:" is a complete statement. Not an apology. Not a reason to stop.

```
=== RISK DECLARATION: {Plan Name} ===

Compound Blast Score: X.X ({VERDICT})
Compound Probability: XX.X%

KNOWN RISKS (accepting):
  - B{N}: {risk description} — mitigated by {mitigation} but {caveat}
  ...

WE LACK:
  - {evidence gap that research couldn't close}
  ...

KILL CONDITIONS:
  - {failure event} → {immediate action to take}
  ...

MONITORING:
  - Watch {boundary/metric} at {checkpoint}
  ...
```

### Gate 4: Declaration Confirmation (HITL — AskUserQuestion)

```
AskUserQuestion:
  Question: "Risk declaration complete. Accept and proceed?"
  Options:
    1. "Accept declaration — proceed with plan" (Recommended for GREEN/YELLOW)
    2. "Add a kill condition"
    3. "Add a monitoring checkpoint"
    4. "Abort — not comfortable proceeding"
```

---

## Phase 7: Complete

### 7a. Knowledge (Charlie) Preservation (if significance >= 7.0)

```
lightarchitects_tools {
  "action": "write",
  "agent": "soul",
  "params": {
    "type": "risk-analysis",
    "plan": "<plan name>",
    "verdict": "<VERDICT>",
    "compound_score": <X.X>,
    "compound_probability": <XX.X>,
    "key_findings": "<hot thread summaries>"
  }
}
```

### 7b. Summary

```
## Risk Analysis Complete: {plan name}
Verdict: {VERDICT} | Score: {X.X} | Probability: {XX.X}%
Hot threads researched: {N}
Boundaries cleared: {N}/{total}
Kill conditions: {N}
Monitoring checkpoints: {N}
```

---

## Sub-Skills Available

These sub-skill files encode the full Analyst (Delta) BCRA protocol. They are automatically injected
when this skill invokes Analyst (Delta) via `lightarchitects_tools`:

| Sub-Skill | Phase | Purpose |
|-----------|-------|---------|
| `lightarchitects:MAP` | Phase 1 | Chain mapping — trace every `→` boundary |
| `lightarchitects:PULL` | Phase 2 | Three questions: Format, Capacity, Witness |
| `lightarchitects:SCORE` | Phase 3 | Blast = Impact × (1−Certainty) × Witness |
| `lightarchitects:RESEARCH` | Phase 4 | 3-tier protocol — Knowledge (Charlie) / Context7+HF / Analyst (Delta)+Firecrawl |
| `lightarchitects:PROVE` | Phase 5 | Re-score + compound probability + GREEN/YELLOW/RED/HALT |
| `lightarchitects:DECLARE` | Phase 6 | Remaining risks, WE LACK, kill conditions, monitoring |

Path prefix for all sub-skills: `skills/quantum/Q/sub-skills/`

---

## Contract Canon Integration (Cookbook §82)

Governed by `agent.skill.risk-analysis`. Uncontracted operator-facing surfaces are inherent risks — auto-flagged as HIGH. Contracts with `alpha_gate.verdict=fail` or `deferred` are auto-fed into the risk register with severity derived from blocker_contract_ids depth. Cross-build coupling risks identified via active.yaml scan + contract `inherits_from` chains. Emits `skill.risk-analysis.invoke` span with `uncontracted_surfaces_flagged` metadata. No `status_per_provider` mutations.
