#!/usr/bin/env bash
# Analyst (Delta) PostToolUse hook — logs tool results to investigation audit trail.
#
# Accepts both the legacy bare name (quantumTools/qsTools) and the full
# unified plugin prefix (mcp__plugin_quantum_QUANTUM__quantumTools).
# Exit 0 to pass through.

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

# Log to investigation audit trail if case_dir is set
CASE_DIR=$(echo "$INPUT" | jq -r '.tool_input.caseDir // empty' 2>/dev/null)
if [ -n "$CASE_DIR" ] && [ -d "$CASE_DIR" ]; then
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  AUDIT_FILE="$CASE_DIR/.quantum-audit.jsonl"
  printf '{"timestamp":"%s","action":"%s","tool":"quantumTools"}\n' \
    "$TIMESTAMP" "$ACTION" >> "$AUDIT_FILE" 2>/dev/null || true
fi

exit 0
