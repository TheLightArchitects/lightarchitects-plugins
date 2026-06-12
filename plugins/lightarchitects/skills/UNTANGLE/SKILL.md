---
name: UNTANGLE
description: "Orchestrates the agents-playbook §15.5.7 Triage subprotocol — separates accumulated
  WIP into reviewable feat/ branches with zero data loss. Use when a repo has accumulated
  uncommitted work (≥10 modified files, ≥5 untracked, or mixed staged+unstaged+untracked state)
  and needs feature-branch separation before review. Primary domain: ops (Ops (Bravo)'s territory —
  git repo hygiene is a DevOps operation). Use when the user says '/untangle', 'untangle WIP',
  'separate uncommitted into branches', 'triage this repo', 'clean up before review'."
user-invocable: true
version: 1.0.0
context: root
---

# /UNTANGLE — WIP Cleanup → Feature-Branch Separation → Review Tasks

> Tangled WIP becomes orderly threads. Preserve everything. Lose nothing.
> One archive holds the truth; many feature branches make it reviewable.

Wraps the canonical Triage subprotocol (`canon://agents-playbook#15.5.7`).
Primary executor: the ops domain agent (Ops (Bravo)'s territory — git repo hygiene
is a DevOps operation, not a code-authoring one). Claude may invoke
`/UNTANGLE` directly OR delegate to Ops (Bravo) via `Agent(subagent_type: lightarchitects:ops)`.

## When to Use

- `git status` shows ≥10 modified files OR ≥5 untracked OR mixed staged+unstaged+untracked
- WIP sits on primary (`main`) — violates agents-playbook §15.3 invariant
- WIP straddles multiple unrelated features — single review is too coarse
- Multi-repo cleanup needed (invoke once per repo, never in parallel across repos)
- Before any `/BUILD` when primary worktree is dirty (G0 gate failure)

## Mode Detection

- `/UNTANGLE` — single-repo mode (current cwd)
- `/UNTANGLE <repo-path>` — explicit-repo mode (resolves to that repo's primary worktree)
- `/UNTANGLE --multi <repo1> <repo2> ...` — multi-repo mode (sequential, never parallel)

## Step 1: Sanity + Pre-flight Inventory

Verify repo state + capture safe-return state. All read-only.

```bash
git status --short | wc -l                            # WIP scope
git diff --stat | tail -2                             # unstaged delta
git diff --cached --stat | tail -2                    # staged delta
git log --oneline -5                                  # current HEAD chain
git rev-parse origin/<base>                           # last pushed point
git stash list                                        # existing stashes
git reflog -10                                        # recent moves
git ls-tree -r HEAD | wc -l                           # current tree size
```

Persist to `/tmp/triage-<repo>-<YYYYMMDD>.log` — this is the recovery anchor.

**Bail conditions**:
- `git status --short | wc -l` is 0 → nothing to triage; exit
- Detached HEAD → resolve before continuing
- Active merge/rebase/cherry-pick → resolve before continuing
- Repo is the primary worktree of an active build → consult §15.3 invariant first

## Step 2: HITL Gate — Confirm Triage

Show scope + confirm via `AskUserQuestion`:

```
Repo: <repo>
Branch: <current>
Base: origin/<base> @ <sha>
WIP scope: N modified + M untracked
Working tree size: <T> tree entries

Proceeding will:
  1. Create triage/<repo>-wip-archive-<date> (single commit, --no-verify)
  2. Return primary to <base>
  3. Prompt for feature-group mapping
  4. Create N feat/<repo>-<feature> branches from <base>
  5. Register N review tasks via TaskCreate

Continue? [yes / abort]
```

## Step 3: Archive Snapshot (foreground, atomic)

**Single Bash call**, no backgrounding:

```bash
git checkout -b triage/<repo>-wip-archive-<YYYYMMDD> && \
  git add -A && \
  git commit --no-verify -m "chore(archive): WIP snapshot <date> — pre-triage

Do NOT merge. Holding archive per agents-playbook §15.5.7.
Hook bypassed (--no-verify): Tier A per feedback_no_verify_two_tier.
Contents: <brief summary of what's being preserved>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

Verify per §15.4.5 — the commit MUST change the tree:

```bash
PARENT=$(git rev-parse HEAD~1^{tree})
HEAD=$(git rev-parse HEAD^{tree})
[ "$PARENT" = "$HEAD" ] && echo "❌ PHANTOM EMPTY ARCHIVE — investigate" && exit 1
```

If phantom: pre-commit hook auto-discarded changes. Investigate hook config
or use `git update-ref` plumbing to bypass.

## Step 4: Return to Clean Base

```bash
git checkout <base> && \
  git status --short | wc -l    # MUST be 0
```

If non-zero: untracked files survived (likely from .gitignore omissions).
Investigate the leftover files before continuing.

## Step 5: Feature-Slice Mapping (HITL gate)

Read the archive's diff and propose groupings:

```bash
git diff <base>..triage/<repo>-wip-archive-<date> --name-only > /tmp/archive-files.txt
git diff <base>..triage/<repo>-wip-archive-<date> --name-only --diff-filter=A > /tmp/archive-added.txt
git diff <base>..triage/<repo>-wip-archive-<date> --name-only --diff-filter=M > /tmp/archive-modified.txt
```

Inspect a sample of each file's diff content (especially the largest deltas).
Group by **shared feature concern**, NOT shared directory.

Present proposed grouping for approval:

```
Proposed feature branches for <repo>:
  feat/<repo>-license-proprietary    — N files (NOTICE + TPL + deny.toml + Cargo.lock)
  feat/<repo>-<feature-A>            — N files (...)
  feat/<repo>-<feature-B>            — N files (...)
  ...

Each branch will:
  - Cut from <base> (current main HEAD)
  - Receive its files via git checkout <archive> -- <files>
  - Get one commit with descriptive message
  - Trigger a TaskCreate review task

Continue with this grouping? [yes / revise]
```

HITL gate prevents incorrect groupings from baking into review.

## Step 6: Feature-Slice Branches (per-feature, foreground)

For each approved group, ONE atomic Bash call:

```bash
git checkout -b feat/<repo>-<feature-name> && \
  git checkout triage/<repo>-wip-archive-<date> -- <files-for-this-feature> && \
  git commit -m "feat(<feature>): <description>

<details>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>" && \
  git checkout <base>
```

**`--no-verify` policy** (per `feedback_no_verify_two_tier`):
- Hook passes → no flag needed
- Hook fails on environmental issue (verify by reproducing on `<base>` HEAD
  with no WIP) → `--no-verify` OK, document env requirement in commit message,
  flag BLOCKING in review task
- Hook fails on code defect → operator per-action approval; if approved,
  commit message MUST flag the defect explicitly, review task MUST include
  BLOCKING note mirroring defect location

Verify each commit per §15.4.5 tree check.

## Step 7: Containment Verification

Per §15.4.5 — use `ls-tree`, NOT symmetric diff stats:

```bash
git ls-tree -r triage/<repo>-wip-archive-<date> | sort > /tmp/archive.tree
for branch in $(git branch --list 'feat/<repo>-*' | grep -v archive); do
  git ls-tree -r "$branch" | sort
done | sort -u > /tmp/features.tree
comm -23 /tmp/archive.tree /tmp/features.tree         # MUST be empty
```

Empty output → full containment achieved. Any output → files missing from
some feature branch. Identify and either:
- Add to an existing feature branch (amend or new commit)
- Create an additional feature branch
- Document why excluded (e.g., dev artifacts like `.claude/` belong in `.gitignore`)

## Step 8: Review Task Registration

For each `feat/<repo>-<feature>` branch, create a `TaskCreate` review task:

```
Subject: REVIEW feat/<repo>-<feature> — <one-line summary>
Description:
  Branch: feat/<repo>-<feature>
  Repo: <repo>
  Files: N files (+I/-D lines)

  REVIEW CRITERIA:
  1. Northstar alignment: which Pillar (P1: webshell E2E / P2: orchestration / both / none)?
  2. Canon compliance: which canon docs apply? (builders-cookbook, agents-playbook, etc.)
  3. Active plan cross-check: does an existing build plan cover this work? Cite plan_path if yes.
  4. Fullstack viability: standalone or requires dependent work? Has a wiring plan?
  5. Decision criteria: keep (merge to main) / rework (specific gaps) / drop (not aligned)?

  BLOCKING ISSUES (if any flagged during triage):
  - <list any defects flagged in commit messages>

  Compare against: git diff <base>..feat/<repo>-<feature>
```

## Step 9: Final State Report

Present summary:

```
✅ <repo> triaged successfully:
   Archive: triage/<repo>-wip-archive-<date> (preserves N+M files)
   Feature branches: K created (feat/<repo>-*)
   Review tasks: K registered
   Containment: VERIFIED (ls-tree diff empty)

Next: review each feat/<repo>-* branch via the registered tasks.
Cleanup: archive branch may be deleted after all features are merged or dropped
         (per agents-playbook §15.5.4 standard cleanup).
```

## Safeguards (mandatory)

1. **Foreground only** — never `run_in_background: true` for git ops
2. **HITL at Step 2 and Step 5** — operator approves scope + grouping before any branch creation
3. **Post-commit tree verification** at every `git commit` (§15.4.5)
4. **Containment verification** at Step 7 (ls-tree, not symmetric diff)
5. **`--no-verify` two-tier policy** strictly observed (`feedback_no_verify_two_tier`)
6. **No `git stash --include-untracked` on heavy WIP** — loses staged/unstaged distinction
7. **No `git reset --hard` on source branch** before archive verification
8. **No combining branch-state ops across multiple Bash calls** — use `&&` chains

## Graceful Degradation

If the lightarchitects plugin / ops agent is unavailable:

1. Run §15.5.7 manually per agents-playbook
2. Hand-craft TaskCreate entries (one per feature branch) using the canonical template
3. Report: "UNTANGLE skill unavailable — manual triage per agents-playbook §15.5.7"

## References

- `canon://agents-playbook#15.5.7` — canonical Triage subprotocol
- `canon://agents-playbook#15.4.5` — post-commit tree verification
- `canon://agents-playbook#15.3` — G0 gate (primary clean check)
- `memory://feedback_no_verify_two_tier` — Tier A (archives) vs Tier B (env) policy
- `memory://feedback_no_destructive_git` — destructive op approval (applies to recovery steps)
- `memory://feedback_git_lifecycle_learnings` — 2026-05-11 cleanup session learnings
