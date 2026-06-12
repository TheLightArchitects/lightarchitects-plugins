---
name: COOKBOOK-ENFORCER
description: LA-specific rules that CI does NOT catch (human review required), plus toolchain gate reference and severity map
skill_id: lightarchitects/COOKBOOK-ENFORCER
context: reference
---

# Builders Cookbook Enforcer

## Toolchain-Enforced Gates (trust the pipeline — skip these in review)

CI blocks merges on these — agents skip re-check, focus on human-review rules below.

| Rule | Enforced by |
|------|-------------|
| No `.unwrap()` / `.expect()` in production | `clippy -D clippy::unwrap_used` |
| No `panic!()` | `clippy -D clippy::panic` |
| `unsafe` requires `// SAFETY:` comment | `clippy -D clippy::undocumented_unsafe_blocks` |
| `clippy::pedantic` as errors | `clippy -- -D warnings` |
| Cyclomatic complexity ≤ 10 | `clippy -D clippy::cognitive_complexity` |
| Function body ≤ 60 lines | `clippy -D clippy::too_many_lines` |
| Checked arithmetic | `clippy -D clippy::arithmetic_side_effects` |
| All public items documented (`///`) | `cargo doc --no-deps` |
| Test coverage ≥ 90% | `cargo llvm-cov` |
| Consistent formatting | `cargo fmt --check` |

## LA-Specific Rules (human review — CI does NOT catch these)

| # | Rule | Why it matters | How to spot it |
|---|------|---------------|----------------|
| 11 | MCP handler body ≤ 60 lines | Handlers > 60 lines become unreviewed state machines | Count lines in any `fn handle_*` or `fn tool_*` body |
| 12 | `SkillError` variants, not `anyhow` in MCP handlers | `anyhow` loses type structure across JSON-RPC boundary | Look for `anyhow::Result` / `bail!` in handler return types |
| 13 | `tokio` runtime only — no `async_std` | Mixing runtimes panics at *runtime*, not compile time | `grep "async_std" Cargo.toml Cargo.lock` |
| 14 | `serde` derive — no manual `Serialize/Deserialize` | Manual impls drift from schema silently | Any `impl Serialize for` / `impl Deserialize for` without `#[derive]` |
| 15 | Prefer `mpsc` / `broadcast` channels over `Arc<Mutex<>>` | Mutex chains → deadlocks under load | Look for `.lock().unwrap()` call chains |
| 16 | No blocking calls in async context | Blocks the tokio thread pool; stalls all handlers on that thread | `std::thread::sleep`, `std::fs::read` called directly in `async fn` |
| 17 | Log at `tracing` not `println!` | `println!` corrupts the stdio JSON-RPC stream in MCP servers | `grep -rn "println!" src/` |
| 18 | No hardcoded absolute paths in source | Machine-specific paths break cross-machine builds and tests | Grep for `/Users/`, `/home/`, `/root/` literals in non-test source |
| 19 | No secrets committed to source or Knowledge (Charlie) vault entries | Vault entries travel further than expected (sync, backup, logs) | Grep for `sk-ant-api`, `la_[a-z]`, `eyJ`, `BEGIN.*KEY` |

**Auto-fixable**: 14 (add `#[derive(Serialize, Deserialize)]`), 17 (sed `println!` → `tracing::info!`). **Manual**: 11, 12, 13, 15, 16, 18, 19.

## Violation Severity (LA-specific rules only)

| Severity | Rules | Action |
|----------|-------|--------|
| CRITICAL | 13, 17, 19 | Block all review; fix before any further work |
| HIGH | 12, 15, 16 | Fix in same PR; no deferral without explicit justification |
| MEDIUM | 11, 14, 18 | Fix before release; leave a review comment if deferring |
