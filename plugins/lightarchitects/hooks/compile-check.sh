#!/bin/bash
# PostToolUse hook: compiler-in-the-loop feedback for Write|Edit
#
# Fires after code files are written/edited. Runs the project's native
# compiler and captures structured errors as feedback context. The coding
# agent reads the feedback and self-corrects on the next turn.
#
# Supported: Rust (cargo check), TypeScript (tsc), Python (py_compile)
#
# ADVISORY: Always exits 0. Compile errors are feedback, not blockers.
# Output goes to stdout as additionalContext for Claude's next turn.
# Structured JSON bundle written to /tmp/la-compile-feedback.json.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty' 2>/dev/null)

# Only check code files
case "$FILE_PATH" in
  *.rs|*.ts|*.js|*.svelte|*.py) ;;
  *) exit 0 ;;
esac

# Verify file exists
[ -f "$FILE_PATH" ] || exit 0

# --- Project root detection ---
# Walk up from the file to find the project root (Cargo.toml, package.json, pyproject.toml)
find_project_root() {
  local dir="$1"
  local marker="$2"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/$marker" ]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

FILE_DIR=$(dirname "$FILE_PATH")
ERRORS_JSON="[]"
ERROR_COUNT=0
COMPILER=""

# --- Rust ---
if [[ "$FILE_PATH" == *.rs ]]; then
  PROJECT_ROOT=$(find_project_root "$FILE_DIR" "Cargo.toml") || true
  if [ -n "$PROJECT_ROOT" ] && command -v cargo >/dev/null 2>&1; then
    COMPILER="cargo check"
    # cargo check with JSON output for structured parsing
    RAW_OUTPUT=$(cd "$PROJECT_ROOT" && cargo check --message-format=json 2>&1) || true

    # Filter to JSON lines only (cargo mixes status text with JSON), then parse
    ERRORS_JSON=$(echo "$RAW_OUTPUT" | grep '^\s*{' | jq -s '
      [.[] | select(.reason == "compiler-message" and .message.level == "error")
       | {
           file: (.message.spans[0].file_name // "unknown"),
           line: (.message.spans[0].line_start // 0),
           column: (.message.spans[0].column_start // 0),
           message: .message.message,
           severity: "error",
           code: (.message.code.code // null)
         }
      ] | unique_by(.file, .line, .message)
    ' 2>/dev/null) || ERRORS_JSON="[]"

    ERROR_COUNT=$(echo "$ERRORS_JSON" | jq 'length' 2>/dev/null) || ERROR_COUNT=0
  fi

# --- TypeScript / JavaScript / Svelte ---
elif [[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.js || "$FILE_PATH" == *.svelte ]]; then
  PROJECT_ROOT=$(find_project_root "$FILE_DIR" "package.json") || true
  if [ -n "$PROJECT_ROOT" ]; then
    # Check for tsconfig.json — only run tsc if TypeScript is configured
    if [ -f "$PROJECT_ROOT/tsconfig.json" ] && command -v npx >/dev/null 2>&1; then
      COMPILER="tsc --noEmit"
      RAW_OUTPUT=$(cd "$PROJECT_ROOT" && npx tsc --noEmit 2>&1) || true

      # Parse tsc output: file(line,col): error TS1234: message
      ERRORS_JSON=$(echo "$RAW_OUTPUT" | grep '^.*([0-9]*,[0-9]*): error' | head -20 | while IFS= read -r line; do
        file=$(echo "$line" | sed 's/(.*//')
        line_num=$(echo "$line" | sed 's/.*(\([0-9]*\),.*/\1/')
        col=$(echo "$line" | sed 's/.*,\([0-9]*\)).*/\1/')
        msg=$(echo "$line" | sed 's/.*): error [A-Z]*[0-9]*: //')
        code=$(echo "$line" | sed 's/.*): error \([A-Z]*[0-9]*\):.*/\1/')
        jq -n --arg f "$file" --arg l "$line_num" --arg c "$col" --arg m "$msg" --arg cd "$code" \
          '{"file":$f,"line":($l|tonumber),"column":($c|tonumber),"message":$m,"severity":"error","code":$cd}'
      done | jq -s '. // []' 2>/dev/null) || ERRORS_JSON="[]"

      ERROR_COUNT=$(echo "$ERRORS_JSON" | jq 'length' 2>/dev/null) || ERROR_COUNT=0
    fi
  fi

# --- Python ---
elif [[ "$FILE_PATH" == *.py ]]; then
  if command -v python3 >/dev/null 2>&1; then
    COMPILER="python3 -m py_compile"
    RAW_OUTPUT=$(python3 -m py_compile "$FILE_PATH" 2>&1) || true

    if [ -n "$RAW_OUTPUT" ]; then
      # Parse Python compile errors
      py_line=$(echo "$RAW_OUTPUT" | sed -n 's/.*line \([0-9]*\).*/\1/p' | head -1)
      py_msg=$(echo "$RAW_OUTPUT" | tail -1)
      if [ -n "$py_line" ] && [ -n "$py_msg" ]; then
        ERRORS_JSON=$(jq -n --arg f "$FILE_PATH" --arg l "$py_line" --arg m "$py_msg" \
          '[{"file": $f, "line": ($l | tonumber), "column": 0, "message": $m, "severity": "error", "code": null}]')
        ERROR_COUNT=1
      fi
    fi
  fi
fi

# --- No compiler available or not a recognized project ---
if [ -z "$COMPILER" ]; then
  exit 0
fi

# --- Write structured JSON bundle ---
FEEDBACK_FILE="/tmp/la-compile-feedback.json"
jq -n \
  --arg file "$FILE_PATH" \
  --arg compiler "$COMPILER" \
  --argjson count "$ERROR_COUNT" \
  --argjson errors "$ERRORS_JSON" \
  --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    timestamp: $timestamp,
    trigger_file: $file,
    compiler: $compiler,
    error_count: $count,
    compile_errors: $errors
  }' > "$FEEDBACK_FILE" 2>/dev/null

# --- Output to Claude's context ---
if [ "$ERROR_COUNT" -eq 0 ]; then
  # Clean compile — minimal output
  jq -n --arg ctx "Compile check: PASS ($COMPILER)" '{"additionalContext": $ctx}'
  exit 0
fi

# Format errors for human readability
SUMMARY="Compile check: ${ERROR_COUNT} error(s) found by ${COMPILER}\n"
SUMMARY="${SUMMARY}Errors written to ${FEEDBACK_FILE}\n\n"

ERROR_LIST=$(echo "$ERRORS_JSON" | jq -r '.[] | "  \(.file):\(.line): \(.message)"' 2>/dev/null)
SUMMARY="${SUMMARY}${ERROR_LIST}\n\nFix these errors — they will block the build."

FORMATTED=$(printf "%b" "$SUMMARY")
jq -n --arg ctx "$FORMATTED" '{"additionalContext": $ctx}'
exit 0
