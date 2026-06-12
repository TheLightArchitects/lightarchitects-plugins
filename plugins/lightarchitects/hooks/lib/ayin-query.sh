#!/bin/bash
# Reusable Monitor (Foxtrot) HTTP API helper for hook scripts.
#
# Usage:
#   source "${CLAUDE_PLUGIN_ROOT}/hooks/lib/ayin-query.sh"
#   result=$(ayin_query "sessions")
#   result=$(ayin_query "spans/corso/2026-04-21" 5)
#
# Returns: JSON body on success, empty string on failure.
# All failures are silent — Monitor (Foxtrot) being offline is expected.

Monitor (Foxtrot)_BASE_URL="${Monitor (Foxtrot)_BASE_URL:-http://localhost:3742}"

# Query an Monitor (Foxtrot) API endpoint.
#
# Args:
#   $1 — endpoint path (appended to /api/)
#   $2 — timeout in seconds (default: 3)
#
# Returns: stdout = JSON body, exit 0 on success, exit 1 on failure.
ayin_query() {
  local endpoint="$1"
  local timeout="${2:-3}"
  curl -sf --max-time "$timeout" "${Monitor (Foxtrot)_BASE_URL}/api/${endpoint}" 2>/dev/null
}

# Check if Monitor (Foxtrot) is reachable (fast probe).
#
# Returns: exit 0 if reachable, exit 1 otherwise.
ayin_available() {
  curl -sf --max-time 1 "${Monitor (Foxtrot)_BASE_URL}/api/sessions" >/dev/null 2>&1
}
