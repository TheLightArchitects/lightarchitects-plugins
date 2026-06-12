---
name: GATE
description: "Pre-merge and per-phase quality gate. Runs V0→Q→S→I→N→D→V (merge scope) or
  Q1–Q4+D2 (phase scope). Reads plan frontmatter, evaluates against all 7 canon documents,
  delegates to domain agents, emits GATE_REVIEW JSONL + .gate-evals/ artifact. Use when a
  branch is ready to merge, after each LASDLC phase boundary, or when BUILD delegates
  per-phase gating."
user-invocable: true
version: 1.0.0
context: root
---

# /GATE — Pre-Merge and Phase Quality Gate

> Read the plan. Read the canon. Run the sequence. Emit structured results.

## Scope Modes

| Flag | Gates run | When used |
|------|-----------|-----------|
| `--scope merge` | V0 → Q → S → I → N → D → V (full) | Pre-merge; default when invoked manually |
| `--scope phase` | Q1–Q4 + D2 only | Per Agents Playbook §15.9: phase-boundary gate inside BUILD |

If `--scope` is omitted, default to `merge`.

## Canon (read before running any gate)

All evaluation is against the authoritative documents. Read the current file — do not evaluate from memory.

| Document | Path | Governs |
|---|---|---|
| Platform Canon | `$HELIX/user/standards/canon/platform-canon.md` | Constitutional principles, strand mosaic |
| Builders Cookbook | `$HELIX/user/standards/canon/builders-cookbook.md` | All coding standards |
| Agents Playbook | `$HELIX/user/standards/canon/agents-playbook.md` | Agent patterns, test pyramid, A2A protocol |
| Architects Blueprint | `$HELIX/user/standards/canon/architects-blueprint.md` | Plan compliance, C1-C8 scoring |
| Operators Manual | `$HELIX/user/standards/canon/operators-manual.md` | Operational surface changes |
| Security Guardrails | `$HELIX/user/standards/canon/security-guardrails.md` | Full adversarial lens |
| LASDLC Template | `$HELIX/user/standards/canon/LASDLC-TEMPLATE-v1.yaml` | Plan schema, phase/gate structure |
| Gatekeeper Registry | `$HELIX/user/standards/canon/gatekeeper-registry.yaml` | Finding → sibling ownership routing |

---

## Step 0 — Read the Plan

Locate the build plan:

```
~/.claude/plans/<codename>.md          # primary location (PLAN output)
$HELIX/corso/builds/<codename>/plan.md # promoted location
```

Read frontmatter. Extract and hold:

| Field | Required | Used by |
|---|---|---|
| `validation_status` | Yes | Step 0 block condition |
| `lasdlc_template_version` | Yes | Schema version check |
| `northstar_lineage.northstar_text` | Yes | N gate evaluation |
| `northstar_lineage.pillar_mapping` | Yes | N gate routing |
| `northstar_lineage.build_to_northstar_mapping` | Yes | N2 concreteness check |
| `status` | Yes | Step 0 block condition |
| `project` | No | Report header |
| `codename` | No | Artifact path |

**Block conditions:**

```
if plan not found:
    HALT — "No plan found for this branch. Run /PLAN <target> to author one."

if validation_status != "VALIDATED" and != "draft_residual":
    HALT — "Plan validation_status=<status>. Gates require a VALIDATED plan.
             Run /PLAN <codename> to complete the review loop."

if validation_status == "draft_residual":
    invoke question tool — see draft_residual waiver checkpoint below

if status == "draft":
    HALT — "Plan status=draft. Gates run on in-progress or promoted plans only."

if lasdlc_template_version != "2.5.1":
    WARN — "Plan schema version mismatch: expected 2.5.1, got <version>.
             Some gate checks may not apply correctly."
```

```ask
questions:
  - question: "Plan has residual gaps (draft_residual). Gate anyway with explicit waiver?"
    header: "Plan waiver"
    multiSelect: false
    options:
      - label: "Gate with waiver (logged)"
        description: "Proceed with gate. Residual gaps logged to audit/gate-overrides."
      - label: "Remediate via /PLAN"
        description: "Return to /PLAN to fix the residual gaps first."
      - label: "Cancel"
        description: "Abort the gate run."
```

If `--scope phase` and no plan is found: continue without plan context (phase gates are
BUILD-internal and the plan has already been validated at build start).

---

## V0 — Primary Worktree Isolation (`--scope merge` only)

```bash
git -C <project-root> branch --show-current
```

If result ≠ `main`: **HARD STOP**. Surface HITL:

> "Primary worktree is on '<branch>', not 'main'. GATE cannot proceed.
> Restore: `git checkout main`
> Then create a gate worktree: `git worktree add ~/lightarchitects/worktrees/<codename> <branch>`
> Re-run /GATE from there."

All subsequent gates run inside the gate worktree, not the primary.

**Worktree prerequisite — frontend build:** if the diff touches any `*-ui/` directory,
build the frontend before running Q2 clippy. RustEmbed proc macros require `dist/` to
exist at compile time; the failure manifests as a proc-macro error, not a missing-file error.

```bash
pnpm --dir <worktree>/<ui-dir> install --frozen-lockfile
pnpm --dir <worktree>/<ui-dir> build
```

---

## Q — Quality

Read Builders Cookbook before evaluating. Apply to the diff.

```bash
cargo fmt --all -- --check                                             # Q1
cargo clippy --workspace --all-targets --all-features -- -D warnings   # Q2
cargo test --workspace --all-features                                   # Q3
pnpm test:run && pnpm exec svelte-check --threshold error               # Q4 (if UI surface)
cargo run --release -p contract-gate -- \
    --schema standards/canon/la-contracts.schema.json \
    --contracts-dir standards/canon/contracts                          # Q5 (Cookbook §82.4)
```

**Flakiness protocol (Q3 only):** if a test fails in `--workspace` but passes when run in
isolation (`cargo test -p <crate> <test>`), it is a pre-existing parallel race condition —
not a regression introduced by this branch. Note in report as `FLAKY (pre-existing)`.
Do not block the gate. A flake in new test code written by this branch is a blocker.

**Q5 contract-gate** (Cookbook §82.4) is **non-waivable in-skill**. Both passes must come
back clean:
1. **Schema** — every `standards/canon/contracts/**/*.yaml` validates against v1.2 schema
2. **Symmetric-edge sweep** — `mcp.capability ↔ wire.mcp` cross-references reciprocate

Q5 failure halts the gate verdict at FAIL and routes the diff to the operator. Waivers only
flow through the gatekeeper waiver flow at the operator level.

**Q-gate verdict:** `PASS` if Q1–Q3 + Q5 clean (Q4 if UI surface). Documented pre-existing
flakes do not block; Q5 failures always block.

---

## S — Security (`--scope merge` only)

Read Security Guardrails before evaluating. Apply to the diff.

**S1 — Threat model:**

Spawn the security domain agent to assess the diff:

```
Agent(
  subagent_type: "lightarchitects:security"
  model: "sonnet"
  prompt: "Threat model the following branch diff against Security Guardrails canon.
           Enumerate new trust boundaries, input vectors, data flows, and secrets exposure.
           Branch: <branch>. Diff summary: <summary of changed files>.
           Report findings with severity. Apply the full adversarial lens from
           $HELIX/user/standards/canon/security-guardrails.md."
)
```

The security agent handles Sentinel (Echo) availability, pre-flight Knowledge (Charlie) helix search for prior
findings, Analyst (Delta) CVE pre-scan, and industry baselines internally. No need to orchestrate
those separately.

**Two patterns not yet in Security Guardrails canon (include until promoted):**

1. `!Send` across `.await` in async handlers — any `async fn` that holds a `!Send` type
   (`tracing::span::EnteredSpan`, `MutexGuard`, `Rc<T>`) past an `.await` point silently
   breaks `axum::handler::Handler<_, _>`. The error appears at the call site, not the source.
   Grep new async handler code for `.entered()` and lock guards held across `.await`.

2. DashMap iteration + mutation deadlock — iterating a `DashMap` while holding a shard
   reference and then calling `.remove()` or a blocking send deadlocks. Collect keys to
   `Vec` first, then mutate in a separate pass.

**S2 — Supply chain:**
```bash
cargo deny check
```

**S3 — Canon gate (Arbiter (Golf)):**

Required if the diff introduces new cryptographic primitives, auth flows, or permission
surfaces. When required:

```
mcp__plugin_lightarchitects_lightarchitects__tools
  sibling: "laex"
  action: "reflect"
  spec: "<description of the new surface>"
```

If Arbiter (Golf) MCP unavailable and S3 is required: **block**. Surface to the operator — no waiver.

**S5 — Contract-canon forbidden_behaviors compliance (Cookbook §82.1):**

Read every `operator.surface/*.yaml` whose `ui_locator` or `screen_key` overlaps the diff
scope. For each touched contract, scan the diff against the entries in `forbidden_behaviors[]`.

```bash
# Inventory touched operator surfaces
for f in standards/canon/contracts/operator.surface/*.yaml; do
  surface=$(yq -r '.operator_surface.screen_key // empty' "$f")
  ui_locator=$(yq -r '.operator_surface.ui_locator' "$f")
  # Match against diff via grep for ui_locator components + screen_key
done
```

Any match against a `forbidden_behaviors[]` entry → `E_GATE_FORBIDDEN_BEHAVIOR` with the
contract id + entry index. Routing: BLOCKING per Gatekeeper Registry [S] dimension.

**S-gate verdict:** `PASS` if S1 clean + S2 pass + S3 pass (or S3 not triggered) + S5 clean.
Any finding the Gatekeeper Registry classifies as HIGH or CRITICAL: surface to operator
immediately before continuing.

---

## I — Integration (`--scope merge` only)

```bash
git fetch github main
git log --oneline github/main..HEAD   # commits ahead
cargo build --workspace --all-features
```

If `github/main` has moved ahead of the branch base: rebase, re-run Q, then continue.

**I-gate verdict:** `PASS` if clean descendant of `github/main` + build passes.

---

## N — Northstar (`--scope merge` only)

Read `northstar_lineage` from the plan extracted in Step 0.

**N1 — Lineage present and non-empty:**
- `northstar_text` exists and is not a placeholder
- `build_to_northstar_mapping` exists and contains at least one concrete step
- `pillar_mapping` is set (any value other than absent is acceptable; "none" is a flag but
  not a blocker — some valid builds don't advance a platform pillar)

**N2 — Chain is concrete, not aspirational:**

Evaluate `northstar_text` + `build_to_northstar_mapping` from the plan. The test is
platform-agnostic: does the diff demonstrably close the gap the chain describes, or does
it only move toward it?

- Concrete: "mockStream removal → operators see real copilot output" — the diff removes
  the mock. The connection is direct and verifiable.
- Aspirational: "this lays the groundwork for operators to eventually..." — no direct
  connection to the diff. Flag as N2 FAIL.

The specific pillar names (P1/P2 for LA platform builds, or custom names for external
projects) are read from `pillar_mapping` and used for report labelling only. N2 judgment
is against the chain itself, not a hardcoded pillar definition.

**N3 — No open exclusion zones:**

Read the plan body for any declared exclusion zone flags. Standard ones to look for:
`first_of_kind`, `security_compliance_pre_laex`, `irreversible_production_op`. If present
and unresolved, flag to operator before proceeding.

**N-gate verdict:** `PASS` if N1 (fields present + non-empty) + N2 (chain concrete) +
N3 (no open exclusion zones).

---

## D — Documentation

Spawn the knowledge domain agent for D1:

```
Agent(
  subagent_type: "lightarchitects:knowledge"
  model: "sonnet"
  prompt: "Run DOC-AUDIT on the changed files in branch <branch>.
           Scan all new public items (Rust: pub fn/struct/enum/const/type,
           TS/Svelte: exported functions and components) for missing doc comments.
           Report gaps by file. Path: <worktree path>."
)
```

**D2** — Plan reflects actual scope. If waves were added or deliverables deferred, the
plan's phase log should say so. Read the plan body.

**D3** — CLAUDE.md current if the branch introduces new tooling, commands, or architecture
patterns the next engineer needs to know.

**D-gate verdict:** D1 hard (knowledge agent enforces). D2/D3 soft-fail with explicit note.

---

## V — Verification

Read Agents Playbook (Canon XXVII, 6-suite pyramid) before evaluating.

**V1 — Test pyramid audit:**

```
Agent(
  subagent_type: "lightarchitects:testing"
  model: "haiku"
  prompt: "Run PYRAMID-AUDIT on the changes in branch <branch>.
           Identify which of the 6 Canon XXVII suites (unit/integration/property/
           E2E/regression/smoke) cover the new behaviour. Flag missing suites.
           Worktree: <path>."
)
```

**V2 — Binary smoke:**

```bash
cargo build --release -p <affected-crate>
```

**V3 — Playwright E2E** (if new operator-facing UI surface):

```
Agent(
  subagent_type: "lightarchitects:testing"
  model: "sonnet"
  prompt: "Run Playwright E2E (headless: false always) on the affected webshell surfaces
           in branch <branch>. Dev server at <url>. Test the golden path for <feature>.
           Report pass/fail with screenshot evidence."
)
```

If the surface depends on infrastructure not yet wired (stub-only backend path), defer V3
with an explicit waiver: state the condition that unblocks it and the target sprint.

**V-gate verdict:** V1 + V2 required. V3 required unless explicit waiver with named
unblocking condition.

---

## Step N — Write Artifacts

After all gates complete, write two artifacts:

**1. Gate eval YAML** (per Agents Playbook §15.9, line 1300):

```
<build_root>/.gate-evals/<phase-id>-merge.yaml   # merge scope
<build_root>/.gate-evals/<phase-id>-phase.yaml   # phase scope
```

Fields: `schema_version: 1`, `gate: merge|phase`, `scored_by: "/GATE"`,
`scored_at: <ISO-8601>`, `build_id: <codename>`, `phase_id: <from --phase flag or "merge">`,
`overall_verdict: pass|fail|blocked`, `dimensions: {...}`.

**2. GATE_REVIEW JSONL** (Agents Playbook §7.4 — required when invoked by BUILD):

```jsonl
{"v":1,"type":"GATE_REVIEW","build_codename":"<codename>","scope":"merge|phase","timestamp":"<ISO-8601>","confidence":<0.0-1.0>,"verdict":"accept|reject|hitl","payload":{"dimensions":{"Q1_fmt":"pass|fail","Q2_clippy":"pass|fail","Q3_tests":{"result":"pass|fail","tests_run":<n>,"tests_fail":<n>},"Q4_svelte":"pass|fail|n/a","S1_security":{"result":"pass|fail","findings":[]},"S2_supply_chain":"pass|fail","S3_laex":"pass|fail|n/a","I1_rebase":"pass|fail|n/a","N1_northstar":{"result":"pass|fail","pillar":"<pillar_mapping value>"},"N2_chain":"pass|fail","D1_docs":"pass|fail","D2_plan":"pass|fail","V1_pyramid":"pass|fail","V2_smoke":"pass|fail","V3_e2e":"pass|fail|deferred:<condition>"},"summary":"<one sentence>"}}
```

Emit this to stdout as a JSONL line so the BUILD Governor can consume it.

---

## Output Format (human-readable report)

```
GATE REPORT — <branch> @ <sha>  [scope: merge|phase]

V0 Primary-on-main:  ✅/❌  (<detail>)
Q  Quality:          ✅/❌  (Q1 fmt ✅ Q2 clippy ✅ Q3 tests ✅ <n> pass Q4 svelte ✅)
S  Security:         ✅/❌  (S1 <agent verdict> S2 deny ✅ S3 <pass|n/a|blocked>)
I  Integration:      ✅/❌  (<n> commits ahead, rebase <clean|needed>, build ✅)
N  Northstar:        ✅/❌  (chain <concrete|aspirational>, pillar <pillar_mapping value>)
D  Documentation:    ✅/❌  (D1 <gaps|clean> D2 plan <current|stale> D3 CLAUDE.md <current|stale>)
V  Verification:     ✅/❌  (V1 pyramid <suites> V2 smoke ✅ V3 <pass|deferred: <condition>>)

Verdict: ALL PASS — ready for merge
      or: BLOCKED — <gate>: <specific failure>. Re-run /GATE after fix.
```

Route any finding to the sibling owner per the Gatekeeper Registry. Do not leave findings
unowned.

---

## Contract Canon Integration (Cookbook §82)

This skill is governed by `agent.skill.gate` at `standards/canon/contracts/agent.skill/gate.yaml`. The five §82.3 touchpoints:

### Read
At Step 0 (Read the Plan), `/GATE` reads:
- `standards/canon/contracts/operator.surface/*` — full corpus, scoped to surfaces overlapping the diff at S5
- `standards/canon/contracts/agent.skill/gate` — this skill's own contract; cross-verified at startup
- Plan frontmatter `contracts_touched:` — used to propagate into `GATE_REVIEW` JSONL payload

### Touched-contract citation
The `GATE_REVIEW` JSONL emitted at Step N has a new `payload.contracts_touched[]` field carrying every contract id from the plan's frontmatter. Pre-merge gate verifies the field is non-empty when the diff touches contracted surfaces.

### forbidden_behaviors enforcement
S5 (above) — grep each touched contract's `forbidden_behaviors[]` against the diff. Routing: BLOCKING per Gatekeeper Registry [S] dimension.

### required_spans emission
This skill emits `skill.gate.invoke` (parent_relationship: child_of_caller) with metadata: `scope, phase_id, codename, overall_verdict, dimensions_passed, dimensions_failed`.

### status_per_provider impact
`/GATE` does not mutate `status_per_provider` — V4 (executed by /VERIFY sub-skill) is the surface that updates verdicts based on conformance_test results.

## Graceful Degradation

| Condition | Action |
|---|---|
| Sentinel (Echo) MCP unavailable | Security agent handles internally; note `S1: MANUAL` if it falls back |
| Arbiter (Golf) MCP unavailable + S3 triggered | Block. Escalate to the operator — no waiver |
| Plan not found (`--scope phase`) | Continue without plan context; skip N gate |
| `validation_status: draft_residual` | question tool before proceeding (see waiver checkpoint above) |
| No UI surface | Skip Q4 and V3; mark as `n/a` in dimensions |
