---
name: LINT
description: "Code quality gate — check a file against the Light Architects Builders Cookbook standards."
version: 1.0.0
user-invocable: true
context: root
metadata:
  triggers:
    - "lint"
    - "check standards"
    - "standards check"
    - "code quality"
    - "check this file"
    - "builders cookbook"
    - "ZERO TODOs"
    - "unwrap check"
    - "quality gate"
  filePattern:
    - "*.rs"
    - "*.ts"
    - "*.tsx"
    - "*.py"
---

# /LINT — Standards Check

> Check a file against the Light Architects Builders Cookbook (v1.0.0) using Ops (Bravo)'s `standards_check` action. Reports violations with line numbers and severity.

## Section 0: Input Collection (HITL)

```
Question: "Which file do you want to check?"
Header: "Lint"
```

If the operator provides a file path directly (e.g. `~/Projects/<project>/src/foo.rs`), skip the prompt.

## Section A: Run Standards Check

Call `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"eva"`):
```json
{
  "action": "standards_check",
  "params": {
    "file_path": "<absolute path>",
    "include_cookbook": false
  }
}
```

Set `include_cookbook: true` if the operator asks "what does the cookbook say about X".

## Section B: Interpret Results

Format violations as a checklist:

```
✅ 0 violations — passes standards
❌ N violations:
  - Line 42 [error]: NO .unwrap() in production
  - Line 67 [warning]: TODO/FIXME without ticket reference
```

**Severity guide**:
- `error` — Must fix before merge. Blocks the Engineer (Alpha) pipeline.
- `warning` — Should fix. Will be flagged in code review.

## Section C: Suggested Fixes

For each `error` violation, suggest the correct fix:
- `.unwrap()` → use `?` operator or `match`
- `.expect()` → use `?` operator with `.context()`
- `panic!` → return `Err(...)` using anyhow
- `unsafe` without SAFETY → add `// SAFETY: <reason>`

For `TODO/FIXME` warnings:
- Add a ticket reference: `// TODO [Ops (Bravo)-123]: description`
- Or resolve the TODO before shipping.

## Standards Reference

Canonical: `~/lightarchitects/soul/helix/user/standards/builders-cookbook.md`

Key rules enforced:
- NO `.unwrap()` / `.expect()` in production
- NO `panic!`
- `unsafe` requires `// SAFETY:` comment
- 60-line function limit
- TODO/FIXME must reference a ticket
