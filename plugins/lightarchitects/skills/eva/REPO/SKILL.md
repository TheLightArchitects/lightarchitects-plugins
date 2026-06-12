---
name: REPO
description: "Repository operations — code review, refactoring, architecture analysis using Ops (Bravo)'s build pipeline."
version: 1.0.0
user-invocable: true
context: root
metadata:
  triggers:
    - "review this"
    - "code review"
    - "refactor"
    - "architecture review"
    - "simplify"
    - "review PR"
    - "review the code"
    - "architect this"
    - "clean this up"
    - "build review"
  filePattern:
    - "*.rs"
    - "*.ts"
    - "*.tsx"
    - "*.py"
    - "*.go"
    - "src/**"
    - "lib/**"
---

# /REPO — Repository Operations

> Code review, refactoring, and architecture analysis through Ops (Bravo)'s `build` pipeline. For standards violations, see `/LINT`.

## Section 0: Mode Selection (HITL)

```
Question: "What kind of repo work?"
Header: "Repo"
Options:
  1. "Code review" — "Detailed review with ZERO TODOs enforcement"
  2. "Refactor" — "Restructure without changing behaviour"
  3. "Architecture" — "System design and structural analysis"
  4. "Simplify" — "Reduce complexity, remove dead code"
```

## Section A: Code Review

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`):
```json
{
  "action": "build_review",
  "params": {
    "file_path": "<absolute path>",
    "focus": "quality"
  }
}
```

Ops (Bravo) enforces ZERO TODOs. Every review flags:
- TODO/FIXME without ticket reference
- `.unwrap()` / `.expect()` in Rust production code
- Functions over 60 lines
- Missing error handling

Present violations as a checklist. For each `error`, provide the corrected code snippet.

## Section B: Refactor

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`):
```json
{
  "action": "build_refactor",
  "params": {
    "file_path": "<absolute path>",
    "goal": "<description of what to improve>"
  }
}
```

After refactor output:
1. Run `/LINT` on the result to verify no standards regressions.
2. Confirm with the operator before applying changes to disk.

## Section C: Architecture Analysis

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`):
```json
{
  "action": "build_architect",
  "params": {
    "scope": "<module, crate, or system description>",
    "concern": "<what to evaluate: coupling, boundaries, abstractions, etc.>"
  }
}
```

Present findings as:
- **Strengths** — what the architecture does well
- **Risks** — coupling, hidden dependencies, single points of failure
- **Recommendations** — specific structural changes with rationale

## Section D: Simplify

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`):
```json
{
  "action": "build_simplify",
  "params": {
    "file_path": "<absolute path>",
    "target": "<what to simplify: logic, structure, dependencies>"
  }
}
```

Ops (Bravo)'s simplicity principle: "Because simple is powerful!" Favour fewer abstractions, shorter call chains, and obvious names.

## Standards Reference

Canonical: `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md`

Key rules for review:
- NO `.unwrap()` / `.expect()` in production Rust
- Cyclomatic complexity <= 10
- 60-line function limit
- ZERO TODOs without ticket references
- `unsafe` requires `// SAFETY:` comment
