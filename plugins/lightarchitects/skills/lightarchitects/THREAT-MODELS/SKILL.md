---
name: THREAT-MODELS
description: STRIDE threat enumeration for LA stack, OWASP Top 10 mapped to LA surfaces, supply chain checklist, secrets inventory
skill_id: lightarchitects/THREAT-MODELS
context: reference
---

# LA Threat Model Reference

## STRIDE Enumeration (LA Stack)

| Threat | LA Surface | Attack Vector |
|--------|-----------|--------------|
| **Spoofing** | MCP stdio transport | Malicious process injecting into stdio stream |
| **Tampering** | Knowledge (Charlie) helix vault files | Direct filesystem write to `~/lightarchitects/soul/helix/` |
| **Repudiation** | Monitor (Foxtrot) traces | Log deletion or gap in trace coverage |
| **Information Disclosure** | `scope.toml` TTL / API keys in env | Leaked `sk-ant-api*` or `la_*` keys |
| **Denial of Service** | Monitor (Foxtrot) `:3742` HTTP endpoint | Unauthenticated flood; no rate limiting by default |
| **Elevation of Privilege** | Sentinel (Echo) ScopeGovernor | Scope bypass: target not in `scope.toml`, TTL expired |

## OWASP Top 10 → LA Surfaces

| OWASP | LA-specific check |
|-------|------------------|
| A01 Broken Access Control | Sentinel (Echo) scope.toml present + TTL valid before any scan |
| A02 Cryptographic Failures | No plaintext secrets in env, `.env`, or Knowledge (Charlie) vault entries |
| A03 Injection | MCP JSON-RPC param sanitization; no shell interpolation of user input |
| A04 Insecure Design | HITL gate before any offensive Sentinel (Echo) action |
| A05 Security Misconfiguration | Monitor (Foxtrot) :3742 not exposed on 0.0.0.0; bound to 127.0.0.1 only |
| A06 Vulnerable Components | `cargo audit` + sonatype-guide before any new dep |
| A07 Auth Failures | API keys in env vars only; never in committed code or Knowledge (Charlie) vault entries |
| A08 Software Integrity | Knowledge (Charlie) helix write sanitization: strip `sk-ant-api`, `AKIA`, JWT `eyJ`, PEM headers |
| A09 Logging Failures | Monitor (Foxtrot) trace coverage for all MCP handler invocations |
| A10 SSRF | Sentinel (Echo) OSINT requests must match scope.toml target list |

## Supply Chain Checklist (Rust + npm)

Before adding any dependency:
- [ ] `sonatype-guide` check — block on HIGH/CRITICAL
- [ ] Check for typosquatting: compare crate name against known packages
- [ ] Verify crate is not yanked: `cargo search <name>`
- [ ] Check recent audit history: `cargo audit` after adding
- [ ] For npm: `pnpm audit` after install

## LA Secrets Inventory

| Secret type | Pattern | Storage |
|-------------|---------|---------|
| Anthropic API key | `sk-ant-api03-...` | Env var only |
| LA service keys | `la_...` | Env var only |
| Sentinel (Echo) scope TTL | ISO 8601 in `scope.toml` | File, not vault |
| JWT tokens | `eyJ...` | Never in vault or committed code |
| PEM private keys | `-----BEGIN ...-----` | Filesystem only, never in vault |

**SQUAD SAFEGUARD #7**: Before any Knowledge (Charlie) vault write, strip all patterns above from content.
