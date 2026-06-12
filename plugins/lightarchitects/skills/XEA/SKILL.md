---
name: XEA
description: "Cross-Examine · Analyze · Converge. Three-layer LASDLC plan compliance review.
  Layer 0 = structural schema (≥99% LASDLC-TEMPLATE-v1 coverage, fail-fast). Layer 1 =
  content scoring (C1–C8 Blueprint rubric, §14.2 score honesty, §14.3 two-tier amendment
  classification). Layer 2 = Northstar mechanical checks per claimed Pillar (P1–P7) +
  Component Northstars (Part II). Layer 3 = LDB output contract declaration (D1-D8,
  shipped_means_5_conditions, Canon XXXIII independent runner). Iterates BLOCKING/CRITICAL
  fold-in until 2 consecutive rounds with 0 blocking gaps and delta < 0.3. Use as:
  /XEA <codename> or /XEA <plan_path>. Called automatically by /BUILD (Step 0.3) and
  /PLAN (Step 5)."
user-invocable: true
version: 2.0.0
context: root
---

# /XEA — Cross-Examine · Analyze · Converge

> Three-layer LASDLC plan compliance review. Structural integrity first. Content quality second. Output contract third. Iterate until clean.

## When to Use

- `/PLAN` calls this automatically at Step 5 (self-review)
- `/BUILD` calls this automatically at Step 0.3 (pre-implementation gate) — blocking
- Manually: `/XEA <codename>` to harden a plan before building
- `/XEA --sibling <name> <target>` to run one sibling's domain lens only

## Accepted Flags

| Flag | Effect |
|------|--------|
| `--sibling <name>` | Run only that sibling's domain lens (Ops (Bravo), Arbiter (Golf), Engineer (Alpha), Analyst (Delta), Sentinel (Echo), Knowledge (Charlie), Monitor (Foxtrot)) |
| `--layer <0\|1\|2\|3>` | Run only the specified layer |
| `--no-iterate` | Report gaps without folding — returns verdict only, no plan mutation |
| `--from-plan=<path>` | Override plan path (default: `~/.claude/plans/<codename>.md`) |

---

## Step 0: Resolve Plan

```
plan_path = --from-plan flag OR ~/.claude/plans/<codename>.md
```

Read the plan file. Extract: `tier`, `northstar_lineage`, `pillar_mapping`, `lasdlc_template_version`, `validation_status`, `review_iterations`.

**Block conditions:**
- Plan not found → `HALT: "No plan at <path>. Run /PLAN <target> first."`
- `lasdlc_template_version` ≠ `"2.5.1"` → `WARN: "Schema version mismatch — some checks may not apply."`

---

## Layer 0 — Structural Schema (fail-fast, ≥99% required)

Run mechanically before content scoring. Each S0.x check is a binary pass/fail. A FAIL here is BLOCKING — do not proceed to Layer 1 until all blocks are resolved.

### Structural checklist

| Check | Requirement | Source | Fail class |
|-------|-------------|--------|------------|
| **S0.1** | Tier declared with selection rationale; matches scope heuristics (≥3 crates → MEDIUM, security-surface → LARGE, cross-API → LARGE) | Blueprint Part III | BLOCKING |
| **S0.2** | Phase count matches tier (SMALL=4, MEDIUM=6, LARGE=7) | LASDLC §1 | BLOCKING |
| **S0.3** | Frontmatter complete: `project`, `codename`, `status`, `tier`, `northstar_pillar`, `created`, `updated`, `lasdlc_template_version: "2.5.1"` | Blueprint §2.2 | BLOCKING |
| **S0.4** | All 9 required plan sections present: Purpose+Northstar, Architecture, Phase Set, Research Basis, Risk Register, File-Function Map, Pre-Flight, C1–C8 Self-Score, Close-Out | Blueprint §2.3 | BLOCKING |
| **S0.5** | `[A+S+Q+C+O+P+K+D+T+R]` gate vocabulary at every phase boundary | LASDLC §8, Canon XXXVIII | BLOCKING |
| **S0.6** | `pre_flight` block declared: G1–G8 checks enumerated | Agents Playbook §15.3 | BLOCKING |
| **S0.7** | `close_out` block declared: cleanup, archive, lessons promotion | Blueprint Part XVIII | BLOCKING |
| **S0.8** | `file_function_map`: every deliverable → file + function + agent owner | Blueprint §2.3 | BLOCKING |
| **S0.9** | `agent_topology_schema`: co-owned files have declared merge protocol | LASDLC §agent_topology | BLOCKING |
| **S0.10** | `operator_experience_layer` block: `northstar_anchor` + `per_phase_operator_view` + widget/view_mode/update_signal per phase block (v2.1+) | LASDLC §operator_experience, C4 | BLOCKING |
| **S0.11** | `northstar_lineage` block: `northstar_text`, `pillar_mapping`, `build_to_northstar_mapping`, `northstar_metric_delta_estimate` | Blueprint §2.3, LASDLC | BLOCKING |
| **S0.12** | `security_compliance` block declared: `security_classification` + compliance frameworks | LASDLC §security_compliance | BLOCKING for Restricted/Secret; CRITICAL for others |
| **S0.13** | `deliverable_benchmark` block declared: D-component scope + `independent_runner` identified (Canon XXXIII: never the build's own agent) | LASDLC §7.7 | BLOCKING |
| **S0.14** | `shipped_means_5_conditions` enumerated with verification owner per condition | LASDLC `northstar_lineage.shipped_means_5_conditions` | BLOCKING |
| **S0.15** | Blueprint Part I Covenant declaration: research-first evidence present; Part XVII handoff checklist items identified + ownership assigned | Blueprint Part I + Part XVII | CRITICAL |
| **S0.16** | Tier 3 canon audit scheduled: plan has `canons:` list > 3 entries OR tier = LARGE | Blueprint §14.5 | BLOCKING if triggered and not scheduled |
| **S0.17** | Reference table integrity: if ≥3 amendments applied this iteration, all reference tables swept (Tier 2/3 constraint tables, Blueprint XXI file maps, TS EventType entries) | CLAUDE.md policy | BLOCKING |

**Layer 0 verdict**: `PASS` if all S0.x are PASS. Any BLOCKING → halt; surface findings; do not proceed to Layer 1.

---

## Layer 1 — Content Scoring (C1–C8 Blueprint Rubric)

Run after Layer 0 PASS. Aggregate formula: `0.10·C1 + 0.15·C2 + 0.15·C3 + 0.10·C4 + 0.10·C5 + 0.10·C6 + 0.15·C7 + 0.15·C8`

### Sibling ownership

| Dimension | Owner | Load-bearing rule |
|-----------|-------|-------------------|
| **C1** Plan Completeness (10%) | Engineer (Alpha) | — |
| **C2** Cross-Validation Discipline (15%) | Analyst (Delta) | C2b (independent verification) caps C2 at 70 without it |
| **C3** Gate Coverage (15%) | Arbiter (Golf) | Security gate (C3b) resolves to `helix/user/standards/industry-baselines/security/` |
| **C4** Operator Experience Coverage (10%) | Ops (Bravo) | `terminal_window_open_count === 0` test must exist for P1 plans |
| **C5** Cost + Observability Discipline (10%) | Monitor (Foxtrot) | N/A escape if schemas not instanced; reweight proportionally |
| **C6** Loop-Cycle Integrity (10%) | Engineer (Alpha) | C6c (cross-validation per phase) is 30% of C6 |
| **C7** Northstar Alignment (15%) | Arbiter (Golf) (Layer 3) | C7a+C7b each 25% of C7; without them C7 caps at 50 |
| **C8** Context Hydration + Precision (15%) | **Arbiter (Golf)** | C8f (Canon XXXV confidence-threshold gate) blocks VALIDATED if unvalidated claims present |

### Score honesty enforcement (Blueprint §14.2 — mandatory)

Each anchor delta vs prior iteration MUST cite the specific amendment ID that justifies it. "Score went from 87 to 90" without amendment citation is a Canon V violation. Audit-honest aggregate (independent agent) beats self-scored aggregate — the lower number is honest when they diverge. Band transitions (ACCEPTABLE→STRONG at ≥75, STRONG→EXEMPLARY at ≥90) must be earned by gap closure, not anchor inflation.

### Two-tier amendment classification (Blueprint §14.3 — mandatory before each fold)

Classify every finding before deciding whether to iterate the plan:

**Fold into plan body (BLOCKING/CRITICAL):**
- BLOCKING — plan cannot reach VALIDATED without this fix
- CRITICAL — material risk (security ZERO-EXCEPTION, contract-design defect, architectural inconsistency)

**Track in review record only (HIGH/MEDIUM/LOW):**
- HIGH — important but does not gate VALIDATED
- MEDIUM — polish / refinement
- LOW — citation hygiene, formatting

Do not fold HIGH/MEDIUM/LOW into the plan body — this bloats plans and dilutes the VALIDATED contract.

### Score ceilings by feature type (calibration signal, not plan defect)

| Feature type | C7 ceiling | Aggregate ceiling |
|---|---|---|
| Direct Pillar 1 operator UX completion | 97–100 | 99–100 |
| Direct Pillar 2 orchestration capability | 95–98 | 98–99 |
| Indirect Pillar 2 infrastructure / observability | 93–95 | 98.5–99 |
| External / utility (no Northstar alignment) | 70–80 | 90–94 |

When the score stabilizes at a feature-type ceiling, annotate this in the verdict and do not continue iterating.

### Layer 1 verdict

- `PASS` — aggregate ≥ 75 (STRONG), no UNVALIDATED claims (C8f), C7 ≥ 75 with C7a+C7b present
- `INSUFFICIENT_EVIDENCE` — aggregate 60–74 or C7 60–74 (needs more research)
- `UNVALIDATED` — aggregate < 60 or C7 < 60 or UNVALIDATED claims present
- `DISPUTED` — ≥2 canon citations conflict → escalate to HITL

---

## Layer 2 — Northstar Mechanical Verification

Run after Layer 1 PASS. These are binary mechanical checks per northstar.md, not rubric scores.

| Check | What it verifies | Source |
|-------|-----------------|--------|
| **N1** | Identify claimed Pillar(s) from `northstar_lineage.pillar_mapping` | canon://northstar Part I |
| **N2** | Run each specific numbered mechanical check for every claimed Pillar (P1 has 6 E-gates + MCP surface check; P2 has 8 checks; P3–P7 each have their own numbered list) | canon://northstar §P1–P7 |
| **N3** | Pillar AND relationship: verify the plan does not regress any unclaimed Pillar's mechanical checks | canon://northstar Part I preamble |
| **N4** | Component Northstars (Part II): run the relevant `§A`–`§?` section checks for the plan's technical scope (§A CLI, §B Agent Runtime, §C Orchestration, §D Plugin Layer, etc.) | canon://northstar Part II |
| **N5** | C7d concrete delta: `northstar_metric_delta_estimate` is a verifiable measurement plan with a post-ship check, not just "improves P2" | Blueprint §14 C7d |
| **N6** | Per-phase Northstar fit predicate declared (C7c): each phase exit has a checkable condition tied to the claimed Pillar | Blueprint §14 C7c |

**Layer 2 verdict**: `PASS` if all N1–N6 pass. Any FAIL is BLOCKING — surface with the specific mechanical check number that failed and the canon://northstar line that defines it.

---

## Layer 3 — Output Contract Declaration (LDB)

Run after Layer 2 PASS. Verifies the plan has correctly set up the LDB framework. **Actual D1–D8 scores are computed at close-out by cold-context benchmark agents** (Canon XXXIII) — XEA only verifies the declaration is correct and complete.

| Check | Requirement | D-component |
|-------|-------------|-------------|
| **L1** | D1 (Request Fidelity) declared: acceptance criteria defined, D1c operator survey trigger specified | Always required |
| **L2** | D2 (ISO/IEC 25010) scoped: which characteristics (D2a–D2g) apply to this deliverable | Always required |
| **L3** | D3 (CISQ/automated) scoped: reliability, performance efficiency, security, maintainability rules identified | Always required |
| **L4** | D6 (Security) first-class: D6a–D6j sub-components declared; D6i Sentinel (Echo) live pen-test scheduled if security_classification = Restricted/Secret | Always required |
| **L5** | D8 (Parallel Agentic Performance) declared: Monitor (Foxtrot) spans identified; compression claim ("hours→minutes") is explicit and Monitor (Foxtrot)-measurable | Required if plan makes parallelism or performance claims (Canon XXXVI) |
| **L6** | `independent_runner` identified: cold-context agent named for LDB execution at close-out | Always required (Canon XXXIII: build's own agents never self-score LDB) |
| **L7** | `shipped_means_5_conditions` wired: all 5 conditions have a verification owner; condition 4 (LDB ≥STRONG) is explicitly the target, not just C1–C8 STRONG | Always required |

**Layer 3 verdict**: `PASS` if all L1–L7 present and correctly declared. Missing blocks are BLOCKING.

---

## Iteration Loop

```
verdict = run Layer 0 → Layer 1 → Layer 2 → Layer 3

loop:
    classify all findings by §14.3 taxonomy (BLOCKING/CRITICAL vs HIGH/MEDIUM/LOW)
    fold BLOCKING/CRITICAL into plan body
    track HIGH/MEDIUM/LOW in review record (not in plan)
    increment iteration counter
    re-run all 4 layers
    compute score delta vs prior iteration

    if consecutive_rounds_with_no_blocking >= 2 AND score_delta < 0.3:
        STOP — present verdict with ceiling annotation
    if iteration > 7:
        STOP — HITL escalation (question tool) — see max-iterations checkpoint below
```

```ask
questions:
  - question: "XEA has exceeded 7 iterations without convergence. How do you want to proceed?"
    header: "XEA max iterations"
    multiSelect: false
    options:
      - label: "Accept current verdict"
        description: "Use the current score and proceed. Remaining gaps documented in review record."
      - label: "Continue iterating"
        description: "Run another round of XEA amendments."
      - label: "Cancel"
        description: "Abort XEA and do not proceed with /BUILD."
```

**Termination note**: when the loop stops because delta < 0.3, the remaining gap is almost always the C7 feature-type ceiling. Annotate clearly: "Score has converged at <N>. C7 ceiling for this feature type is <93–95/95–98/97–100>. This is a calibration signal, not a plan defect."

---

## Verdict Output Format

Emit a structured verdict block as both a YAML block (to append to the plan) and a human-readable summary.

```yaml
xea_verdict:
  iteration: N
  reviewed_at: <ISO-8601>
  layer_0_structural:
    result: PASS | FAIL
    failing_checks: [S0.x, ...]   # empty if PASS
  layer_1_content:
    C1: <score>; C2: <score>; C3: <score>; C4: <score>
    C5: <score>; C6: <score>; C7: <score>; C8: <score>
    aggregate: { low: N, point: N, high: N }
    band: EXEMPLARY | STRONG | ACCEPTABLE | DEFICIENT | UNSAFE
    delta_vs_prior_iteration: { C1: +/-N, ..., aggregate: +/-N }
    amendment_citations: { C1: "SCR1-3", ... }   # §14.2 honesty enforcement
  layer_2_northstar:
    result: PASS | FAIL
    claimed_pillars: [P1, P2, ...]
    failing_checks: [N2_P2_check_3, N4_section_A_item_2, ...]
  layer_3_ldb:
    result: PASS | FAIL
    missing_blocks: [L4, L6, ...]
  overall_validation_status: VALIDATED | INSUFFICIENT_EVIDENCE | UNVALIDATED | DISPUTED
  blocking_gaps_folded: [<list of amendment IDs>]
  tracked_findings: [<HIGH/MEDIUM/LOW items — not in plan body>]
  ceiling_annotation: "<feature-type ceiling note if applicable>"
  residual_gaps: [<gaps not yet resolved>]
```

**Human-readable summary format:**

```
XEA VERDICT — <codename> (iteration N)

Layer 0 Structural:  ✅/❌  (<n> checks pass, <n> BLOCKING)
Layer 1 Content:     ✅/❌  (aggregate <N> — <band>; C7=<N> <pillar>)
Layer 2 Northstar:   ✅/❌  (<checked pillars>; <n> mechanical checks pass)
Layer 3 LDB:         ✅/❌  (D-components declared; independent runner: <name>)

Status: VALIDATED | BLOCKED — <specific gap>
```

---

## Sibling Domain Configs

Each sibling runs its lens against the plan using its canonical baseline files:

| Sibling | Owned Dimensions | Baseline Paths |
|---------|-----------------|----------------|
| Engineer (Alpha) | C1, C3, C6, [A], [T] | `builders-cookbook`, `architecture/ieee`, `quality/iso`, `testing/owasp` |
| Arbiter (Golf) | C3, C7, C8, [C], [Q] | all 7 canon docs + `gatekeeper-registry` + `quality/iso` |
| Ops (Bravo) | C4, C5, [O] | `operations/google-cloud/dora`, `operations/google/sre-golden-signals`, `cncf/opentelemetry` |
| Analyst (Delta) | C2, [R] | `research/` + `architects-blueprint` |
| Sentinel (Echo) | [S] (D6 sub-components) | `security-guardrails` + `owasp-llm` + `owasp-agentic` + `nist-csf/ssdf` + `mitre-atlas` |
| Knowledge (Charlie) | [K], [D] | `platform-canon` + `agents-playbook` |
| Monitor (Foxtrot) | C5, [P] (D8) | `cncf/opentelemetry` + `google/sre-golden-signals` + `apdex` + `w3c/trace-context` |

**Confidence deductors (apply to each sibling's domain score):**

| Condition | Deduction |
|-----------|-----------|
| Unresolved contradiction between two cited sources | −10% per conflict |
| Single source, no corroboration | Cap at 85% |
| Source > 2 years old on fast-moving domain | −5% |
| Paywalled / unverifiable URL | Disqualified as cross-verified |
| Baseline file missing | −5% per file |

---

## Contract Canon Integration (Cookbook §82)

This skill is governed by `agent.skill.xea` at `standards/canon/contracts/agent.skill/xea.yaml`. The five §82.3 touchpoints:

### Read
Layer 0 (Structural Schema) reads:
- `standards/canon/contracts/operator.surface/*` — to evaluate S0.18 contract coverage
- The plan's `contracts_touched:` frontmatter — input to S0.18

### Touched-contract citation
S0.18 verifies that the plan's `contracts_touched:` covers every operator.surface contract overlapping the plan's stack-class scope. Output is a list of `(plan_target_substring, matching_contract_id)` pairs; empty list against a non-empty contract corpus = BLOCKING.

### forbidden_behaviors enforcement
Not enforced at /XEA — XEA reviews plans, not diffs. Forbidden-behavior enforcement happens at /BUILD per-wave S5 + /GATE pre-merge S5.

### required_spans emission
`/XEA` emits `skill.xea.invoke` (parent_relationship: child_of_caller) with metadata: `codename, iteration_count, layer_0_pass, aggregate_score, validation_status, contracts_coverage_pass`.

### status_per_provider impact
None. XEA reviews plan compliance, does not mutate canon.

### Layer 0 — S0.18 Contract Coverage (new 2026-06-04)

| Check | Requirement | Source | Fail class |
|-------|-------------|--------|------------|
| **S0.18** | Plan target touches operator.surface contract(s) → `contracts_touched:` is non-empty + cites each touched contract id | Cookbook §82.1 + §82.3 | BLOCKING |

S0.18 algorithm:
1. Read plan target + stack_classification + file_function_map
2. For each `standards/canon/contracts/operator.surface/*.yaml`, check if `operator_surface.ui_locator` or `operator_surface.screen_key` overlaps the plan scope (string match against target keywords; refined by screen_key match against stack_classification)
3. Collect touched_contract_ids
4. If non-empty and `contracts_touched:` frontmatter is absent/empty → fail S0.18 BLOCKING
5. If `contracts_touched:` lists ids not actually touched → fail with class S0.18.WRONG_CITATION

S0.18 cannot be deferred — Layer 0 is fail-fast.

## Graceful Degradation

If sibling MCP unavailable: run the affected dimension manually (Claude reads the canon doc directly and applies the relevant rubric section). Flag as `self-reviewed` in the verdict with `confidence_interval.width >= 20pp`. Recommend `/SCRUM` on completion.

If plan has no `deliverable_benchmark` block (pre-v2.4.0 plan): Layer 3 returns BLOCKING on L1–L7, prompting the fold. This is expected for plans authored before LASDLC v2.4.0.

---

## References

- `canon://architects-blueprint` — Part XIV (C1–C8 rubric, §14.1–§14.5), Part XVII (handoff checklist)
- `canon://northstar` — Part I (7 Vision Pillars + mechanical checks), Part II (Component Northstars §A–§Q)
- `canon://lasdlc-template` — `$HELIX/user/standards/canon/LASDLC-TEMPLATE-v1.yaml` (§7.7 LDB v1.0)
- `canon://platform-canon` — Canon XXXIII (independent verification), Canon XXXV (citation gate), Canon XXXVI (quality-first compression)
- `memory://feedback_xea_loop_plan_hardening` — score ceiling table, convergence pattern
- `memory://feedback_score_honesty_discipline` — §14.2 operational application
- `memory://feedback_two_tier_amendment_classification` — §14.3 fold-in vs track-in-record
