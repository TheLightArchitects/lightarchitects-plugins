---
name: VAULT-SEED
description: "One-time protocol for bootstrapping a new Knowledge (Charlie) vault with minimum viable
  context. Produces 5-10 seed entries from static sources (STACKS, COOKBOOK-ENFORCER,
  git log, Cargo.toml, CLAUDE.md). Idempotent — skips if ≥3 vault_seed entries exist.
  Use when: joining a project with an empty vault, first SQUAD run on a new project,
  or manually via knowledge agent: 'Seed the vault for this project.'"
user-invocable: false
version: 1.0.0
context: root
---

# VAULT-SEED — One-Time Vault Bootstrap

> A warm vault is a compounding moat. A cold vault is an expensive lie.
> Seed once. Pre-flight finds things from run 1.

## User Identity Resolution

Before writing any entries:

```bash
git config --global user.name
```

Fallback: `whoami`. The resolved name is the `{user-id}` used for all vault paths in this session.

## When to Use

- First SQUAD `software_engineering` run on a new project
- Joining an existing project with an empty or near-empty Knowledge (Charlie) helix
- Manually: knowledge agent receives "Seed the vault for this project"
- SETUP flow: Step 1 (automatic, before relational opt-in)

## Idempotency Check (always first)

Check both the soul search AND the sentinel file:

```bash
test -f ~/lightarchitects/soul/helix/.vault-seeded && echo "already seeded"
```

Also:
```
sibling: "soul"  action: "search"  query: "vault_seed"
```

If `.vault-seeded` sentinel exists OR ≥3 vault_seed entries found → **SKIP** entirely.
Report: "Vault already seeded (found N vault_seed entries). No action needed."

If neither condition triggers → proceed with seeding.

## Seed Sources (in order)

Work through each source. Extract decisions, conventions, and rationale.
Target: ≥5 entries total. Stop after 10.

### Source 1 — STACKS sub-skill

```
action: "get_skill"  skill: "lightarchitects/STACKS"
```

Extract as entries:
- Stack technology choices (Rust MCP stdio, SvelteKit, Neo4j, etc.)
- Crate ownership boundaries (which crate owns what domain)
- Key error-handling conventions per layer
- Why these choices were made (consult CLAUDE.md if STACKS doesn't explain)

### Source 2 — COOKBOOK-ENFORCER sub-skill

```
action: "get_skill"  skill: "lightarchitects/COOKBOOK-ENFORCER"
```

Extract as entries:
- Top 5 team conventions most likely to be violated (CRITICAL + HIGH severity rules)
- Each rule as one entry: what the rule is, why it exists, what it prevents

### Source 3 — Recent git history

```bash
git log --oneline -20
```

Extract as entries (skip pure chore/docs commits):
- Architectural decisions visible from commit messages
- Dependencies added or removed
- Breaking changes or migrations
- Each entry answers: "what was decided, and why (inferred from message)"

### Source 4 — Dependency choices (Cargo.toml / package.json)

```bash
# Rust projects:
cat Cargo.toml | grep -E "^\[dependencies\]|^[a-z]" | head -40
# TypeScript:
cat package.json | python3 -c "import json,sys; d=json.load(sys.stdin); [print(k,v) for k,v in {**d.get('dependencies',{}), **d.get('devDependencies',{})}.items()]" | head -40
```

Extract as entries:
- Non-obvious dependency choices (why tokio over async-std, why serde_json over alternatives)
- Unusual version pins with rationale
- Each entry answers: "what was chosen and why"

### Source 5 — CLAUDE.md architectural decisions

```bash
cat CLAUDE.md
```

Extract as entries:
- Explicit architectural decisions stated in CLAUDE.md
- Constraints noted (dependencies, compatibility, required patterns)
- Any "do not" or "always" rules that reveal past mistakes

## Entry Format

Each seed entry uses the compact `decision_log` format (≤200 tokens):

```yaml
---
type: decision_log
tags: [vault_seed, {source}, {domain}]
significance: 3.0
generated_by: knowledge_agent
---
**Target**: {what was built/chosen/decided}
**Decision**: {core choice, one-line rationale}
**Alternatives rejected**: {what wasn't chosen and why — prevents re-litigation}
**Lessons**: {what this entry warns against; failure modes to avoid}
**Next run**: {what pre-flight should surface when touching this area}
```

Where `{source}` is one of: `stacks`, `cookbook`, `git_history`, `dependencies`, `claude_md`.
Where `{domain}` is the relevant crate or module name.

**Minimum viable entry** (when rationale is unknown):
```yaml
**Target**: {what was chosen}
**Decision**: {observed choice — rationale unknown, inferred from context}
**Alternatives rejected**: unknown — flag for enrichment on next touch
**Lessons**: verify this decision is still intentional before changing it
**Next run**: confirm rationale still holds
```

## Write Protocol

For each entry, write to the user-tier vault path:

```
sibling: "soul"  action: "write_note"  params: {
  path: "helix/user/{user-id}/decisions/architectural/{slug}.md",
  content: "<entry content>",
}
```

Where `{slug}` is a kebab-case slug derived from the entry title (lowercase, spaces → hyphens, max 60 chars).

**Path mapping by source:**
- `stacks` entries → `helix/user/{user-id}/decisions/architectural/`
- `cookbook` entries → `helix/user/{user-id}/decisions/architectural/`
- `git_history` entries → `helix/user/{user-id}/decisions/architectural/`
- `dependencies` entries → `helix/user/{user-id}/decisions/architectural/`
- `claude_md` entries → `helix/user/{user-id}/decisions/architectural/`

Write entries one at a time. After each write, continue to the next entry.
If Knowledge (Charlie) is unavailable: write all entries to `~/.claude/projects/.../memory/` as `vault_seed_{n}.md`.

**After all entries written**, write the sentinel:
```bash
touch ~/lightarchitects/soul/helix/.vault-seeded
```

## Default Scaffold Created

After seeding entries, create this empty directory structure for the user:

```bash
# Create helix.toml marker files for each user-tier sub-helix
# (actual directory creation happens when first entry is written)
```

**New user gets empty structure (helix.toml files only — no content):**
- `helix/user/{user-id}/memories/` — personal memories (publish: false)
- `helix/user/{user-id}/notes/` — personal notes (publish: false)
- `helix/user/{user-id}/journal/` — personal journal (publish: false)
- `helix/user/{user-id}/builds/` — build records
- `helix/user/{user-id}/decisions/architectural/` — where VAULT-SEED writes entries
- `helix/user/{user-id}/decisions/operational/`
- `helix/user/{user-id}/standards-overrides/`

**Explicitly NOT created:**
- `spiritual/` — never auto-created; user opts in via SETUP wizard
- `career/`, `training/`, `health/` — never auto-created (personal-only)
- `navigation/hubs/`, `navigation/mocs/` — user builds their own
- `.compacted/` — only created when user's first compaction occurs

For each directory above that should be created, create a minimal `helix.toml` marker:
```
sibling: "soul"  action: "write_note"  params: {
  path: "helix/user/{user-id}/decisions/architectural/helix.toml",
  content: "[helix]\nname = \"architectural-decisions\"\nscope_tier = \"user\"\npublish = false\n",
}
```
(Similarly for other directories, adjusting `name` accordingly.)

## Output

```
## VAULT-SEED Complete

Entries written: {N}
Sources used: {sources}

### Entries Created
{list of entries with title + source tag}

Pre-flight query: `soul/search query: "vault_seed"` will return all {N} entries.
```

If idempotency check skipped the run:
```
## VAULT-SEED Skipped

Vault already seeded: {N} vault_seed entries found.
Run `soul/search query: "vault_seed"` to view them.
```
