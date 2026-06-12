#!/usr/bin/env bash
# Light Architects Plugin — Installer
#
# Downloads the larc-proxy client binary and wires the lightarchitects plugin
# into Claude Code. Run once after cloning this repo.
#
# Usage:
#   bash install.sh                  # full install
#   bash install.sh --dry-run        # preview without writing
#
# Requires: curl, Claude Code or Claude Desktop, a LIGHTARCHITECTS_API_KEY
#
# Get an API key at: https://lightarchitects.ai
#
# "Prove all things." — 1 Thessalonians 5:21

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LA_ROOT="${LA_ROOT:-${HOME}/.lightarchitects}"
LA_BIN="${LA_ROOT}/bin"
LARC_PROXY="${LA_BIN}/larc-proxy"
PLUGIN_CACHE="${HOME}/.claude/plugins/cache/light-architects"
RELEASES_URL="https://github.com/TheLightArchitects/larc-proxy/releases/latest/download"
DRY_RUN=false

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
err()  { echo -e "${RED}✗${NC} $*" >&2; }
step() { echo -e "\n${BOLD}── $* ──────────────────────────────────${NC}"; }

for arg in "$@"; do
  case "$arg" in --dry-run) DRY_RUN=true ;; esac
done

run() { if $DRY_RUN; then echo "  [dry-run] $*"; else eval "$@"; fi; }

# ─── detect platform ──────────────────────────────────────────────────────────
detect_platform() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$arch" in
    arm64|aarch64) arch="aarch64" ;;
    x86_64)        arch="x86_64"  ;;
    *) err "Unsupported architecture: $arch"; exit 1 ;;
  esac
  case "$os" in
    darwin) echo "${arch}-apple-darwin" ;;
    linux)  echo "${arch}-unknown-linux-musl" ;;
    *) err "Unsupported OS: $os"; exit 1 ;;
  esac
}

# ─── 1. Directory scaffold ────────────────────────────────────────────────────
step "Scaffolding ${LA_ROOT}"
run "mkdir -p \"${LA_BIN}\""
ok "bin directory ready"

# ─── 2. Download larc-proxy binary ────────────────────────────────────────────────
step "larc-proxy binary"

PLATFORM="$(detect_platform)"
BINARY_URL="${RELEASES_URL}/larc-proxy-${PLATFORM}"

if [ -f "${LARC_PROXY}" ] && ! $DRY_RUN; then
  INSTALLED="$(${LARC_PROXY} --version 2>/dev/null || echo 'unknown')"
  ok "already installed: ${INSTALLED}"
  warn "Re-downloading to ensure latest version..."
fi

ok "Platform: ${PLATFORM}"
ok "Downloading from: ${BINARY_URL}"

run "curl -fsSL \"${BINARY_URL}\" -o \"${LARC_PROXY}\""
run "chmod +x \"${LARC_PROXY}\""

if ! $DRY_RUN && [ -f "${LARC_PROXY}" ]; then
  ok "larc-proxy installed: $(${LARC_PROXY} --version 2>/dev/null || echo 'ok')"
fi

# ─── 3. Plugin cache symlink ──────────────────────────────────────────────────
step "Plugin cache"

PLUGIN_TARGET="${SCRIPT_DIR}/plugins/lightarchitects"
run "mkdir -p \"${HOME}/.claude/plugins/cache\""

if [ -L "${PLUGIN_CACHE}" ]; then
  existing="$(readlink "${PLUGIN_CACHE}")"
  if [ "$existing" = "$PLUGIN_TARGET" ]; then
    ok "symlink correct → ${PLUGIN_TARGET}"
  else
    warn "updating symlink: ${existing} → ${PLUGIN_TARGET}"
    run "rm \"${PLUGIN_CACHE}\""
    run "ln -s \"${PLUGIN_TARGET}\" \"${PLUGIN_CACHE}\""
    ok "symlink updated"
  fi
elif [ -d "${PLUGIN_CACHE}" ]; then
  warn "${PLUGIN_CACHE} is a real directory — skipping (review manually)"
else
  run "ln -s \"${PLUGIN_TARGET}\" \"${PLUGIN_CACHE}\""
  ok "symlink created → ${PLUGIN_TARGET}"
fi

# ─── 4. MCP config snippet ────────────────────────────────────────────────────
step "MCP config"

MCP_CONFIG="${HOME}/.claude/mcp.json"

cat <<SNIPPET

Add this to ${MCP_CONFIG} under "mcpServers":

  "lightarchitects": {
    "command": "${LARC_PROXY}",
    "env": {
      "LIGHTARCHITECTS_API_KEY": "<your-api-key>",
      "LIGHTARCHITECTS_API_URL": "https://api.lightarchitects.ai"
    }
  }

Get an API key at: https://lightarchitects.ai

SNIPPET

if [ -f "${MCP_CONFIG}" ]; then
  ok "Found ${MCP_CONFIG} — merge the snippet above manually"
else
  warn "${MCP_CONFIG} not found — create it with the snippet above"
fi

# ─── 5. Done ──────────────────────────────────────────────────────────────────
step "Done"

if $DRY_RUN; then
  warn "Dry run complete — no files written."
else
  ok "larc-proxy binary: ${LARC_PROXY}"
  ok "Plugin cache:  ${PLUGIN_CACHE}"
  echo ""
  echo "Next steps:"
  echo "  1. Add the MCP snippet above to ~/.claude/mcp.json"
  echo "  2. Set LIGHTARCHITECTS_API_KEY in your environment"
  echo "  3. In Claude Code: /mcp"
  echo "  4. Try: /BUILD or /PLAN"
fi
