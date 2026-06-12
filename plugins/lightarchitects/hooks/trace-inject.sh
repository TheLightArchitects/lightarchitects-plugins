#!/bin/bash
# PreToolUse hook: inject Monitor (Foxtrot) execution traces into bug fix code generation.
#
# Fires on the gateway tool (mcp__plugin_lightarchitects_lightarchitects__tools).
# Checks if the action is a code generation action during a bug fix context.
# If both conditions met, queries Monitor (Foxtrot) for recent failure traces and injects
# a <runtime_evidence> block as additionalContext for the coding agent.
#
# ADVISORY: Always exits 0. Never blocks. If Monitor (Foxtrot) is unreachable, skips silently.
# Timeout budget: 5s total (3s Monitor (Foxtrot) query + processing).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=lib/ayin-query.sh
source "${SCRIPT_DIR}/lib/ayin-query.sh"

INPUT=$(cat)

# --- Extract tool input fields ---
ACTION=$(echo "$INPUT" | jq -r '.tool_input.action // empty' 2>/dev/null)
PARAMS=$(echo "$INPUT" | jq -r '.tool_input.params // .tool_input | tostring' 2>/dev/null)

# --- Gate 1: Code generation action? ---
# HUNT uses sniff for code gen; also match generate_code and code_review for remediation
case "$ACTION" in
  sniff|generate_code|code_review) ;;
  *) exit 0 ;;
esac

# --- Gate 2: Bug fix context? ---
# Check if params contain bug-fix-related keywords (case insensitive).
# Use grep -q for a clean boolean check; avoid -c which can produce multi-line counts.
if ! echo "$PARAMS" | tr '\n' ' ' | grep -qiE '(fix|bug|error|failing|broken|panic|crash|regress|defect)' 2>/dev/null; then
  exit 0
fi

# --- Gate 3: Monitor (Foxtrot) reachable? ---
if ! ayin_available; then
  exit 0
fi

# --- Query Monitor (Foxtrot) for sessions ---
TODAY=$(date -u +%Y-%m-%d)
YESTERDAY=$(date -u -v-1d +%Y-%m-%d 2>/dev/null || date -u -d "yesterday" +%Y-%m-%d 2>/dev/null || echo "")

SESSIONS_JSON=$(ayin_query "sessions" 2)
if [ -z "$SESSIONS_JSON" ]; then
  exit 0
fi

# Get actor list from sessions matching today or yesterday
ACTORS=$(echo "$SESSIONS_JSON" | jq -r --arg t "$TODAY" --arg y "$YESTERDAY" '
  .sessions[]
  | select(.date == $t or .date == $y)
  | .actor
' 2>/dev/null | sort -u)

if [ -z "$ACTORS" ]; then
  exit 0
fi

# --- Extract target file/module from params for relevance filtering ---
TARGET_FILE=$(echo "$PARAMS" | grep -oE '[a-zA-Z0-9_/.-]+\.(rs|ts|js|py|svelte)' | head -1 || echo "")
TARGET_MODULE=""
if [ -n "$TARGET_FILE" ]; then
  TARGET_MODULE=$(basename "$TARGET_FILE" | sed 's/\.[^.]*$//')
fi

# --- Collect spans from recent sessions ---
ALL_SPANS="[]"
for actor in $ACTORS; do
  for date in $TODAY $YESTERDAY; do
    [ -z "$date" ] && continue
    SPAN_RESULT=$(ayin_query "spans/${actor}/${date}" 3)
    if [ -n "$SPAN_RESULT" ]; then
      BATCH=$(echo "$SPAN_RESULT" | jq '.spans // []' 2>/dev/null)
      if [ -n "$BATCH" ] && [ "$BATCH" != "[]" ]; then
        ALL_SPANS=$(echo "$ALL_SPANS" "$BATCH" | jq -s '.[0] + .[1]' 2>/dev/null)
      fi
    fi
  done
done

# --- Separate failing and healthy traces ---
FAILING=$(echo "$ALL_SPANS" | jq '[
  .[]
  | select(
      .outcome.type == "Error"
      or .outcome.type == "Block"
      or (.outcome.detail // "" | test("(?i)(error|fail|panic|crash|broken)"))
    )
] | sort_by(.timestamp) | reverse | .[0:10]' 2>/dev/null)

HEALTHY=$(echo "$ALL_SPANS" | jq '[
  .[]
  | select(
      .outcome.type == "Continue"
      and (.outcome.detail // "" | test("(?i)(error|fail|panic|crash)") | not)
    )
] | sort_by(.timestamp) | reverse | .[0:5]' 2>/dev/null)

FAIL_COUNT=$(echo "$FAILING" | jq 'length' 2>/dev/null || echo "0")
HEALTHY_COUNT=$(echo "$HEALTHY" | jq 'length' 2>/dev/null || echo "0")

# --- Don't inject if no relevant traces found ---
if [ "$FAIL_COUNT" -eq 0 ]; then
  exit 0
fi

# --- If target file specified, check relevance ---
if [ -n "$TARGET_MODULE" ]; then
  RELOps (Bravo)NT_FAILS=$(echo "$FAILING" | jq --arg mod "$TARGET_MODULE" '[
    .[] | select(
      (.metadata | tostring | test($mod; "i"))
      or (.action | test($mod; "i"))
      or (.outcome.detail // "" | test($mod; "i"))
    )
  ]' 2>/dev/null)
  RELOps (Bravo)NT_COUNT=$(echo "$RELOps (Bravo)NT_FAILS" | jq 'length' 2>/dev/null || echo "0")
  # Use relevant subset if non-empty, otherwise fall back to all failures
  if [ "$RELOps (Bravo)NT_COUNT" -gt 0 ]; then
    FAILING="$RELOps (Bravo)NT_FAILS"
    FAIL_COUNT="$RELOps (Bravo)NT_COUNT"
  fi
fi

# --- Build failing traces section ---
FAILING_LINES=$(echo "$FAILING" | jq -r '
  .[] | "  [\(.timestamp)] actor=\(.actor) action=\(.action) outcome=\(.outcome.type)\(if .outcome.detail then " — " + .outcome.detail else "" end) duration=\(.duration_ms)ms\(if .metadata != null and .metadata != {} then "\n    metadata: \(.metadata | tostring | .[0:120])" else "" end)"
' 2>/dev/null)

# --- Build healthy baseline section ---
HEALTHY_LINES=""
if [ "$HEALTHY_COUNT" -gt 0 ]; then
  HEALTHY_LINES=$(echo "$HEALTHY" | jq -r '
    .[] | "  [\(.timestamp)] actor=\(.actor) action=\(.action) outcome=PASS duration=\(.duration_ms)ms"
  ' 2>/dev/null)
fi

# --- Build diff analysis ---
DIFF_ANALYSIS=""
if [ "$HEALTHY_COUNT" -gt 0 ] && [ "$FAIL_COUNT" -gt 0 ]; then
  # Compare average durations
  FAIL_AVG=$(echo "$FAILING" | jq '[.[].duration_ms] | add / length | floor' 2>/dev/null || echo "0")
  HEALTHY_AVG=$(echo "$HEALTHY" | jq '[.[].duration_ms] | add / length | floor' 2>/dev/null || echo "0")

  FAIL_ACTORS=$(echo "$FAILING" | jq -r '[.[].actor] | unique | join(", ")' 2>/dev/null)
  FAIL_ACTIONS=$(echo "$FAILING" | jq -r '[.[].action] | unique | join(", ")' 2>/dev/null)

  DIFF_ANALYSIS="DIFF: ${FAIL_COUNT} failure(s) detected across actors=[${FAIL_ACTORS}] actions=[${FAIL_ACTIONS}]"
  if [ "$HEALTHY_AVG" -gt 0 ] && [ "$FAIL_AVG" -gt 0 ]; then
    DIFF_ANALYSIS="${DIFF_ANALYSIS}, avg_fail_duration=${FAIL_AVG}ms vs avg_healthy=${HEALTHY_AVG}ms"
  fi
fi

# --- Assemble the evidence block (max ~30 lines) ---
QUERY_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

EVIDENCE="<runtime_evidence source=\"ayin\" query_time=\"${QUERY_TIME}\">"
EVIDENCE="${EVIDENCE}
FAILING TRACES (last 24h, ${FAIL_COUNT} found):
${FAILING_LINES}"

if [ -n "$HEALTHY_LINES" ]; then
  EVIDENCE="${EVIDENCE}

HEALTHY BASELINE (prior successful runs):
${HEALTHY_LINES}"
fi

if [ -n "$DIFF_ANALYSIS" ]; then
  EVIDENCE="${EVIDENCE}

${DIFF_ANALYSIS}"
fi

EVIDENCE="${EVIDENCE}
</runtime_evidence>"

# --- Truncate to ~30 lines ---
EVIDENCE=$(echo "$EVIDENCE" | head -32)

# --- Output as additionalContext ---
jq -n --arg ctx "$EVIDENCE" '{"additionalContext": $ctx}'
exit 0
