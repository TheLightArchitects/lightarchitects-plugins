# Compile Check — Compiler-in-the-Loop Feedback

**Type**: PostToolUse hook (advisory, non-blocking)
**Trigger**: Write|Edit on code files (.rs, .ts, .js, .svelte, .py)
**Phase**: Fires after `rustfmt-on-save.sh` and `quality-check.sh`

---

## Purpose

Provides immediate compiler feedback after every code write during HUNT (or any coding phase). The compiler is the ultimate authority on syntax validity — this hook captures its verdict and makes it available as structured context for self-correction.

The feedback loop is: **write code -> format -> lint -> compile check -> read errors -> fix -> repeat**.

---

## When It Fires

The hook runs on every Write or Edit to files matching: `*.rs`, `*.ts`, `*.js`, `*.svelte`, `*.py`.

It detects the project type by walking up from the edited file to find:
- `Cargo.toml` -> Rust project -> `cargo check --message-format=json`
- `package.json` + `tsconfig.json` -> TypeScript project -> `npx tsc --noEmit`
- Python file -> `python3 -m py_compile <file>`

If no recognized project marker or compiler is found, the hook exits silently.

---

## Output

### To Claude (additionalContext)

On success:
```
Compile check: PASS (cargo check)
```

On failure:
```
Compile check: 3 error(s) found by cargo check
Errors written to /tmp/la-compile-feedback.json

  src/main.rs:42: expected `;`
  src/lib.rs:17: cannot find value `foo` in this scope
  src/handler.rs:88: mismatched types
```

### Structured JSON (`/tmp/la-compile-feedback.json`)

```json
{
  "timestamp": "2026-04-21T12:00:00Z",
  "trigger_file": "src/main.rs",
  "compiler": "cargo check",
  "error_count": 3,
  "compile_errors": [
    {
      "file": "src/main.rs",
      "line": 42,
      "column": 15,
      "message": "expected `;`",
      "severity": "error",
      "code": "E0308"
    }
  ]
}
```

---

## Integration with HUNT Phase

During HUNT (code generation), the coding agent should:

1. Write code via Write/Edit tool
2. `rustfmt-on-save.sh` auto-formats (zero tokens)
3. `quality-check.sh` checks for violations (unwrap, panic, secrets)
4. `compile-check.sh` runs the compiler and returns errors
5. Agent reads the `additionalContext` and fixes errors in the next turn
6. Repeat until `Compile check: PASS`

This creates a tight feedback loop where the compiler teaches the agent about type errors, missing imports, and syntax issues without requiring a human to run the build manually.

---

## Graceful Degradation

- Missing `cargo`: skips Rust check silently
- Missing `npx`/`tsc`: skips TypeScript check silently
- Missing `python3`: skips Python check silently
- Compiler hangs: 30s timeout kills the process
- JSON parse failure: outputs empty error array, still PASS

The hook never blocks the conversation. Errors are advisory context.

---

## Relationship to Other Hooks

| Order | Hook | Purpose |
|-------|------|---------|
| 1 | `rustfmt-on-save.sh` | Auto-format .rs files |
| 2 | `quality-check.sh` | Lint for violations (unwrap, panic, secrets, function length) |
| 3 | `compile-check.sh` | Run native compiler, capture structured errors |

Format first, then lint, then compile. Each layer catches different classes of issues.
