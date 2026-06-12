---
name: VERIFY
description: "Formal verification via Lean 4 / Oracle. Routes functions with pre/postconditions through mathematical proof verification. Selective — only for correctness-critical paths. Proof failures surface as alpha gate blocks with formal counterexamples. Use when code has REQUIRES/ENSURES/INVARIANT annotations."
user-invocable: true
version: 1.0.0
context: fork
agent: orchestrator
model: inherit
color: cyan
tools:
  - Read
  - Glob
  - Grep
  - Bash
  - mcp__plugin_lightarchitects_lightarchitects__tools
---

# /VERIFY — Formal Verification via Oracle

> Selective formal proof of correctness for annotated functions.
> Routes through Engineer (Alpha) `prove` action → Oracle module → Lean 4 backend.

## When to Use

- Functions with `// REQUIRES:`, `// ENSURES:`, `// INVARIANT:` annotations
- Correctness-critical paths (auth, crypto, financial, safety)
- After code generation, before commit — as an alpha gate supplement
- Manually via `/VERIFY <target>` or automatically via `/CODE-VERIFY`

## Process

### Step 1: Target Resolution

Accept one of:
- File path: `/VERIFY src/lib/auth.rs`
- Function name: `/VERIFY validate_token`
- Directory: `/VERIFY src/crypto/`
- Keyword: `/VERIFY all` — scan entire project for annotated functions

### Step 2: Annotation Scan

Search target files for formal specification annotations:

```
// REQUIRES: input.len() > 0
// ENSURES: result.is_ok() implies output.len() == input.len()
// INVARIANT: self.balance >= 0
```

Also recognize:
- Rust `#[requires(...)]` / `#[ensures(...)]` attributes (contracts crate)
- Doc comments with `# Safety`, `# Panics`, `# Errors` sections (informal but scannable)
- `// SAFETY:` comments on unsafe blocks

Collect all annotated functions with their specifications.

### Step 3: Proof Obligation Generation

For each annotated function, invoke the CORSO `prove` action:

```
mcp__plugin_lightarchitects_lightarchitects__tools
  action: "prove"
  params: {
    target: "<file_path>",
    function: "<function_name>",
    requires: "<precondition>",
    ensures: "<postcondition>",
    invariants: ["<invariant1>", "<invariant2>"]
  }
```

The `prove` action routes through the gateway to Engineer (Alpha), which invokes the
Oracle module. The Oracle module:
1. Translates the Rust/TS function + annotations into a Lean 4 proof obligation
2. Invokes `lake build` to attempt the proof
3. Returns: PROVEN / UNPROVEN / TIMEOUT / ERROR with details

### Step 4: Verdict

| Oracle Result | Verdict | Action |
|---|---|---|
| PROVEN | PASS (green) | Function is formally verified. **Confidence ≥95%** (Canon XXXV). |
| UNPROVEN | FAIL (red) | Alpha gate block — counterexample provided. **Confidence: DEFINITIVE**. |
| TIMEOUT | WARN (amber) | Proof search exceeded time budget — manual review needed. **Confidence: LOW**. |
| ERROR | WARN (amber) | Lean 4 not installed or translation failed — skip gracefully. **Confidence: N/A**. |

**Confidence Threshold Gate** (Canon XXXV): Confidence applies to the *translation layer*
(Rust/TS → Lean 4 proof obligation), not the mathematical proof itself.
- PROVEN: Mathematical certainty (100%) — the proof succeeded
- UNPROVEN: Counterexample is DEFINITIVE (1.00) — the proof failed concretely
- TIMEOUT/ERROR: Translation or toolchain failure — confidence N/A

Format: `confidence: 0.XX (GRADE)` applies only to TIMEOUT/ERROR verdicts where the
translation layer's correctness is uncertain. Evidence chain required for all verdicts.

### Step 5: Report

```
## Formal Verification Report

### PROVEN (2 functions)
  src/crypto/hmac.rs:42  verify_signature
    REQUIRES: key.len() >= 32
    ENSURES: result == expected_mac
    Status: PROVEN in 1.2s

### UNPROVEN (1 function)
  src/auth/validate.rs:18  validate_token
    REQUIRES: token.len() > 0
    ENSURES: result.is_ok() implies claims.exp > now()
    Status: UNPROVEN — counterexample: token with exp=0 passes validation
    ALPHA GATE: BLOCKED

### SKIPPED (0 functions)

Verdict: FAIL (1 unproven obligation)
```

## Contract Canon Integration (Cookbook §82)

This skill is governed by `agent.skill.verify` at `standards/canon/contracts/agent.skill/verify.yaml`. The five §82.3 touchpoints:

### Read
- `standards/canon/contracts/operator.surface/*` — to extract conformance_test blocks for V4
- `standards/canon/contracts/code.trait/*` — to extract method-contract postconditions for assertion mapping

### Touched-contract citation
V4 emits a per-contract pass/fail record into the test pyramid report: `contracts_verified[<id>] = pass | fail | not_applicable`.

### forbidden_behaviors enforcement
Not enforced at /VERIFY — covered by /BUILD per-wave S5 + /GATE pre-merge S5.

### required_spans emission
`/VERIFY` emits `skill.verify.invoke` (parent_relationship: child_of_caller) with metadata: `scope, tests_run, tests_passed, tests_failed, coverage_pct, contract_gate_clean`.

### status_per_provider impact (BIG)
V4 IS the surface that updates contract `status_per_provider`. When a conformance_test passes for provider P against contract C, V4 writes:

```yaml
# in standards/canon/contracts/operator.surface/<C>.yaml
status_per_provider:
  <P>:
    result: PASS
    evidence_tier: VERIFIED
    last_verified: <ISO8601>
    evidence_path: target/test-evidence/<run_id>/
```

Then re-runs `make contract-gate` to confirm the corpus still validates. This is the **only** skill that mutates contracts via the conformance path; all other skills read-only.

### V4 — operator.surface conformance test execution (new dimension)

For each contract with a `conformance_test:` block touching the diff scope:

1. Resolve `given:` precondition (env vars, fixture files)
2. Execute `when:` action (via /webshell HTTP probe / cargo test target / playwright spec)
3. Verify each `then[].assertion` — span_witness via Monitor (Foxtrot), filesystem_witness via Read
4. Record evidence_tier per assertion
5. Update `status_per_provider.<provider>.result` if all assertions VERIFIED
6. Re-run make contract-gate to confirm post-mutation corpus integrity

V4 failures route via Gatekeeper Registry [T] dimension.

## Graceful Degradation

If Lean 4 is not installed (`lean` / `lake` not on PATH):
- Report: "Lean 4 not installed — formal verification skipped"
- Verdict: WARN (not FAIL)
- List annotated functions found but not verified
- Suggest: `elan install` to set up Lean 4 toolchain

If the Oracle module / `prove` action is unavailable:
- Fall back to annotation scan only
- Report which functions have formal specs but couldn't be verified
- Verdict: WARN

## Integration

- `/CODE-VERIFY` automatically invokes `/VERIFY` when annotated functions are detected
- Engineer (Alpha) alpha agent checks `/VERIFY` results at phase gates
- Supervisor alerts surface UNPROVEN findings with counterexamples in the webshell
