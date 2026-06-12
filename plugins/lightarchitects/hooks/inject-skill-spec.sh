#!/bin/bash
# inject-skill-spec.sh
# Injects the Light Architects skill execution specification into session context.
# Called at SessionStart (startup|resume|clear|compact) so every session begins
# with the full skill runtime protocol loaded.
#
# Output format: additionalContext block (read by Claude Code's hook system)
# For .vibe or other environments: stdout is injected as session context.

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SPEC_FILE="${PLUGIN_ROOT}/references/skill-execution-spec.md"
USING_SKILLS_FILE="${PLUGIN_ROOT}/skills/USING-SKILLS/SKILL.md"

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "⚠️  skill-execution-spec.md not found at $SPEC_FILE" >&2
  exit 0
fi

# Output the spec as additionalContext
echo "---additionalContext---"
echo "# Light Architects Skill Execution Protocol"
echo "# Auto-injected at session start by inject-skill-spec.sh"
echo ""
cat "$SPEC_FILE"
echo ""

# Also output the USING-SKILLS entry point if present
if [[ -f "$USING_SKILLS_FILE" ]]; then
  echo ""
  echo "# USING-SKILLS Entry Point"
  cat "$USING_SKILLS_FILE"
fi
