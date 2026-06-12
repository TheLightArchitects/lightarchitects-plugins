# Light Architects Plugin Marketplace

Claude Code plugin providing the **Light Architects** platform — a squad of specialized AI agents that coordinate multi-domain software development workflows.

## What it does

The `lightarchitects` plugin wires seven role-specific agents into Claude Code, each owning a distinct domain of the development lifecycle:

| Agent | NATO | Role | LASDLC Gate |
|-------|------|------|-------------|
| Engineer | Alpha | Architecture, build, quality review | [A] [Q] [T] |
| Ops | Bravo | Deployment, CI/CD, performance | [O] [P] |
| Knowledge | Charlie | Memory graph, documentation, enrichment | [K] [D] |
| Analyst | Delta | Investigation, research, risk scoring | [R] |
| Sentinel | Echo | Security audit, threat modeling, red team | [S] |
| Monitor | Foxtrot | Observability, traces, anomaly detection | [O] [P] |
| Arbiter | Golf | Canon validation, standards enforcement | [C] |

## Skills

Invoke these directly in Claude Code with `/SKILL_NAME`:

| Skill | Purpose |
|-------|---------|
| `/BUILD` | Full feature pipeline — plan → implement → review → deploy |
| `/PLAN` | Draft a LASDLC-compliant build plan |
| `/REVIEW` | Multi-lens code review (quality + security + logic) |
| `/SECURE` | Security scan and threat model |
| `/VERIFY` | Run test pyramid and coverage gates |
| `/DEPLOY` | Build, sign, deploy, verify |
| `/RESEARCH` | Multi-source investigation with evidence chains |
| `/SCRUM` | Squad retrospective — all agents in parallel |
| `/OBSERVE` | Runtime debugging and trace analysis |
| `/OPTIMIZE` | Profile → evidence → ranked improvements |
| `/ENRICH` | Persist learnings to the knowledge graph |
| `/SYNC` | Synchronize plan into tracking artifacts |
| `/REFLECT` | Retrospective and session lessons |
| `/ONBOARD` | New-developer orientation on a codebase |

## Requirements

- [Claude Code](https://claude.ai/code) (CLI or desktop app)
- The `lightarchitects` gateway binary (see [lightarchitects-sdk](https://github.com/TheLightArchitects/lightarchitects-sdk))
- macOS or Linux

## Install

```bash
# 1. Clone this repo
git clone https://github.com/TheLightArchitects/lightarchitects-plugins.git
cd lightarchitects-plugins

# 2. Build and install the gateway binary
#    (or set LA_GATEWAY_BIN to an existing binary)
git clone https://github.com/TheLightArchitects/lightarchitects-sdk.git
cd lightarchitects-sdk && make deploy
cd ..

# 3. Run the installer — scaffolds ~/.lightarchitects/ and prints MCP config
bash install.sh

# 4. Add the printed MCP snippet to ~/.claude/mcp.json

# 5. In Claude Code: /mcp  (reconnect the server)
```

## MCP config

Add this to `~/.claude/mcp.json` (the `install.sh` prints the exact snippet for your machine):

```json
{
  "mcpServers": {
    "lightarchitects": {
      "command": "${LA_GATEWAY_BIN:-~/.lightarchitects/bin/lightarchitects}",
      "env": {
        "RUST_LOG": "info",
        "OLLAMA_API_KEY": "${OLLAMA_API_KEY}",
        "PERPLEXITY_API_KEY": "${PERPLEXITY_API_KEY}",
        "HF_TOKEN": "${HF_TOKEN}"
      }
    }
  }
}
```

## Directory layout

```
plugins/lightarchitects/
├── .claude-plugin/plugin.json   # Plugin manifest
├── .mcp.json                    # MCP server config template
├── agents/                      # Domain agent definitions
├── hooks/                       # Claude Code lifecycle hooks
├── skills/                      # Invocable skills (BUILD, PLAN, etc.)
└── references/                  # Skill execution spec + pipelines
```

## Related

- [lightarchitects-sdk](https://github.com/TheLightArchitects/lightarchitects-sdk) — Gateway binary source
- [larc-crates](https://github.com/TheLightArchitects/larc-crates) — Public Rust crates (crypto, API key management)

## License

MPL-2.0 — see [LICENSE](LICENSE).
