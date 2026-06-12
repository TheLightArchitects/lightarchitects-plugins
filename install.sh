#!/usr/bin/env bash
# Light Architects Plugin — First-Run Installer
#
# Scaffolds ~/.lightarchitects/ and wires the lightarchitects plugin into
# Claude Code. Run once after cloning this repo.
#
# Usage:
#   bash install.sh                  # full install
#   bash install.sh --dry-run        # preview without writing
#   LA_GATEWAY_BIN=/custom/path bash install.sh  # custom gateway binary path
#
# Prerequisites:
#   - Claude Code installed (claude --version)
#   - The lightarchitects gateway binary already built and placed at
#     ~/.lightarchitects/bin/lightarchitects  (or set LA_GATEWAY_BIN)
#
# "Prove all things." — 1 Thessalonians 5:21

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LA_ROOT="${LA_ROOT:-${HOME}/.lightarchitects}"
LA_HELIX="${LA_HELIX:-${LA_ROOT}/helix}"
LA_GATEWAY_BIN="${LA_GATEWAY_BIN:-${LA_ROOT}/bin/lightarchitects}"
PLUGIN_CACHE="${HOME}/.claude/plugins/cache/light-architects"
DRY_RUN=false

# ─── colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
err()  { echo -e "${RED}✗${NC} $*" >&2; }
step() { echo -e "\n── $* ──────────────────────────────────"; }

for arg in "$@"; do
  case "$arg" in --dry-run) DRY_RUN=true ;; esac
done

run() {
  if $DRY_RUN; then echo "  [dry-run] $*"; else eval "$@"; fi
}

# ─── 1. Directory scaffold ─────────────────────────────────────────────────────
step "Scaffolding ${LA_ROOT}"

for dir in \
  "${LA_ROOT}/bin" \
  "${LA_HELIX}/user/standards/canon" \
  "${LA_HELIX}/user/standards/industry-baselines/security" \
  "${LA_HELIX}/user/standards/industry-baselines/quality" \
  "${LA_HELIX}/user/standards/industry-baselines/operations" \
  "${LA_HELIX}/user/standards/industry-baselines/research" \
  "${LA_HELIX}/user/standards/industry-baselines/documentation" \
  "${LA_HELIX}/squad/platform/lessons" \
  "${LA_HELIX}/claude/journal" \
  "${LA_ROOT}/corso/bin" \
  "${LA_ROOT}/eva/bin" \
  "${LA_ROOT}/soul/bin" \
; do
  if [ ! -d "$dir" ]; then
    run "mkdir -p \"$dir\""
    ok "created $dir"
  else
    ok "exists  $dir"
  fi
done

# ─── 2. Plugin cache symlink ───────────────────────────────────────────────────
step "Plugin cache → ${PLUGIN_CACHE}"

PLUGIN_TARGET="${SCRIPT_DIR}/plugins/lightarchitects"

if [ ! -d "${HOME}/.claude/plugins/cache" ]; then
  run "mkdir -p \"${HOME}/.claude/plugins/cache\""
fi

if [ -L "${PLUGIN_CACHE}" ]; then
  current_target="$(readlink "${PLUGIN_CACHE}")"
  if [ "$current_target" = "$PLUGIN_TARGET" ]; then
    ok "symlink already correct → ${PLUGIN_TARGET}"
  else
    warn "symlink points to ${current_target} — updating"
    run "rm \"${PLUGIN_CACHE}\""
    run "ln -s \"${PLUGIN_TARGET}\" \"${PLUGIN_CACHE}\""
    ok "symlink updated → ${PLUGIN_TARGET}"
  fi
elif [ -d "${PLUGIN_CACHE}" ]; then
  warn "${PLUGIN_CACHE} is a real directory — skipping (manual review needed)"
else
  run "ln -s \"${PLUGIN_TARGET}\" \"${PLUGIN_CACHE}\""
  ok "symlink created → ${PLUGIN_TARGET}"
fi

# ─── 3. MCP config snippet ────────────────────────────────────────────────────
step "MCP server config"

MCP_CONFIG="${HOME}/.claude/mcp.json"
MCP_SNIPPET=$(cat <<JSON
{
  "mcpServers": {
    "lightarchitects": {
      "command": "${LA_GATEWAY_BIN}",
      "env": {
        "RUST_LOG": "info",
        "OLLAMA_API_KEY": "\${OLLAMA_API_KEY}",
        "OLLAMA_TIMEOUT": "15",
        "OLLAMA_LOCAL_URL": "http://localhost:11434",
        "PERPLEXITY_API_KEY": "\${PERPLEXITY_API_KEY}",
        "HF_TOKEN": "\${HF_TOKEN}"
      }
    }
  }
}
JSON
)

if [ ! -f "${LA_GATEWAY_BIN}" ] && ! $DRY_RUN; then
  warn "Gateway binary not found at ${LA_GATEWAY_BIN}"
  warn "Build it first: see https://github.com/TheLightArchitects/lightarchitects-sdk"
  warn "Or set LA_GATEWAY_BIN=/path/to/binary before running install.sh"
else
  ok "Gateway binary: ${LA_GATEWAY_BIN}"
fi

echo ""
echo "Add this to ${MCP_CONFIG} under 'mcpServers':"
echo "──────────────────────────────────────────────"
echo "$MCP_SNIPPET" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(json.dumps(data['mcpServers'], indent=2))
" 2>/dev/null || echo "$MCP_SNIPPET"
echo "──────────────────────────────────────────────"
echo ""

if [ -f "${MCP_CONFIG}" ]; then
  ok "Found existing ${MCP_CONFIG} — merge the snippet above manually"
  ok "(Auto-merge skipped to avoid corrupting your config)"
else
  warn "No ${MCP_CONFIG} found. Copy the snippet above into that file."
fi

# ─── 4. Verify ────────────────────────────────────────────────────────────────
step "Verification"

ok "LA_ROOT          = ${LA_ROOT}"
ok "LA_HELIX         = ${LA_HELIX}"
ok "LA_GATEWAY_BIN   = ${LA_GATEWAY_BIN}"
ok "Plugin cache     = ${PLUGIN_CACHE}"

if $DRY_RUN; then
  echo ""
  warn "Dry run complete — no files were written."
else
  echo ""
  ok "Install complete."
  echo ""
  echo "Next steps:"
  echo "  1. Build the gateway: cd lightarchitects-sdk && make deploy"
  echo "  2. Add the MCP snippet above to ~/.claude/mcp.json"
  echo "  3. In Claude Code: /mcp   (to reconnect the MCP server)"
  echo "  4. Test: invoke /BUILD or ask Claude to use a skill"
fi
