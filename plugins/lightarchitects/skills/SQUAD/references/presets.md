# Preset-to-Team Mapping

Each preset defines a team composition with per-teammate task prompts. The routing priority
determines teammate order — first agent listed is the team's primary investigator.

Presets carry a `writes_code` flag that drives tier auto-selection:
- `writes_code: false` → T1 (in-session, shared context, read-only agents)
- `writes_code: true` → T2 (worktree isolation, one branch per agent)

Agent prompts include two layers:
- **Summary table**: brief role description (injected into `## Assignment` header)
- **Full Cycle Instructions**: complete MCP action sequences injected into `## Full Cycle`

Both layers are injected into the Team Spawn Template (see bottom of file).

---

## software_engineering

**Purpose**: Day-to-day coding — quality gates, DX, observability, doc coverage.
**writes_code**: true

| # | Agent | Task |
|---|-------|------|
| 1 | engineer | Lead: full build cycle (plan → fetch → code_review → implement → guard) — LASDLC [A] |
| 2 | ops | DX, CI/CD, observability, and performance: quality gate status, CI friction, deployment readiness, trace gaps, regression check — LASDLC [O+P] |
| 3 | knowledge | Helix context + doc coverage: prior decisions, architectural patterns, project history, `///` audit — LASDLC [K+D] |
| 4 | testing | Test suite validation: coverage audit, missing tests, Canon XXVII compliance — LASDLC [T] |

### Full Cycle Instructions

**engineer (primary):**
Run the full Engineer (Alpha) build cycle via MCP actions in sequence. Before each phase, pull the
sub-skill protocol on demand: `action: "get_skill"` `skill: "corso/SCOUT"` (etc.) returns
the full protocol inline. Execute that phase, then continue to the next.
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "sniff"` with plan-generation context for the target → generate a gold-standard implementation plan
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "fetch"` → research relevant docs, dependencies, and patterns via Context7 and helix
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "code_review"` on the target path → analyze existing code architecture, patterns, and quality before implementing
4. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "sniff"` with code-generation context (inject plan + fetch findings) → implement the plan with CORSO quality gates (fmt, clippy, tests)
5. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "guard"` on all changed files → post-build security scan
Output: implementation plan, code on your T2 worktree branch, guard report, test status.

**ops:**
Run DevOps assessment, observability coverage check, and performance regression scan:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "status"` → check project health and CI/CD status
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "lint"` → verify quality gates (cargo fmt, clippy, tests)
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "repo"` → review CI/CD workflow configuration, pre-commit hooks, deploy gates
4. `curl localhost:3742/api/traces?target={target}` → query existing trace coverage
5. `curl localhost:3742/api/topology` → review instrumentation topology
6. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "chase"` on changed files → detect O(n²) patterns and >5% performance regressions
Report: DX friction points, quality gate status, CI/CD gaps, uninstrumented critical paths, tracing gaps, [P] gate pass/fail verdict.

**knowledge:**
Helix context and documentation coverage:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` with the target as query → find prior decisions and related entries
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "helix"` with relevant filters → architectural decisions that constrain this work
3. Grep `pub fn\|pub struct\|pub enum\|pub trait` in changed source files → inventory all public items
4. Grep `///` in same files → check doc coverage per public item
5. If CLAUDE.md exists: Read it → verify accuracy against current codebase state
**Close-out (mandatory, every run):** `sibling: "soul"` `action: "write_note"` with `type: decision_log`, content covering the target, key decisions made, why, and what to surface next run — unconditionally, regardless of significance score. The vault must accumulate from real work.
If significance >= 7.0: additionally `sibling: "eva"` `action: "enrich"` → full 8-layer engineering enrichment.
Report: relevant prior decisions, patterns to follow, public items missing `///`, CLAUDE.md drift (if any), [D] gate pass/fail (≥90% coverage required).

**testing:**
Audit test coverage and validate Canon XXVII compliance:
1. Glob `**/*_test.rs`, `tests/`, `spec/` → inventory all existing test files
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "code_review"` on test files → analyze coverage, identify gaps in the 6-suite pyramid
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "lint"` → run `cargo test` and measure coverage
Report: coverage percentage per suite (unit/integration/property/E2E/regression/smoke), missing suites, [T] gate pass/fail verdict.

---

## security

**Purpose**: Pentest + forensics + AppSec. Full security assessment.
**writes_code**: false

**Routing**: Scan actions default to Analyst (Delta) for research-oriented work. For active offensive
scanning (port scans, vulnerability probes, red-team operations), route explicitly to Sentinel (Echo)
by setting `sibling: seraph` in the agent prompt. Without this, scan requests go to QUANTUM's
evidence-gathering pipeline instead of Sentinel (Echo)'s engagement cycle.

**ScopeGovernor enforcement**: Before spawning any agent that calls Sentinel (Echo) scan or execute
actions, validate that `~/.seraph/scope.toml` exists and passes all 5 gates (TTL, target,
tool, concurrent, domain). If scope.toml is missing or any gate fails, HALT team spawn and
report the specific gate failure. Do not fall back to Sentinel (Echo)-less scanning — inform the user
that scope authorization is required. This fires on direct `/SQUAD security` too, not only
when invoked via `/SECURE`.

| # | Agent | Task |
|---|-------|------|
| 1 | security | Offensive lead: full engagement cycle (osint → scan → capture → analyze → close) within authorized scope — LASDLC [S] |
| 2 | quality | Defensive review: GUARD scan (OWASP Top 10, supply chain, secrets, unsafe code) — LASDLC [Q] |
| 3 | researcher | Threat research: CVE sweep, dependency risk evidence chain with confidence scores — LASDLC [R] |
| 4 | knowledge | Helix context: prior audit findings, known vulnerability patterns, security decisions — LASDLC [K] |
| 5 | ops | Runtime signals: anomalous request flows, auth bypass patterns in traces — LASDLC [O] |

### Full Cycle Instructions

**security (primary):**
Run the full Sentinel (Echo) engagement cycle within authorized scope:
1. MANDATORY: Read `~/.seraph/scope.toml`. Validate all 5 gates (TTL, target, tool, concurrent, domain). If any gate fails, HALT immediately — report the specific gate failure code and stop. Do not proceed with any scan action.
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "seraph"` `action: "osint"` on the target → passive recon: subdomain enumeration, exposed surface OSINT
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "seraph"` `action: "scan"` on the target → active vulnerability scanning, service enumeration (requires `tool: "scan"` authorized in scope.toml)
4. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "seraph"` `action: "capture"` on the target → traffic capture and analysis (skip if target is source code only)
5. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "seraph"` `action: "analyze"` with scan findings → forensic analysis of artifacts and findings
6. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "seraph"` `action: "investigate_close"` → finalize evidence chain, generate structured deliverable
Output: findings with CRITICAL/HIGH/MEDIUM/LOW/INFO severity, evidence chain, remediation guidance.

**quality:**
Run Engineer:Guard defensive code review:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "guard"` on the target path → OWASP Top 10 patterns, supply chain risks, credential exposure, unsafe code, dependency audit
Cross-reference with security agent's offensive findings for a unified risk picture.
Output: defensive findings ranked by severity, supply chain vulnerabilities, secrets detection results.

**researcher:**
Run threat research evidence chain:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "scan"` with topic as CVE/threat research → triage threat landscape for target
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "probe"` → multi-source research (SOUL helix + Context7 + HuggingFace + community advisories) for dependency CVEs and known exploit patterns
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "theorize"` with gathered evidence → threat model hypotheses with confidence badges (DEFINITIVE/STRONG/MODERATE/LOW/SPECULATIVE)
Output: CVE findings with evidence tiers, dependency risk assessment, threat model recommendations.

**knowledge:**
Pull prior security context:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` with security/vulnerability keywords → prior audit findings and remediations
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "helix"` filtering for security-tagged entries → architectural security decisions that constrain assessment
Output: prior vulnerabilities, past remediation patterns, architectural security constraints.

**ops:**
Check runtime security signals:
1. `curl localhost:3742/api/anomaly` → automated anomaly detection
2. `curl localhost:3742/api/traces?filter=auth` → authorization patterns in trace data
Output: anomalous runtime patterns, suspicious trace sequences, runtime security signals.

---

## research

**Purpose**: Deep investigation + multi-source research.
**writes_code**: false

| # | Agent | Task |
|---|-------|------|
| 1 | researcher | Lead: full 7-phase investigation cycle (scan → sweep → trace → probe → theorize → verify → close) — LASDLC [R] |
| 2 | knowledge | Helix context + creative synthesis: prior research, past decisions, institutional memory, cross-domain connections — LASDLC [K] |
| 3 | ops | Metrics evidence: runtime data that supports or contradicts research hypotheses — LASDLC [O] |

### Full Cycle Instructions

**researcher (primary):**
Run the full Analyst (Delta) investigation cycle:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "scan"` → assess the research topic, classify patterns and known unknowns
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "sweep"` → evidence collection from all available sources
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "trace"` → pattern analysis, timeline construction, root cause candidates
4. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "probe"` → 3-tier research dispatch: Tier 1 (SOUL helix sequential) + Tier 2+3 in parallel (Context7, HuggingFace, quantumTools research, Firecrawl)
5. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "theorize"` → ranked hypotheses with confidence badges (DEFINITIVE/STRONG/MODERATE/LOW/SPECULATIVE)
6. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "verify"` → validate top hypotheses against evidence via N-MultiPass
7. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "close"` → generate structured research report with evidence citations
Every claim must cite its evidence tier (PRIMARY > SECONDARY > TERTIARY).
Output: structured research report with confidence scores, evidence chain, actionable recommendations.

**knowledge:**
Pull institutional memory and apply creative synthesis:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` with the research topic → prior research entries and decisions
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "helix"` with topic filters → past architectural decisions that constrain or inform this research
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "research"` with researcher's findings as context → cross-domain synthesis, analogies, non-obvious implications
Output: prior research, past decisions, team knowledge baseline, creative synthesis layer.

**ops:**
Contribute runtime metrics evidence:
1. `curl localhost:3742/api/metrics` → current runtime metrics that support or contradict hypotheses
2. `curl localhost:3742/api/traces?filter={topic}` → trace data relevant to the research question
Output: metrics and trace evidence for researcher's hypothesis validation.

---

## devops

**Purpose**: CI/CD pipelines + deploy gates + observability.
**writes_code**: true

| # | Agent | Task |
|---|-------|------|
| 1 | ops | Lead DevOps + observability: full DevOps cycle (status → lint → repo → deploy) + observability posture — LASDLC [O] |
| 2 | quality | Quality gate enforcement: verify CI workflows enforce required standards — LASDLC [Q] |
| 3 | knowledge | Deployment history: past incidents, infrastructure decisions from helix — LASDLC [K] |
| 4 | testing | Test gate coverage: verify CI enforces test pyramid, coverage thresholds — LASDLC [T] |

### Full Cycle Instructions

**ops (primary):**
Run the full Ops (Bravo) DevOps assessment and observability check:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "status"` → check project health, binary status, dependency freshness
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "lint"` → verify quality gates: fmt, clippy, tests pass; no TODO/FIXME without ticket references
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "repo"` → review CI/CD workflows: GitHub Actions, pre-commit hooks, deployment gates configuration
4. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "deploy_gate"` → pre-deploy gate: proceed/hold/rollback with rationale (run before any production-affecting deploy)
5. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "deploy"` → assess deployment configuration: make targets, binary paths, codesign, MCP reconnect guidance
6. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "pipeline_reflect"` → post-phase reflection: capture findings + next action guidance
Output: DevOps assessment — friction points, quality gate status, CI/CD configuration review, deployment readiness report.

**quality:**
Quality gate enforcement review:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "code_review"` on CI/CD configuration files → verify workflows enforce correct standards
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "guard"` on deployment scripts → check for security issues in deploy pipelines
Output: CI/CD quality enforcement gaps, deployment script security issues.

**knowledge:**
Pull deployment history and infrastructure decisions:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` with deployment/incident keywords → past deployment failures and resolutions
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "helix"` filtering for infrastructure/ops entries → architectural decisions affecting deployment
**Close-out (mandatory, every run):** `sibling: "soul"` `action: "write_note"` with `type: decision_log`, content covering the target, key decisions, why, and what to surface next run — unconditionally, regardless of significance score.
If significance >= 7.0: additionally `sibling: "eva"` `action: "enrich"` → full 8-layer engineering enrichment.
Output: deployment incident history, infrastructure constraints from past decisions.

**testing:**
Audit test gate coverage and CI enforcement:
1. Glob `**/*_test.rs`, `tests/`, `spec/` → inventory test files and coverage tooling
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "lint"` → check CI enforces test gates (cargo test, coverage thresholds)
Report: test pyramid status per Canon XXVII, coverage gap vs. ≥90% threshold, [T] gate pass/fail verdict.

---

## code_review

**Purpose**: Focused PR review + logic verification.
**writes_code**: false

| # | Agent | Task |
|---|-------|------|
| 1 | quality | Quality + security: code_review (SNIFF) + GUARD on changed files — LASDLC [Q] |
| 2 | researcher | Logic verification: trace execution paths, check edge cases and invariants — LASDLC [R] |
| 3 | knowledge | Context: prior changes to these files, related decisions, historical patterns — LASDLC [K] |

### Full Cycle Instructions

**quality (primary):**
Run Engineer (Alpha)'s code review cycle on the changed files:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "code_review"` on changed files → SNIFF phase: code quality, complexity, naming, architecture consistency, Builders Cookbook compliance
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "guard"` on changed files → GUARD phase: OWASP patterns, dependency security, secrets detection, input validation gaps
Output: quality and security findings ranked by severity (CRITICAL/HIGH/MEDIUM/LOW/INFO), specific file:line references, remediation steps.

**researcher:**
Logic verification on the changed code:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "scan"` → classify the type of changes, identify logic-heavy paths
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "trace"` → trace execution paths through changed code, identify edge cases and boundary conditions
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "verify"` with claim: "changes preserve existing behavior and add intended new behavior" → N-MultiPass validation
Output: logic correctness assessment, edge cases identified, invariants violated, confidence score.

**knowledge:**
Provide historical context for changed files:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` with filenames and component names → prior modifications and related architectural decisions
Output: context on why files exist in current form, past issues in this area, decisions that constrain this review.

---

## learning

**Purpose**: Codebase onboarding + exploration.
**writes_code**: false

| # | Agent | Task |
|---|-------|------|
| 1 | engineer | Codebase exploration: map architecture, entry points, how the system fits together — LASDLC [A] |
| 2 | researcher | Technology research: key design decisions, trade-offs, library and protocol patterns — LASDLC [R] |
| 3 | knowledge | Onboarding context: project goals, team conventions, architectural decisions from helix — LASDLC [K] |

### Full Cycle Instructions

**engineer (primary):**
Explore and map the codebase architecture:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "discover"` → explore codebase structure, map architecture layers, identify entry points and data flows
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "code_review"` on the main entry points → architecture analysis (CHOW) for newcomer orientation
Output: architecture map, entry points, component relationships, how the system fits together — structured for a newcomer.

**researcher:**
Research the technology decisions:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "probe"` → research the key technologies, patterns, and protocols used in the codebase
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "theorize"` → explain the design decisions and their trade-offs
Output: technology overview, design decision rationale, pattern descriptions, learning roadmap.

**knowledge:**
Pull onboarding context:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` with project-specific terms → onboarding context, goals, team conventions
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "helix"` → architectural decision records relevant to the codebase
Output: project goals, team conventions, key architectural decisions, historical context that shapes how the code works today.

---

## audit

**Purpose**: Compliance + vulnerability scanning.
**writes_code**: false

| # | Agent | Task |
|---|-------|------|
| 1 | quality | Compliance code review: policy violations, licensing gaps, standards mapped to compliance frameworks — LASDLC [Q] |
| 2 | security | Vulnerability assessment: scan without active exploitation (scope.toml required for scan action) — LASDLC [S] |
| 3 | knowledge | Compliance history: prior audit findings, remediation records, compliance decisions from helix — LASDLC [K] |

### Full Cycle Instructions

**quality (primary):**
Run a full compliance-focused code review:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "code_review"` → map code against compliance framework requirements (OWASP ASVS, SOC 2, HIPAA, PCI DSS as applicable to the target)
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "guard"` → vulnerability scan, dependency audit (`cargo audit`), license check, secrets detection
Output: compliance gaps mapped to specific controls, policy violations with file:line references, licensing issues, dependency CVEs.

**security:**
Run Sentinel (Echo) vulnerability assessment (no exploitation):
1. If scope.toml exists and `tool: "scan"` is authorized: `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "seraph"` `action: "scan"` → vulnerability scan without active exploitation
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "seraph"` `action: "investigate_close"` → compile findings into structured report
If scope.toml is absent or `scan` is not authorized: perform static assessment using Read/Grep tools only — clearly report scope limitation.
Output: vulnerability assessment with CRITICAL/HIGH/MEDIUM/LOW severity, remediation guidance.

**knowledge:**
Pull compliance history:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` with audit/compliance keywords → prior audit findings and remediations
Output: prior audit results, remediation history, compliance baseline context for this target.

---

## forensics

**Purpose**: Incident response + evidence chain.
**writes_code**: false

| # | Agent | Task |
|---|-------|------|
| 1 | researcher | Lead investigation: full 7-phase incident-focused cycle (scan → sweep → trace → probe → theorize → verify → close) — LASDLC [R] |
| 2 | security | Forensic analysis: binary/artifact examination, network forensics, IOC analysis — LASDLC [S] |
| 3 | knowledge | Incident history: prior responses, related evidence, known failure modes from helix — LASDLC [K] |

### Full Cycle Instructions

**researcher (primary):**
Run the full Analyst (Delta) investigation cycle for incident response:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "scan"` → triage the incident: classify severity, identify affected systems, detect attack patterns
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "sweep"` → evidence collection: extract artifacts, logs, traces; build evidence manifest with chain-of-custody
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "trace"` → timeline construction: correlate events, identify attack chain, surface root cause candidates
4. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "probe"` → research: SOUL helix for prior incidents + Context7/Firecrawl for IOC matching and known exploit patterns
5. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "theorize"` → ranked hypotheses for root cause with confidence badges
6. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "verify"` → validate root cause hypothesis against evidence
7. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "close"` → incident report: RCA, IOC list, timeline, remediation steps, lessons learned
Output: incident report with evidence chain, root cause, attack timeline, remediation steps.

**security:**
Forensic artifact analysis:
1. If binary/file evidence exists: `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "seraph"` `action: "analyze"` → binary analysis, YARA rule matching, malware indicators
2. If network captures exist: `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "seraph"` `action: "capture"` → traffic analysis, C2 beacon detection, lateral movement patterns
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "seraph"` `action: "investigate_close"` → add SERAPH findings to evidence chain
Output: artifact analysis findings, network forensics results, IOC confirmation/refutation.

**knowledge:**
Pull incident history and known failure modes:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` with incident-specific keywords → prior incidents matching this pattern
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "helix"` with forensics/incident tags → past response playbooks and known failure modes
After investigation closes, if significance >= 7.0: `action: "write_note"` → save incident findings to helix for future reference.
Output: similar prior incidents, known failure modes, previous resolution patterns.

---

## solo

**Purpose**: Quality gates + memory + doc coverage, minimal overhead.
**writes_code**: true

| # | Agent | Task |
|---|-------|------|
| 1 | engineer | Quality enforcement: full gate pipeline (code_review → implement → guard) — LASDLC [A] |
| 2 | knowledge | Memory, context, and doc coverage: helix history + `///` audit on changed files — LASDLC [K+D] |

### Full Cycle Instructions

**engineer (primary):**
Run Engineer (Alpha)'s quality gate pipeline:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "code_review"` on the target → SNIFF analysis: quality, complexity, standards compliance
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "sniff"` with implementation context → HUNT: execute required code changes with quality gates
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "guard"` on changed files → post-change security scan
Output: quality gate report, code changes on T2 worktree branch, guard findings.

**knowledge:**
Memory, context, and documentation coverage:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` → relevant helix context for the task
2. Grep `pub fn\|pub struct\|pub enum\|pub trait` in changed files → inventory all public items
3. Grep `///` in same files → check doc coverage per public item
4. **Close-out (mandatory, every run):** `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "write_note"` with `type: decision_log`, content covering the target, key decisions, why, and what to surface next run — unconditionally, regardless of significance score.
   If significance >= 7.0: additionally `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "enrich"` → full 8-layer engineering enrichment.
Output: relevant prior context, doc coverage report, [D] gate pass/fail (≥90% required), vault entry written.

---

## observability

**Purpose**: Runtime debugging + anomaly detection + performance profiling.
**writes_code**: false

| # | Agent | Task |
|---|-------|------|
| 1 | ops | Lead: query traces, identify anomalies, map topology, profile latency — LASDLC [O+P] |
| 2 | researcher | Root cause: investigate anomalies ops identified, build evidence chain — LASDLC [R] |
| 3 | knowledge | Operational history: prior incidents with similar patterns, known failure modes — LASDLC [K] |

### Full Cycle Instructions

**ops (primary):**
Lead observability analysis and performance profiling:
1. `curl localhost:3742/api/metrics` → current health metrics overview
2. `curl localhost:3742/api/topology` → instrumentation topology and span coverage
3. `curl localhost:3742/api/anomaly` → automated anomaly detection
4. `curl localhost:3742/api/traces?filter={symptom}` → targeted trace search
5. `curl localhost:3742/api/traces?filter=latency` → latency distribution (p50/p95/p99)
6. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "chase"` on the suspected bottleneck → CORSO CHASE profiling
Output: anomaly report with trace evidence, topology gaps, severity assessment, latency percentiles, bottleneck identification, [P] regression flag if >5% wall-clock increase.

**researcher:**
Root cause investigation on Monitor (Foxtrot)'s findings:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "scan"` with AYIN anomalies as input → classify the failure pattern
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "trace"` → build timeline from trace evidence, identify root cause candidates
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "theorize"` → root cause hypotheses ranked by confidence
4. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "verify"` → validate against available evidence
Output: root cause hypothesis with confidence score, evidence chain, recommended resolution.

**knowledge:**
Operational memory:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` with symptom keywords → prior incidents matching this pattern
After diagnosis, if significance >= 7.0: `action: "write_note"` → save to helix.
Output: prior incidents, known failure modes, previous resolutions.

---

## full

**Purpose**: Full platform — all 7 domain agents covering every LASDLC gate.
**writes_code**: true

| # | Agent | Task |
|---|-------|------|
| 1 | researcher | Investigation and research: full 7-phase Analyst (Delta) cycle — LASDLC [R] |
| 2 | engineer | Quality + implementation: full code review + build cycle — LASDLC [A] |
| 3 | security | Offensive security: full engagement cycle within authorized scope (ScopeGovernor mandatory) — LASDLC [S] |
| 4 | quality | Defensive quality: GUARD scan + Builders Cookbook compliance — LASDLC [Q] |
| 5 | ops | DevOps + observability + performance: full DevOps cycle + metrics + anomaly + regression check — LASDLC [O+P] |
| 6 | knowledge | Institutional memory + doc coverage: helix search, prior decisions, vault enrichment, `///` audit — LASDLC [K+D] |
| 7 | testing | Test suite validation: coverage audit, Canon XXVII compliance — LASDLC [T] |

### Full Cycle Instructions

**researcher:**
Full 7-phase Analyst (Delta) investigation. See `research` preset Full Cycle Instructions.

**engineer:**
Full Engineer (Alpha) build cycle. See `software_engineering` preset Full Cycle Instructions.

**security:**
Full Sentinel (Echo) engagement cycle (ScopeGovernor 5-gate check is mandatory). See `security` preset Full Cycle Instructions.

**quality:**
GUARD scan + CHOW review. See `code_review` preset Full Cycle Instructions.

**ops:**
Full DevOps + observability + performance cycle. See `devops` and `observability` preset Full Cycle Instructions (including Engineer:Chase profiling and Monitor (Foxtrot) latency analysis).

**knowledge:**
Full Knowledge (Charlie) helix query + vault enrichment + doc coverage audit. Follow `software_engineering` preset Full Cycle Instructions (knowledge block) for the combined operations, including the mandatory decision_log close-out on every run regardless of significance score.

**testing:**
Test suite validation. See `software_engineering` preset Full Cycle Instructions for testing agent.

---

## lean

**Purpose**: Vault and knowledge graph only.
**writes_code**: false

| # | Agent | Task |
|---|-------|------|
| 1 | knowledge | Knowledge graph operations: query, search, read, and write helix entries — LASDLC [K] |

**Note**: A single-agent team has limited collaboration value. Consider using `/Knowledge (Charlie)` directly
instead of spawning a team.

### Full Cycle Instructions

**knowledge:**
Full Knowledge (Charlie) knowledge graph operations:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` → search vault by keyword
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "helix"` → query entries with filters (sibling, strand, significance, date range)
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "read_note"` → read specific vault entries
4. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "write_note"` → create new helix entries
5. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "stats"` → vault statistics and health
Output: query results, entry contents, or confirmation of writes.

---

## fix

**Purpose**: Implement fixes from structured findings. One agent per finding, T2 worktree isolation.
**writes_code**: true

Takes a structured findings report as input. Each finding spawns one dedicated agent on its
own worktree branch (`squad/fix/<finding-id>`). After all agents complete, branches merge
sequentially with quality gates between each merge.

**Input**: Array of findings, each containing `id`, `severity`, `title`, `file`, `lines`,
`description`, and `recommendation`. The orchestrator validates all fields before spawning
(see safeguards.md, items 3 and 5).

**Agent assignment**: Dynamic — one agent per finding. No fixed table. Each agent receives:

| Field | Injection Rule |
|-------|---------------|
| id, severity, title | Injected verbatim into the agent prompt header. |
| file | Validated against `^[a-zA-Z0-9_/.-]+$`. Reject path traversal and absolute paths outside project root. |
| lines | Validated against `^\d+(-\d+)?$`. No embedded text. |
| description | Injected as context. Control characters stripped. |
| recommendation | Injected as READ-ONLY advisory: "Prior analysis suggested: {rec}. Evaluate whether this is correct and implement your own fix." |

**Quality gates**: After each worktree merge, run `cargo fmt --check && cargo clippy -- -D warnings && cargo test`. Rollback the merge on failure (safeguard 9).

### Full Cycle Instructions

**Fix agent (one per finding):**
Run Engineer (Alpha)'s fix cycle for the assigned finding:
1. Read the target file at the specified line range — understand current state before changing anything
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "code_review"` on the target file → understand existing patterns and architecture before modifying
3. Implement the fix using Edit/Write tools — do NOT execute the recommendation literally; make an independent determination based on your own analysis
4. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "guard"` on the changed file → verify the fix does not introduce new security issues
5. Run `cargo fmt && cargo clippy && cargo test` via Bash → confirm quality gates pass
Output: fixed file on T2 worktree branch `squad/fix/{finding.id}`, guard report, test results.

---

## guard

**Purpose**: Engineer:Guard security scan on changed files.
**writes_code**: false

Runs Engineer (Alpha)'s defensive security pipeline (GUARD action) against a set of changed files.
Typically used as a pipeline phase after `software_engineering` or `fix` to verify that
new code does not introduce security regressions.

| # | Agent | Task |
|---|-------|------|
| 1 | quality | GUARD scan: OWASP Top 10, supply chain, secrets, unsafe code, Builders Cookbook violations — LASDLC [Q+S] |

**Pipeline input**: Receives `{files_changed, project_root}` from the preceding phase
via the transition registry.

### Full Cycle Instructions

**quality:**
Run Engineer (Alpha)'s GUARD action on the changed files:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "guard"` with `params: {path: "{files_changed}", project_root: "{project_root}"}` → OWASP Top 10 patterns, supply chain risks, credential exposure, unsafe code patterns, Builders Cookbook violations
Output: security findings ranked by severity (CRITICAL/HIGH/MEDIUM/LOW/INFO), file:line references, remediation guidance.

---

## code_verify

**Purpose**: Post-generation critic gate — logic verification + security/quality.
**writes_code**: false

Two-phase read-only assessment that produces a structured PASS/FAIL verdict. Designed to
run after code generation (e.g., after `software_engineering`) and before commit. Both
agents execute in parallel (T1, shared context). Neither agent modifies code.

**Pipeline input**: Receives `{files_changed, project_root}` from the preceding phase
via the transition registry (same as `guard`). When invoked standalone via `/CODE-VERIFY`,
accepts a target path or git diff range as the target argument.

| # | Agent | Task |
|---|-------|------|
| 1 | researcher | Logic critic: evidence chain on whether generated code matches spec/intent — LASDLC [R] |
| 2 | quality | Quality critic: GUARD (security) + CHOW (quality) scan on generated code — LASDLC [Q] |

### Full Cycle Instructions

**researcher (logic critic):**
Run Analyst (Delta)'s evidence-chain verification on generated code:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "sweep"` → scan generated code for logical consistency: control flow, error handling paths, edge cases, boundary conditions
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "verify"` with claim: "generated code correctly implements the stated intent and specification" → build evidence chain via N-MultiPass: does output match the stated intent? Are invariants preserved? Are there logic gaps?
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "theorize"` with evidence → rank confidence in correctness with badges (DEFINITIVE/STRONG/MODERATE/LOW/SPECULATIVE)
Report: PASS (confidence >= STRONG) or FAIL (confidence < STRONG) with:
- Evidence chain: specific line references supporting/contradicting correctness
- Confidence score with badge
- Logic gaps or invariant violations identified
- Edge cases not handled

**quality (quality critic):**
Run Engineer (Alpha)'s dual security + quality assessment on generated code:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "guard"` on generated files → security scan: OWASP Top 10 patterns, secrets exposure, unsafe code, supply chain risks, input validation gaps
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "code_review"` on generated files → quality analysis: complexity (cyclomatic ≤10, function ≤60 lines), Builders Cookbook compliance, naming conventions, architecture consistency, error handling patterns
Report: PASS (no CRITICAL/HIGH findings) or FAIL (any CRITICAL/HIGH finding) with:
- Findings by severity (CRITICAL/HIGH/MEDIUM/LOW/INFO)
- File:line references for each finding
- Remediation guidance for FAIL items
- Builders Cookbook violations cited by section

### Verdict Aggregation

The orchestrator combines both reports into a unified verdict:

| researcher | quality | Verdict |
|------------|---------|---------|
| PASS | PASS | **PASS** — code is logic-correct and quality-clean |
| PASS | FAIL | **FAIL** — logic sound but security/quality issues found |
| FAIL | PASS | **FAIL** — quality clean but logic gaps detected |
| FAIL | FAIL | **FAIL** — both logic and quality issues found |

If both PASS but either reports MEDIUM/LOW findings: **WARN** — passed with advisory notes.

---

## risk_analysis

**Purpose**: Analyst (Delta) deep risk scoring + helix context for a target or codebase area.
**writes_code**: false

Two agents operating in parallel: researcher runs the full Analyst (Delta) risk-scoring cycle
(MAP → PULL → SCORE → RESEARCH → PROVE → DECLARE), knowledge provides institutional
memory of prior risk decisions and known patterns from the vault.

| # | Agent | Task |
|---|-------|------|
| 1 | researcher | Analyst (Delta) risk scoring: dependency mapping, threat surface analysis, evidence-backed risk scores — LASDLC [R] |
| 2 | knowledge | Helix context: prior risk assessments, known vulnerability patterns, past remediations — LASDLC [K] |

### Full Cycle Instructions

**researcher:**
Run the Analyst (Delta) risk-scoring pipeline:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "scan"` → assess the risk surface, classify threat categories and unknowns
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "probe"` → multi-source evidence gathering (helix, Context7, community advisories, CVE databases)
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "theorize"` → risk hypotheses with confidence badges (DEFINITIVE/STRONG/MODERATE/LOW/SPECULATIVE)
4. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "verify"` → evidence chain validation
5. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "investigate_close"` → finalize risk report with scored findings
Output: risk findings ranked by severity + confidence, evidence chains, remediation priority matrix.

**knowledge:**
Pull vault context for this risk assessment:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` with risk/vulnerability keywords → prior risk assessments and remediations
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "helix"` filtering for security-tagged entries → architectural risk decisions on record
After completion: `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "write_note"` if significance >= 7.0.
Output: relevant prior risk context, known patterns to cross-reference against researcher findings.

---

## gatekeeper

**Purpose**: Pre-merge 9-dimension LASDLC compliance check. Read-only verdict across all quality dimensions.
**writes_code**: false

Seven agents execute in parallel — covering all 9 LASDLC dimensions. Each produces a PASS/FAIL verdict with evidence.
Ops covers [O], [P], and Monitor (Foxtrot) observability. Quality covers [Q] and Arbiter (Golf) canon compliance. Knowledge covers [K] and [D]. Researcher covers [R] risk assessment.
Designed to run as a pipeline phase after any write preset (software_engineering, devops, solo, full, fix)
or as a standalone compliance check before any merge.

| # | Agent | Task |
|---|-------|------|
| 1 | engineer | [A] Architecture gate: verify patterns, abstractions, cyclomatic complexity ≤10, function length ≤60 |
| 2 | security | [S] Security gate: OWASP Top 10, supply chain risks, credential exposure, unsafe code — requires ScopeGovernor |
| 3 | quality | [Q+C] Quality + Canon gates: Builders Cookbook compliance, clippy pedantic, Arbiter (Golf) canon validation |
| 4 | ops | [O+P] Operations + Performance + Observability gates: CI/CD health, binary status, O(n²) check, Monitor (Foxtrot) trace analysis |
| 5 | knowledge | [K+D] Knowledge + Documentation gates: helix context, `///` coverage ≥90%, CLAUDE.md currency |
| 6 | testing | [T] Testing gate: Canon XXVII 6-suite audit, ≥90% coverage requirement |
| 7 | researcher | [R] Research + Risk gate: Analyst (Delta) BCRA blast score analysis, dependency risk surface, evidence chain review |

### Full Cycle Instructions

**engineer:**
Architecture compliance check:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "code_review"` on the target → analyze patterns, complexity, function lengths, abstraction quality
2. Bash: `grep -r 'fn ' {target} | wc -l` → count functions; flag any >60 lines
Report: architecture finding summary, [A] gate PASS/FAIL verdict.

**security:**
Security compliance check (ScopeGovernor 5-gate validation required):
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "guard"` on the target → OWASP, supply chain, secrets, unsafe code
2. If scope.toml is valid: `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "seraph"` `action: "osint"` on the target → passive exposure check
Report: security findings with severity, [S] gate PASS/FAIL verdict.

**quality:**
Quality compliance and canon check:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "code_review"` on the target → Builders Cookbook compliance, coding standards
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "lint"` → clippy pedantic clean?
3. Read `~/lightarchitects/soul/helix/user/standards/canon/builders-cookbook.md` and `~/lightarchitects/soul/helix/user/standards/canon/canon.md` → check changed code and decisions against canonical rules (Arbiter (Golf) canon enforcement gate)
Report: quality findings, [Q] gate PASS/FAIL verdict; canon violations, [C] Canon gate PASS/FAIL verdict.

**ops:**
Operations, performance, and observability compliance check:
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "status"` → project health, binary freshness
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "repo"` → CI/CD workflows, quality gate enforcement
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "chase"` on changed files → detect O(n²) patterns and complexity regressions
4. `curl localhost:3742/api/traces?filter=latency` → Monitor (Foxtrot) P95/P99 latency across recent sessions; flag >5% regression vs baseline
5. `curl localhost:3742/api/traces?filter=errors` → Monitor (Foxtrot) error rate and anomaly signals on changed code paths
Report: ops findings, [O] gate PASS/FAIL verdict; performance findings, [P] gate PASS/FAIL verdict (fail on O(n²) or >5% latency regression); observability findings (Monitor (Foxtrot) signal clean or anomaly flagged).

**knowledge:**
Documentation compliance and helix context:
1. Grep `pub fn\|pub struct\|pub enum\|pub trait` in target → inventory all public items
2. Grep `///` in same files → coverage per public item
3. If CLAUDE.md exists: Read it → check currency against codebase
4. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` with target keywords → relevant prior decisions on record
Report: doc coverage percentage, undocumented public items, CLAUDE.md currency, [D] gate PASS/FAIL verdict (fail if <90%); prior decisions context.

**testing:**
Testing compliance check:
1. Glob `**/*_test.rs`, `tests/`, `spec/` → inventory all test suites
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "eva"` `action: "lint"` → run cargo test, measure coverage
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "corso"` `action: "code_review"` on test files → Canon XXVII 6-suite audit
Report: coverage per suite, missing suites, [T] gate PASS/FAIL verdict (fail if <90% or any Canon XXVII suite missing).

**researcher:**
Risk and evidence chain assessment (Analyst (Delta) BCRA):
1. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "scan"` on the target → evidence-based diff analysis, anomaly detection in change surface
2. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "quantum"` `action: "research"` on new dependencies or patterns → blast score across dependency, binary, API, config, coverage boundaries
3. `mcp__plugin_lightarchitects_lightarchitects__tools` `sibling: "soul"` `action: "search"` query: `"<target> risk incident prior decision"` → retrieve any prior risk decisions from helix
Report: blast scores per boundary, risk surface summary, prior incident context, [R] gate PASS/FAIL verdict (fail if any boundary scores CRITICAL).

### Verdict Aggregation

| Gate | PASS | FAIL |
|------|------|------|
| [A] Architecture | Complexity ≤10, functions ≤60 lines, no god objects | Any violation |
| [S] Security | No CRITICAL/HIGH findings | Any CRITICAL/HIGH finding |
| [Q] Quality | Builders Cookbook clean, clippy pedantic pass | Any violation |
| [C] Canon | No canon rule violations (Builders Cookbook, Engineer (Alpha) Protocol, canon.md) | Any canon violation |
| [O] Operations | CI enforcing gates, binary health passing | Any CI gate missing |
| [P] Performance | No O(n²), no >5% latency regression, Monitor (Foxtrot) signal clean | Any violation |
| [K+D] Knowledge+Docs | ≥90% public item coverage, CLAUDE.md current | Either condition fails |
| [T] Testing | ≥90% coverage, all 6 Canon XXVII suites present | Either condition fails |
| [R] Research+Risk | All BCRA blast scores below CRITICAL, no prior incident match | Any CRITICAL blast score |

Overall verdict: **PASS** if all 9 gates pass. **FAIL** if any gate fails. Report each gate independently.

---

## squad

**Purpose**: Direct sibling invocation and multi-sibling consultation. No code writing.
**writes_code**: false

Single agent that routes to the right sibling(s) based on request context. Spawns
parallel sub-agents for multi-sibling consultations, synthesizes responses into a
unified verdict. Can pull sub-skill protocols on demand via `action: "get_skill"` to
brief itself before routing a complex request.

| # | Agent | Task |
|---|-------|------|
| 1 | squad | Route to the appropriate sibling(s), synthesize results — SQ |

### Full Cycle Instructions

**squad:**
Route and synthesize:
1. Parse the request to identify which sibling(s) to invoke (see classifier keywords in `agents/squad.md`)
2. If protocol briefing needed: `mcp__plugin_lightarchitects_lightarchitects__tools` `action: "get_skill"` `skill: "{sibling}/{SKILL_NAME}"` → load protocol inline
3. For single sibling: invoke directly via gateway, return attributed response
4. For multiple siblings: spawn parallel sub-agents (one per sibling), collect results
5. Synthesize: per-sibling findings, agreement points, conflicts, routing recommendation if needed
Output: attributed sibling responses, synthesis with agreement/conflict summary.

---

## Write Classification Summary

| Preset | writes_code | Default Tier |
|--------|-------------|--------------|
| software_engineering | true | T2 |
| security | false | T1 |
| research | false | T1 |
| devops | true | T2 |
| code_review | false | T1 |
| learning | false | T1 |
| audit | false | T1 |
| forensics | false | T1 |
| solo | true | T2 |
| observability | false | T1 |
| full | true | T2 |
| lean | false | T1 |
| fix | true | T2 |
| guard | false | T1 |
| code_verify | false | T1 |
| risk_analysis | false | T1 |
| gatekeeper | false | T1 |
| squad | false | T1 |

---

## MCP Tool Routing

All siblings route through the unified lightarchitects gateway. Individual sibling tools (`corsoTools`, `evaTools`, `soulTools`, `quantumTools`, `seraphTools`) are silently deprecated — use the gateway with a `sibling:` routing parameter:

| Domain Agent | MCP Tool | Subagent Type | Model Tier | Primary Sibling | LASDLC Gate |
|--------------|----------|---------------|------------|-----------------|-------------|
| engineer | `mcp__plugin_lightarchitects_lightarchitects__tools` | `lightarchitects:engineer` | `sonnet` | Engineer (Alpha) (build/implement) | [A] Architecture |
| quality | `mcp__plugin_lightarchitects_lightarchitects__tools` | `lightarchitects:quality` | `sonnet` | Engineer (Alpha) (review/guard) | [Q] Quality |
| security | `mcp__plugin_lightarchitects_lightarchitects__tools` | `lightarchitects:security` | `sonnet` | Sentinel (Echo) (offensive + defensive) | [S] Security |
| ops | `mcp__plugin_lightarchitects_lightarchitects__tools` | `lightarchitects:ops` | `sonnet` | Ops (Bravo) + Monitor (Foxtrot) HTTP + Engineer (Alpha) (CHASE) | [O+P] Operations+Perf |
| researcher | `mcp__plugin_lightarchitects_lightarchitects__tools` | `lightarchitects:researcher` | `sonnet` | Analyst (Delta) | [R] Research |
| knowledge | `mcp__plugin_lightarchitects_lightarchitects__tools` | `lightarchitects:knowledge` | `sonnet` | Knowledge (Charlie) + Ops (Bravo) (craft) | [K+D] Knowledge+Docs |
| testing | `mcp__plugin_lightarchitects_lightarchitects__tools` | `lightarchitects:testing` | `haiku` | Engineer (Alpha) (HUNT) + Ops (Bravo) (LINT) | [T] Testing |
| squad | `mcp__plugin_lightarchitects_lightarchitects__tools` | `lightarchitects:squad` | `inherit` | All siblings via gateway | [SQ] Sibling Router |

**Model tier rationale** (source: code.claude.com/docs/en/sub-agents, validated 2026-05-14):
- `sonnet` — complex multi-step reasoning: full build/review/security/investigation/synthesis cycles
- `haiku` — structured verification: coverage audit, Canon XXVII pyramid check, test inventory
- `inherit` — routing-only agents pass through the parent session model
- Security is pinned to `sonnet` regardless of preset — AppSec quality must never be cheapened

### Sub-Skill Access

All sibling capabilities are accessed via the unified gateway. Route through
`mcp__plugin_lightarchitects_lightarchitects__tools` with a `sibling:` + `action:` pair.
There are no standalone sibling plugins — all capabilities come from the lightarchitects gateway.

**On-demand protocol loading**: Before entering a phase that requires detailed protocol
knowledge, pull the sub-skill content via the gateway:

```
mcp__plugin_lightarchitects_lightarchitects__tools  action: "get_skill"  skill: "corso/GUARD"
```

The gateway returns the SKILL.md content inline. Load it, execute the phase, discard.
This keeps spawn-time context lean and eliminates the 8KB injection ceiling. See
`references/subskill-map.md` for the full injection model rationale.

| Gateway Action | Purpose |
|----------------|---------|
| `sibling: "eva"` `action: "status"` | Check project health and binary status |
| `sibling: "eva"` `action: "lint"` | Run quality gates (fmt, clippy, tests) |
| `sibling: "eva"` `action: "repo"` | Review CI/CD workflows and repository configuration |
| `sibling: "eva"` `action: "deploy"` | Assess deployment configuration and make targets |
| `sibling: "eva"` `action: "discover"` | Deep codebase exploration and architecture mapping |
| `sibling: "corso"` `action: "guard"` | OWASP, supply chain, secrets, unsafe code scan |
| `sibling: "corso"` `action: "fetch"` | Research phase — Context7, helix, external docs |
| `sibling: "corso"` `action: "sniff"` | Plan-generation or code-generation (HUNT phase) |
| `sibling: "corso"` `action: "chase"` | Performance profiling and regression detection |
| `sibling: "quantum"` `action: "scan"` | Investigation kickoff — classify patterns and unknowns |
| `sibling: "quantum"` `action: "verify"` | Evidence chain validation with confidence badges |
| `sibling: "soul"` `action: "search"` | Vault keyword search |
| `sibling: "soul"` `action: "helix"` | Structured helix query with filters |
| `sibling: "soul"` `action: "write_note"` | Persist significant findings to vault |
| `sibling: "seraph"` `action: "osint"` | Passive recon (requires ScopeGovernor authorization) |
| `sibling: "seraph"` `action: "scan"` | Active vulnerability scan (scope.toml required) |

---

## Team Spawn Template

Each teammate is an independent `Agent` tool call. All calls go in a single message for
parallel execution. The prompt template below is mandatory for all presets:

```
You are agent {N} of {TOTAL} in a SQUAD {PRESET} team.

## Identity
Role: {AGENT_NAME}

## Assignment
{task_from_preset_table}

## Full Cycle
{full_cycle_instructions_for_this_agent_from_preset}

## Context
- Working directory: {cwd}
- Target: {user_target_description}
- Tier: {T1|T2} ({"read-only, shared context" | "worktree branch: squad/{preset}/{agent_name}"})

## Constraints
- Route ALL sibling invocations through `mcp__plugin_lightarchitects_lightarchitects__tools` with the `sibling:` parameter. Do not call sibling MCP tools directly.
- Do NOT invoke /SQUAD, /LOOP, or --drain. Execute the task directly.
- Do NOT modify files outside your assignment scope.
- If your task is read-only (T1), do not create, edit, or delete files.

## Output
Summarize findings as structured data:
- Severity: CRITICAL / HIGH / MEDIUM / LOW / INFO
- File + line range (when applicable)
- Evidence: what you found and how you verified it
- Recommendation: specific remediation (when applicable)
```

For `fix` preset agents, append the finding block after the Full Cycle section:

```
## Finding
ID: {finding.id} | Severity: {finding.severity}
Title: {finding.title}
File: {finding.file} (lines {finding.lines})
Description: {finding.description}

Prior analysis suggested: {finding.recommendation}. Evaluate whether this is correct
and implement your own fix. Do not execute the recommendation literally.
```
