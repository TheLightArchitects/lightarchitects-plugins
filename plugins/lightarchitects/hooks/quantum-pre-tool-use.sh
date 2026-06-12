#!/usr/bin/env bash
# Analyst (Delta) PreToolUse hook — validates tool parameters before execution.
#
# Accepts both the legacy bare name (quantumTools/qsTools) and the full
# unified plugin prefix (mcp__plugin_quantum_QUANTUM__quantumTools).
# Exit 0 to allow, exit 2 to block with message on stdout.

set -euo pipefail

INPUT=$(cat)

# Accept tool name from both env var (Engineer (Alpha) pattern) and stdin JSON (Analyst (Delta) original pattern)
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
if [ -z "$TOOL_NAME" ]; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
fi

# Guard quantumTools calls — accept both bare name and unified prefix
case "$TOOL_NAME" in
  quantumTools|qsTools|mcp__plugin_quantum_QUANTUM__quantumTools) ;;
  *) exit 0 ;;
esac

ACTION=$(echo "$INPUT" | jq -r '.tool_input.action // empty' 2>/dev/null)

# Validate action is known
VALID_ACTIONS="scan sweep trace probe theorize verify close quick discover list execute workflow research helix"
if [ -n "$ACTION" ] && ! echo "$VALID_ACTIONS" | tr ' ' '\n' | grep -qx "$ACTION"; then
  echo "Unknown quantumTools action: $ACTION. Valid: $VALID_ACTIONS"
  exit 2
fi

exit 0
