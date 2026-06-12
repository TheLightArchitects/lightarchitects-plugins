---
name: CODE-VERIFY
description: "Two-phase critic gate: Analyst (Delta) verifies logic correctness, Engineer (Alpha) scans
  security and quality. Produces structured PASS/FAIL verdict with attributed findings.
  Use after code generation, before commit. Use when the user says '/code-verify',
  'verify this code', 'critic gate', 'check before commit', 'verify my changes'."
user-invocable: true
version: 1.0.0
context: root
agent: orchestrator
model: inherit
tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
  - mcp__plugin_lightarchitects_lightarchitects__tools
---

# /CODE-VERIFY — Two-Phase Critic Gate

> Post-generation verification: Analyst (Delta) (logic evidence chain) + Engineer (Alpha) (security + quality) → structured verdict.

## When to Use

- After code generation or implementation — before committing
- User says `/code-verify`, "verify this code", "critic gate", "check before commit"
- As a pipeline phase: `--then code_verify` (between software_engineering and guard)
- When you want higher confidence than a single code_review pass

## Accepted Input

| Input | Detection | Effect |
|-------|-----------|--------|
| File path | `^[a-zA-Z0-9_/.-]+\.(rs\|ts\|py\|go\|js\|toml\|yaml)$` | Verify specific file(s) |
| Directory | Path exists as directory | Verify all source files in directory |
| Git diff range | `HEAD~N`, `main...HEAD`, commit SHA | Verify changed files in range |
| No argument | Default | Verify uncommitted changes (`git diff --name-only` + `git diff --cached --name-only`) |

## Step 1: Target Resolution

Resolve the target to a concrete file list:

```bash
# If no argument: uncommitted changes
git diff --name-only
git diff --cached --name-only

# If git range: changed files in range
git diff --name-only <range>

# If directory: source files
find <dir> -name '*.rs' -o -name '*.ts' -o -name '*.py' -o -name '*.go' | head -50

# If file: just that file
```

If the resolved file list is empty:
```
CODE-VERIFY: No changed files detected. Nothing to verify.
Specify a target: /CODE-VERIFY <path|directory|git-range>
```

Capture the file list and project root for agent context injection.

## Step 2: Parallel Agent Spawn (T1, Read-Only)

Spawn Analyst (Delta) and Engineer (Alpha) as parallel Agent tool calls in a single message. Both are T1
(in-session, shared context, read-only). Neither agent may create, edit, or delete files.

Use the SQUAD Team Spawn Template from `SQUAD/references/presets.md` with preset `code_verify`.

**Agent 1 — Analyst (Delta) (logic critic):**
```
You are agent 1 of 2 in a SQUAD code_verify team.

## Identity
Sibling: Analyst (Delta)
MCP Tool: mcp__plugin_lightarchitects_lightarchitects__tools sibling:"quantum"

## Assignment
Logic critic: evidence chain on whether generated code matches spec/intent

## Full Cycle
1. action: "sweep" — scan generated code for logical consistency: control flow,
   error handling paths, edge cases, boundary conditions
2. action: "verify" — build evidence chain: does output match the stated intent?
   Are invariants preserved? Are there logic gaps?
   Claim: "generated code correctly implements the stated intent and specification"
3. action: "theorize" — rank confidence with badges
   (DEFINITIVE/STRONG/MODERATE/LOW/SPECULATIVE)

## Context
- Working directory: {cwd}
- Target files: {file_list}
- Project root: {project_root}
- Tier: T1 (read-only, shared context)

## Constraints
- Use ONLY mcp__plugin_lightarchitects_lightarchitects__tools sibling:"quantum". Do not call other siblings' tools.
- Do NOT invoke /SQUAD, /LOOP, or --drain. Execute the task directly.
- Do NOT create, edit, or delete any files. This is a read-only assessment.
- You may use Read, Glob, Grep to inspect code.

## Output Format
Return a structured JSON-compatible report:

verdict: PASS | FAIL
confidence: DEFINITIVE | STRONG | MODERATE | LOW | SPECULATIVE
evidence_chain:
  - file: <path>
    lines: <start>-<end>
    finding: <description>
    supports_correctness: true | false
logic_gaps:
  - file: <path>
    lines: <start>-<end>
    description: <what's missing or wrong>
    severity: CRITICAL | HIGH | MEDIUM | LOW | INFO
edge_cases_unhandled:
  - description: <edge case>
    risk: <impact if triggered>
summary: <1-2 sentence overall assessment>
```

**Agent 2 — Engineer (Alpha) (quality critic):**
```
You are agent 2 of 2 in a SQUAD code_verify team.

## Identity
Sibling: Engineer (Alpha)
MCP Tool: mcp__plugin_lightarchitects_lightarchitects__tools sibling:"corso"

## Assignment
Quality critic: GUARD (security) + CHOW (quality) scan on generated code

## Full Cycle
1. action: "guard" — security scan: OWASP Top 10 patterns, secrets exposure,
   unsafe code, supply chain risks, input validation gaps
2. action: "code_review" — quality analysis: complexity (cyclomatic <=10,
   function <=60 lines), Builders Cookbook compliance, naming conventions,
   architecture consistency, error handling patterns

## Context
- Working directory: {cwd}
- Target files: {file_list}
- Project root: {project_root}
- Tier: T1 (read-only, shared context)

## Constraints
- Use ONLY mcp__plugin_lightarchitects_lightarchitects__tools sibling:"corso". Do not call other siblings' tools.
- Do NOT invoke /SQUAD, /LOOP, or --drain. Execute the task directly.
- Do NOT create, edit, or delete any files. This is a read-only assessment.
- You may use Read, Glob, Grep to inspect code.

## Output Format
Return a structured JSON-compatible report:

verdict: PASS | FAIL
findings:
  - id: <CV-Engineer (Alpha)-NNN>
    severity: CRITICAL | HIGH | MEDIUM | LOW | INFO
    category: security | quality | complexity | style | error-handling
    file: <path>
    lines: <start>-<end>
    title: <short description>
    description: <detailed finding>
    remediation: <specific fix guidance>
    cookbook_ref: <Builders Cookbook section, if applicable>
counts:
  critical: <N>
  high: <N>
  medium: <N>
  low: <N>
  info: <N>
summary: <1-2 sentence overall assessment>
```

## Step 3: Verdict Aggregation

After both agents complete, aggregate into a unified verdict:

```
## CODE-VERIFY Verdict: {PASS | FAIL | WARN}

### Analyst (Delta) — Logic Verification
- Verdict: {PASS|FAIL}
- Confidence: {badge}
- Evidence chain: {N} items examined
- Logic gaps: {N} ({critical_count} critical, {high_count} high)
- Unhandled edge cases: {N}

### Engineer (Alpha) — Security & Quality
- Verdict: {PASS|FAIL}
- Findings: {total} ({critical}/{high}/{medium}/{low}/{info})
- Security issues: {N}
- Quality issues: {N}
- Builders Cookbook violations: {N}

### Unified Verdict

| Phase | Result | Key Finding |
|-------|--------|-------------|
| Logic (Analyst (Delta)) | {PASS/FAIL} | {top finding or "Clean"} |
| Security (Engineer (Alpha)) | {PASS/FAIL} | {top finding or "Clean"} |
| Quality (Engineer (Alpha)) | {PASS/FAIL} | {top finding or "Clean"} |
| **Overall** | **{PASS/FAIL/WARN}** | |

{If FAIL: list all CRITICAL and HIGH findings with file:line references}
{If WARN: list MEDIUM findings as advisory notes}
{If PASS: "All checks passed. Safe to commit."}
```

### Verdict Rules

| Analyst (Delta) | Engineer (Alpha) | Overall |
|---------|-------|---------|
| PASS | PASS (no MEDIUM+) | **PASS** |
| PASS | PASS (MEDIUM findings) | **WARN** |
| PASS | FAIL | **FAIL** |
| FAIL | PASS | **FAIL** |
| FAIL | FAIL | **FAIL** |

### Machine-Parseable Envelope

For webshell supervisor alert rendering, wrap the verdict in a parseable envelope:

```json
{
  "type": "code_verify_verdict",
  "verdict": "PASS | FAIL | WARN",
  "timestamp": "<ISO-8601>",
  "target": "<resolved target>",
  "phases": {
    "quantum": {
      "verdict": "PASS | FAIL",
      "confidence": "<badge>",
      "logic_gaps": 0,
      "edge_cases": 0
    },
    "corso": {
      "verdict": "PASS | FAIL",
      "counts": {"critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0}
    }
  },
  "blocking_findings": [],
  "advisory_findings": []
}
```

## Pipeline Integration

When used as a `--then code_verify` phase in a SQUAD pipeline:
- Receives `{files_changed, project_root}` from the transition registry
- Skips Step 1 target resolution (already resolved)
- Runs Step 2 and Step 3 as normal
- On FAIL: halts the pipeline, reports findings, does NOT proceed to next phase
- On WARN: proceeds to next phase with advisory notes attached
- On PASS: proceeds to next phase

Recommended pipeline: `software_engineering --then code_verify --then guard --then code_review`

## Contract Canon Integration (Cookbook §82)

Governed by `agent.skill.code-verify`. Reads every `standards/canon/contracts/code.trait/*` and verifies via grep / rust-analyzer-lsp:
1. `trait_path` exists in source
2. Each `method_contracts[].name` maps to a function with a signature consistent with the contract's preconditions + postconditions
3. Each `observability.required_spans[].name` is emitted at the call sites the contract declares

Findings carry `contract_id` field. Routing: HIGH for missing trait impls, MEDIUM for signature drift. Re-runs `make contract-gate` before reporting clean. Emits `skill.code-verify.invoke` span. No `status_per_provider` mutations.

## Graceful Degradation

If a sibling MCP is unavailable:

- **Analyst (Delta) unavailable**: Run Engineer (Alpha) only. Verdict downgrades: PASS becomes WARN with note "Logic verification skipped (Analyst (Delta) unavailable)."
- **Engineer (Alpha) unavailable**: Run Analyst (Delta) only. Verdict downgrades: PASS becomes WARN with note "Security/quality scan skipped (Engineer (Alpha) unavailable)."
- **Both unavailable**: Report error, suggest `/REVIEW` as fallback.
