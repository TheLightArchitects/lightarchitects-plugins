---
name: CHOW
description: "Code & Architecture analysis domain. Coding standards, quality metrics, code
  smell detection, architecture style matching, and language-specific patterns. C0RS0
  executes with corsoTools action chow."
user-invocable: false
context: fork
agent: C0RS0
version: 5.0.0
---

# /CHOW — Code & Architecture Domain

> Build Phase 4/7: REVIEW — Post-implementation code analysis and quality review

## Lifecycle Context

Follows **HUNT** (implementation complete) -> feeds into **GUARD** (security scan on detected patterns).

The primary coding and architecture **analysis** entry point for C0RS0. Loads Light Architects coding standards, architecture analysis, quality enforcement, and code smell detection context into C0RS0, which then executes reviews using the chow MCP tool.

> **Note**: Code generation (`corsoTools` action: `hunt`) is handled by HUNT during plan execution.
> CHOW provides the quality standards and patterns that HUNT enforces when generating code.

```
Claude -> loads CHOW context -> C0RS0 executes with chow tool
```

---

## Protocol

### Step 1: Gather Requirements (if spec is vague)

1. Gather coding-specific requirements:
   - What to build/fix/refactor/review?
   - Which project/files/modules?
   - Language, framework, dependencies?
   - Architecture goals? Pain points?
   - Acceptance criteria?
2. Synthesize into a clear specification
3. Present spec for confirmation

### Step 1.5: Plugin Enrichment (Mandatory)

Before code review, query external plugins for pattern verification and AI-augmented review. Run both in parallel when available.

1. **Context7 Pattern Reference**: Query for current framework patterns relevant to the changed code.
   - Call `mcp__plugin_context7_context7__resolve-library-id` with the primary framework/library
   - Call `mcp__plugin_context7_context7__query-docs` with the resolved ID and a query targeting the specific API surface under review
   - Use Context7 results to verify that code patterns match current library best practices (not outdated idioms)

2. **Coderabbit AI Review**: Run coderabbit for a second-opinion AI code review.
   - Invoke `coderabbit:code-review` via the Skill tool with the changed files as scope
   - Compare coderabbit findings with CHOW's internal quality standards
   - Flag any discrepancies — coderabbit may catch issues that pattern-based analysis misses

**Graceful skip**: If Context7 or Coderabbit are unavailable, log the skip and proceed with internal review only. Plugin enrichment augments but does not replace CHOW's built-in quality gates.

### Step 2: Execute with MCP Tools

Use `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "corso"`, `action: "chow"` for quality analysis, applying all coding standards, architecture intelligence, Context7 pattern reference, coderabbit findings, and domain context below.

---

## Quality Gates

### Pre-Execution
- [ ] Requirements clear and confirmed
- [ ] Target files/modules identified
- [ ] Language and framework known
- [ ] Architecture style detected
- [ ] Language-specific patterns identified

### Post-Execution
- [ ] No `.unwrap()` / `.expect()` / `panic!()` in new code
- [ ] All functions <= 60 lines, complexity <= 10
- [ ] Error paths handled (not swallowed)
- [ ] No duplicated logic blocks
- [ ] No deep nesting (>3 levels)
- [ ] Test coverage >= 90%
- [ ] All acceptance criteria met

---

## Light Architects Coding Standards (Non-Negotiable)

### Rust

```
- NO .unwrap() / .expect() in production — use ? or match
- NO panic!() — use Result<T, E>
- unsafe requires // SAFETY: comment with justification
- clippy::pedantic enforced as errors
- Checked arithmetic (checked_add, saturating_sub)
- Functions <= 60 lines
- Cyclomatic complexity <= 10
- Error chains preserve cause (thiserror for library, anyhow for app)
```

### Quality Metrics

```
- Every public function returns Result
- No swallowed errors (empty catch / if let Err(_))
- No TODO/FIXME without ticket reference
- Meaningful variable/function names
- Comments explain WHY, not WHAT
- Test coverage >= 90%
```

### Architecture Principles

```
- Determinism over cleverness
- Fail-safe defaults & degraded modes
- Total traceability
- No unbounded loops (fixed upper bounds)
- No dynamic memory in critical paths
```

---

## Error Handling Enforcement

```
- Result propagation via ? operator
- No swallowed errors (empty catch / if let Err(_))
- Error chains preserve cause (thiserror for library, anyhow for app)
- Every public function returns Result
- Use map_err() to add context when crossing module boundaries
```

## Arithmetic Safety

```
- Use checked_add, checked_mul for overflow-prone operations
- Use saturating_sub for underflow-prone subtractions
- No implicit integer truncation
```

---

## Code Smell Detection (from `review.rs:identify_code_smells`)

| Smell | Detection | Fix |
|-------|-----------|-----|
| Long function | >60 lines | Split into focused helpers |
| Deep nesting | >3 indent levels | Extract, early return, guard clauses |
| God object | >10 methods on one struct | Decompose into focused types |
| Duplicated logic | Same pattern in 2+ places | Extract shared function |
| Long parameter list | >4 params | Use builder pattern or config struct |
| Boolean blindness | `fn foo(bar: bool, baz: bool)` | Use enums for clarity |

---

## Quality Metrics (from `review.rs:extract_quality_metrics`)

```
- Max 60 lines per function — split longer functions
- Cyclomatic complexity <= 10 — extract branches into helpers
- Meaningful comment ratio — comments explain WHY, not WHAT
- No duplicated logic blocks (same pattern in 2+ places)
- No deep nesting (>3 indent levels)
```

---

## Architecture Style Matching (from `architecture.rs:infer_architecture_style`)

Detect and enforce architecture consistency:

| Signal Keywords | Architecture Style |
|----------------|-------------------|
| `http`, `grpc`, `async`, `service` | Microservices |
| `mpsc`, `channel`, `event`, `handler` | Event-Driven |
| `controller`, `service`, `repository` | Layered |
| `port`, `adapter`, `hexagonal` | Hexagonal / Ports & Adapters |

---

## Language-Specific Patterns (from `architecture.rs:select_architecture_patterns`)

**Rust**:
- Type-driven design (newtype pattern, enums for state)
- Result/Option propagation with `?`
- Ownership and borrowing (prefer `&T` over `Clone`)
- Trait-based abstraction (define interfaces as traits)
- Builder pattern for complex construction

**Python**:
- Decorators for cross-cutting concerns
- Context managers for resource lifecycle
- Protocol classes for structural typing
- Dataclasses for value objects

**JavaScript/TypeScript**:
- Module pattern for encapsulation
- Promise/async-await for concurrency
- Factory functions over classes
- Discriminated unions (TS) for type safety

**Go**:
- Interface-based design (small interfaces)
- Goroutines + channels for concurrency
- Table-driven tests
- Error wrapping with `fmt.Errorf`

---

## Scalability Analysis (from `architecture.rs:build_scalability_context`)

| Signal | Scalability Concern |
|--------|-------------------|
| Database access | Connection pooling, query optimization |
| Async/concurrent | Task management, backpressure |
| Static content | Multi-instance review, CDN consideration |
| State management | Stateless design, external state stores |

---

## Phase Exit Gate (MANDATORY before advancing to GUARD)

Claude MUST verify every item before moving to the next phase. Items marked [BLOCKING] halt the pipeline if unmet. Standards reference: Builder's Cookbook v1.0.0 (§11 Code Review Protocol, §13.2 Code Review Cadence).

### Static Gate — Review Scope (from HUNT handoff)

- [ ] [BLOCKING] Changed files list received from MANIFEST `hunt_output.changed_files:` — review THESE files specifically
- [ ] [BLOCKING] Every file in the changed files list reviewed (not just a sample — complete coverage)
- [ ] If HUNT applied fixes during execution: those fixes are included in the review scope

### Static Gate — Three-Phase Review Complete (Cookbook §11.1)

- [ ] [BLOCKING] **Phase 1 (Correctness)**: Every changed file reviewed for logic errors, off-by-one, null/None handling, race conditions
- [ ] [BLOCKING] **Phase 2 (Architecture)**: Changes align with existing patterns — no rogue abstractions, no pattern violations (Cookbook §2.1 SOLID, §2.3 Modularity)
- [ ] [BLOCKING] **Phase 3 (Edge Cases)**: Empty input, max-size input, malformed input, concurrent access — each boundary tested or explicitly documented as out of scope
- [ ] [BLOCKING] No over-engineering — changes are proportional to the task, no premature abstractions (Cookbook §2.5)

### Static Gate — Code Quality Standards (Cookbook §13.2 Per-Phase Checklist)

- [ ] [BLOCKING] No `.unwrap()` / `.expect()` / `panic!()` in production code (Cookbook §4.1)
- [ ] [BLOCKING] Input validation at all boundaries (Cookbook §10.4)
- [ ] [BLOCKING] Error handling complete — no swallowed errors (Cookbook §15.3 Error Message Template)
- [ ] [BLOCKING] No hardcoded secrets or credentials (Cookbook §10.3)
- [ ] [BLOCKING] Complexity within limits — ≤10 cyclomatic, ≤60 lines per function (Cookbook §3)
- [ ] Structured logging at appropriate levels — no `println!`/`eprintln!` for operational logging (Cookbook §15.2)
- [ ] Tests cover happy path + 2 edge cases minimum per public function (Cookbook §9.2)
- [ ] Code smell detection — duplicated logic, god objects, feature envy flagged

### Static Gate — Pattern Consistency & Regression

- [ ] [BLOCKING] New code follows existing codebase conventions (naming, structure, error handling patterns identified during FETCH)
- [ ] Module organization follows domain boundaries (Cookbook §2.7)
- [ ] Separation of concerns maintained — no business logic in transport/protocol layers (Cookbook §2.6)
- [ ] Loose coupling verified — modules communicate via traits/interfaces, not concrete types (Cookbook §2.4)
- [ ] If new public API was added: documented with function-level comments (Cookbook §16.3)
- [ ] Performance regression check — no O(n²) where O(n) existed, no unnecessary allocations in hot paths
- [ ] No accidental API surface changes — public interfaces unchanged unless plan specified otherwise

### SCOUT-Generated Items

- [ ] All items from MANIFEST `phase_gates.chow` verified complete

### Review Findings Documented

- [ ] All findings categorized by severity (CRITICAL / HIGH / MEDIUM / LOW)
- [ ] CRITICAL and HIGH findings have concrete fix recommendations
- [ ] [BLOCKING] All CRITICAL findings fixed before advancing (not deferred — fixed now)
- [ ] If fixes were applied during review: re-verified that fixes don't introduce new issues (no fix-introduces-bug cycles)
- [ ] Review summary written to MANIFEST `gates.chow_exit.findings:` section
- [ ] Elapsed time recorded in MANIFEST `timing.chow_elapsed:`

**Gate signal:** Set MANIFEST `gates.chow_exit.passed: true` with timestamp.

---

## Cross-Domain Context

| When | Skill Context | MCP Tools |
|------|--------------|-----------|
| Security review of new code | GUARD | `corsoTools` action: `guard` |
| Architecture patterns research | FETCH | `corsoTools` action: `fetch` |
| Test strategy for new code | CHASE | `corsoTools` action: `chase` |

---

## MCP Tools Available

| `corsoTools` Action | Purpose |
|---------------------|---------|
| `chow` | Quality analysis and review (Paul + Elijah + Joshua) |
