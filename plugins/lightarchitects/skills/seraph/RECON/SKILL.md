---
name: RECON
description: "This skill is invoked internally by Sentinel (Echo)'s engagement cycle for the
  reconnaissance phase. Orchestrates OSINT collection, web surface analysis (firecrawl),
  CVE research (HuggingFace), initial network discovery (seraphTools osint/scan), and
  evidence grading (Analyst (Delta)). Multi-source intelligence with confidence-tiered output."
user-invocable: false
context: fork
version: 3.0.0
---

# /RECON — Reconnaissance Phase

> Engagement Phase 2/6: RECON — OSINT + network discovery

## Lifecycle Context

Follows SCOPE → feeds into SURVEY.

## Protocol

### Step 1: Gather Reconnaissance Targets

1. Load validated scope from SCOPE phase output
2. Extract target CIDRs, domains, and hostnames

### Step 1.5: Context7 Tool Documentation (Mandatory)

Before executing OSINT or scan tools, query Context7 for real-time documentation on the recon tools being used. This provides verified, version-specific usage docs for accurate parameter construction.

1. Call `mcp__plugin_context7_context7__resolve-library-id` with the target tool name (e.g., "nmap", "subfinder")
2. Call `mcp__plugin_context7_context7__query-docs` with the resolved library ID and the recon objective
3. Include Context7 results as reference for tool parameter construction in Steps 2-3

**Graceful skip**: If Context7 MCP plugin is unavailable, log the skip reason and proceed without it. Context7 enriches recon accuracy but is not a blocking gate.

### Step 2: Execute OSINT Collection

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "seraph"`, `action: "osint"`:
- Subdomain enumeration (subfinder, amass)
- Service discovery (httpx, dnsx)
- Inject scope context to prevent out-of-scope enumeration

### Step 2.5: Web Surface OSINT (firecrawl)

Scrape target websites for exposed information, technology stack detection, and attack surface mapping. Firecrawl handles JavaScript-rendered pages that raw HTTP requests miss.

1. For each target domain from SCOPE:
   - Scrape the main URL — extract technology stack (framework, server, CDN)
   - Scrape `robots.txt` and `sitemap.xml` — discover hidden paths
   - Scrape login/auth pages — identify auth provider (Clerk, Auth0, etc.)
   - Check for exposed API documentation (Swagger/OpenAPI)
2. Compile web surface findings: tech stack, exposed endpoints, auth mechanism, interesting paths

**Graceful skip**: If firecrawl is unavailable, proceed without web surface OSINT. Network-level recon (Steps 2-3) still provides sufficient attack surface data.

### Step 2.7: CVE Research (HuggingFace)

Search for recent CVEs and security research papers targeting the discovered technology stack.

1. From Step 2.5 tech stack identification, extract framework names and versions
2. Call `mcp__claude_ai_Hugging_Face__paper_search` with queries like:
   - "{framework} vulnerability" (e.g., "Next.js vulnerability")
   - "{service} CVE 2025 2026" (e.g., "Clerk CVE 2025 2026")
3. For significant findings, call `mcp__claude_ai_Hugging_Face__hf_doc_search` for deeper context
4. Cross-reference with sonatype-guide for dependency-level CVEs if package manifests are accessible

**Output**: Known CVE list with paper references, prioritized by recency and severity.

**Graceful skip**: If HuggingFace tools are unavailable, proceed without CVE research. Manual CVE lookup can supplement during SURVEY.

### Step 3: Execute Initial Network Scan

Execute `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "seraph"`, `action: "scan"`:
- Discovery scan on enumerated targets (nmap, fping)
- Service version detection on open ports

### Step 4: Compile Reconnaissance Report

Synthesize OSINT + web surface + CVE research + scan findings into structured target list:
- Live hosts with open ports
- Service versions identified
- Subdomains enumerated
- Technology stack (from firecrawl)
- Known CVEs (from HuggingFace + sonatype)
- Feed compiled list into SURVEY phase context

### Step 4.5: Evidence Grading (Analyst (Delta))

Structure recon findings into confidence-tiered evidence chains using Analyst (Delta)'s investigation methodology.

1. Call `mcp__plugin_lightarchitects_lightarchitects__tools` with `sibling: "quantum"`, `action: "scan"` — register findings as evidence items
2. For each finding, assign confidence tier:
   - **DEFINITIVE**: Directly observed (open port confirmed, banner grabbed)
   - **STRONG**: Tool-confirmed but not manually verified (CVE match, tech stack detection)
   - **MODERATE**: Inferred from multiple signals (probable service version, likely vulnerability)
   - **SPECULATIVE**: Single weak signal (timing anomaly, possible but unconfirmed)
3. Output structured evidence table with confidence tiers

**Why this matters**: SURVEY and STRIKE phases inherit these confidence tiers. A DEFINITIVE finding goes straight to exploitation testing; a SPECULATIVE finding gets additional verification first. This prevents wasting STRIKE resources on false positives.

**Graceful skip**: If QUANTUM qsTools is unavailable, compile findings without formal confidence grading. Note findings as "ungraded" for SURVEY to handle.

## Quality Gates

### Pre-Execution
- [ ] Scope validated (SCOPE phase complete)
- [ ] Target list defined within scope boundaries
- [ ] OSINT tools available on Khadas

### Post-Execution
- [ ] Subdomain enumeration complete
- [ ] Port scan results collected
- [ ] Web surface analyzed (or gracefully skipped with logged reason)
- [ ] CVE research completed (or gracefully skipped with logged reason)
- [ ] Evidence graded by confidence tier (or ungraded if Analyst (Delta) unavailable)
- [ ] Target list compiled for SURVEY with confidence tiers
- [ ] Evidence chain updated

## Cross-Domain Context

| Phase | Skill | Relationship |
|-------|-------|-------------|
| 1. scope | SCOPE | Provides validated targets for RECON |
| 3. survey | SURVEY | Receives confidence-tiered target list from RECON |

## Tool Integration Map

| Step | Primary Tool | Enrichment Tool | Fallback |
|------|-------------|----------------|----------|
| 1.5 | Context7 | — | Proceed without docs |
| 2 | Sentinel (Echo) osint | — | Core capability, no skip |
| 2.5 | firecrawl | — | Skip, log reason |
| 2.7 | HuggingFace paper_search | sonatype-guide | Skip, log reason |
| 3 | Sentinel (Echo) scan | — | Core capability, no skip |
| 4.5 | QUANTUM qsTools | — | Skip, findings ungraded |

---

## Contract Canon Integration (Cookbook §82)

Sentinel (Echo) owns Gatekeeper Registry gate **[S] Security**. Per §82.1, Sentinel (Echo) reads `operator.surface/*` for `forbidden_behaviors[]` + `render_safety` blocks, `provider.llm/*` for SSRF / auth / credential rules, and `hmac_chain.audit_trail/*` for tamper-evidence requirements. Pentest findings carry OWASP LLM01-LLM10 classes mapped to contract `errors[].owasp_class` fields. When a surface fails forbidden_behaviors compliance, Sentinel (Echo) routes `E_SECURE_FORBIDDEN` BLOCKING per §82.1. Sentinel (Echo) never bypasses `make contract-gate` even during emergency hot-fix scenarios — security in a corrupted contracts/ tree is undefined.
