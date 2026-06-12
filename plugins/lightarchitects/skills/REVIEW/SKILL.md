---
name: REVIEW
description: "Multi-lens code review pipeline via SQUAD. Extracts git diff, identifies
  changed files, then delegates to SQUAD code_review. Equivalent to Engineer:Scan + GUARD
  + Analyst (Delta) verify with parallel execution. Use when the user says '/review', 'review
  this PR', 'code review', 'check my changes'. For security vulnerability assessment,
  use /secure instead."
user-invocable: true
version: 2.0.0
context: root
---

# /REVIEW — Code Review Pipeline

> Thin wrapper: git diff extraction + PR identification → SQUAD code_review.

## When to Use

- User has changes ready for review (staged, committed, or in a PR)
- User says `/review`, "review this", "code review", "check my changes"
- Before merging a feature branch
- After a BUILD completes — validate the output

## Accepted Flags

| Flag | Expansion | Effect |
|------|-----------|--------|
| `--fix` | Append fix phase | `code_review → fix` — implement confirmed review issues |

Rejected flags: `--then`, `--watch`, `--drain`, `--research`.

## Step 1: Argument Validation (SAFEGUARD #24)

If a target argument is provided, validate against `^[a-zA-Z0-9_/. -]+$`. Reject SQUAD control flags and shell metacharacters. See SAFEGUARD #24 in `references/meta-skills.md`.

On unrecognized flag:
```
ERROR: /REVIEW does not accept {flag}.
Recognized flags for /REVIEW: --fix
For raw pipeline control, use /SQUAD directly.
```

## Step 2: Change Set Extraction

Extract the diff before invoking SQUAD so agents have the full context:

```bash
git diff --stat HEAD~1      # file count + line summary
git diff HEAD~1             # full diff
```

For PR review: `git diff main...HEAD`

Identify:
- Files changed and affected modules
- Whether write-sensitive areas are in the diff (auth, crypto, networking, input boundaries)
- Whether new dependencies were added (`Cargo.toml`, `package.json` changes)

**Builders Cookbook reference** (canon://builders-cookbook): Review against mandatory rules:
- §1: NO `.unwrap()` / `.expect()` in production, NO `panic!()` — use `Result<T, E>`
- §3: `unsafe` requires `// SAFETY:` comment
- §4: `clippy::pedantic` as errors, cyclomatic complexity ≤10, 60-line function limit
- §16: All public items documented with `///` comments

**Confidence Threshold Gate** (Canon XXXV): Review verdicts require confidence values:
- PASS (≥95% confidence, no CRITICAL/HIGH findings)
- WARN (≥85% confidence, MEDIUM findings only)
- FAIL (<85% confidence or any CRITICAL/HIGH finding)

Pass the change set summary as the SQUAD target argument so agents focus review on what actually changed.

## Step 3: HITL Gate

**Without --fix**: No write disclosure needed. Confirm target and proceed.

**With --fix** (write-path disclosure, SAFEGUARD #21):
```
SQUAD: code_review → fix
Agents: ~4–5 | Estimated tokens: ~35–60K
WRITES CODE: fix phase will create branches for confirmed review issues.
  - Branch pattern: squad/fix/{agent-name}
  - Merge strategy: sequential with quality gates
  - Rollback: automatic on gate failure
Proceed? [y/N]
```

## Step 4: SQUAD Invocation

**Standard review:**
```
/SQUAD code_review "<changes description or file list>"
```

**With --fix:**
```
/SQUAD code_review "<changes>" --then fix
```

SQUAD agents in the `code_review` preset run Engineer:Scan (quality analysis), Engineer:Guard (security scan), and Analyst (Delta) verify (logic correctness) in parallel. Full cycle instructions are in `references/presets.md`.

## Contract Canon Integration (Cookbook §82)

Governed by `agent.skill.review`. Reads `standards/canon/contracts/operator.surface/*` (forbidden_behaviors) and `code.trait/*` (method_contracts) during the code_review preset. Each finding carries `contract_refs[]` identifying contracts whose rules the finding cites. New public surfaces in the diff trigger `E_REVIEW_UNCONTRACTED_SURFACE` HIGH finding if no matching `operator.surface.*` contract exists. Emits `skill.review.invoke` span. No `status_per_provider` mutations (read-only).

## Graceful Degradation

If SQUAD is unavailable:

1. CORSO review: `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "corso"` action:`code_review` path:`"<changed files>"`
2. Skip Analyst (Delta) logic verification and Knowledge (Charlie) helix context

Report: "Running Engineer (Alpha)-only review."
