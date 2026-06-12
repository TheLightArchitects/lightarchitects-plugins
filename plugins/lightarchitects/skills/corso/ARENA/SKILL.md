---
name: arena
description: Manage the L-ARC Arena multi-agent research platform — start, stop, restart, status, logs, deploy. Works with Docker Compose on any host.
user_invocable: true
metadata:
  bashPattern: "arena|docker compose|l-arc-containers"
  filePattern: "**/docker-compose.yml"
  priority: 80
---

# /arena — L-ARC Arena Management

Manage the containerized multi-agent research platform. One command for all lifecycle operations.

## Configuration

The Arena deployment path is configurable. Check these locations in order:

1. `ARENA_PATH` environment variable
2. `~/.arena/path` file (single line with the path)
3. Default: `/home/khadas/l-arc-containers` (Khadas deployment)
4. Fallback: `./l-arc-containers` (local development)

For remote (SSH) deployments, also set:
- `ARENA_HOST` — SSH host (e.g., `khadas@10.129.155.20`)
- Or `~/.arena/host` file

## Commands

Parse the user's intent and execute the matching command:

| User Says | Command | What It Does |
|-----------|---------|-------------|
| `/arena start` | `docker compose up -d` | Start all containers (orchestrator + 5 agents) |
| `/arena stop` | `docker compose down` | Stop all containers gracefully |
| `/arena restart` | `docker compose restart` | Restart all containers |
| `/arena restart eva` | `docker compose restart arena-eva` | Restart one agent |
| `/arena status` | `docker compose ps` + `docker stats` | Show container status + memory |
| `/arena logs` | `docker compose logs -f --tail 50` | Tail all container logs |
| `/arena logs eva` | `docker logs -f arena-eva` | Tail one agent's logs |
| `/arena deploy` | Build + restart cycle | Rebuild binary, rebuild image, restart |
| `/arena health` | Health check | API health + agent heartbeat counts + Discord check |
| `/arena clear` | Clear Discord + reset state | Fresh start (clear messages, reset papers-covered, clear tasks) |

## Execution Protocol

### Step 1: Resolve Path

```bash
ARENA_PATH="${ARENA_PATH:-$(cat ~/.arena/path 2>/dev/null || echo '/home/khadas/l-arc-containers')}"
ARENA_HOST="${ARENA_HOST:-$(cat ~/.arena/host 2>/dev/null || echo '')}"
```

If `ARENA_HOST` is set, prefix all commands with `ssh $ARENA_HOST`.

### Step 2: Execute Command

**start:**
```bash
cd $ARENA_PATH && docker compose up -d
```

**stop:**
```bash
cd $ARENA_PATH && docker compose down -t 5
```

**restart [agent]:**
```bash
# All
cd $ARENA_PATH && docker compose restart

# One agent
cd $ARENA_PATH && docker compose restart arena-{agent}
```

**status:**
```bash
cd $ARENA_PATH && docker compose ps --format 'table {{.Name}}\t{{.Status}}'
docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}'
```

Display as a clean table with health indicators.

**logs [agent]:**
```bash
# All (last 50 lines, follow)
cd $ARENA_PATH && docker compose logs -f --tail 50

# One agent
docker logs -f --tail 50 arena-{agent}
```

**deploy:**
```bash
# 1. Build the binary (on host or via SSH)
cd $SOURCE_PATH && cargo build --release -p l-arc-gateway

# 2. Copy to container build dir
cp target/release/l-arc-gateway $ARENA_PATH/bin/

# 3. Rebuild image + restart
cd $ARENA_PATH && docker compose build --quiet && docker compose up -d
```

**health:**
```bash
# API health
curl -sf http://localhost:3800/health

# Heartbeat count (last hour)
tail -100 ~/.ironclaw/shared/metrics/heartbeat-log-$(date +%Y-%m-%d).jsonl | wc -l

# Latest per-sibling
tail -10 ~/.ironclaw/shared/metrics/heartbeat-log-$(date +%Y-%m-%d).jsonl | \
  python3 -c 'import sys,json; [print(f"{json.loads(l)[\"sibling\"]:8} {json.loads(l)[\"confidence\"]}") for l in sys.stdin]'
```

**clear:**
```bash
# Clear Discord (requires DISCORD_BOT_TOKEN)
# Reset papers-covered, tasks, staging, sibling-activity
# Restart all agents
```
Use the same Discord bulk-delete + state reset pattern from the session.

### Step 3: Display Result

Format output as a clean summary. For `status`, show:

```
L-ARC Arena — 6 containers
┌──────────────────┬──────────┬───────────┐
│ Container        │ Status   │ Memory    │
├──────────────────┼──────────┼───────────┤
│ orchestrator     │ healthy  │ 22 MB     │
│ agent-eva        │ running  │ 5 MB      │
│ agent-corso      │ running  │ 5 MB      │
│ agent-quantum    │ running  │ 5 MB      │
│ agent-seraph     │ running  │ 5 MB      │
│ agent-ayin       │ running  │ 5 MB      │
└──────────────────┴──────────┴───────────┘
Total: 47 MB | Uptime: 2h 15m
```

## Consumer Setup

For new users setting up Arena for the first time:

```bash
# 1. Clone or download the Arena container files
git clone https://github.com/TheLightArchitects/l-arc-arena-docker

# 2. Configure
cp .env.example .env
# Edit .env with your Ollama URL, Discord webhooks, etc.

# 3. Start
/arena start

# 4. Check
/arena status
```

## Error Handling

- **Docker not installed**: "Docker is required. Install with: curl -fsSL https://get.docker.com | sh"
- **Containers not found**: "Arena not deployed at {path}. Run /arena deploy or set ARENA_PATH."
- **SSH unreachable**: "Cannot reach {host}. Check ARENA_HOST and SSH config."
- **Agent unhealthy**: Show logs for the failing agent, suggest `/arena restart {agent}`.
