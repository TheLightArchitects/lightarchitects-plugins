---
name: EVIDENCE-QUALITY
description: Evidence quality hierarchy, source freshness rules, confidence badge selection, Knowledge (Charlie) helix citation format
skill_id: lightarchitects/EVIDENCE-QUALITY
context: reference
---

# Evidence Quality Reference

## Evidence Hierarchy

| Tier | Source | Confidence |
|------|--------|-----------|
| **Primary** | Official docs authored by library maintainer | DEFINITIVE |
| **Secondary** | Context7 verified docs; HuggingFace peer-reviewed paper | STRONG |
| **Tertiary** | Firecrawl live web; GitHub issues; community blogs | MODERATE |
| **Institutional** | Knowledge (Charlie) helix entry (confidence-weighted by age) | MODERATE → LOW (stale if > 90 days) |
| **Synthetic** | Model training knowledge; no external citation | LOW — always flag explicitly |

## Source Freshness Rules

| Source | Freshness check | Action if stale |
|--------|----------------|-----------------|
| Context7 | `query-docs` returns version; check against latest release | Note version mismatch; fetch live docs via Firecrawl |
| Knowledge (Charlie) helix entry | Check entry date in frontmatter | > 90 days → mark as "stale — verify before citing"; query fresh source |
| HuggingFace paper | Check arXiv submission date | > 2 years → look for more recent work citing this paper |
| Firecrawl live | Content has a date? Check it | > 6 months → attempt refresh scrape |

## Confidence Badge Selection

| Claim type | Required tier | Badge |
|-----------|--------------|-------|
| "X is the correct API for Y" | Primary or Secondary | DEFINITIVE |
| "The consensus is X" | Secondary + corroborating Tertiary | STRONG |
| "Evidence suggests X" | Tertiary only | MODERATE |
| "I believe X based on training" | Synthetic only | LOW — flag explicitly |

**Rule**: Never use DEFINITIVE for a Tertiary or lower source. Never present a LOW claim as guidance without explicit flagging.

## Citation Format (inline)

- Knowledge (Charlie) helix: `[Knowledge (Charlie) helix, {date}, session {id}, sig {score}]: "{quote}"`
- Context7: `[Context7 /{lib-id}, {topic}, tokens {n}]: "{finding}"`
- HuggingFace: `[HuggingFace, arXiv:{id}, {author} ({year})]: "{finding}"`
- Firecrawl: `[Firecrawl, {url}, scraped {date}]: "{finding}"`

## Parallel Dispatch

Run Knowledge (Charlie) helix + Context7 + Analyst (Delta) scan in one parallel message. Synthesize after all return. Divergence = flag for user.

## Output Template

```markdown
### Finding: {title}
**Confidence**: {DEFINITIVE | STRONG | MODERATE | LOW}
**Source**: {citation}
{2-3 sentence description}
**Evidence**: [{tier} citation]: "{quote}"
**Recommendation**: {action or "Informational only"}
```
