---
name: PLAN
description: "Interactive plan author — generates a LASDLC + Architects Blueprint-compliant
  build plan with Northstar lineage, then runs /XEA (3-layer compliance review: structural
  schema ≥99%, C1–C8 content scoring, Northstar mechanical checks, LDB output contract)
  until validation_status=VALIDATED (max 3 iterations + operator override). Persists the
  plan to ~/.claude/plans/<codename>.md with frontmatter, then offers /BUILD, /SCRUM,
  [edit], or [plan only]. Use when you want a verified plan before any code is written:
  '/plan', 'plan this', 'architect this', 'design the implementation', 'how should we
  build', 'show me the plan first'."
user-invocable: true
version: 2.4.0
context: root
---

# /PLAN — Northstar-anchored, canon-validated build plan author

> Draft per **LASDLC-TEMPLATE-v1** + **Architects Blueprint** → self-review until `validation_status=VALIDATED` → persist with frontmatter → decision gate.

## /PLAN vs. /BUILD

| | `/PLAN` | `/BUILD` |
|--|---------|---------|
| What runs | Plan author + self-review loop | Full build pipeline against an existing VALIDATED plan |
| Code written? | NO — stops before any implementation | YES — agents implement in worktree |
| Output artifact | `~/.claude/plans/<codename>.md` (status: draft) | Commits on `feat/<codename>` branch + /GATE per phase |
| Decision point | After review: build / scrum / edit / plan only | Before spawn: write-path disclosure |
| Pre-condition | Target string | Plan file with `validation_status: VALIDATED` |

## Accepted Flags

| Flag | Effect |
|------|--------|
| `--research` | Analyst (Delta) + Knowledge (Charlie) gather prior art before draft (Architects Blueprint Part IV — Research-First Doctrine) |
| `--northstar="<text>"` | Skip Step 2 elicitation; use provided Northstar verbatim |
| `--codename=<id>` | Override auto-derived codename for the plan file |

Rejected: `--then`, `--watch`, `--drain`, `--fix`.

---

## Step 1: Argument Validation (SAFEGUARD #24)

Target pattern: `^[a-zA-Z0-9_/. -]+$`. Reject SQUAD control flags, shell metacharacters,
path traversal. Derive `codename` from target (kebab-case, ≤40 chars) unless `--codename` set.

---

## Step 2: Northstar Elicitation (MANDATORY)

> Every plan declares a `northstar_lineage` block (Architects Blueprint Part I — Three Covenants §2). A plan with no Northstar **cannot exit Phase 1**.

### Step 2.1: Detect build context

Inspect the target string + cwd for platform-component signals:
- **Platform build** if target touches: `helix/`, `Knowledge (Charlie)`, `Ops (Bravo)`, `Engineer (Alpha)`, `Sentinel (Echo)`, `Monitor (Foxtrot)`, `Analyst (Delta)`, `lightarchitects-sdk`, `webshell`, `light-architects-plugins`, `~/lightarchitects/`
- **External build** otherwise (third-party project, generic feature, user code)

### Step 2.2: Generate 3 smart proposals + free-form fallback

**For platform builds** — map proposals to the canonical Pillars (`canon://northstar` — 7 Pillars P1–P7, read the doc for current definitions):

> **P1 — E2E Engineering from Webshell UI**: operator completes a full engineering session from the webshell without terminal fallback.
> **P2 — Vibe Coding Orchestration**: lightarchitects spawns, sandboxes, monitors, and steers other coding agents with security-by-default and session continuity.
> **P3 — MoE Platform**: multi-model, multi-agent routing with specialization and ensemble verification.
> **P4 — Operator-Legible Arc**: operator always knows where a build is, why, and what's next.
> *(P5–P7: see `canon://northstar` for Security, Research Quality, and Plugin Ecosystem Pillars.)*

Generate three context-fitted proposals such as:
- *"Advances P1: {feature} closes the {gate} so operators can {action} without terminal."*
- *"Advances P2: {feature} adds {capability} to the orchestrator (sandbox / session / observability / multi-agent)."*
- *"Advances Both: {feature} closes a webshell gate AND extends orchestration capability."*

**For external builds** — generate three generic templates derived from feature scope:
- *"Outcome: {primary user value} measurable by {metric}."*
- *"Capability: {system can now do X that it couldn't before}, removing {prior constraint}."*
- *"Quality: {existing surface} reaches {threshold} on {dimension}, unblocking {downstream work}."*

### Step 2.3: question tool (single select, 4 options)

```
question: "What Northstar does this build advance?"
header: "Northstar"
options:
  - label: "<Proposal 1 — 1-line summary>" / description: "<full proposal text>"
  - label: "<Proposal 2 — 1-line summary>" / description: "<full proposal text>"
  - label: "<Proposal 3 — 1-line summary>" / description: "<full proposal text>"
  - label: "Write my own" / description: "Free-form Northstar — opens text input on the next turn"
```

If user selects "Write my own" → follow up with question tool text prompt:
```
question: "Write the Northstar for this build (1–3 sentences):"
header: "Custom Northstar"
options: ["[free-form via Other]"]
```

Store the chosen Northstar verbatim in `northstar_lineage.northstar_text` for the draft + persist step.

### Step 2.6: Capture origin context (MANDATORY — added v2.3.0)

Immediately after the Northstar is locked (Step 2.3 selection or 2.4 flag), synthesize a
`northstar_origin` record from the **conversation context that triggered this /PLAN call**.

This record answers: *"Why was this plan created in the first place, and does the Northstar
genuinely follow from that reason?"*

```yaml
northstar_lineage:
  northstar_origin:
    trigger: |
      <1-3 sentence verbatim or close paraphrase of what the user said / what event
      caused this plan to be requested. Cite the specific message, issue, prior build
      outcome, or helix entry that is the proximate cause. If the trigger was a previous
      build closing a gap, name the build and the gap it left open.>
    origin_citations:
      - source: "<'user message' | 'helix entry: <path>' | 'build: <codename>' | 'canon gap: <ref>'>"
        excerpt: "<verbatim or near-verbatim quote from the source>"
    northstar_coherence_claim: |
      <1-2 sentences asserting WHY the chosen Northstar follows from the trigger.
      Must reference at least one specific detail from origin_citations — generic
      "this advances P1" statements are NOT valid here.>
```

**Coherence check**: if you cannot write a `northstar_coherence_claim` that references a
specific detail from `origin_citations`, the Northstar is probably misaligned — return to
Step 2.3 and propose a better-fitting option. Do not proceed to Step 3 with a generic
claim.

### Step 2.4: Skip condition

If `--northstar="<text>"` flag was passed, skip 2.1–2.3 and use the flag value verbatim. Still record `northstar_lineage` in the plan.

---

## Step 2.5: Stack Classification Elicitation (MANDATORY — LASDLC v2.6.0+)

> Declared once at plan-time; locked as a build-time invariant. Drives gate_checklist_variant and diagram depth requirements (Blueprint Part XXVI).

### Step 2.5.1: Context-aware pre-detection

Before asking, inspect the target string + cwd for stack signals:

- **`full-stack` signals**: WebEvent types + Svelte components + Rust routes in same diff; `lightarchitects-webshell` + crate changes together
- **`frontend-only` signals**: `lightarchitects-webshell-ui/` only; no `Cargo.toml` additions; `.svelte` + `.ts` files only
- **`backend-only` signals**: crate-level only; no `src/routes/`, no `.svelte` files; Rust `src/` changes only
- **`cli-tooling` signals**: `lightarchitects-gateway/` or MCP-only; no webshell dependency

If signal is unambiguous (≥80% confidence from target string), auto-detect and confirm in the question tool label (e.g., "This looks like a backend-only build — confirm?").

### Step 2.5.2: question tool (single select, 4 options)

```
question: "What is the stack classification for this build?"
header: "Stack class"
options:
  - label: "Full-stack (backend + frontend)" / description: "Touches both Svelte/TS frontend and Rust backend in this build. Both cargo and pnpm gates apply."
  - label: "Frontend-only (Svelte/TS)" / description: "Svelte/TS surface only — no new Rust handlers or Cargo.toml additions. pnpm gates only."
  - label: "Backend-only (Rust/Cargo)" / description: "Rust/crate work only — no .svelte files, no pnpm changes. cargo gates only."
  - label: "CLI tooling (binary/MCP)" / description: "CLI binary or MCP server only — no webshell surface. cargo gates only; C3 component diagram always required."
```

If auto-detected with ≥80% confidence, present the detected class as first option labeled `"<class> (detected — Recommended)"`.

### Step 2.5.3: Store + diagram planning

Store chosen value in plan frontmatter as `stack_classification.value`.

After storing, immediately determine the diagram set required for this build (Blueprint Part XXVII §27.2 + §26.4, **Canon XLI**):

- Note tier-required diagrams (from Step 2 tier determination or Step 4 draft generation):

  | Tier | Required set |
  |------|-------------|
  | SMALL | C3 (component) only |
  | MEDIUM | C2 (container) + C3 (component) |
  | LARGE | C1 (system context) + C2 + C3 + C4 (code) + ERD + sequence diagrams for any async/cross-binary flow |

- Add stack-class additions (screen-flow + state-machine for `frontend-only`/`full-stack`; ERD if schema changes possible for `backend-only`)
- **Diagram library selection** (two baseline docs, distinct purposes):
  - `$HELIX/user/standards/industry-baselines/architecture/diagrams/DIAGRAMS.md` — standards compliance: ISO/IEC/IEEE 42010, TOGAF, C4, UML hierarchy. Determines WHICH notation to apply.
  - `$HELIX/user/standards/industry-baselines/architecture/diagrams/diagram-library.html` — tool selection: Mermaid, D2, PlantUML, Likec4, C4-native maturity + license comparison. Determines WHICH tool to use.
  - Consult both; record the chosen tool in `architecture_artifacts.diagram_library` (enum: `mermaid|d2|plantuml|likec4|c4-native`).
- Add the full diagram list to `architecture_artifacts.generated_diagrams` placeholder in the plan draft

**Canon XLI — Diagram-First Doctrine (mandatory)**:

Diagrams in Phase 1 are **design inputs**, not Phase 0 generation outputs. The architect authors them as the act of designing; implementation follows the diagrams. Record this obligation in the plan:

```yaml
architecture_artifacts:
  diagram_library: <mermaid|d2|plantuml|likec4|c4-native>   # from industry-baseline selection
  diagrams_authored_phase: "1"                                # Canon XLI — drawn before implementation
  generated_diagrams: []                                      # populated at Phase 0 arch generate run
  a_gate_predicate:
    diagram_present: pending    # set to verified at Phase 1 [A] gate
    drift_clean: pending        # set to verified at each subsequent [A] gate by arch verify
    checklist_current: pending  # set to verified at each [A] gate
```

The `[A] gate passes := diagram_present ∧ drift_clean ∧ checklist_current` (Canon XLI mechanical predicate). All three conjuncts must be verified at every [A] gate; missing any one is a BLOCKING finding routed to Engineer (Alpha) + Arbiter (Golf).

### Step 2.5.4: Diagram phase wiring

Include the following in the plan's phase set at the correct phases (Canon XLI):

```
Phase 0 — Pre-flight + Drift Baseline:
  - Run: arch generate --output $HELIX/corso/builds/<codename>/diagrams/
    (establishes baseline; does NOT replace architect-authored Phase 1 diagrams)
  - Populate architecture_artifacts.generated_diagrams[] in plan frontmatter

Phase 1 — Architecture (design input, mandatory before any implementation):
  - Author all tier-required diagrams using the selected diagram_library
  - Set architecture_artifacts.a_gate_predicate.diagram_present = verified
  - [A] gate: diagram_present ∧ drift_clean ∧ checklist_current must hold before Phase 2 begins
```

---

## Step 3: (Optional) Research — `--research` only

Per Architects Blueprint Part IV (Research-First Doctrine) — research comes **BEFORE** architecture.

```
mcp__plugin_lightarchitects_lightarchitects__tools sibling:"quantum" action:"research" query:"<target>"
mcp__plugin_lightarchitects_lightarchitects__tools sibling:"soul" action:"search" query:"<target>"
```

If new dependencies are likely in scope, also:
```
mcp__plugin_sonatype-guide_sonatype-guide__getRecommendedComponentVersions  # per candidate dep
```

Synthesize §4.1–§4.6 findings (problem domain, tech landscape, best practices, reference impl, dependency risk, cost). Pass as context to Step 4.

---

## Step 3.5: Template Snapshot (MANDATORY — added v2.3.0)

Before generating any draft content, read the canonical LASDLC template:

```
Read: $HELIX/user/standards/canon/LASDLC-TEMPLATE-v1.yaml
```

Extract and hold in working memory:
- `template_version` — record in plan frontmatter as `lasdlc_template_version`
- All top-level schema field names (the ordered set of sections the draft must include)
- `northstar_lineage.shipped_means_5_conditions` — the 5 conditions the plan's own `shipped_means_5_conditions` must satisfy
- `architecture_artifacts.schema.diagrams` — tier-appropriate diagram set for Step 4 Phase 0
- `stack_classification.schema.gate_checklist_variant` — which gate variant applies to this build's stack class

**Why**: the template is the authoritative schema. The draft is a filled-in copy of the template — not a freeform document that happens to share field names. Any field present in the template that is applicable to this tier MUST appear in the draft. Any field omitted must be justified in a `# omitted: <reason>` inline note.

If the template file is not readable → halt with: *"Cannot read LASDLC template at canonical path. Verify `$HELIX/user/standards/canon/LASDLC-TEMPLATE-v1.yaml` exists before authoring a plan."*

---

## Step 4: Draft Generation (Iteration `N`, starting N=1)

Generate a LASDLC-compliant plan using the template snapshot from Step 3.5 as a **required scaffold** — not as a ceiling. The template defines the floor:

- **Template fields** (floor — non-negotiable): all tier-required template fields must be present, named verbatim, and ordered as in the template. Omissions require a `# omitted: <reason>` inline note and are classified as BLOCKING in Step 5.5 unless the tier genuinely excludes the field.
- **Plan-specific extensions** (above the floor — encouraged): additional fields, sub-sections, or sections that the specific plan requires may be added freely. Extensions should follow the template's naming conventions (snake_case keys, consistent block structure) but are not constrained to the template schema. Place extensions after the relevant template section they extend, or in a clearly labeled `## Plan-Specific Extensions` block at the end of the body.
- **No renaming** of template fields: if the template says `northstar_lineage`, the plan says `northstar_lineage`. Extensions get new names; they do not replace existing ones.

The template is the structural contract between plans and the toolchain (/BUILD, /GATE, active.yaml). Extensions are the plan author's design space.

Generate via Engineer:Scout, instantiated against the template snapshot:

```
mcp__plugin_lightarchitects_lightarchitects__tools sibling:"corso" action:"sniff"
  context: "plan-generation"
  spec: "<target>"
  northstar: "<northstar_text from Step 2>"
  research_findings: "<from Step 3 if --research>"
  iteration: N
  review_findings: "<from Step 5 if N>1>"
```

### Required plan structure (LASDLC-TEMPLATE-v1 + Blueprint 21 Parts)

The draft MUST include (tier-appropriate subset for SMALL, full set for MEDIUM/LARGE):

1. **Frontmatter** (see Step 6 for exact schema)
2. **Northstar lineage** — `northstar_text`, `pillar_mapping` (if platform build), `build_to_northstar_mapping` (concrete chain, not aspirational), `northstar_metric_delta_estimate`
3. **Tier + phase set** — SMALL (4 phases) / MEDIUM (6 phases) / LARGE (7 phases) per Blueprint Part III
4. **Phases interleaved with `/GATE` phases** — every substantive phase followed by `phase-N-gate` entry per `feedback_gate_phases.md` memory. Pattern:
   ```
   - phase-1-scope
   - gate-1
   - phase-2-research
   - gate-2
   - phase-3-build
   - gate-3
   - phase-4-verify
   - gate-4 (pre-merge)
   ```
5. **`[A+S+Q+C+O+P+K+D+T+R]` gate vocabulary at every phase boundary** (Canon XXXVIII)
6. **File-function map** — every deliverable mapped to file:function + agent owner (Blueprint §2.1)
7. **Pre-flight checks** — G1-G8 worktree gate (Playbook §15.3) before Phase 1
8. **Close-out** — cleanup, archive, lessons promotion (Blueprint Part XVIII)
9. **Per-phase exit criteria** — specific, checkable conditions
10. **Risks & mitigations** (Blueprint Part XV)
11. **Timeline + parallelization** (Blueprint Part XVI — file-ownership partitioning)
12. **Reference materials** (Blueprint Part XIX) — canon URIs cited
13. **Files created/modified summary** (Blueprint Part XXI)
14. **`deliverable_benchmark` block** — D-component scope (D1–D8) + `independent_runner` identified (LASDLC §7.7, Canon XXXIII)
15. **`shipped_means_5_conditions`** — all 5 conditions enumerated with verification owner (LASDLC `northstar_lineage`)
16. **Blueprint Part XVII handoff checklist** — items in-scope identified + ownership assigned for "can a stranger run this?" test

**Present the draft in full.**

---

## Step 5: XEA Review (replaces A1–A5 self-review anchors)

Delegate the full compliance review to `/XEA`. XEA runs the three-layer checklist (structural schema, C1–C8 content, Northstar mechanical, LDB output contract) and returns a structured verdict.

```
Skill: XEA, args: "<codename>"
```

XEA handles:
- **Layer 0** — structural schema ≥99% (S0.1–S0.17 mechanical checklist)
- **Layer 1** — C1–C8 Blueprint rubric with §14.2 score honesty and §14.3 two-tier amendment classification
- **Layer 2** — Northstar mechanical checks per claimed Pillar (P1–P7) + Component Northstars (Part II)
- **Layer 3** — LDB output contract declaration (D1–D8, shipped_means_5_conditions, independent_runner)

### Step 5.2: Map XEA verdict → review_verdict block

Append XEA's output to the plan as `## Review Verdict`:

```yaml
review_verdict:
  iteration: N
  reviewed_at: <ISO-8601>
  xea_layer_0: PASS | FAIL  # structural schema — failing_checks: [S0.x, ...]
  xea_layer_1:              # C1-C8 content
    C1: <score>; C2: <score>; C3: <score>; C4: <score>
    C5: <score>; C6: <score>; C7: <score>; C8: <score>
    aggregate: { low: N, point: N, high: N }
    band: EXEMPLARY | STRONG | ACCEPTABLE | DEFICIENT | UNSAFE
    delta_vs_prior_iteration: { aggregate: +/-N }
    amendment_citations: { C1: "<amendment-id>", ... }
  xea_layer_2: PASS | FAIL  # northstar mechanical — failing_checks: [N2_P2_check_3, ...]
  xea_layer_3: PASS | FAIL  # LDB declaration — missing_blocks: [L4, L6, ...]
  validation_status: VALIDATED | INSUFFICIENT_EVIDENCE | UNVALIDATED | DISPUTED
  blocking_gaps_folded: [<amendment IDs>]
  tracked_findings: [<HIGH/MEDIUM/LOW — out of plan body>]
  ceiling_annotation: "<if applicable>"
  residual_gaps: [<gaps not yet resolved>]
```

`validation_status` mapping (per XEA output):
- **VALIDATED** — all 4 layers PASS
- **INSUFFICIENT_EVIDENCE** — Layer 1 aggregate 60–74 or C7 60–74 (needs more research)
- **UNVALIDATED** — Layer 0 FAIL or Layer 1 aggregate <60 or UNVALIDATED claims in C8f
- **DISPUTED** — ≥2 canon citations conflict → escalate to HITL

---

## Step 5.5: Template + Blueprint Structural Evaluation (added v2.3.0)

Run **after** XEA returns its verdict, **before** deciding whether to iterate. This evaluation is complementary to XEA — XEA scores content quality; this step checks structural fidelity to the template and origin coherence.

### Step 5.5.1: Template field coverage scan

Using the template snapshot from Step 3.5, walk every top-level schema field and verify:

| Check | Pass condition | Fail action |
|-------|---------------|-------------|
| **T1** | All tier-required sections present in draft body | List missing sections; classify as BLOCKING |
| **T2** | Field names match template exactly (no renames, no freeform aliases) | Flag misnamed fields; classify as BLOCKING |
| **T3** | `lasdlc_template_version` in frontmatter matches snapshot's `template_version` | Correct the version field |
| **T4** | `stack_classification.value` present and matches one of the 4 enum values | Classify as BLOCKING |
| **T5** | `gate_checklist_variant` derived from `stack_classification.value` (not hardcoded) | Classify as BLOCKING |
| **T6** | Canon XLI [A] gate predicate declared: `architecture_artifacts.diagram_library` set (from industry-baseline selection); `diagrams_authored_phase: "1"` present; `a_gate_predicate` block with all three conjuncts (`diagram_present`, `drift_clean`, `checklist_current`); `generated_diagrams` placeholder with tier-correct set. All four sub-checks required. | Classify as CRITICAL if MEDIUM/LARGE; BLOCKING for all tiers if `diagram_library` absent |
| **T7** | `shipped_means_5_conditions` has exactly 5 conditions, each with a verification owner | Classify as BLOCKING |
| **T8** | `northstar_lineage.northstar_origin` block present (Step 2.6) with non-empty `trigger`, `origin_citations`, and `northstar_coherence_claim` | Classify as BLOCKING |
| **T9** | `northstar_coherence_claim` references at least one specific detail from `origin_citations` (not generic "advances P1") | Classify as CRITICAL |

### Step 5.5.2: Blueprint Part coverage scan

Read `canon://architects-blueprint` Parts I–XXI. For each Part that is in-scope for the plan's tier, verify the corresponding section is present in the draft:

| Blueprint Part | Required for | Check |
|----------------|--------------|-------|
| Part I — Covenants | All tiers | Research-first evidence section or `--research` note |
| Part III — Tier + Phase Set | All tiers | Phase count matches tier; gates interleaved |
| Part XIV — C1-C8 Rubric | All tiers | Self-score section or deferred to XEA verdict |
| Part XV — Risks | MEDIUM/LARGE | Risk register with mitigations |
| Part XVI — Timeline | MEDIUM/LARGE | Timeline + parallelization with file-ownership partitioning |
| Part XVII — Handoff | All tiers | "Can a stranger run this?" checklist items |
| Part XVIII — Close-out | All tiers | Cleanup + archive + lessons promotion steps |
| Part XIX — References | All tiers | Canon URIs cited for all major claims |
| Part XXI — File map | All tiers | File-function map; every deliverable has a file + function + agent |
| Part XXVII — Diagram gen | MEDIUM/LARGE (if v2.5.2+) | `arch generate` Phase 0 step present; Phase 1 diagram authoring step present |
| Canon XLI — Diagram-First | All tiers | `a_gate_predicate` block declared; `diagram_library` from industry-baseline; `diagrams_authored_phase: "1"` |

Missing Parts: classify as BLOCKING (Parts III, XVII, XVIII, XXI) or CRITICAL (others).

### Step 5.5.3: Origin-Northstar coherence check

Re-read `northstar_lineage.northstar_origin` from the draft. Verify:
- `trigger` references the actual conversation/event that prompted the plan — not a generic description of the feature
- `northstar_coherence_claim` is falsifiable: a reader with no context could understand both WHY the plan was requested AND why the chosen Northstar is the right fit
- The content of the draft's Phase 1 (scope) and the `northstar_text` are mutually consistent — no mismatch between what is being built and what the Northstar claims it achieves

If the coherence check fails → classify as CRITICAL and return to Step 2.6 to rewrite the `northstar_origin` block before re-evaluating.

### Step 5.5.4: Emit evaluation verdict

```yaml
template_blueprint_eval:
  evaluated_at: <ISO-8601>
  template_version_checked: <snapshot version from Step 3.5>
  t1_section_coverage:  PASS | FAIL  # missing: [<list>]
  t2_field_naming:      PASS | FAIL  # misnamed: [<list>]
  t3_version_match:     PASS | FAIL
  t4_stack_class:       PASS | FAIL
  t5_gate_variant:      PASS | FAIL
  t6_canon_xli:         PASS | FAIL | NA   # diagram_library set + diagrams_authored_phase=1 + a_gate_predicate block + tier-correct generated_diagrams
  t7_shipped_means:     PASS | FAIL
  t8_origin_block:      PASS | FAIL
  t9_coherence_claim:   PASS | FAIL
  blueprint_parts_missing: [<Part N — description>]
  overall: PASS | FAIL
  blocking_count: N
  critical_count: N
```

**If `overall: FAIL`**: fold BLOCKING findings into the draft before running Step 6's iteration decision. CRITICAL findings also fold into the draft (not just tracked). This evaluation runs on every iteration — not just iteration 1.

---

## Step 6: Iteration Loop (max 3, Canon XXXV-enforced)

The iteration decision now requires BOTH XEA (Step 5) AND template/Blueprint evaluation (Step 5.5) to pass:

```
if validation_status == VALIDATED AND template_blueprint_eval.overall == PASS:
    proceed to Step 7 (Persist)
elif iteration < 3:
    inject review_verdict.residual_gaps + findings as context
    increment iteration counter
    return to Step 4 (Draft Generation)
else:
    Step 6.1: HITL escalation (with operator-override exception per §6.2)
```

### Step 6.1: HITL Escalation (only fires after 3 failed iterations)

```ask
questions:
  - question: "After 3 review iterations, the plan still has residual gaps. How do you want to proceed?"
    header: "Plan residual"
    multiSelect: false
    options:
      - label: "Hand to /SCRUM"
        description: "Squad review — 3-round Good/Gaps/Fixes against the current draft + verdict block. May surface fixes the self-review missed."
      - label: "Accept with gaps logged"
        description: "Persist as draft with status=draft_residual. /BUILD will refuse until gaps closed. You acknowledge the gaps in writing."
      - label: "Abandon"
        description: "Discard the plan. No file written."
      - label: "Operator-authorized iteration 4+ (per §6.2)"
        description: "Operator authorizes another iteration per §6.2 exception. Use when residual gaps are BLOCKING/CRITICAL items that can be folded in-plan."
```

On "Hand to /SCRUM" → invoke `Skill: SCRUM` with the plan + verdict block as topic. After SCRUM returns, run Step 5 once more. If still not VALIDATED → return here with the SCRUM findings appended.

### Step 6.2: Operator-Authorized Iteration Cap Override (Exception Clause — added v2.1.0, ratified per Canon XV)

**Rule**: The nominal max-3 cap is OVERRIDABLE when iteration 3 produces canon-audit findings that include BLOCKING or CRITICAL items requiring in-plan folding rather than architectural rework or tier escalation. Operator authority overrides the skill default per Canon XV (Principal Hierarchy: Architect > Operator > User).

**When this exception applies**:
- Iteration 3 self-review or Tier-3 canon audit (per Blueprint §14.5) surfaces fold-able BLOCKING/CRITICAL items
- The fold scope is documentation/contract-clarification, not new architectural surface
- Operator explicitly directs "fix the plan" rather than picking from Step 6.1 escalation options (Hand to /SCRUM / Accept-with-gaps / Abandon)

**When this exception does NOT apply (operator should NOT override)**:
- Findings require new architectural surface (new types, new gates, new code modules) — that's a tier-escalation signal per LASDLC Template §1.4 `late_stage_reeval_triggers`, not an iteration extension
- Findings include ZERO-EXCEPTION canon items (Security §2.6, §5.1, §10.2, etc.) that materially expand wall-clock by >15% — tier re-evaluation is the right response
- Operator chose this option to avoid the discipline of /SCRUM or HITL acceptance — the override is for fold-ability, not bypass

**Operational requirements when override is invoked**:
1. Document the override in plan frontmatter:
   ```yaml
   operator_override_note: |
     Iteration N exceeds /PLAN spec's nominal 3-iteration cap. Operator explicitly
     directed "fix the plan" rather than picking from Step 6.1 HITL options.
     Operator authority overrides skill default per Canon XV. Scope: <BLOCKING/CRITICAL
     items folded this iteration>. <HIGH/MEDIUM/LOW> findings tracked in review record.
   ```
2. Increment `review_iterations` honestly in frontmatter (do NOT rebase to "3 + amendment" without acknowledgment)
3. Re-run Step 5 self-review on iteration N output; if VALIDATED, proceed to Step 7 + Step 8; if not, return to Step 6.1 (each subsequent override is a stronger tier-mismatch signal)
4. If iteration N>5, surface tier-escalation recommendation explicitly — multiple overrides indicate the build's tier was wrong from the start

**Composition with Canon XXXIX**: This exception is the operational mechanism by which canon-audit findings (Tier 3 per Blueprint §14.5) get folded into late-iteration plans. Canon XXXIX (Canon Promotion Pipeline) is the meta-canon governing canon evolution; this clause is the per-build operational implementation that ensures canon-audit-surfaced amendments have a valid fold-in path without forcing HITL escalation.

**Pressure-tested**: Demonstrated 2026-05-13 during the `gateway-action-audit-claude-runtime` plan authoring. Iter 3 produced canon-audit findings (3 CRITICAL ZERO-EXCEPTION + 2 CRITICAL contract-design + 2 BLOCKING structural). The right response was "close the canon gaps" via in-plan folding, not HITL escalation or tier escalation. Iter 4 (operator-authorized override) reached aggregate 91.35 EXEMPLARY through gap closure. Memory: `feedback_iteration_cap_operator_override.md`. Arbiter (Golf)0 DEFERRED canon-promotion of this exception (operational, not constitutional); added to operational doc per Arbiter (Golf)0 verdict.

---

## Step 7: Persist Plan + Frontmatter

Write to `~/.claude/plans/<codename>.md`. Frontmatter per `feedback_plan_frontmatter_convention`:

```yaml
---
project: <project-id>            # inferred from cwd; question tool if ambiguous
codename: <codename>             # from Step 1
status: draft                    # draft | in-progress | promoted | abandoned
phase: phase-0-preflight
lasdlc_template_version: "2.5.1"
validation_status: VALIDATED     # VALIDATED required for /BUILD to accept
review_iterations: N             # final iteration count
northstar_lineage:
  northstar_text: "<from Step 2>"
  pillar_mapping: "P1 | P2 | both | none"   # null for external builds
  build_to_northstar_mapping: "<concrete chain>"
  northstar_metric_delta_estimate: "<delta + measurement plan>"
  northstar_origin:                          # added v2.3.0 — Step 2.6
    trigger: "<proximate cause of this plan: user message, gap from prior build, etc.>"
    origin_citations:
      - source: "<'user message' | 'helix entry: <path>' | 'build: <codename>' | 'canon gap: <ref>'>"
        excerpt: "<verbatim or near-verbatim quote>"
    northstar_coherence_claim: "<why the chosen Northstar follows from this specific trigger>"
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# <codename> — Build Plan

<body: all 21 Blueprint Parts in tier-appropriate detail, including the
review_verdict block from Step 5.2 as a `## Review Verdict` section>
```

Confirm file written, then continue to Step 8.

---

## Step 8: Decision Loop (MANDATORY — question tool, loops until [build] or [plan only])

```ask
questions:
  - question: "Plan VALIDATED and saved. What next?"
    header: "Plan ready"
    multiSelect: false
    options:
      - label: "Build it (Recommended)"
        description: "Invoke /BUILD <codename> — preflight worktree gate, then SQUAD with per-phase /GATE."
      - label: "Squad review (3-round)"
        description: "Run /SCRUM for cross-critique before building. Plan remains status: draft."
      - label: "Edit the plan"
        description: "Revise the plan content. Re-runs Step 5 self-review on the edit."
      - label: "Plan only"
        description: "Stop here. Plan saved. Invoke /BUILD <codename> later when ready."
```

### Branch: Build it → EXIT LOOP

```
Skill: BUILD, args: "<codename>"
```

`/BUILD` reads the plan file, validates `validation_status: VALIDATED`, then proceeds.

### Branch: Squad review → CONTINUE LOOP

```
Skill: SCRUM, args: "<codename> — plan review"
```

After SCRUM returns, **re-run Step 5** to fold the squad findings into a new verdict. If verdict regresses below VALIDATED → return to Step 6 (iteration loop). Else return to Step 8.

### Branch: Edit → CONTINUE LOOP

```ask
questions:
  - question: "What would you like to change in the plan?"
    header: "Edit plan"
    multiSelect: false
    options:
      - label: "Add missing section"
        description: "Add a section that was omitted or inadequately covered."
      - label: "Revise existing content"
        description: "Update existing content based on your review."
      - label: "Fix specific finding"
        description: "Address a specific gap or issue identified in the review."
```

Apply edits → re-run Step 5 → if VALIDATED, update plan file (bump `updated:`, append edit note to verdict block) → return to Step 8.

### Branch: Plan only → EXIT LOOP

Summarize plan + path in conversation. Inform:
```
Plan saved: ~/.claude/plans/<codename>.md (validation_status: VALIDATED)
When ready: /BUILD <codename>
```

---

## Loop Invariants

- Step 6 iteration loop is **bounded** (max 3 + HITL escalation).
- Step 8 decision loop is **unbounded** but every iteration goes through the question tool so user can exit at any time.
- The plan file is **never** written with `validation_status` other than VALIDATED or `draft_residual` (Step 6.1 explicit override path only).

---

## Contract Canon Integration (Cookbook §82)

This skill is governed by `agent.skill.plan` at `standards/canon/contracts/agent.skill/plan.yaml`. The five §82.3 touchpoints:

### Read
At Step 3.5 (Template Snapshot), `/PLAN` additionally reads:
- `standards/canon/contracts/operator.surface/*` — full inventory; if any contract's `ui_locator` or `screen_key` overlaps the target's stack-class scope, it MUST be cited in the plan's `contracts_touched:` frontmatter
- `standards/canon/contracts/agent.skill/*` — to identify whether the plan touches existing slash-skills
- `agent.skill.plan` itself — cross-check own version + inherits_from chain

### Touched-contract citation (new frontmatter requirement)
Add `contracts_touched:` to plan frontmatter:

```yaml
contracts_touched:
  - id: operator.surface.copilot-send-message
    relationship: amends             # amends | extends | implements | references
    expected_alpha_gate_delta: fail→pass
  - id: code.trait.runner
    relationship: implements
    expected_alpha_gate_delta: deferred→pass
```

XEA's Layer 0 check **S0.18** (added 2026-06-04) fails plans that touch contracted surfaces with empty/missing `contracts_touched:`.

### forbidden_behaviors enforcement
At Step 4 (Draft Generation), the `file_function_map` MUST be cross-checked against each touched contract's `forbidden_behaviors[]`. Any plan deliverable that would inherently violate a forbidden behavior is rejected — replace with an alternative deliverable OR amend the contract first via a separate /PLAN cycle.

### required_spans emission
`/PLAN` emits `skill.plan.invoke` (parent_relationship: child_of_caller) with metadata: `target, codename, tier, iterations_used, validation_status, contracts_touched_count`.

### status_per_provider impact
`/PLAN` does not mutate any contract's `status_per_provider`. Only /VERIFY V4 (executed during /BUILD close-out) propagates conformance results back into contracts.

## Graceful Degradation

If Engineer (Alpha) MCP is unavailable for Step 4:

1. **Manual draft**: use Read + Grep + Glob + Context7 for research; author plan body manually against the LASDLC + Blueprint structure.
2. **Manual self-review (Step 5)**: read each canon doc; compute C1–C8 by hand; emit the same `review_verdict` block.
3. **Same iteration loop** (Step 6) applies.

Report: "Engineer (Alpha) unavailable — plan drafted + self-reviewed manually using core tools. Self-review may have lower coverage of A4 (canon scan) — recommend `/SCRUM` before `/BUILD`."

---

## References

- `canon://lasdlc-template` — `$HELIX/user/standards/canon/LASDLC-TEMPLATE-v1.yaml` *(read at Step 3.5; template version locked in frontmatter)*
- `canon://architects-blueprint` — Parts I–XXI, especially Part XIV (C1–C8 rubric) *(Part coverage verified at Step 5.5.2)*
- `canon://platform-canon` — Canon XXX (Strand Mosaic), XXXIV (intervals), XXXV (citation gate), XXXVIII (gate vocabulary), **Canon XLI** (Diagram-First Doctrine — `diagram_present ∧ drift_clean ∧ checklist_current`)
- `canon://industry-baselines/architecture/diagrams/DIAGRAMS` — `$HELIX/user/standards/industry-baselines/architecture/diagrams/DIAGRAMS.md` *(standards compliance: ISO/IEC/IEEE 42010, TOGAF, C4, UML hierarchy — consult at Step 2.5.3)*
- `canon://industry-baselines/architecture/diagrams/diagram-library` — `$HELIX/user/standards/industry-baselines/architecture/diagrams/diagram-library.html` *(tool selection: Mermaid/D2/PlantUML/Likec4/C4-native — consult at Step 2.5.3)*
- `canon://northstar` — `$HELIX/user/standards/canon/northstar.md` (7 Pillars P1–P7, 17 Component Northstars §A–§Q)
- `memory://feedback_gate_phases` — interleave `/GATE` phases between substantive phases
- `memory://feedback_plan_frontmatter_convention` — required frontmatter fields

## Changelog

| Version | Change |
|---------|--------|
| 2.4.0 | Step 2.5.3: Canon XLI (Diagram-First Doctrine) wired — tier table, `diagram_library` selection from `industry-baselines/architecture/diagrams/diagram-library`, `a_gate_predicate` block (`diagram_present ∧ drift_clean ∧ checklist_current`), `diagrams_authored_phase: "1"`. Step 2.5.4: Phase 0 = drift baseline only; Phase 1 = architect-authored diagrams. T6 expanded to four sub-checks. Verdict YAML `t6_diagram_set` → `t6_canon_xli`. Blueprint scan row added for Canon XLI. |
| 2.3.0 | Step 2.6: `northstar_origin` capture (trigger + origin_citations + coherence_claim). Step 3.5: template snapshot before draft. Step 4: draft-as-filled-copy discipline. Step 5.5: template/Blueprint structural evaluation (T1–T9 + Blueprint Part scan + origin coherence). Step 6: iteration gate requires BOTH XEA PASS AND Step 5.5 PASS. |
| 2.2.0 | Stack classification elicitation (Step 2.5), diagram set planning. |
| 2.1.0 | Operator-authorized iteration cap override (Step 6.2). |
| 2.0.0 | XEA delegation (Step 5), SCRUM integration (Step 6.1, Step 8). |
