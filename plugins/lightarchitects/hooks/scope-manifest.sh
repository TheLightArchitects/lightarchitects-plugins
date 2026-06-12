#!/usr/bin/env bash
# scope-manifest.sh — PreToolUse hook for Write|Edit
# Injects a structured scope manifest (imports, exports, functions, types,
# sibling file exports) as advisory context before code writes.
# Always exits 0 — never blocks. Timeout budget: 5s.

set -uo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // ""' 2>/dev/null || echo "")

# No path, path traversal, or non-code file — pass through silently
[ -z "$FILE_PATH" ] && exit 0
[[ "$FILE_PATH" == *..* ]] && exit 0

# Detect language from extension
case "$FILE_PATH" in
  *.rs)      LANG="rust" ;;
  *.ts)      LANG="typescript" ;;
  *.svelte)  LANG="svelte" ;;
  *.js)      LANG="javascript" ;;
  *.py)      LANG="python" ;;
  *)         exit 0 ;;  # Not a supported code file
esac

# If file doesn't exist yet (new Write), emit a minimal manifest with siblings only
if [ ! -f "$FILE_PATH" ]; then
  DIR=$(dirname "$FILE_PATH")
  BASENAME=$(basename "$FILE_PATH")
  SIBLINGS=""
  if [ -d "$DIR" ]; then
    SIBLINGS=$(ls "$DIR" 2>/dev/null | grep -vF "$BASENAME" | grep -E '\.(rs|ts|js|svelte|py)$' | head -15 | tr '\n' ', ' | sed 's/,$//')
  fi
  if [ -n "$SIBLINGS" ]; then
    MANIFEST="<scope_manifest file=\"$FILE_PATH\" status=\"new_file\">
SIBLING_FILES: $SIBLINGS
</scope_manifest>"
    jq -n --arg ctx "$MANIFEST" '{"additionalContext": $ctx}'
  fi
  exit 0
fi

# --- Extract scope from existing file ---
MAX_LINES=50  # Truncation limit for the manifest

extract_rust() {
  local f="$1"
  local imports exports functions types structs impls mods

  imports=$(grep -n '^use ' "$f" 2>/dev/null | head -20 | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)
  mods=$(grep -n '^pub mod \|^mod ' "$f" 2>/dev/null | head -10 | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)
  functions=$(grep -nE '^[[:space:]]*(pub(\([^)]*\))?\s+)?(async\s+)?fn\s+[a-zA-Z_]' "$f" 2>/dev/null | head -30 | sed 's/\s*{.*//' | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)
  structs=$(grep -nE '^[[:space:]]*(pub(\([^)]*\))?\s+)?struct\s+[A-Z]' "$f" 2>/dev/null | head -15 | sed 's/\s*{.*//' | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)
  types=$(grep -nE '^[[:space:]]*(pub(\([^)]*\))?\s+)?type\s+[A-Z]' "$f" 2>/dev/null | head -10 | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)
  impls=$(grep -nE '^impl(<[^>]+>)?\s+[A-Z]' "$f" 2>/dev/null | head -10 | sed 's/\s*{.*//' | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)

  local out=""
  [ -n "$imports" ] && out="${out}IMPORTS:\n${imports}\n"
  [ -n "$mods" ] && out="${out}MODULES:\n${mods}\n"
  [ -n "$structs" ] && out="${out}STRUCTS:\n${structs}\n"
  [ -n "$types" ] && out="${out}TYPES:\n${types}\n"
  [ -n "$impls" ] && out="${out}IMPL_BLOCKS:\n${impls}\n"
  [ -n "$functions" ] && out="${out}FUNCTIONS:\n${functions}\n"
  echo -e "$out"
}

extract_typescript() {
  local f="$1"
  local imports exports functions types interfaces classes

  imports=$(grep -nE "^import " "$f" 2>/dev/null | head -20 | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)
  exports=$(grep -nE "^export " "$f" 2>/dev/null | grep -v '^export default' | head -20 | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)
  functions=$(grep -nE '(^|\s)(export\s+)?(async\s+)?function\s+[a-zA-Z_]|(^|\s)(export\s+)?const\s+[a-zA-Z_]+\s*=\s*(async\s+)?\(' "$f" 2>/dev/null | head -20 | sed 's/\s*{.*//' | sed 's/\s*=>.*//' | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)
  interfaces=$(grep -nE '(^|\s)(export\s+)?interface\s+[A-Z]' "$f" 2>/dev/null | head -15 | sed 's/\s*{.*//' | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)
  types=$(grep -nE '(^|\s)(export\s+)?type\s+[A-Z]' "$f" 2>/dev/null | head -15 | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)
  classes=$(grep -nE '(^|\s)(export\s+)?class\s+[A-Z]' "$f" 2>/dev/null | head -10 | sed 's/\s*{.*//' | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)

  local out=""
  [ -n "$imports" ] && out="${out}IMPORTS:\n${imports}\n"
  [ -n "$exports" ] && out="${out}EXPORTS:\n${exports}\n"
  [ -n "$interfaces" ] && out="${out}INTERFACES:\n${interfaces}\n"
  [ -n "$types" ] && out="${out}TYPES:\n${types}\n"
  [ -n "$classes" ] && out="${out}CLASSES:\n${classes}\n"
  [ -n "$functions" ] && out="${out}FUNCTIONS:\n${functions}\n"
  echo -e "$out"
}

extract_svelte() {
  local f="$1"
  # Extract from <script> sections only
  local script_content
  script_content=$(sed -n '/<script/,/<\/script>/p' "$f" 2>/dev/null || true)

  local imports exports functions

  imports=$(echo "$script_content" | grep -E "^\s*import " 2>/dev/null | head -20 | sed 's/^[[:space:]]*//' || true)
  exports=$(echo "$script_content" | grep -E "^\s*export " 2>/dev/null | head -15 | sed 's/^[[:space:]]*//' || true)
  functions=$(echo "$script_content" | grep -E '(^|\s)(export\s+)?(async\s+)?function\s+[a-zA-Z_]|(^|\s)(export\s+)?const\s+[a-zA-Z_]+\s*=\s*(async\s+)?\(' 2>/dev/null | head -15 | sed 's/\s*{.*//' | sed 's/\s*=>.*//' | sed 's/^[[:space:]]*//' || true)

  # Also note component props (Svelte 5 $props pattern)
  local props
  props=$(echo "$script_content" | grep -E '\$props|\$\$props|export let ' 2>/dev/null | head -10 | sed 's/^[[:space:]]*//' || true)

  local out=""
  [ -n "$imports" ] && out="${out}IMPORTS:\n${imports}\n"
  [ -n "$exports" ] && out="${out}EXPORTS:\n${exports}\n"
  [ -n "$props" ] && out="${out}PROPS:\n${props}\n"
  [ -n "$functions" ] && out="${out}FUNCTIONS:\n${functions}\n"
  echo -e "$out"
}

extract_python() {
  local f="$1"
  local imports functions classes

  imports=$(grep -nE '^(import |from .+ import )' "$f" 2>/dev/null | head -20 | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)
  functions=$(grep -nE '^(async )?def [a-zA-Z_]' "$f" 2>/dev/null | head -20 | sed 's/\s*:.*//' | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)
  classes=$(grep -nE '^class [A-Z]' "$f" 2>/dev/null | head -10 | sed 's/\s*:.*//' | sed 's/^[0-9]*://' | sed 's/^[[:space:]]*//' || true)

  local out=""
  [ -n "$imports" ] && out="${out}IMPORTS:\n${imports}\n"
  [ -n "$classes" ] && out="${out}CLASSES:\n${classes}\n"
  [ -n "$functions" ] && out="${out}FUNCTIONS:\n${functions}\n"
  echo -e "$out"
}

# Extract sibling file exports (1 level deep, lightweight)
extract_sibling_exports() {
  local dir="$1"
  local basename="$2"
  local lang="$3"
  local result=""

  local pattern
  case "$lang" in
    rust)       pattern='*.rs' ;;
    typescript) pattern='*.ts' ;;
    svelte)     pattern='*.svelte' ;;
    javascript) pattern='*.js' ;;
    python)     pattern='*.py' ;;
  esac

  local count=0
  for sibling in "$dir"/$pattern; do
    [ -f "$sibling" ] || continue
    [ "$(basename "$sibling")" = "$basename" ] && continue
    count=$((count + 1))
    [ $count -gt 8 ] && break  # Cap at 8 siblings

    local sib_name
    sib_name=$(basename "$sibling")
    local sib_exports=""

    case "$lang" in
      rust)
        sib_exports=$(grep -E '^pub (fn|struct|enum|type|trait|mod|const|static) ' "$sibling" 2>/dev/null | head -8 | sed 's/\s*{.*//' | sed 's/\s*where.*//' | tr '\n' '; ' || true)
        ;;
      typescript|javascript)
        sib_exports=$(grep -E '^export ' "$sibling" 2>/dev/null | grep -v '^export default' | head -8 | sed 's/\s*{.*//' | sed 's/\s*=>.*//' | tr '\n' '; ' || true)
        ;;
      svelte)
        sib_exports=$(sed -n '/<script/,/<\/script>/p' "$sibling" 2>/dev/null | grep -E '^\s*export ' | head -5 | sed 's/^[[:space:]]*//' | tr '\n' '; ' || true)
        ;;
      python)
        sib_exports=$(grep -E '^(def |class |async def )' "$sibling" 2>/dev/null | head -8 | sed 's/\s*:.*//' | tr '\n' '; ' || true)
        ;;
    esac

    if [ -n "$sib_exports" ]; then
      result="${result}  ${sib_name}: ${sib_exports}\n"
    else
      result="${result}  ${sib_name}\n"
    fi
  done

  echo -e "$result"
}

# --- Main extraction ---
SCOPE=""
case "$LANG" in
  rust)       SCOPE=$(extract_rust "$FILE_PATH") ;;
  typescript) SCOPE=$(extract_typescript "$FILE_PATH") ;;
  svelte)     SCOPE=$(extract_svelte "$FILE_PATH") ;;
  javascript) SCOPE=$(extract_typescript "$FILE_PATH") ;;  # Same patterns
  python)     SCOPE=$(extract_python "$FILE_PATH") ;;
esac

# Gather sibling info
DIR=$(dirname "$FILE_PATH")
BASENAME=$(basename "$FILE_PATH")
SIBLINGS=$(extract_sibling_exports "$DIR" "$BASENAME" "$LANG")

# Build manifest
if [ -n "$SCOPE" ] || [ -n "$SIBLINGS" ]; then
  MANIFEST="<scope_manifest file=\"$FILE_PATH\" lang=\"$LANG\">"
  [ -n "$SCOPE" ] && MANIFEST="${MANIFEST}
${SCOPE}"
  if [ -n "$SIBLINGS" ]; then
    MANIFEST="${MANIFEST}SIBLINGS:
${SIBLINGS}"
  fi
  MANIFEST="${MANIFEST}</scope_manifest>"

  # Truncate if over budget
  LINE_COUNT=$(echo "$MANIFEST" | wc -l | tr -d ' ')
  if [ "$LINE_COUNT" -gt "$MAX_LINES" ]; then
    MANIFEST=$(echo "$MANIFEST" | head -n $((MAX_LINES - 1)))
    MANIFEST="${MANIFEST}
... (truncated — ${LINE_COUNT} lines total)
</scope_manifest>"
  fi

  jq -n --arg ctx "$MANIFEST" '{"additionalContext": $ctx}'
fi

exit 0
