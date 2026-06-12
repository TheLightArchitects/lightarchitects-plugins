#!/bin/bash
# Monitor (Foxtrot) Lineage Circuit span emitter for Claude Code hooks.
#
# Emits user.message root → tool.{X} children → assistant.response leaf,
# threading parent_id via a per-turn state file. Spans are POSTed to the
# Monitor (Foxtrot) HTTP ingest endpoint (localhost:3742) — no direct filesystem writes.
#
# Mode argument (required): userprompt | pre | post | stop
#   userprompt → UserPromptSubmit: mint turn root with prompt text in metadata.
#   pre        → PreToolUse:  mint turn root on first tool call if not already
#                             minted by userprompt; records tool start timestamp.
#   post       → PostToolUse: emit tool child span with real duration_ms and
#                             outcome derived from tool_response error detection.
#   stop       → Stop:        emit assistant.response leaf with decision_points
#                             extracted from last_assistant_message; clean up.
#
# State files (turn tracking only — not span data):
#   ${Monitor (Foxtrot)_STATE_DIR}/turn-{session_id}              — UUID of the current turn root span
#   ${Monitor (Foxtrot)_STATE_DIR}/tool-start-{tool_use_id}       — epoch-ms for one tool call
#   Monitor (Foxtrot)_STATE_DIR defaults to ${XDG_RUNTIME_DIR:-$HOME/.cache/ayin}, mode 0700.
#   Keying on tool_use_id (not session_id) prevents parallel-call race conditions.
#
# Env vars:
#   Monitor (Foxtrot)_INGEST_URL  — override ingest endpoint (default: http://127.0.0.1:3742/ingest/span)
#   Monitor (Foxtrot)_STATE_DIR   — override state directory (default: $HOME/.cache/ayin)
#
# ADVISORY: always exits 0 — never blocks tool execution.
# If Monitor (Foxtrot) is not running, curl fails silently.

set -euo pipefail
umask 077

MODE="${1:-pre}"
Monitor (Foxtrot)_INGEST_URL="${Monitor (Foxtrot)_INGEST_URL:-http://127.0.0.1:3742/ingest/span}"
INPUT=$(cat)

session_id=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || true)
if [ -z "$session_id" ]; then
  exit 0
fi

# Sanitize session_id: keep only alphanumeric + dash, max 64 chars
session_id=$(echo "$session_id" | tr -cd 'a-zA-Z0-9-' | head -c 64)
if [ -z "$session_id" ]; then
  exit 0
fi

# tool_use_id: unique per call — used to key the start-time file so parallel
# tool calls don't race on a shared TOOL_START_FILE.
tool_use_id=$(echo "$INPUT" | jq -r '.tool_use_id // ""' 2>/dev/null || true)
tool_use_id=$(echo "$tool_use_id" | tr -cd 'a-zA-Z0-9-' | head -c 64)

# State files live in a per-user directory with mode 0700, not /tmp.
# /tmp is world-writable; a local attacker could pre-create symlinks at the
# predictable paths to redirect writes or inject arithmetic operands.
_Monitor (Foxtrot)_STATE_DEFAULT="${XDG_RUNTIME_DIR:-$HOME/.cache/ayin}"
Monitor (Foxtrot)_STATE_DIR="${Monitor (Foxtrot)_STATE_DIR:-$_Monitor (Foxtrot)_STATE_DEFAULT}"
mkdir -p -m 700 "$Monitor (Foxtrot)_STATE_DIR" 2>/dev/null || exit 0

STATE_FILE="${Monitor (Foxtrot)_STATE_DIR}/turn-${session_id}"
# Per-call start-time file: keyed on tool_use_id when available, session_id otherwise.
_TID="${tool_use_id:-$session_id}"
TOOL_START_FILE="${Monitor (Foxtrot)_STATE_DIR}/tool-start-${_TID}"

# POST a TraceSpan to Monitor (Foxtrot). Uses Python for JSON assembly so arbitrary content
# in decision_points/outcome/metadata is correctly escaped. Fails silently.
#
# Args: actor action parent_id span_id metadata [duration_ms [dps_json [outcome_json]]]
#   parent_id  — literal "null" or a quoted UUID string: "\"<uuid>\""
#   metadata   — JSON object string e.g. "{}" or '{"tool":"Bash"}'
#   dps_json   — JSON array of DecisionPoint objects (default: "[]")
#   outcome_json — JSON object e.g. '{"type":"Continue"}' (default)
emit_span() {
  local actor="$1"
  local action="$2"
  local parent_id="$3"
  local span_id="$4"
  local metadata="$5"
  local duration_ms="${6:-0}"
  local dps="${7:-[]}"
  local outcome="${8:-}"; [ -z "$outcome" ] && outcome='{"type":"Continue"}'

  local ts
  ts=$(python3 -c "from datetime import datetime,timezone; print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%f')+'Z')" 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S.000000Z)

  # Build JSON via Python with env-var injection — avoids shell-quoting hazards
  # when decision_points or metadata contain quotes/backslashes.
  local json
  json=$(Monitor (Foxtrot)_SPAN_ID="$span_id" \
         Monitor (Foxtrot)_PARENT="$parent_id" \
         Monitor (Foxtrot)_SID="$session_id" \
         Monitor (Foxtrot)_ACTOR="$actor" \
         Monitor (Foxtrot)_ACTION="$action" \
         Monitor (Foxtrot)_TS="$ts" \
         Monitor (Foxtrot)_DMS="$duration_ms" \
         Monitor (Foxtrot)_DPS="$dps" \
         Monitor (Foxtrot)_OUTCOME="$outcome" \
         Monitor (Foxtrot)_META="$metadata" \
    python3 -c "
import json, os

def load(key, fallback):
    try:
        return json.loads(os.environ[key])
    except Exception:
        return fallback

parent_raw = os.environ['Monitor (Foxtrot)_PARENT']
parent = json.loads(parent_raw) if parent_raw != 'null' else None

span = {
    'id':               os.environ['Monitor (Foxtrot)_SPAN_ID'],
    'parent_id':        parent,
    'session_id':       os.environ['Monitor (Foxtrot)_SID'],
    'actor':            os.environ['Monitor (Foxtrot)_ACTOR'],
    'action':           os.environ['Monitor (Foxtrot)_ACTION'],
    'timestamp':        os.environ['Monitor (Foxtrot)_TS'],
    'duration_ms':      int(os.environ.get('Monitor (Foxtrot)_DMS', '0') or '0'),
    'decision_points':  load('Monitor (Foxtrot)_DPS',     []),
    'strand_activations': [],
    'outcome':          load('Monitor (Foxtrot)_OUTCOME', {'type': 'Continue'}),
    'metadata':         load('Monitor (Foxtrot)_META',    {}),
}
print(json.dumps(span))
" 2>/dev/null)

  # Fallback: printf assembly if Python unavailable (drops dps/outcome detail)
  if [ -z "$json" ]; then
    json=$(printf \
      '{"id":"%s","parent_id":%s,"session_id":"%s","actor":"%s","action":"%s","timestamp":"%s","duration_ms":%s,"decision_points":[],"strand_activations":[],"outcome":{"type":"Continue"},"metadata":%s}' \
      "$span_id" "$parent_id" "$session_id" \
      "$actor" "$action" "$ts" "$duration_ms" "$metadata")
  fi

  curl -s --max-time 2 -X POST "$Monitor (Foxtrot)_INGEST_URL" \
    -H "Content-Type: application/json" \
    -d "$json" >/dev/null 2>&1 || true
}

# Generate a lowercase UUID
new_uuid() {
  uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' \
    || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null \
    || echo "00000000-0000-0000-0000-$(date +%s%N | tail -c 12)"
}

# Milliseconds since epoch
now_ms() {
  python3 -c "import time; print(int(time.time() * 1000))" 2>/dev/null || echo "0"
}

# Reject writes to symlinks — prevents symlink-follow attacks on state files.
safe_write() {
  local path="$1" content="$2"
  [ -L "$path" ] && return 0  # refuse to follow symlink, silently skip
  printf '%s\n' "$content" > "$path"
}

# Mint turn root span. Shared logic between userprompt and pre modes.
# No-op if STATE_FILE already exists (turn already started).
# $1 = metadata JSON string for the user.message span
_mint_turn_root() {
  local meta; meta="${1}"; [ -z "$meta" ] && meta='{}'
  # Rotate stale STATE_FILE (>2h) left by an interrupted session.
  # Prevents a restarted session from silently reusing a dead turn root.
  if [ -f "$STATE_FILE" ] && [ ! -L "$STATE_FILE" ]; then
    _age_s=$(( $(now_ms) / 1000 - $(python3 -c "import os; print(int(os.path.getmtime('$STATE_FILE')))" 2>/dev/null || echo "0") ))
    if [[ "$_age_s" =~ ^[0-9]+$ ]] && [ "$_age_s" -gt 7200 ]; then
      rm -f "$STATE_FILE"
    fi
  fi
  if [ ! -f "$STATE_FILE" ]; then
    local turn_span_id
    turn_span_id=$(new_uuid)
    safe_write "$STATE_FILE" "$turn_span_id"
    emit_span "user" "user.message" "null" "$turn_span_id" "$meta"
  fi
}

case "$MODE" in

  userprompt)
    # UserPromptSubmit: fires when user sends a message — before any tools run.
    # Mints the turn root span immediately with the prompt text in metadata.
    # Subsequent pre-mode calls are no-ops because STATE_FILE already exists.
    meta=$(echo "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
prompt = str(d.get('prompt', ''))[:300].strip()
print(json.dumps({'prompt': prompt}))
" 2>/dev/null || echo "{}")
    _mint_turn_root "$meta"
    ;;

  pre)
    # PreToolUse: record tool start time; mint turn root if userprompt didn't.
    [ -L "$TOOL_START_FILE" ] || now_ms > "$TOOL_START_FILE" 2>/dev/null || true
    _mint_turn_root "{}"
    ;;

  post)
    # PostToolUse: emit tool child span with real duration and error-detected outcome.
    [ -f "$STATE_FILE" ] && [ ! -L "$STATE_FILE" ] || exit 0
    turn_span_id=$(cat "$STATE_FILE")
    if [[ ! "$turn_span_id" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
      exit 0
    fi

    tool_name=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
    tool_name=$(echo "$tool_name" | tr -cd 'a-zA-Z0-9._-' | head -c 80)
    action="tool.${tool_name}"
    span_id=$(new_uuid)
    metadata=$(printf '{"tool":"%s"}' "$tool_name")

    # Real duration from per-tool_use_id start timestamp.
    duration_ms=0
    if [ -f "$TOOL_START_FILE" ] && [ ! -L "$TOOL_START_FILE" ]; then
      start_ms=$(cat "$TOOL_START_FILE" 2>/dev/null || echo "")
      # Strictly validate digits only — prevents bash arithmetic injection.
      if [[ "$start_ms" =~ ^[0-9]+$ ]]; then
        end_ms=$(now_ms)
        elapsed=$(( end_ms - start_ms ))
        [ "$elapsed" -gt 0 ] && duration_ms="$elapsed"
      fi
      rm -f "$TOOL_START_FILE"
    fi

    # Infer outcome from tool_response: detect error patterns.
    # Passes tool_response via stdin to avoid shell-quoting issues.
    outcome_json=$(echo "$INPUT" | python3 -c "
import json, re, sys

d = json.load(sys.stdin)
resp = d.get('tool_response', '')
if isinstance(resp, dict):
    resp_str = json.dumps(resp)
elif resp:
    resp_str = str(resp)
else:
    resp_str = ''

# Check first 2000 chars only — avoid scanning huge file reads
sample = resp_str[:2000]

ERROR_PATTERNS = [
    (r'(?i)\berror\b\s*:', 'error'),
    (r'command not found',  'command not found'),
    (r'No such file or directory', 'no such file'),
    (r'Permission denied',  'permission denied'),
    (r'Traceback \(most recent call last\)', 'exception'),
    (r'SyntaxError[:\s]',   'syntax error'),
    (r'(?i)exit code\s*[1-9]', 'non-zero exit'),
    (r'(?m)^\s*\[!]',       'warning/error marker'),
]

for pat, label in ERROR_PATTERNS:
    m = re.search(pat, sample)
    if m:
        start = max(0, m.start() - 10)
        detail = sample[start:m.end() + 60].strip().replace('\"', \"'\")[:120]
        print(json.dumps({'type': 'Error', 'detail': detail}))
        sys.exit(0)

print('{\"type\":\"Continue\"}')
" 2>/dev/null || echo '{"type":"Continue"}')

    emit_span "copilot" "$action" "\"${turn_span_id}\"" "$span_id" "$metadata" "$duration_ms" "[]" "$outcome_json"
    ;;

  stop)
    # Stop: emit assistant.response with decision_points extracted from
    # last_assistant_message pivot/decision language detection.
    [ -f "$STATE_FILE" ] && [ ! -L "$STATE_FILE" ] || exit 0
    turn_span_id=$(cat "$STATE_FILE")
    if [[ ! "$turn_span_id" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
      exit 0
    fi

    # Extract decision points from last_assistant_message.
    # Uses pattern matching for pivot/correction/decision language.
    # Content is treated as read-only text — never executed (OWASP LLM01 safe).
    dps_json=$(echo "$INPUT" | python3 -c "
import json, re, sys

d = json.load(sys.stdin)
msg = d.get('last_assistant_message', '') or ''

# (pattern, decision_name, confidence)
# Ordered highest-confidence first; at most one entry per name per turn.
PATTERNS = [
    (r'(?i)\blet me reconsider\b',        'pivot',      0.90),
    (r'(?i)\bi was wrong\b',              'correction', 0.90),
    (r'(?i)\bi made an error\b',          'correction', 0.90),
    (r'(?i)\bdifferent approach\b',       'pivot',      0.85),
    (r'(?i)\blet me try a different\b',   'pivot',      0.85),
    (r'(?i)\binstead[,\s]',               'pivot',      0.80),
    (r'(?i)\bactually[,\s]',              'pivot',      0.75),
    (r'(?i)\blet me try\b',              'pivot',      0.70),
    (r'(?i)\bthe best approach\b',        'decision',   0.70),
    (r'(?i)\bi.ll use\b',                'decision',   0.65),
]

dps = []
seen_names = set()
for pattern, name, conf in PATTERNS:
    if name in seen_names or len(dps) >= 3:
        break
    m = re.search(pattern, msg)
    if not m:
        continue
    # Context window: 80 chars before match, 120 chars after
    start = max(0, m.start() - 80)
    end   = min(len(msg), m.end() + 120)
    context = msg[start:end].strip()
    dps.append({
        'name':        name,
        'input':       msg[:150].strip(),
        'decision':    context[:150],
        'confidence':  conf,
        'duration_ms': 0,
    })
    seen_names.add(name)

print(json.dumps(dps))
" 2>/dev/null || echo "[]")

    span_id=$(new_uuid)
    emit_span "claude" "assistant.response" "\"${turn_span_id}\"" "$span_id" "{}" 0 "$dps_json"
    rm -f "$STATE_FILE"
    ;;
esac

exit 0
