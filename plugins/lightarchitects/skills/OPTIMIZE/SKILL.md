---
name: OPTIMIZE
description: "Universal optimization pipeline via SQUAD. Classifies target into 6 types,
  routes algorithmic targets to SHARPEN for formal verification, delegates all others to
  SQUAD solo → code_review. Use when the user says '/optimize', 'make this faster',
  'optimize this', 'reduce dependencies', 'reduce complexity', 'simplify this module'."
user-invocable: true
version: 2.0.0
context: root
---

# /OPTIMIZE — Universal Optimization Pipeline

> Thin wrapper: 6-type classification + SHARPEN routing → SQUAD solo → code_review.
> Budget: ~800 words total (classification is load-bearing, gets extra budget vs. standard 600).

## When to Use

- User wants to improve existing code, deps, structure, or performance
- User says `/optimize`, "make this faster", "optimize", "improve", "simplify"
- After an OBSERVE reveals performance issues
- Before a DEPLOY to ensure the code is as efficient as practical

## Accepted Flags

| Flag | Expansion | Effect |
|------|-----------|--------|
| `--research` | Prepend research phase | `research → solo → code_review` |

Rejected flags: `--then`, `--watch`, `--drain`, `--fix`.

## Step 1: Argument Validation (SAFEGUARD #24)

Validate the target: `^[a-zA-Z0-9_/. -]+$`. Reject SQUAD control flags and shell metacharacters. See SAFEGUARD #24 in `references/meta-skills.md`.

On unrecognized flag:
```
ERROR: /OPTIMIZE does not accept {flag}.
Recognized flags for /OPTIMIZE: --research
For raw pipeline control, use /SQUAD directly.
```

## Step 2: Target Classification (6 types)

Classify the optimization target before routing. Read the target file/module to determine which type applies:

| Type | Characteristics | Examples | Routing |
|------|-----------------|---------|---------|
| **1. Algorithmic** | Sort, search, hash, numerical, compression, math | BM25 scoring, RRF weighting, quantization, HMAC | → `/SHARPEN` (formal verification) |
| **2. Architectural** | Module structure, dependency graph, abstraction boundaries | Dead code, crate split, service boundaries | → SQUAD solo (architectural lens) |
| **3. Performance** | Latency, throughput, VRAM, allocations, hot paths | Slow queries, memory leaks, allocation overhead | → SQUAD solo (profiling lens) |
| **4. Dependency** | Crate count, version freshness, unused deps, license | `Cargo.toml` bloat, unused imports, stale versions | → SQUAD solo (dependency audit lens) |
| **5. Build pipeline** | CI time, compile time, incremental builds, cache | Slow CI, large artifacts, missing caching | → SQUAD solo (devops lens) |
| **6. Code quality** | Complexity, duplication, naming, pattern violations | Cyclomatic complexity > 10, copy-paste, long functions | → SQUAD solo (quality lens) |

**Multiple types**: If the target spans multiple types, classify by the dominant characteristic. If genuinely ambiguous, ask the user.

## Step 3: Type 1 Routing — SHARPEN (Algorithmic targets)

**For algorithmic / mathematical code (Type 1)**: Stop here. Route to `/SHARPEN`:

```
Algorithmic optimization detected (Type 1).
Routing to /SHARPEN for formal verification — proving the optimization is correct,
not just benchmarking it.

/SHARPEN "<target>"
```

SHARPEN uses Leanstral formal verification to **prove** correctness. Budget: 800 words total for this optimization session (vs. the standard 600 for SQUAD engagements). Do NOT route Type 1 targets through SQUAD solo.

## Step 4: HITL Gate — Write-Path Disclosure (SAFEGUARD #21)

For Types 2–6, before invoking SQUAD:

```
SQUAD: solo → code_review [type: {classification}]
       [research → solo → code_review  ← if --research]
Agents: ~3–5 | Estimated tokens: ~30–55K
WRITES CODE: solo phase will create branches for approved optimizations.
  - Branch pattern: squad/solo/{agent-name}
  - Merge strategy: sequential with quality gates
  - Rollback: automatic on gate failure
Proceed? [y/N]
```

## Step 5: SQUAD Invocation

Include the classification type in the target description so agents apply the right lens:

**Standard optimize:**
```
/SQUAD solo "<target> [type: {classification}]" --then code_review
```

**With --research flag:**
```
/SQUAD research "<target>" --then solo "<target> [type: {classification}]" --then code_review
```

SQUAD agents in the `solo` preset run Engineer:Scan (static analysis) + CHASE (performance profiling) + Monitor (Foxtrot) metrics + Analyst (Delta) research in the appropriate combination for the classified type. Full cycle instructions are in `references/presets.md`.

## Contract Canon Integration (Cookbook §82)

Governed by `agent.skill.optimize`. Respects contract latency budgets — `operator.surface.observability.first_token_budget_ms` and `duration_budget_ms` are the **floor**, not the target. Optimization that breaks a contract budget without an amendment = `E_OPTIMIZE_BUDGET_VIOLATION` BLOCKING. Reads contract budgets at Step 0; each proposal includes per-touched-contract impact analysis. Emits `skill.optimize.invoke` span with `contract_impact_count`. Contract amendment is a separate /PLAN cycle, not an inline optimization decision.

## Graceful Degradation

If SQUAD is unavailable, invoke Engineer (Alpha) directly based on classification:

| Type | Fallback action |
|------|----------------|
| 2. Architectural | `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "corso"` action:`code_review` |
| 3. Performance | `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "corso"` action:`chase` |
| 4. Dependency | `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "corso"` action:`guard` |
| 5. Build pipeline | `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "corso"` action:`code_review` |
| 6. Code quality | `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "corso"` action:`code_review` |

Skip code_review phase. Report: "Running Engineer (Alpha)-only optimization."
