---
name: GUARD
description: "Security & Deployment domain context. Dual-scan: Engineer (Alpha) defensive compliance (4,997
  vulnerability patterns, supply chain audit) runs in parallel with Sentinel (Echo) adversarial red team
  (trust boundary analysis, exploit chains). Threat model injection, language-specific threat
  detection, deploy gate enforcement. Combined verdict from both scans."
user-invocable: false
context: fork
agent: C0RS0
version: 5.0.0
---

# /GUARD — Security & Deployment Domain

> Build Phase 4/7: AUDIT — Scan for threats after code is linted, before testing

## Lifecycle Context

Follows **SNIFF** (detect code issues) -> feeds into **CHASE** (verify fixes pass tests).

The primary security and deployment entry point for C0RS0. Loads **threat modeling, vulnerability scanning, supply chain auditing, and deploy gate enforcement** context into C0RS0, which then executes directly using security MCP tools.

```
Claude -> loads GUARD context -> C0RS0 executes with guard tool
```

---

## Protocol

### Step 1: Gather Requirements (if spec is vague)

1. Gather security-specific context:
   - **Objective**: What to audit, scan, or secure?
   - **Scope**: Which project, modules, files, infrastructure?
   - **Compliance**: OWASP, SOC2, GDPR, HIPAA, or internal standards?
   - **Known concerns**: Prior findings, suspected vulnerabilities?
   - **Threat actors**: Internal, external, supply chain?
   - **Deploy target**: Cloud, on-prem, container, serverless?
2. Synthesize into a clear specification
3. Present spec for confirmation

### Step 1.5: Plugin Enrichment (Mandatory)

Before security analysis, query external plugins for supply chain intelligence and security documentation. Run all queries in parallel.

1. **Sonatype Dependency Scan** (RULE 5 — Dependency Safety Gate):
   - Call `mcp__plugin_sonatype-guide_sonatype-guide__getRecommendedComponentVersions` for each new or updated dependency in scope
   - Call `mcp__plugin_sonatype-guide_sonatype-guide__getLatestComponentVersion` to verify dependency freshness
   - Flag any dependencies with known CVEs, outdated versions, or license conflicts
   - Include Sonatype findings as supply chain context for the guard action

2. **Context7 Security Docs**: Query for security best practices of the specific frameworks in scope.
   - Call `mcp__plugin_context7_context7__resolve-library-id` with the framework name
   - Call `mcp__plugin_context7_context7__query-docs` with a security-focused query (e.g., "security best practices", "authentication patterns", "input validation")
   - Include Context7 security docs as verified reference for the threat model

**Graceful skip**: If Sonatype or Context7 are unavailable, log the skip and proceed with internal scanning only. Plugin enrichment augments but does not replace GUARD's 4,997 vulnerability patterns.

### Step 2: Execute Defensive + Adversarial Scans (Parallel)

**Three complementary scans run in parallel:**

1. **CORSO GUARD (defensive compliance)**: `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "corso"`, `action: "guard"` — 4,997 vulnerability patterns, supply chain audit, coding violations, secrets detection. Checks: "Does this code follow security standards?"

2. **Sentinel (Echo) RED-TEAM (adversarial analysis)**: Dispatch `seraph:code-analyst` agent — adversarial source code review across 4 JIT phases (SURFACE → PROBE → CHAIN → VERDICT). Checks: "How can an attacker break this?"

3. **Sentinel (Echo) AUDIT (compliance mapping)** *(optional — when a standard is specified)*: Dispatch `seraph:code-analyst` agent — maps controls from a named standard (SOC 2, OWASP ASVS, etc.) to codebase evidence across 3 JIT phases (SCOPE → MAP → GAPS). Checks: "Does this codebase satisfy the certification requirements?"

**Agent dispatch** (run alongside the `guard` tool call):

```
Agent:
  subagent_type: "lightarchitects:security"
  description: "Sentinel (Echo) red team {workspace_name}"
  run_in_background: true
  prompt: |
    MODE: red-team
    You are Sentinel (Echo) operating in offensive security mode. Execute the RED-TEAM cycle (SURFACE → PROBE → CHAIN → VERDICT).

    INDUSTRY BASELINES (MANDATORY — ground your assessment):
    Read your domain's industry-baselines.md file first:
    - Sentinel (Echo) (security): ~/lightarchitects/soul/helix/seraph/industry-baselines.md ([S] gate)
      Key standards: OWASP Top 10, MITRE ATT&CK/ATLAS, NIST SSDF, ISO 27001, CIS Controls, SLSA, SBOM
    Cite baselines per Canon XXXV (verbatim quotes from primary sources).

    TARGET: {workspace_path}
    LANGUAGE: {detected language(s)}
    PRIOR FINDINGS: {SNIFF/GUARD findings from Step 1.5, or "none"}
    HARDEN: false
    CONSTRAINTS: report only — fixes applied separately
```

**AUDIT agent dispatch** (optional — only when a compliance standard is specified):

```
Agent:
  subagent_type: "lightarchitects:security"
  description: "Sentinel (Echo) compliance audit ({standard}) for {workspace_name}"
  run_in_background: true
  prompt: |
    MODE: compliance-audit
    You are Sentinel (Echo) operating in compliance audit mode. Execute the AUDIT cycle (SCOPE → MAP → GAPS).

    INDUSTRY BASELINES (MANDATORY — ground your assessment):
    Read your domain's industry-baselines.md file first:
    - Sentinel (Echo) (security): ~/lightarchitects/soul/helix/seraph/industry-baselines.md ([S] gate)
      Key standards: OWASP Top 10, MITRE ATT&CK/ATLAS, NIST SSDF, ISO 27001, CIS Controls, SLSA, SBOM
    - For {standard}: Cross-reference with specific control framework (SOC 2, OWASP ASVS, PCI DSS, etc.)
    Cite baselines per Canon XXXV (verbatim quotes from primary sources).

    TARGET: {workspace_path}
    STANDARD: {soc2|owasp-asvs|pci-dss|...}
    LANGUAGE: {detected language(s)}
    PRIOR FINDINGS: {GUARD findings, or "none"}
    CONSTRAINTS: full audit
```

**When to dispatch the compliance audit**: Only when the operator explicitly requests a compliance standard
(e.g., "SOC 2 audit", "OWASP ASVS check"), or when the build plan specifies a compliance target.
The compliance audit is NOT dispatched on every GUARD run — it's opt-in.

**Result merging**: After all scans complete, merge findings:
- Engineer:Guard findings = compliance items (standards violations, missing patterns)
- Sentinel (Echo) RED-TEAM findings = adversarial items (exploitable vulns, attack chains)
- Combined verdict: PASS requires **both** GUARD clean (zero HIGH/CRITICAL) AND RED-TEAM HARDENED or FORTIFIED

**Graceful degradation**: If Sentinel (Echo) plugin is unavailable (MCP not connected, agent fails to launch), GUARD proceeds with defensive scan only. Log: "Sentinel (Echo) RED-TEAM unavailable — defensive scan only." Sentinel (Echo) augments GUARD but does not block it.

### Step 2a: Engineer (Alpha) Defensive Scan

Use `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "corso"`, `action: "guard"` for comprehensive security analysis (includes path-based scanning), applying all threat intelligence context, Sonatype supply chain data, and Context7 security docs below.

### Step 2b: Collect Sentinel (Echo) Results

After the Sentinel (Echo) agent completes (poll via `TaskOutput`):
- Parse the RED-TEAM report (findings table, exploit chains, verdict)
- Append Sentinel (Echo) findings to the GUARD output
- If Sentinel (Echo) found CRITICAL/HIGH items that GUARD missed, flag them prominently
- Combined security posture uses the WORSE of the two verdicts

---

## Quality Gates

### Pre-Execution
- [ ] Scope and objectives defined
- [ ] Threat model applied for target language
- [ ] Supply chain gate checklist included
- [ ] Deploy gate stages defined (if deployment scope)

### Post-Execution
- [ ] Engineer:Guard verdict: pass (zero HIGH/CRITICAL compliance findings)
- [ ] Sentinel (Echo) RED-TEAM verdict: HARDENED or FORTIFIED (or gracefully skipped)
- [ ] Combined security posture: uses WORSE of both verdicts
- [ ] Supply chain audit: zero critical/high CVEs
- [ ] No hardcoded secrets detected
- [ ] All acceptance criteria met

---

## Threat Model (from `security.rs:infer_threat_model`)

Scan code for these patterns and assess threat level:

| Pattern | Keywords | Threats |
|---------|----------|---------|
| Filesystem | `fs::`, `File::`, `open(`, `Path` | Path traversal, symlink attacks, TOCTOU |
| Network | `http`, `tcp`, `socket`, `TcpListener` | MITM, injection, DoS, SSRF |
| Unsafe | `unsafe`, `transmute`, `from_raw` | Memory corruption, UB, use-after-free |
| Command | `Command::new`, `exec`, `system(` | Command injection, privilege escalation |
| Deserialization | `serde`, `Deserialize`, `from_str` | Type confusion, denial of service |
| Cryptography | `rand`, `hash`, `encrypt`, `sign` | Weak algorithms, key exposure |
| Authentication | `token`, `session`, `auth`, `password` | Credential theft, session hijacking |

---

## Language-Specific Threats (from `security.rs`)

**Rust**:
- `.unwrap()` -> panic in production (DoS vector)
- Integer overflow -> `checked_*` required
- `unsafe` blocks -> must have `// SAFETY:` justification
- `transmute` -> almost always wrong, audit carefully
- Raw pointer dereference -> prove aliasing rules satisfied

**JavaScript**:
- `innerHTML`, `document.write` -> XSS
- `eval()`, `Function()` -> code injection
- `__proto__`, `prototype` -> prototype pollution
- `JSON.parse` on untrusted input -> DoS via large payloads

**Python**:
- `eval()`, `exec()` -> code injection
- `pickle.loads()` -> arbitrary code execution
- f-strings with user input -> injection
- `os.system()`, `subprocess` without shell=False -> command injection
- SQL string formatting -> SQL injection (use parameterized queries)

**Go**:
- `defer` in loops -> resource leaks
- Goroutine leaks -> unbounded goroutine creation
- `unsafe.Pointer` -> memory corruption

---

## Supply Chain Gate (from Gold Standard S12)

| Check | Requirement | Blocking |
|-------|------------|----------|
| `cargo audit` | Zero critical/high CVEs | Yes |
| Dependency freshness | Updated within 12 months | Warning |
| License whitelist | MIT, Apache-2.0, BSD only | Yes |
| Lockfile committed | `Cargo.lock` in version control | Yes |
| Minimal deps | Prefer std library over crates | Advisory |

---

## Deploy Gate (from `infrastructure.rs`)

**CI/CD Pipeline Stages**:
1. Source control trigger (git push, PR)
2. Build (language-specific compilation)
3. Test suite (unit + integration)
4. Lint / format check
5. **Security scan** (SAST, dependency audit)
6. Container build (if applicable)
7. Registry push
8. Deploy to staging
9. Health check
10. Deploy to production
11. Monitoring enabled

**Container Security**:
- Multi-stage Docker builds (minimize attack surface)
- Non-root user in container
- No secrets in image layers
- Pin base image versions (no `latest` tag)
- Scan container images for CVEs

**Secrets Management**:
- Use `corsoTools` action: `guard` secrets mode
- Never hardcode API keys, tokens, passwords
- Environment variables or secrets manager only
- Rotate credentials regularly
- Audit access logs

---

## Coding Violations to Report

| Violation | Severity | Rule |
|-----------|----------|------|
| `.unwrap()` in production | HIGH | no-unwrap |
| `.expect()` in production | HIGH | no-expect |
| `panic!()` macro | HIGH | no-panic |
| `unsafe` without `// SAFETY:` | HIGH | unsafe-comment |
| Hardcoded secrets | CRITICAL | no-secrets |
| SQL string concatenation | CRITICAL | sql-injection |
| `eval()` / `exec()` | CRITICAL | no-eval |
| Missing input validation | MEDIUM | input-validation |
| Unbounded loop | MEDIUM | bounded-loops |
| Missing error handling | MEDIUM | handle-errors |

---

## Cross-Domain Context

| When | Skill Context | MCP Tools |
|------|--------------|-----------|
| Security findings need code fixes | SNIFF (review) / HUNT (generation) | `corsoTools` actions: `code_review`, `sniff` |
| Fixes need regression testing | CHASE | `corsoTools` action: `chase` |
| Researching CVEs, security advisories | FETCH | `corsoTools` action: `fetch` |

---

## MCP Tools Available

| Tool | Owner | Purpose | Dispatch |
|------|-------|---------|----------|
| `corsoTools` action: `guard` | CORSO | Defensive compliance (4,997 vulnerability patterns) + path-based scanning | Always |
| `seraph:code-analyst` agent | Sentinel (Echo) | Adversarial source code review (SURFACE → PROBE → CHAIN → VERDICT) | Always (graceful skip if unavailable) |
| `seraph:code-analyst` agent | Sentinel (Echo) | Compliance mapping against named standards (SOC 2, OWASP, etc.) | Opt-in (when standard specified) |
