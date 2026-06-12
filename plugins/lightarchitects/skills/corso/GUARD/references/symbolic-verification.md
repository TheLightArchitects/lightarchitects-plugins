# Symbolic Verification — GUARD Integration

## Purpose

Formal proof of correctness for functions with pre/postcondition annotations.
Uses the Engineer (Alpha) `prove` gateway action → Oracle module → Lean 4 backend.

This is the highest-confidence verification layer — a successful proof is a
mathematical guarantee, not a probabilistic assessment.

## When to Invoke

- **Automatically**: during `/CODE-VERIFY` when annotated functions are detected
- **Manually**: via `/VERIFY <target>`
- **In GUARD phase**: when the build target contains `// REQUIRES:` / `// ENSURES:` annotations

## Annotation Format

```rust
// REQUIRES: precondition expression
// ENSURES: postcondition expression
// INVARIANT: loop/struct invariant expression
```

Expressions use the source language's syntax. The Oracle module translates to Lean 4.

## Gateway Action

```
action: "prove"
agent: "corso"
params: {
  target: "src/crypto/hmac.rs",
  function: "verify_signature",
  requires: "key.len() >= 32",
  ensures: "result == expected_mac"
}
```

## Output

| Result | Meaning | GUARD Action |
|--------|---------|-------------|
| PROVEN | Mathematical proof found | PASS — log proof witness |
| UNPROVEN | No proof found, counterexample generated | FAIL — alpha gate block |
| TIMEOUT | Proof search exceeded budget (default 60s) | WARN — manual review |
| ERROR | Lean 4 unavailable or translation failed | WARN — skip gracefully |

## Alpha Gate Integration

When `/VERIFY` produces UNPROVEN results:
- Engineer (Alpha) alpha treats it as a FAIL condition
- The counterexample is included in the gate block message
- Supervisor alerts render it in the webshell Activity panel
- The finding format matches the standard SupervisorAlert schema:
  ```json
  {
    "gate": "alpha",
    "verdict": "FAIL",
    "message": "VERIFY: UNPROVEN — validate_token (src/auth/validate.rs:18)",
    "details": "Counterexample: token with exp=0 passes validation"
  }
  ```

## Dependencies

- **Lean 4**: `lean` and `lake` on PATH (install via `elan`)
- **Oracle module**: `lightarchitects/src/oracle/` in the SDK
- If either is missing, verification degrades to WARN (not FAIL)

## Selective Application

Not every function needs formal verification. Reserve for:
- **Authentication**: token validation, permission checks
- **Cryptography**: HMAC, encryption, key derivation
- **Financial**: balance calculations, transaction processing
- **Safety**: unsafe blocks, FFI boundaries, state machines
- **Invariants**: data structure consistency, protocol compliance

The cost of a Lean 4 proof search is 5-60s per function. Only annotate paths
where a formal guarantee justifies the verification budget.
