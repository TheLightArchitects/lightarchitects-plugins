---
name: SECURE
description: "Security assessment pipeline via SQUAD. Validates scope.toml 5-gate
  governance, selects threat model, discloses write path, then delegates to SQUAD
  security → fix → code_review. Equivalent to the full Sentinel (Echo) engagement cycle +
  Engineer:Guard with parallel execution. Use when the user says '/secure', 'security
  audit', 'security scan', 'pentest this', 'is this secure'."
user-invocable: true
version: 2.0.0
context: root
---

# /SECURE — Security Assessment Pipeline

> Thin wrapper: scope 5-gate check + threat model selection → SQUAD security → fix → code_review.

## When to Use

- User wants a security audit of code, infrastructure, or architecture
- Pre-deploy security gate
- User says `/secure`, "security audit", "security scan", "is this secure"
- After a dependency update (supply chain check)

## Accepted Flags

| Flag | Expansion | Effect |
|------|-----------|--------|
| `--fix` | Already in default pipeline | `security → fix → code_review` (default) |

Rejected flags: `--then`, `--watch`, `--drain`, `--research`.

## Step 1: Argument Validation (SAFEGUARD #24)

Validate the target before proceeding. Pattern: `^[a-zA-Z0-9_/. -]+$`

Reject SQUAD control flags, shell metacharacters, and path traversal in the target argument. See SAFEGUARD #24 in `references/meta-skills.md` for the full error template.

## Step 2: Scope Validation (Sentinel (Echo) ScopeGovernor — 5 gates)

**Mandatory before any SQUAD invocation.** Read `~/.seraph/scope.toml` and validate all 5 gates:

| Gate | Check | On failure |
|------|-------|-----------|
| **1. TTL** | `scope.expires` is in the future | HALT — scope expired, ask the operator to update |
| **2. Target** | Target is in `scope.targets` list | HALT — target not in authorized scope |
| **3. Tool** | Assessment tools (scan, osint, analyze) are in `scope.allowed_tools` | HALT — tool not authorized |
| **4. Concurrent** | No other Sentinel (Echo) engagement currently running | HALT — concurrent engagement in progress |
| **5. Domain** | Target domain matches `scope.domain` (web, network, source-code, infra) | HALT — domain mismatch |

All 5 gates must pass. If any gate fails, HALT immediately — do not proceed to SQUAD. Report which gate failed and what change is required.

## Step 3: Threat Model Selection

Based on the target type, select and **read** the relevant baselines.
Root: `~/lightarchitects/soul/helix/user/standards/industry-baselines/security/`

**Confidence Threshold Gate** (Canon XXXV): Every severity assessment requires
`confidence_value` (0.00–1.00) + `primary_source_citations[]` (verbatim, IEEE format).
- CRITICAL/HIGH findings: ≥95% confidence required (VALIDATED)
- MEDIUM findings: ≥85% confidence (STRONG)
- LOW/INFO: ≥60% confidence (MODERATE)
UNVALIDATED findings (<95% for CRITICAL/HIGH) → escalate to Tier 1–4 research
(Knowledge (Charlie) helix → Context7 → Firecrawl → sibling consultation) before reporting.

| Target type | Baselines to load | Framework tags |
|-------------|-------------------|----------------|
| Source code (line / function / file / files) | `mitre/mitre-cwe-top-25-2024-2026-05-04.md`, `owasp/owasp-proactive-controls-2024-2026-05-05.md`, `owasp/owasp-asvs-2026-05-04.md` | CWE Top 25, ASVS v4, Proactive Controls 2024 |
| Application | `owasp/owasp-top-10-2021-2026-05-04.md`, `owasp/owasp-asvs-2026-05-04.md`, `ptes/ptes-methodology-2026-05-05.md` | OWASP Top 10, ASVS, PTES |
| API endpoints | `owasp/owasp-api-security-top-10-2023-2026-05-04.md`, `owasp/owasp-asvs-2026-05-04.md` | API Top 10 2023, ASVS §13 |
| Links / URLs / web surface | `owasp/owasp-top-10-2021-2026-05-04.md`, `owasp/owasp-cheatsheet-series-index-2026-05-05.md` | OWASP Top 10, Cheat Sheet Series |
| LLM / AI model code | `owasp/owasp-llm-top-10-v2.0-2026-05-05.md`, `owasp/owasp-llm-prompt-injection-cheatsheet-2026-05-05.md`, `google/google-saif-risks-2026-05-05.md`, `mitre/mitre-atlas-2026-05-04.md` | LLM Top 10 v2.0, SAIF 2.0, ATLAS |
| MCP agent / agentic system | `owasp/owasp-top-10-agentic-2026-2026-05-05.md`, `owasp/owasp-llm-prompt-injection-cheatsheet-2026-05-05.md`, `google/google-saif-risks-2026-05-05.md` | Agentic Top 10 2026, SAIF Secure Agents |
| Infrastructure / network | `mitre/mitre-attack-enterprise-2026-05-04.md`, `nist/nist-csf-v2.0-2026-05-04.md`, `mitre/atomic-red-team-2026-05-05.md` | ATT&CK Enterprise, CSF v2, Atomic Red Team |
| Dependencies / supply chain | `openssf/` (SLSA), `nist/nist-ssdf-v1.1-2026-05-04.md`, `mitre/mitre-cwe-top-25-2024-2026-05-04.md` | SLSA, SSDF, CWE Top 25 |
| Architecture review | `mitre/mitre-attack-enterprise-2026-05-04.md`, `owasp/owasp-asvs-2026-05-04.md`, `ptes/ptes-methodology-2026-05-05.md` | ATT&CK, ASVS threat modeling, PTES |

**Always load** `ptes/ptes-methodology-2026-05-05.md` as the red team execution backbone regardless of target type.

Extract the top applicable attack patterns and present them alongside the threat model before invoking SQUAD.

**Inline IEEE citation protocol** (Canon XXXVI): All findings in the final report must cite
sources verbatim in IEEE format: `[1] Author, "Title," Year. URL`. Citations must be dated
within 90 days or re-scraped via Firecrawl. Confidence-threshold gate (Canon XXXV) applies:
every finding includes `confidence_value`, `primary_source_citations[]`, `validation_status`.

## Step 4: HITL Gate — Write-Path Disclosure (SAFEGUARD #21)

```
SQUAD: security → fix → code_review
Agents: ~4–6 | Estimated tokens: ~40–70K
WRITES CODE: fix phase will create branches and open PRs for confirmed vulnerabilities.
  - Branch pattern: squad/fix/{agent-name}
  - Merge strategy: sequential with quality gates
  - Rollback: automatic on gate failure
Proceed? [y/N]
```

## Step 5: SQUAD Invocation

```
/SQUAD security "<target>" --then fix --then code_review
```

SQUAD agents in the `security` preset run the full SERAPH engagement cycle (SCOPE→RECON→SURVEY→EXAMINE→STRIKE→REPORT) with CORSO GUARD as the defensive layer in parallel. The `sibling: seraph` routing is embedded in the security preset definition — "scan" actions are directed to SERAPH, not QUANTUM. Full cycle instructions are in `references/presets.md`.

## Contract Canon Integration (Cookbook §82)

This skill is governed by `agent.skill.secure` at `standards/canon/contracts/agent.skill/secure.yaml`. The five §82.3 touchpoints:

### Read
- `standards/canon/contracts/operator.surface/*` — for `forbidden_behaviors[]` and `render_safety` block
- `standards/canon/contracts/provider.llm/*` — for SSRF / auth / credential rules
- `standards/canon/contracts/code.trait/*` — for `panic_free`, `send_sync_required`, error_variants in method_contracts
- `standards/canon/contracts/hmac_chain.audit_trail/*` — for tamper-evidence requirements

### Touched-contract citation
Each finding emitted by /SECURE has a `contract_refs:` field carrying contract ids whose `forbidden_behaviors` or `render_safety` rules the finding cites.

### forbidden_behaviors enforcement (S5 dimension)
Already implemented at /GATE S5 — /SECURE runs the deeper version: scan ALL operator.surface contracts (not just touched), cross-reference against the full branch diff, route findings via OWASP LLM01-LLM10 classes.

### required_spans emission
`/SECURE` emits `skill.secure.invoke` (parent_relationship: child_of_caller) with metadata: `scope, branch, findings_critical, findings_high, findings_medium, owasp_classes_flagged`.

### status_per_provider impact
None — /SECURE does not run conformance tests. It can recommend that a contract's `status_per_provider.<P>.result` be flipped to FAIL based on security findings, but the mutation is performed by /VERIFY V4.

### SSRF guard verification (Cookbook §63.P5)
For any diff that touches `provider.llm` base_url handling, verify ancestor-walk canonicalization is present per Cookbook §63.P5 + provider.llm contract `forbidden_behaviors`. Loopback / private-IP / file-scheme base_urls without explicit operator approval = `E_SECURE_SSRF` BLOCKING.

## Graceful Degradation

If SQUAD is unavailable:

1. SERAPH scan: `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "seraph"` action:`scan` target:`"<target>"`
2. CORSO guard: `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "corso"` action:`guard` path:`"<target>"`
3. Skip Analyst (Delta) parallel analysis and Monitor (Foxtrot) anomaly detection

Report: "Running sequential Sentinel (Echo) + Engineer (Alpha) scan. No parallel agents."
