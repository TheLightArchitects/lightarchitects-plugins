#!/bin/bash
# preset-context.sh — Inject active preset context at session start.
# Reads ~/.lightarchitects/config.toml for active_preset and reports it
# so Claude knows which workflow archetype is active.

set -euo pipefail

CONFIG="${HOME}/.lightarchitects/config.toml"

if [ ! -f "$CONFIG" ]; then
    echo "Light Architects gateway: no config found. Run the gateway once to auto-generate."
    exit 0
fi

# Extract active_preset from TOML (simple grep — no toml parser needed)
PRESET=$(grep '^active_preset' "$CONFIG" 2>/dev/null | sed 's/.*= *"\(.*\)"/\1/' | head -1)

if [ -z "$PRESET" ]; then
    PRESET="software_engineering"
fi

cat <<EOF
Light Architects gateway active. Preset: ${PRESET}.
Use \`tools {action: "preset"}\` to view or switch presets.
Use \`tools {action: "discover"}\` for full agent status.
EOF
