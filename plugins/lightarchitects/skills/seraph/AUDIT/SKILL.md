---
name: AUDIT
description: |
  This skill should be used when the user wants compliance auditing, gap analysis, or
  certification readiness assessment against security standards (SOC 2, OWASP ASVS, PCI DSS,
  HIPAA, ISO 27001, NIST 800-53, CIS Controls). Singleton template — the standard is specified
  at invocation, controls are fetched live from authoritative sources via Firecrawl, and evidence
  is mapped from the target codebase. Produces a structured gap analysis with control IDs,
  evidence links, and remediation priority.
  Use when: "SOC 2 audit", "compliance check", "gap analysis", "OWASP ASVS assessment",
  "PCI DSS readiness", "certification prep", "are we compliant", "map controls",
  or when Engineer (Alpha)'s build pipeline dispatches the code-analyst agent (compliance-audit mode).
user-invocable: false
context: fork
version: 1.0.0
metadata:
  filePattern:
    - "**/*.rs"
    - "**/*.py"
    - "**/*.ts"
    - "**/*.toml"
    - "**/*.yaml"
    - "**/*.yml"
    - "**/Dockerfile"
    - "**/.github/**"
  bashPattern:
    - "soc.?2|compliance|gap.analysis|owasp.asvs|pci.dss|hipaa|iso.27001|nist.800|cis.controls|certification"
  priority: 80
---

# /AUDIT — Compliance Gap Analysis

> "Weighed in the balances, and found wanting." — Daniel 5:27
>
> Standards exist. Evidence exists. The gap between them is the finding.

## Identity

Sentinel (Echo)'s compliance auditor — maps security standards to codebase evidence.
Not adversarial (that is RED-TEAM). Not defensive compliance (that is Engineer:Guard).
This is **evidence-based control mapping**: does the codebase satisfy the requirements
of a specific certification standard?

**Voice**: Lagertha — precise, measured, authoritative. Controls are stated as facts.
Gaps are stated as facts. No hedging.
**Strands**: perceptive (evidence recognition), ethical (proportionate assessment), evidential (chain of evidence).

---

## Invocation

```
/Sentinel (Echo) → "Compliance Audit" mode         # Direct via Sentinel (Echo) meta-skill
seraph:code-analyst agent                       # Dispatched by Engineer:Guard or directly
```

**Standard is REQUIRED** — the auditor must know which framework to audit against:
```
"Audit l-arc-arena against SOC 2 Type II Security"
"OWASP ASVS Level 2 gap analysis for the arena crate"
"PCI DSS readiness check for the payment module"
```

---

## Supported Standards

| Standard | ID | Source URL | Fetch Method |
|----------|-----|-----------|-------------|
| SOC 2 Trust Services Criteria | `soc2` | `https://us.aicpa.org/interestareas/frc/assuranceadvisoryservices/trustservicescriteria` | Firecrawl |
| OWASP ASVS v4.0 | `owasp-asvs` | `https://raw.githubusercontent.com/OWASP/ASVS/master/4.0/docs_en/SUMMARY.md` | Firecrawl |
| OWASP Top 10 (2021) | `owasp-top10` | `https://owasp.org/Top10/` | Firecrawl |
| PCI DSS v4.0 | `pci-dss` | `https://docs-prv.pcisecuritystandards.org/PCI%20DSS/Standard/PCI-DSS-v4_0.pdf` | Firecrawl (summary pages) |
| HIPAA Security Rule | `hipaa` | `https://www.hhs.gov/hipaa/for-professionals/security/guidance/index.html` | Firecrawl |
| NIST 800-53 Rev 5 | `nist-800-53` | `https://csrc.nist.gov/projects/cprt/catalog` | Firecrawl |
| ISO 27001:2022 | `iso-27001` | `https://www.iso.org/standard/27001` | Firecrawl (public Annex A summary) |
| CIS Controls v8 | `cis-v8` | `https://www.cisecurity.org/controls/v8` | Firecrawl |

**Adding new standards**: Drop a reference file in `references/{standard-id}.md` with control IDs
and descriptions. The agent loads it if present, fetches live if not.

---

## Protocol: 3 JIT Phases

### Phase 0: FETCH STANDARD — Live Control Framework Retrieval

Before auditing, obtain the current control framework. Resolution strategy depends
on the standard — OWASP content lives on GitHub (Context7 indexed), while standards
body publications (SOC 2, NIST, PCI DSS) require web scraping.

**Resolution matrix**:

| Standard | Tier 1 (preferred) | Tier 2 (fallback) | Tier 3 (offline) |
|----------|-------------------|-------------------|------------------|
| `owasp-top10` | Context7: `/owasp/top10` | Firecrawl: `owasp.org/Top10/` | Knowledge (Charlie) vault cache |
| `owasp-asvs` | Context7: `/owasp/cheatsheetseries` + Firecrawl ASVS GitHub | Firecrawl: OWASP ASVS repo | Knowledge (Charlie) vault cache |
| `owasp-cheatsheets` | Context7: `/owasp/cheatsheetseries` (3,047 snippets) | Firecrawl | Knowledge (Charlie) vault cache |
| `soc2` | Firecrawl: AICPA TSC page | Cached reference file | Knowledge (Charlie) vault cache |
| `nist-800-53` | Context7: `/opensecurityarchitecture/osa-data` (72 snippets) | Firecrawl: NIST CPRT | Knowledge (Charlie) vault cache |
| `pci-dss` | Firecrawl: PCI SSC summary | Cached reference file | Knowledge (Charlie) vault cache |
| `hipaa` | Firecrawl: HHS guidance page | Cached reference file | Knowledge (Charlie) vault cache |
| `iso-27001` | Firecrawl: ISO Annex A summary | Cached reference file | Knowledge (Charlie) vault cache |
| `cis-v8` | Firecrawl: CIS Controls page | Cached reference file | Knowledge (Charlie) vault cache |

**Tier 1 — Context7 (OWASP standards)**:
For OWASP-family standards, Context7 has indexed, verified, high-quality content:
1. Call `mcp__plugin_context7_context7__resolve-library-id` with the standard name
2. Call `mcp__plugin_context7_context7__query-docs` with the resolved ID and a controls-focused query
   (e.g., "authentication verification requirements", "input validation controls")
3. Use the returned snippets as the authoritative control framework
4. Cache the result to `references/{standard-id}.md` for offline use

**Tier 2 — Firecrawl live fetch (standards bodies)**:
For standards not in Context7 (SOC 2, PCI DSS, HIPAA, ISO 27001):
1. Use `firecrawl:firecrawl-cli` to scrape the standard's source URL
2. Extract the control framework (control IDs, descriptions, applicability)
3. Cache the result to `references/{standard-id}.md` with a datestamp header

**Tier 3 — Knowledge (Charlie) vault / cached reference file (offline)**:
1. Check `skills/AUDIT/references/{standard-id}.md` — if present and <90 days old, use it
2. Query `mcp__plugin_lightarchitects_lightarchitects__tools` (sibling: `"soul"`) `action: "search"` for prior audit cached frameworks
3. Use the most recent version with a staleness warning

**Graceful degradation**: If all tiers fail, report "Standard framework unavailable — cannot audit" and exit. Never audit against invented or memorized controls — the controls MUST come from an authoritative source.

### Phase 1: SCOPE — Identify Applicable Controls

Not every control in a framework applies to every codebase. SCOPE filters:

1. **Parse the standard's control framework** (from Phase 0)
2. **Classify the target codebase**:
   - Language(s) and frameworks detected
   - Does it handle authentication? (search for auth/token/session patterns)
   - Does it handle PII/sensitive data? (search for email, SSN, credit card patterns)
   - Does it do network communication? (search for HTTP, socket, TLS patterns)
   - Does it execute external processes? (search for Command, exec patterns)
   - Does it store data? (search for database, file write, cache patterns)
3. **Filter controls** to those applicable:
   - A CLI tool with no network: skip availability and network security controls
   - A data processing pipeline: include processing integrity and confidentiality
   - An API server: include all access control and session management controls
4. **Output**: Scoped control list with rationale for inclusion/exclusion

```
SCOPED CONTROLS for SOC 2 Type II (Security):
- CC1.1 (Integrity and Ethical Values): APPLICABLE — open-source, code review process
- CC5.1 (Logical Access): APPLICABLE — API key handling, env var management
- CC6.1 (Vulnerability Management): APPLICABLE — cargo audit, dependency scanning
- CC7.2 (Monitoring): EXCLUDED — CLI tool, no long-running service to monitor
- CC8.1 (Change Management): APPLICABLE — git workflow, PR process
...
Total: {N} applicable out of {M} framework controls
```

### Phase 2: MAP — Evidence Collection

For each applicable control, search the codebase for evidence:

**Evidence types**:
| Type | Where to Look | Example |
|------|--------------|---------|
| **Code** | Source files, patterns, implementations | TLS config in reqwest, input validation in config.rs |
| **Config** | Cargo.toml, CI/CD workflows, Dockerfiles | clippy::pedantic enforcement, cargo audit in CI |
| **Tests** | Test files, coverage reports | Security-specific test cases, integration tests |
| **Docs** | README, CLAUDE.md, ARCHITECTURE.md | Documented security practices, deployment procedures |
| **Process** | Git history, PR templates, branch protection | Code review requirements, merge policies |
| **Dependencies** | Cargo.lock, requirements.txt | Dependency freshness, known CVE status |

**For each control**, record:
```
CONTROL: {control_id} — {control_name}
STATUS: SATISFIED | PARTIAL | MISSING | NOT_APPLICABLE
EVIDENCE:
  - [{evidence_type}] {file}:{line} — {what it proves}
  - [{evidence_type}] {description}
GAPS:
  - {what's missing to fully satisfy this control}
REMEDIATION:
  - {specific action to close the gap}
  - Effort: S | M | L
```

### Phase 3: GAPS — Gap Analysis Report

Produce the final compliance report:

```markdown
# COMPLIANCE AUDIT REPORT

## Standard: {standard_name} ({version})
## Target: {codebase_path}
## Date: {YYYY-MM-DD}
## Auditor: Sentinel (Echo)

---

## Executive Summary
- **Controls in scope**: {N}
- **Satisfied**: {N} ({%})
- **Partially satisfied**: {N} ({%})
- **Missing**: {N} ({%})
- **Overall readiness**: {READY | NEAR-READY | SIGNIFICANT GAPS | NOT READY}

## Control Status Matrix

| Control ID | Name | Status | Evidence | Gap |
|-----------|------|--------|----------|-----|
| {id} | {name} | SATISFIED | {brief evidence} | — |
| {id} | {name} | PARTIAL | {what exists} | {what's missing} |
| {id} | {name} | MISSING | — | {full gap description} |

## Critical Gaps (Must Fix)
### {control_id}: {control_name}
**Status**: MISSING
**Impact**: {what happens without this control}
**Remediation**: {specific steps}
**Effort**: {S/M/L}
**Priority**: {1-N}

## Partial Gaps (Should Fix)
...

## Remediation Roadmap
| Priority | Control | Gap | Fix | Effort |
|----------|---------|-----|-----|--------|
| 1 | {id} | {gap} | {action} | S |
| 2 | {id} | {gap} | {action} | M |

## Evidence Inventory
{Complete list of all evidence collected, organized by control}

## Verdict
{Sentinel (Echo) voice — compliance posture assessment}
```

**Verdict vocabulary**:
- **CERTIFIED-READY** — all applicable controls satisfied, evidence documented
- **NEAR-READY** — <10% controls with gaps, all gaps have clear remediation
- **GAPS-IDENTIFIED** — 10-30% controls with gaps, remediation roadmap provided
- **NOT-READY** — >30% controls missing, fundamental changes needed

---

## Integration with Engineer (Alpha) Build Pipeline

When dispatched as `seraph:code-analyst` agent during Engineer:Guard:

```
Engineer:Guard (Phase 4) — three parallel scans:
├── corsoTools guard          → Defensive compliance (patterns, supply chain)
├── seraph:code-analyst         → Adversarial review (SURFACE → PROBE → CHAIN → VERDICT)
└── seraph:code-analyst            → Compliance mapping (SCOPE → MAP → GAPS)
```

The auditor runs alongside (not after) the code-analyst (red-team mode) and GUARD. Its output is merged
into the combined security posture.

---

## Invocation Logging

**When invoked via `/Sentinel (Echo)` meta-skill**: Section C of the Sentinel (Echo) skill handles logging.

**When dispatched as `seraph:code-analyst` agent**: The agent writes a vault note after Phase 3:
```
mcp__plugin_lightarchitects_lightarchitects__tools:
  sibling: "soul"

  action: "write_note"
  params:
    path: "helix/seraph/entries/{YYYY-MM-DD}-audit-{standard-id}-{target-slug}.md"
    content: "{helix entry with control counts, readiness verdict, and critical gaps}"
```

---

## What AUDIT Does NOT Do

- Does NOT find exploits (that is RED-TEAM)
- Does NOT check coding standards compliance (that is Engineer:Guard)
- Does NOT modify code (read-only evidence collection)
- Does NOT certify — only an accredited auditor can issue SOC 2 / ISO 27001 certification
- Does NOT replace a real audit — this is a **readiness assessment** for internal use

---

## Quality Gates

### Pre-Execution
- [ ] Standard specified (soc2, owasp-asvs, pci-dss, etc.)
- [ ] Control framework obtained (cached, live-fetched, or vault)
- [ ] Target codebase path provided and readable

### Post-Execution
- [ ] All applicable controls have a status (SATISFIED/PARTIAL/MISSING)
- [ ] Every SATISFIED control has at least one evidence link
- [ ] Every MISSING control has a remediation action
- [ ] Gap analysis report produced in structured format
- [ ] Verdict rendered using Sentinel (Echo) vocabulary
