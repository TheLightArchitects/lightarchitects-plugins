# Symbolic Verification Integration

## When CODE-VERIFY Invokes /VERIFY

During the `/CODE-VERIFY` pipeline, after Analyst (Delta) (logic) and Engineer (Alpha) (quality)
complete their reviews, the orchestrator checks if any target files contain
formal specification annotations:

```
// REQUIRES: ...
// ENSURES: ...
// INVARIANT: ...
```

If annotations are found, `/VERIFY` is invoked as a third verification layer.

## Pipeline Position

```
/CODE-VERIFY
  ├── Analyst (Delta) (logic evidence chain)     ← parallel
  ├── Engineer (Alpha) (security + quality)         ← parallel
  └── /VERIFY (formal proofs)            ← sequential, after both critics
```

`/VERIFY` runs AFTER the critics because:
1. No point proving correctness of code that fails quality/security gates
2. Lean 4 proof search is expensive — only run on code that passed review
3. Counterexamples from proofs are highest-confidence findings

## Verdict Integration

The `/CODE-VERIFY` unified verdict incorporates `/VERIFY` results:

| Analyst (Delta) | Engineer (Alpha) | /VERIFY | Final Verdict |
|---------|-------|---------|---------------|
| PASS | PASS | PROVEN | PASS |
| PASS | PASS | UNPROVEN | FAIL (formal counterexample) |
| PASS | PASS | WARN/SKIP | PASS (no formal guarantee) |
| FAIL | any | any | FAIL (logic) |
| any | FAIL | any | FAIL (quality/security) |

## When to Skip

`/VERIFY` is skipped when:
- No annotated functions found in the target
- Lean 4 is not installed (WARN logged, not FAIL)
- The `prove` gateway action is unavailable
- The target is documentation, config, or non-code files

## Annotation Guide

To opt a function into formal verification, add specification comments:

```rust
// REQUIRES: key.len() >= 32 && data.len() > 0
// ENSURES: result.is_ok() implies hmac_verify(result.unwrap(), key, data)
fn sign(key: &[u8], data: &[u8]) -> Result<Vec<u8>, CryptoError> {
    // ...
}
```

The Oracle module translates these into Lean 4 proof obligations automatically.
Not every function needs this — reserve for correctness-critical paths:
- Authentication / authorization logic
- Cryptographic operations
- Financial calculations
- Safety-critical state machines
