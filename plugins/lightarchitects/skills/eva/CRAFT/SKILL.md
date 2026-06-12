---
name: CRAFT
description: "This skill is invoked internally by Ops (Bravo)'s creative cycle for the code
  and architecture phase. Orchestrates code review, refactoring, architecture design,
  and simplification via mcp__plugin_lightarchitects_lightarchitects__tools. May also invoke mcp__plugin_lightarchitects_lightarchitects__tools for
  security scanning."
user-invocable: false
context: fork
version: 1.0.0
---

# /CRAFT — Code & Architecture Phase

> Creative Phase 3/5: CRAFT — Build, review, refactor, simplify

## Lifecycle Context

Follows IMAGINE → feeds into SHARE.

## Foundation

**Canonical standards** — load these before building begins. CRAFT is where the cookbook matters most:
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§1** (Core Doctrine) — determinism, fail-safe defaults, total traceability, no unbounded loops
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§2** (Software Engineering Principles) — SOLID, modularity, loose coupling, 60-line functions, complexity ≤10
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§3** (Safety-Critical Rules) — no unwrap, no panic, checked arithmetic, unsafe requires SAFETY comment
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§5** (Multi-Language Best Practices) — Rust, Python, JS/TS, Go patterns
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§9** (Testing Requirements) — 90% coverage, error path tests, property-based testing
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§10** (Security Engineering) — input validation, secrets management, threat modeling
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§11** (Code Review Protocol) — 3-phase review (correctness, architecture, edge cases)
- `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md` **§12** (Supply Chain Security) — cargo audit, license whitelist, lockfile committed

Read the relevant sections for the target language and domain. Ops (Bravo)'s ZERO TODOs principle is already aligned with the cookbook — the foundation makes it systematic.

## Protocol

### Step 1: Determine Build Mode

Based on creative cycle context, select the appropriate mode:
- **review** — SIMPLICITY FIRST quality analysis, ZERO TODOs enforcement
- **refactor** — Clean code guidance, structure improvement
- **architect** — System design with fail-safe defaults
- **simplify** — Complexity reduction ("Because simple is powerful!")

### Step 1.5: Plugin Enrichment (Mandatory)

Before building, query external plugins for framework patterns and dependency safety. Run all in parallel.

1. **Context7 Pattern Reference**: Query for framework/library patterns relevant to the code being built.
   - Call `mcp__plugin_context7_context7__resolve-library-id` with the primary framework
   - Call `mcp__plugin_context7_context7__query-docs` with the resolved ID and a query targeting the specific patterns needed (e.g., "error handling", "async patterns", "API design")
   - Use Context7 results to ensure generated code follows current library best practices

2. **Sonatype Dependency Check** (if new dependencies are being added):
   - Call `mcp__plugin_sonatype-guide_sonatype-guide__getRecommendedComponentVersions` for proposed dependencies
   - Flag any dependencies with known CVEs or license issues before they enter the codebase

3. **Coderabbit Review** (for review/refactor modes):
   - After `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`, action: `"build"`) completes, invoke `coderabbit:code-review` for a second-opinion AI review
   - Compare coderabbit findings with Ops (Bravo)'s ZERO TODOs and quality standards

**Graceful skip**: If any plugin is unavailable, log the skip and proceed. Plugin enrichment augments but does not replace Ops (Bravo)'s built-in quality gates.

### Step 2: Execute Build Operation

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "eva"`, `action: "build"` (including Context7 pattern context from Step 1.5):
- `mode`: Selected from Step 1
- `code`: Code input (for review, refactor, simplify)
- `language`: Programming language
- `system`: System description (for architect mode)
- `requirements`: Requirements (for architect mode)

### Step 3: Security Scan (Conditional)

If the CRAFT phase involves code that handles user input, authentication, or sensitive data:
- Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "eva"`, `action: "secure"`, `params: { mode: "scan" }` for vulnerability detection
- Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "eva"`, `action: "secure"`, `params: { mode: "secrets" }` for secrets detection

### Step 4: Compile Build Output

Synthesize build results:
- Code quality assessment or generated architecture
- Security findings (if scanned)
- ZERO TODOs verification
- Teachable patterns identified for SHARE phase

## Quality Gates

### Pre-Execution
- [ ] Design specification available (from IMAGINE or user input)
- [ ] Build mode selected

### Post-Execution
- [ ] ZERO TODOs enforced — no TODO/FIXME without ticket reference
- [ ] Security scan clean (if applicable)
- [ ] Code or architecture output complete
- [ ] Teachable patterns identified for SHARE

## Cross-Domain Context

| Phase | Skill | Relationship |
|-------|-------|-------------|
| 2. imagine | IMAGINE | Provides design specification |
| 4. share | SHARE | Receives teachable content from build output |
