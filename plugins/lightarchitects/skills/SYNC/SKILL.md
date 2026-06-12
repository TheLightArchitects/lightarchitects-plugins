---
name: SYNC
description: "Roadmap + manifest synchronizer — places a VALIDATED plan into the
  canonical tracking artifacts (active.yaml, portfolio.md, _MOC-builds.md,
  builds-registry.yaml) with Northstar-aware queue placement. Computes leverage
  score, identifies Pillar coverage gaps, finds parallel-launch candidates,
  surfaces pre-existing canon drift without auto-fixing. Use after /PLAN
  produces a VALIDATED plan and before /BUILD spawns the worktree.
  Invocation: '/SYNC --roadmap <codename>', '/sync --roadmap <codename>',
  'sync the roadmap with <codename>', 'place <codename> in queue', 'add
  <codename> to portfolio', 'update tracking artifacts for <codename>'."
user-invocable: true
version: 1.0.0
context: root
---

# /SYNC — Roadmap + manifest synchronizer

> Bridge between `/PLAN` (plan validated) and `/BUILD` (worktree spawned). Surgically updates canonical tracking artifacts with Northstar-aware placement. **Does not write code, does not create worktrees, does not create per-build manifest.yaml** — that remains `/BUILD`'s responsibility on phase transitions.

## /SYNC vs. /PLAN vs. /BUILD

| | `/PLAN` | `/SYNC --roadmap` | `/BUILD` |
|--|---------|-------------------|---------|
| Pre-condition | Target string | Plan with `validation_status: VALIDATED` | Plan in active.yaml + queued |
| Reads | canon, target | plan frontmatter, canon://northstar, all 4 tracking artifacts | plan, manifest.yaml |
| Writes | `~/.claude/plans/<codename>.md` | `active.yaml`, `portfolio.md`, `_MOC-builds.md`, `builds-registry.yaml` | code, worktree, `corso/builds/<codename>/manifest.yaml` |
| Decision | Build / scrum / edit / plan only | Tier placement + queue rank confirmation | Per-phase /GATE |
| Operator interaction | Heavy (Northstar elicitation, iter loop) | Light (auto-place if unambiguous; ask if close call) | Heavy (per-phase confirmation) |

---

## Accepted Flags

| Flag | Effect |
|------|--------|
| `--roadmap <codename>` | **(REQUIRED)** Identifies the plan to sync. Plan must exist at `~/.claude/plans/<codename>.md` with `validation_status: VALIDATED`. |
| `--dry-run` | Compute placement + emit proposed diffs to stdout; do not write. Useful for previewing rank/tier before commit. |
| `--yes` | Skip placement-confirmation `AskUserQuestion`; auto-apply if scoring is unambiguous. Refuses to skip when placement is close-call (score within 5% of adjacent rank). |
| `--tier <T1\|T2\|T3>` | Override computed tier. Logged as `placement_override` in active.yaml entry. |
| `--rank <N>` | Override computed queue rank within tier. Logged as `placement_override`. |
| `--no-drift-flag` | Suppress pre-existing drift findings (Pillar mislabels, sprint-count stale, etc.). Use only when drift is already known + tracked elsewhere. |

Rejected: `--then`, `--watch`, `--drain`, `--fix` (SQUAD control flags), `--auto-fix-drift` (canon drift must go through Arbiter (Golf) per Canon XXXIX).

---

## Step 1: Argument Validation (SAFEGUARD #24)

1. `--roadmap <codename>` is required. Reject if absent.
2. `<codename>` pattern: `^[a-z0-9-]+$`, ≤40 chars. Reject shell metacharacters + path traversal.
3. Plan file must exist at `~/.claude/plans/<codename>.md`. If not → error: *"Plan not found. Run `/PLAN <codename>` first."*
4. Plan must have YAML frontmatter with `validation_status: VALIDATED`. If `INSUFFICIENT_EVIDENCE` / `UNVALIDATED` / `DISPUTED` → error and direct operator back to /PLAN iteration loop.

---

## Step 2: Pre-flight Checks

```bash
# G-S1: canonical tracking dir exists
test -d ~/lightarchitects/soul/helix/corso/builds || error "Tracking dir missing"

# G-S2: all 4 artifacts exist
for f in active.yaml portfolio.md _MOC-builds.md builds-registry.yaml; do
  test -f ~/lightarchitects/soul/helix/corso/builds/$f || error "Missing $f"
done

# G-S3: codename not already present in active.yaml (else offer update vs error)
grep -q "codename: ${codename}" ~/lightarchitects/soul/helix/corso/builds/active.yaml \
  && warn "Already present — offering update vs error"

# G-S4: northstar.md present at canonical URI
test -f ~/lightarchitects/soul/helix/user/standards/canon/northstar.md \
  || error "Cannot read canon://northstar — placement requires Pillar definitions"
```

If G-S3 fires → `AskUserQuestion`:
```
question: "<codename> already present in active.yaml. How proceed?"
options:
  - "Update existing entry (recommended if plan iter or status changed)"
  - "Abort — investigate why duplicate"
  - "Replace existing entry (DESTRUCTIVE — old entry lost)"
```

---

## Step 3: Read Plan Frontmatter

Extract from `~/.claude/plans/<codename>.md`:

| Required field | Used for |
|---|---|
| `project` | Repo selection in tracking entry |
| `codename` | Verify matches arg |
| `validation_status` | Must be VALIDATED |
| `tier` | Tier-1/2/3 placement default |
| `northstar_lineage.pillar_mapping` | Pillar score computation |
| `northstar_lineage.northstar_text` | Description seed |
| `northstar_lineage.build_to_northstar_mapping` | Mechanical-check enumeration |
| `canon_compliance.component_northstars_served` | Mechanical-check count |
| `review_iterations` + `review_verdict.xea_layer_1.aggregate` | XEA score for tracking entry |
| `effort_wall_clock` (frontmatter or Part II) | Leverage-ratio denominator |
| `blocked_by`, `blocks` (frontmatter or Part XV) | Dependency graph |

If any REQUIRED field missing → `AskUserQuestion` to fill OR direct to /PLAN for amendment.

---

## Step 4: Read Canon + Current Tracking State

Read in parallel (single message, multiple Read calls):

1. `~/lightarchitects/soul/helix/user/standards/canon/northstar.md` — Pillar definitions, Component Northstar mechanical checks
2. `~/lightarchitects/soul/helix/corso/builds/active.yaml` — current entries (compute slot for new one)
3. `~/lightarchitects/soul/helix/corso/builds/portfolio.md` — Pillar coverage map + Tier structure
4. `~/lightarchitects/soul/helix/corso/builds/_MOC-builds.md` — sprint count + Tier list
5. `~/lightarchitects/soul/helix/corso/builds/builds-registry.yaml` — total count + manual-sync section

Cache in working memory as structured records — do NOT re-read for each subsequent step.

---

## Step 5: Compute Placement Score

### Step 5.1: Pillar Alignment

For each Pillar in `plan.pillar_mapping`:
- Read Pillar definition from `northstar.md` (verify the Pillar name is canon-aligned; if plan cites "P4 (Operator-Legible Arc)" but canon says P4=async-collab, → FLAG as candidate B-1 finding before continuing)
- Count Pillars currently with `dedicated_tier_1_build = 0` in active.yaml
- **Gap-filler bonus**: +20 points if plan covers an under-served Pillar (no other Tier-1 build dedicates to it)

### Step 5.2: Mechanical-Check Closure

Count items in `plan.canon_compliance.component_northstars_served` that:
- Reference a specific `northstar.md:<section>:<check>` anchor (verified by line-number grep)
- Are NOT already satisfied by an in-progress or recently-shipped build (read `portfolio.md` "Recent ships" + Tier-2 in-progress)

**Closure score**: `mechanical_checks_closed × 5` points.

### Step 5.3: Leverage / Effort Ratio

```
leverage_score = (pillar_alignment + gap_filler_bonus + closure_score) / effort_wall_clock_hours
```

Effort hours from `plan.effort_wall_clock` (parse "~18-21h" → use midpoint = 19.5h).

### Step 5.4: Foundation Bonus

Read `plan.unblocks_downstream` / `plan.blocks` (frontmatter). For each downstream build with `status: planned` or `status: draft`:
- **Foundation bonus**: +10 points per downstream build unblocked

### Step 5.5: Parallel-Launchable Detection

Walk active.yaml Tier-1 entries. For each, compute file-overlap with `plan.files_created + plan.files_modified`:
- 0 overlap → parallel-launchable
- 1-2 overlaps → coordinate-required (note in entry)
- ≥3 overlaps OR cross-canon-doc shared → sequential-required (note as blocker)

### Step 5.6: Final Score

```
total_score = leverage_score + foundation_bonus
queue_rank_within_tier = sort_descending(total_score)
```

---

## Step 6: Determine Tier Placement

Decision tree (read frontmatter `tier` + `status`):

```
plan.status == "shipped" / "promoted" / "completed" → Tier 3 (reference/completed)
plan.status == "in_progress" / "in-progress" / phase started → Tier 2 (in progress)
plan.status == "validated" / "plan-validated" AND no blockers → Tier 1 (ready for /BUILD)
plan.status == "validated" AND blocked_by non-empty → Tier 1 (blocked) — sub-section
plan.status == "draft" → REJECT — return to /PLAN
```

---

## Step 7: Detect Pre-existing Drift (Flag, Don't Fix)

Before applying edits, scan tracking artifacts for drift. Emit findings; do NOT auto-fix.

| Drift class | Detection | Action |
|---|---|---|
| **D-1: Pillar mislabel in portfolio.md** | Compare `portfolio.md` Pillar table rows against `northstar.md:72..200` Pillar headings | Flag as `tracked_findings[]` with severity=MEDIUM; recommend `/SCRUM portfolio-pillar-drift` |
| **D-2: Sprint count stale** | Count Tier-1 + Tier-2 entries in active.yaml vs declared count in portfolio.md / _MOC-builds.md headers | Auto-update sprint count IF it's a simple +1 from this sync (this skill's own change); flag otherwise |
| **D-3: builds-registry.yaml total stale** | Count `- codename:` entries vs `total: N` header | Auto-bump by +1 for this skill's own addition; flag if discrepancy >1 |
| **D-4: Tier-1 entry has `status != validated`** | Walk Tier-1 list in portfolio.md | Flag — should be Tier-2 or Tier-3 |
| **D-5: Plan path missing from active.yaml entry** | Check `plan:` field on each active.yaml entry resolves to existing file | Flag — orphaned entry |
| **D-6: Codename mismatch between artifacts** | active.yaml ↔ portfolio.md ↔ _MOC-builds.md ↔ builds-registry.yaml for each plan | Flag — recommend `/sync --reconcile` (future skill) |

If drift count >5 → surface aggregated report and `AskUserQuestion`:
```
question: "Detected N drift findings unrelated to <codename>. Proceed with this sync?"
options:
  - "Proceed — drift tracked for separate /SCRUM"
  - "Abort and fix drift first"
```

Default (under `--yes`): proceed and track findings.

---

## Step 8: Generate Placement Proposal

Compose a structured proposal (NO writes yet):

```yaml
proposal:
  codename: <name>
  tier: Tier 1 | Tier 2 | Tier 3
  queue_rank: <N>
  queue_rank_rationale: |
    - leverage_score: <X> (pillars: <Y>, mech-checks: <Z>, hours: <H>)
    - foundation_bonus: <B> (unblocks: <downstream-list>)
    - gap_filler_bonus: <G> (P<n> currently under-served: <true/false>)
  parallel_launchable_with:
    - <other-codename> (file-overlap: 0)
  sequential_required_after:
    - <other-codename> (file-overlap: <N>, shared-files: <list>)
  drift_findings: <list>
  edits_to_apply:
    active.yaml: <unified diff>
    portfolio.md: <unified diff>
    _MOC-builds.md: <unified diff>
    builds-registry.yaml: <unified diff>
```

---

## Step 9: Confirmation Gate

If `--yes` AND scoring unambiguous (top score >5% above #2) → auto-apply, log decision.

Else `AskUserQuestion`:
```
question: "Placement proposal: Tier <T>, rank <N>. Apply?"
header: "Placement"
options:
  - label: "Apply (Recommended)" / description: "Write to all 4 tracking artifacts as proposed."
  - label: "Move to different tier/rank" / description: "Override placement — opens follow-up question for tier+rank."
  - label: "Dry-run only" / description: "Print diffs to stdout; do not write."
  - label: "Abort" / description: "Cancel sync; plan remains in ~/.claude/plans/ with no tracking-artifact edits."
```

On override path → second `AskUserQuestion` for desired tier + rank; log as `placement_override`.

---

## Step 10: Apply Edits

Apply in this order (atomic-ish — each Edit is single-tool):

1. **active.yaml** — Insert entry. Placement: append to Tier-1 section if Tier-1, or in the in-progress block if Tier-2. Use full schema from `references/active-yaml-entry-template.yaml` (see below for inline template).
2. **portfolio.md** — Insert in correct Tier section ordered by queue_rank. Update sprint count. Update Pillar coverage map row for affected Pillar(s).
3. **_MOC-builds.md** — Insert in Tier section. Update sprint count.
4. **builds-registry.yaml** — Append to manual-sync section. Bump `total:` by +1.

**Verification after each write**:
- Re-grep for codename in each file → exactly 1 entry
- For portfolio.md and _MOC-builds.md: sprint-count matches re-counted entries

If any verification fails → emit warning and offer rollback.

---

## Step 11: Emit Summary

Concise summary (≤200 words) reporting:
- Tier + queue_rank assigned (+ score breakdown)
- Files updated (4)
- Mechanical-check closures registered
- Pillar gap-fill status
- Parallel-launch candidates identified
- Drift findings flagged for separate review
- Next recommended action (`/SCRUM <codename>` or `/BUILD <codename>`)

---

## Inline Schema Templates

### active.yaml entry (Tier-1 plan-validated)

```yaml
- name: <codename>
  codename: <codename>
  tier: <SMALL|MEDIUM|LARGE|XL>
  status: plan-validated
  priority: <low|medium|high>           # From leverage_score band: ≥80 high, 50-79 medium, <50 low
  queue_rank: <N>                       # Within tier
  queue_parallel_with: [<list>]         # 0-file-overlap peers
  queue_sequential_after: [<list>]      # ≥3-file-overlap peers
  repo: <repo>                          # From plan.project
  branch: feat/<codename>               # Placeholder; created by /BUILD Phase 0
  worktree: ~/lightarchitects/worktrees/<codename>  # Placeholder
  plan: ~/.claude/plans/<codename>.md
  parent_design_memo: <if-applicable>
  northstar: "<P1>+<P2>+..."            # From plan.pillar_mapping
  pillar_mapping: "<plan.pillar_mapping>"
  description: <≤200char summary from plan.northstar_text first line>
  mechanical_checks_satisfied:
    - "<§check> (canon://northstar#<anchor>)"
  scrum_review:
    pending: <true|false>
    note: <if-pending>
  xea:
    iter_1_aggregate: <N>
    iter_N_aggregate: <N>
    iter_N_band: <EXEMPLARY|STRONG|...>
    iter_N_findings_folded: [<list>]
  effort_wall_clock: <plan.effort_wall_clock>
  files_created: <count>
  files_modified: <count>
  loc_estimate: <count>
  phases:
    phase_0_preflight: { status: pending }
    # ... one per plan phase
  blocks: []                             # plan.blocks
  blocked_by: []                         # plan.blocked_by
  unblocks_downstream: [<list>]          # plan.unblocks_downstream
  siblings: [<list>]                     # plan.siblings
  canon_docs_touched: [<list>]
  created: <YYYY-MM-DD>
  updated: <YYYY-MM-DD>
```

### portfolio.md Tier-1 entry

```markdown
### <codename> — <TIER> — <pillar_mapping> — **queue rank <N> (<parallel|sequential> <note>)**
- **Status**: PLAN-VALIDATED | PRE-BUILD
- **Plan iteration**: <N> — aggregate <score> <band>
- **Wall-clock estimate**: <effort_wall_clock>
- **What ships**: <≤200char summary>
- **Northstar delta**: <pillar-gap-fill status + mechanical-checks closed>
- **Strategic role**: <gap-fill | foundation-for-X | complement-to-Y>
- **Plan**: `~/.claude/plans/<codename>.md`
- **Parent design memo** (if any): `~/.claude/plans/<parent>.md`
```

### _MOC-builds.md Tier-1 entry

```markdown
- [[corso/builds/<codename>/manifest|<codename>]] — <TIER> — <pillar_mapping> — iter-<N> <band> <score> — <effort> — **queue rank <N>** — <one-line strategic note>
```

### builds-registry.yaml entry

```yaml
  - codename: "<codename>"
    status: "plan-validated"
    tier: "<TIER>"
    created: "<YYYY-MM-DD>"
    plan_name: "<short description>"
    pillar_mapping: "<plan.pillar_mapping>"
    plan_iteration: <N>
    plan_validation_band: "<band>"
    queue_rank: <N>
    parent_design_memo: <if-applicable>
    mechanical_checks_closed: [<list>]
    role: "<gap-fill | foundation | complement>"
    blockers: []
    effort_estimate: "<effort_wall_clock>"
```

---

## Loop Invariants

- **Idempotent** — re-running `/SYNC --roadmap <same-codename>` updates existing entry without duplication.
- **Non-destructive** — never deletes existing entries; offers replace/update via AskUserQuestion.
- **Canon-respecting** — never edits canon docs (`canon://`); never silently fixes Pillar drift (Canon XXXIX).
- **No code writes** — strictly tracking artifacts only.
- **No worktree creation** — `/BUILD` owns that.
- **No per-build manifest.yaml creation** — `/BUILD` owns that on phase-0 transition.

---

## Graceful Degradation

| Failure | Handling |
|---|---|
| Plan frontmatter incomplete | `AskUserQuestion` to fill missing fields OR direct to /PLAN |
| canon://northstar unreadable | Hard error — placement requires Pillar definitions |
| One of 4 tracking artifacts missing | Hard error — full sync requires all 4 |
| Codename collision | `AskUserQuestion` update vs abort vs replace |
| Drift count >5 | Aggregated report + AskUserQuestion proceed vs fix-first |
| Score-band collision (top 2 within 5%) | Refuse `--yes` auto-apply; force human choice |

---

## Composition with Other Skills

| Upstream | Why fired | Result feeding /SYNC |
|---|---|---|
| `/PLAN <codename>` | Validates a plan to status=draft+VALIDATED | Plan file exists with frontmatter — /SYNC's input |
| `/SCRUM <codename>` (optional) | 3-round squad review may revise XEA score | Updated score reflected in tracking entry on re-/SYNC |

| Downstream | When | What /SYNC enables |
|---|---|---|
| `/BUILD <codename>` | After /SYNC places the plan | Reads active.yaml to know the build is queued + ranked |
| `/SCRUM <codename>` | Pre-/BUILD final review | Reads portfolio.md + active.yaml to know peer context |
| Future `/sync --reconcile` | Bulk drift fixup | Builds on this skill's drift detection |

---

## Pressure-tested

Skill abstraction extracted 2026-05-19 from a manual sync of `copilot-omniscience-read` into active.yaml + portfolio.md + _MOC-builds.md + builds-registry.yaml. Manual run took ~20 minutes; the skill collapses it to a single command with explicit scoring rationale.

See `memory://feedback_sync_skill_extraction` (TBD on first invocation) for context.

---

## References

- `canon://northstar` — Pillar definitions (`northstar.md:72-200`) + Component Northstars (`northstar.md:212+`)
- `canon://lasdlc-template` — plan frontmatter schema
- `canon://platform-canon` — Canon XXXIX (canon evolution — NO auto-fix of drift)
- `canon://architects-blueprint` — Part XVIII (close-out, queue management)
- `~/lightarchitects/soul/helix/corso/builds/{active.yaml, portfolio.md, _MOC-builds.md, builds-registry.yaml}` — tracking artifacts
- `memory://feedback_plan_frontmatter_convention` — required frontmatter fields
- `memory://feedback_html_md_canon_pair_drift` — same-commit doc rule (informs drift detection)
