---
name: DEPLOY
description: "Deployment pipeline via SQUAD. Detects project type, delegates to SQUAD
  devops preset (quality gates + build + verify via Ops (Bravo) sub-skills), then syncs the
  plugin marketplace and prompts /mcp reconnect. Use when the user says '/deploy',
  'deploy this', 'ship it', 'push to production', 'make deploy', 'release X'."
user-invocable: true
version: 2.0.0
context: root
---

# /DEPLOY — Deployment Pipeline

> Thin wrapper: project detection + HITL → SQUAD devops → plugin sync → reconnect.

## When to Use

- User wants to deploy/ship a project to production
- User says `/deploy`, "ship it", "deploy this", "make deploy"
- After a BUILD completes and the feature is ready to ship
- Routine deployment of any Light Architects project

## Accepted Flags

None. `/DEPLOY` accepts only the project argument.

Rejected flags: `--then`, `--watch`, `--drain`, `--fix`, `--research`.

## Step 1: Argument Validation (SAFEGUARD #24)

Validate the project argument: `^[a-zA-Z0-9_/. -]+$`. Reject SQUAD control flags and shell metacharacters.

## Step 2: Project Detection

Read the project's `Makefile` or `Makefile.toml` to identify the deploy command and target:

| Project | Deploy command | Target |
|---------|---------------|--------|
| Engineer (Alpha) | `make deploy` in `Engineer (Alpha)/MCP/Engineer (Alpha)-DEV/` | `~/.corso/bin/corso` |
| Ops (Bravo) | `make deploy` in `Ops (Bravo)/MCP/Ops (Bravo)-DEV/eva/` | `~/.eva/bin/eva` |
| Knowledge (Charlie) | `make deploy` in `Knowledge (Charlie)/Knowledge (Charlie)-DEV/` | `~/.soul/.config/bin/soul` |
| Analyst (Delta) | `cargo make deploy` in `Analyst (Delta)/MCP/Analyst (Delta)-DEV/` | `~/.quantum/bin/quantum-q` |
| Sentinel (Echo) (Mac) | `make deploy-mac` in `Sentinel (Echo)/MCP/Sentinel (Echo)-DEV/` | `~/.seraph/bin/seraph` |
| Monitor (Foxtrot) | `make deploy` in `Monitor (Foxtrot)/Monitor (Foxtrot)-DEV/` | `~/.ayin/bin/ayin` |
| lightarchitects SDK | `make deploy` in `lightarchitects-sdk/` | gateway binary |

If the project is not recognized, read the Makefile directly to identify the `deploy` target.

## Step 3: Gatekeeper Validation [O+P] (gatekeeper-registry.yaml)

Before HITL, verify [O]perations + [P]erformance gate ownership:
- **Primary**: EVA (sibling: "eva") — DevOps orchestration, CI/CD, quality gates
- **Secondary**: Monitor (Foxtrot) (HTTP-only) — runtime traces, latency metrics, anomaly detection
- **Consult**: Engineer (Alpha) (CHASE action) — O(n²) pattern detection, >5% regression scan

Load deploy targets from canonical: `~/Projects/CLAUDE.md` (authoritative).

## Step 4: HITL Gate — Write-Path Disclosure (SAFEGUARD #21)

```
SQUAD: devops "<project>"
Agents: ~3–4 | Estimated tokens: ~30–50K
WRITES CODE: devops preset runs quality gates + make deploy + MCP verification.
  - Deploy target: {binary path from Step 2}
  - Quality gates: fmt, clippy, tests, cargo audit
  - Post-deploy: MCP handshake verification
Proceed? [y/N]
```

## Step 5: SQUAD Invocation

```
/SQUAD devops "<project>"
```

SQUAD agents in the `devops` preset invoke Ops (Bravo) sub-skills via the Skill tool:
- `eva:STATUS` — check project health and sibling connections
- `eva:LINT` — run quality gates (fmt, clippy, tests, cargo audit)
- `eva:REPO` — verify git state (clean working tree, correct branch)
- `eva:DEPLOY` — execute `make deploy` and verify the binary responds to MCP initialize

Full cycle instructions are in `references/presets.md`. SQUAD handles quality gate failures — if any gate fails, SQUAD presents failures and waits for HITL confirmation before proceeding or aborting.

## Step 6: Plugin Marketplace Sync

After SQUAD devops completes, if the deployed project is an MCP server or plugin, sync the plugin marketplace:

```bash
cd ~/Projects/light-architects-plugins && ./scripts/sync-plugins.sh
```

This syncs all 5 MCP repo plugins (Engineer (Alpha), Ops (Bravo), Knowledge (Charlie), Analyst (Delta), Sentinel (Echo)) and the lightarchitects orchestrator plugin from their source of truth to both the marketplace (`~/.claude/plugins/marketplaces/light-architects/`) and the cache (`~/.claude/plugins/cache/light-architects/`).

**Why this matters**: Claude Code discovers skills from the marketplace directory. Without this sync, new skills added to any plugin won't appear in slash-command autocomplete until manually copied.

## Step 7: Reconnect

After any MCP server rebuild and plugin sync:

```
Next steps:
  /mcp              — reconnect Claude Code to the updated binary
  /reload-plugins   — pick up any new skills added during this deploy
```

## Contract Canon Integration (Cookbook §82)

This skill is governed by `agent.skill.deploy` at `standards/canon/contracts/agent.skill/deploy.yaml`. The five §82.3 touchpoints:

### Read
- `standards/canon/contracts/operator.surface/*` — to compute the expected post-deploy alpha_gate state for each touched contract
- `standards/canon/contracts/mcp.capability/*` — for MCP server handshake verification post-deploy
- `standards/canon/contracts/wire.http/*` — for /health probes post-deploy

### Touched-contract citation
Deploy manifest gains a `contracts_verified_post_deploy[]` field listing every contract whose runtime probe was executed.

### forbidden_behaviors enforcement
Pre-deploy gate runs `make contract-gate` per Cookbook §82.4 — non-waivable. If contracts/ tree has any schema or symmetric-edge violation, deploy halts.

### required_spans emission
`/DEPLOY` emits `skill.deploy.invoke` (parent_relationship: child_of_caller) with metadata: `target, fast, contract_gate_clean, codesign_ok, runtime_probe_outcome`.

### status_per_provider impact (BIG)
Post-deploy, /DEPLOY runs a runtime probe (MCP handshake / HTTP /health / smoke binary call) against each touched contract. If the probe contradicts a current `status_per_provider.<P>.result`, an alert is raised — but the mutation itself is NOT performed by /DEPLOY (that's /VERIFY V4). /DEPLOY only flags drift; operator decides whether to re-run /VERIFY.

### Pre-deploy contract-gate (mandatory, BLOCKING)

Before `cargo build --release`:

```bash
cargo run --release -p contract-gate -- \
    --schema standards/canon/la-contracts.schema.json \
    --contracts-dir standards/canon/contracts
```

Exit code != 0 → refuse deploy. No `--skip-contract-gate` flag exists.

### Post-deploy alpha_gate.verdict drift detection

For each `operator.surface.*` contract whose stack-class scope overlaps the deployed component:
1. Read current `alpha_gate.verdict`
2. Run the contract's `conformance_test` minimally (smoke version)
3. If smoke result contradicts current verdict, emit `E_DEPLOY_ALPHA_DRIFT` warning

## Graceful Degradation

If SQUAD is unavailable:

1. Run `make deploy` directly (includes quality gates for the `deploy` target):
   ```bash
   cd <project root> && make deploy
   ```
2. Verify MCP handshake:
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | <binary>
   ```
3. Run plugin sync (Step 5 above)

Report: "Running direct make deploy (SQUAD unavailable). Quality gates run by Makefile."
