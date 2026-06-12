---
name: TEST-FRAMEWORKS
description: Framework detection decision tree, Canon XXVII mapping per stack, flaky test patterns, coverage commands
skill_id: lightarchitects/TEST-FRAMEWORKS
context: reference
---

# LA Test Frameworks Reference

## Framework Detection

```bash
# Rust — check for extended toolchain
grep -E "nextest|proptest|criterion|tokio.*test" Cargo.toml Cargo.lock 2>/dev/null | head -10

# TypeScript/Svelte — check test runner
grep -E '"vitest"|"playwright"|"@testing-library"' package.json 2>/dev/null

# Python — check test runner
grep -E "pytest|hypothesis" requirements.txt pyproject.toml 2>/dev/null
```

## Canon XXVII: 6-Suite Mapping

### Rust

| Suite | Tool | Location | Notes |
|-------|------|----------|-------|
| Unit | `#[test]` | `src/**/*.rs` inline | Fast, isolated, no I/O |
| Integration | `#[test]` | `tests/*.rs` | Cross-crate, uses real deps |
| Property | `proptest!` / `quickcheck` | `tests/prop_*.rs` | Invariant verification |
| E2E | `#[tokio::test]` | `tests/e2e_*.rs` | Full MCP handshake → response |
| Regression | Named `test_regression_*` | `tests/regression/` | Pin known-fixed bugs |
| Smoke | nextest smoke profile | `nextest.toml [profile.smoke]` | <30s, run before every deploy |

Smoke profile in `nextest.toml`: `[profile.smoke]` with `filter = "test(smoke)"`.

### TypeScript / SvelteKit

| Suite | Tool | Location |
|-------|------|----------|
| Unit | Vitest `describe/it` | `src/**/*.test.ts` |
| Integration | Vitest with real stores | `src/**/*.integration.test.ts` |
| Property | `fast-check` | `src/**/*.prop.test.ts` |
| E2E | Playwright | `e2e/**/*.spec.ts` |
| Regression | Vitest named `regression_*` | `src/**/*.regression.test.ts` |
| Smoke | Playwright smoke tag | `e2e/smoke.spec.ts` |

**Playwright**: always `headless: false` (bugs don't reproduce headless); `recordHar: { path: 'test-results/har/' }` — HAR required every run.

## Coverage Gates

| Language | Tool | Command | Gate |
|----------|------|---------|------|
| Rust | cargo-llvm-cov | `cargo llvm-cov --all-features` | ≥90% line + branch |
| TypeScript | Vitest coverage | `pnpm test:coverage` | ≥90% statements |

## Flaky Test Detection Patterns

- **Timing dependency**: `sleep` or `timeout` in test body → replace with `wait_for`
- **Shared mutable state**: global or `static mut` across tests → isolate per test
- **Network dependency**: external HTTP in unit test → mock or skip in CI
- **File system race**: parallel tests writing same temp file → use `tempdir()` per test
- **Order dependency**: test B passes only after test A → each test must be independent
