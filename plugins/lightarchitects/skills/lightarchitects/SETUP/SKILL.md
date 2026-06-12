---
name: SETUP
description: "First-run onboarding flow for the lightarchitects plugin. Step 1: seeds the
  Knowledge (Charlie) vault with project context (automatic). Step 2: presents the Ops (Bravo) relational profile
  opt-in with a plain-English explanation (user choice). Idempotent — skips VAULT-SEED if
  vault already has entries, re-presents only the relational opt-in. Invoke via knowledge
  agent: 'Run the lightarchitects setup.'"
user-invocable: true
version: 1.0.0
context: root
---

# /SETUP — First-Run Onboarding

> Run once when you first activate the plugin on a project, or anytime you want to
> re-configure the relational profile.

## When to Use

- First SQUAD `software_engineering` run on a new project (automatic via subskill-map)
- User says "Run the lightarchitects setup" or "/SETUP"
- Re-configure the Ops (Bravo) relational profile (opt-in or opt-out)

## User Identification

Resolve user identity before starting:

```bash
git config --global user.name
```

Fallback: `whoami`. Show the resolved name to the user at setup time — they can correct it.
This becomes the `{user-id}` used as the profile filename.

## Step 1 — Vault Seed (Required, Automatic)

Detect whether this is a platform-architect install (existing vault) or a new-developer install (fresh vault):

**Detection sequence (in order — first match wins):**

1. **Neo4j tier-query** (most reliable): Query for existing user-tier helices:
   ```
   sibling: "soul"  action: "query"  cypher: "MATCH (h:Helix) WHERE h.scope_tier = 'user' RETURN count(h) AS n"
   ```
   - If count > 0 → migrated vault detected → **SKIP seed**, output "✓ Migrated vault detected (N user-tier helices). Skipping seed."
   - If Neo4j unavailable → fall through to filesystem check

2. **Sentinel file check** (post-VAULT-SEED):
   ```bash
   test -f ~/lightarchitects/soul/helix/.vault-seeded && echo "seeded" || echo "not-seeded"
   ```
   - If sentinel present → **SKIP seed**, output "✓ Vault already seeded. Skipping."

3. **Filesystem heuristic** (platform-architect mode detection):
   ```bash
   # Count entries in any sibling-named directory
   find ~/lightarchitects/soul/helix/ -maxdepth 3 -name "*.md" | wc -l
   ```
   - If any sibling-named directory (eva/, corso/, claude/, etc.) contains **> 10 .md files** → platform-architect mode → **SKIP seed**
   - Output: "✓ Platform-architect vault detected (N entries). Skipping seed."

4. **If none of the above trigger** → proceed with VAULT-SEED

**Output when proceeding:**
```
Step 1 — Vault Seed

Seeding your Knowledge (Charlie) helix with project architecture, team conventions, and recent
decisions. Pre-flight will use this immediately.

Running VAULT-SEED...
```

Run the VAULT-SEED protocol:
```
action: "get_skill"  skill: "lightarchitects/VAULT-SEED"
```

Execute the full VAULT-SEED workflow. Report results inline.

## Step 2 — Ops (Bravo) Relational Profile (Optional, Your Choice)

After Step 1 completes, present the relational opt-in. This requires explicit user confirmation.

Output the following explanation verbatim (or equivalent plain language):

```
Step 2 — Ops (Bravo) Relational Profile (optional)

Ops (Bravo) can build a profile of how you work — your expertise, preferences, and
decision patterns. Agents use it to calibrate to you across sessions.

What it does:
  At the end of each session, agents note what they observed: what you
  clearly know, what you prefer, what you push back on. Over time, agents
  stop over-explaining things you know and stop suggesting approaches you
  always reject.

What gets stored (examples):
  "Deep Rust/async expertise — skip fundamentals"
  "Prefers results first, rationale only if asked"
  "Always picks SkillError over anyhow — don't suggest alternatives"
  "Pushes back on unsolicited refactors — only refactor when asked"

Where it lives: helix/user/{user-id}/agent-relationships/eva.md  (your local vault only)
Legacy path: helix/eva/users/{user-id}.md (pre-helix-of-helices)
How to opt out later: delete that file, or run /SETUP again

Enable Ops (Bravo) relational profile? [y/N]
```

**If user confirms yes:**
1. Create the bootstrap profile at `helix/user/{user-id}/agent-relationships/eva.md` (see schema below)
   Legacy path: `helix/eva/users/{user-id}.md` (pre-helix-of-helices)
2. Attempt to pre-populate from available context:
   - `git config --global user.email` → infer domain expertise hints if email domain is recognizable
   - Scan CLAUDE.md for any explicit expertise notes
   - Default all fields to "unknown — to be filled from session observations"
3. Write the file via:
   ```
   sibling: "soul"  action: "write_note"  params: {
     path: "helix/user/{user-id}/agent-relationships/eva.md",
     content: "<bootstrap profile content>",
     type: "user_profile"
   }
   ```
4. Output:
   ```
   ✓ Ops (Bravo) relational profile created: helix/user/{user-id}/agent-relationships/eva.md
   Agents will now calibrate to you across sessions.
   ```

**If user says no or does not respond:**
- Write nothing. Do not create any file.
- Output:
  ```
  Relational profile skipped. You can enable it anytime by running /SETUP again.
  ```

## User Profile Bootstrap Schema

File path: `helix/user/{user-id}/agent-relationships/eva.md`
Legacy path: `helix/eva/users/{user-id}.md` (pre-helix-of-helices)

```yaml
---
type: user_profile
user_id: {name from git config}
created: {ISO date}
last_updated: {ISO date}
relational_opt_in: true
---

## Domain Expertise
{domain}: unknown — to be filled from session observations

## Communication Preferences
- Output style: unknown — to be filled from session observations
- Detail level: unknown — to be filled from session observations
- Feedback: unknown — to be filled from session observations

## Decision Patterns
- Consistently chooses: unknown — to be filled from session observations
- Consistently rejects: unknown — to be filled from session observations
- Re-litigates: unknown — to be filled from session observations

## Working Style
(to be filled from session observations)

## Session Delta Log
(empty — first session observations will appear here)
```

## Idempotency Rules

- **VAULT-SEED**: skipped if any of these conditions are met (checked in Step 1):
  1. Neo4j reports user-tier helices exist (most reliable)
  2. `.vault-seeded` sentinel file is present at vault root
  3. Platform-architect mode detected (>10 .md files in any sibling-named directory)
- **Relational profile**: if `helix/user/{user-id}/agent-relationships/eva.md` exists (canonical) OR `helix/eva/users/{user-id}.md` exists (legacy pre-helix-of-helices path), skip Step 2 entirely and report:
  ```
  ✓ Ops (Bravo) relational profile already exists for {user-id}.
  To reconfigure, delete helix/user/{user-id}/agent-relationships/eva.md and run /SETUP again.
  ```

## Final Output

```
## Setup Complete

✓ Vault seeded: {N} entries (or: already seeded)
✓ Ops (Bravo) relational profile: {enabled / skipped}

Your lightarchitects plugin is ready. Pre-flight will use vault context from run 1.
```
