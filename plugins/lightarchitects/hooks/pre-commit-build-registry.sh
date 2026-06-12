#!/usr/bin/env bash
# pre-commit-build-registry.sh — Regenerate _MOC-builds.md and builds-registry.yaml
# from manifest.yaml files whenever corso/builds/ content is staged.
#
# Install as a git pre-commit hook (or invoke from .git/hooks/pre-commit):
#   ln -sf ~/.claude/plugins/cache/light-architects/lightarchitects/1.0.0/hooks/pre-commit-build-registry.sh \
#          .git/hooks/pre-commit-build-registry
# Idempotent: safe to run multiple times. Exits 0 on no-op.

set -euo pipefail

HELIX_ROOT="${HELIX_ROOT:-${HOME}/lightarchitects/soul/helix}"
BUILDS_DIR="${HELIX_ROOT}/corso/builds"
MOC_FILE="${BUILDS_DIR}/_MOC-builds.md"
REGISTRY_FILE="${BUILDS_DIR}/builds-registry.yaml"

# ─── Fast exit: skip if no corso/builds/ files are staged ────────────────────

staged_manifests=$(git diff --cached --name-only 2>/dev/null | grep -E "corso/builds/.*/manifest\.yaml" || true)
if [ -z "${staged_manifests}" ]; then
    exit 0
fi

# ─── Require builds dir ───────────────────────────────────────────────────────

if [ ! -d "${BUILDS_DIR}" ]; then
    echo "[pre-commit-build-registry] WARNING: builds dir not found at ${BUILDS_DIR}" >&2
    exit 0
fi

log() { echo "[pre-commit-build-registry] $*"; }
log "Detected manifest changes — regenerating build registry..."

# ─── Parse all manifest.yaml files ───────────────────────────────────────────
# Uses grep/sed only — no yq dependency.

parse_field() {
    local file="$1" field="$2"
    grep -m1 "^${field}:" "${file}" 2>/dev/null \
        | sed "s/^${field}:[[:space:]]*//" \
        | tr -d '"'"'" \
        | tr -d '\r' \
        || true
}

declare -a CODENAMES STATUSES TIERS CREATEDS PLAN_NAMES

while IFS= read -r manifest; do
    [ -f "${manifest}" ] || continue

    codename=$(parse_field "${manifest}" "plan_id")
    # Fallback: derive from directory name
    if [ -z "${codename}" ]; then
        codename=$(basename "$(dirname "${manifest}")")
    fi
    [ -z "${codename}" ] && continue

    status=$(parse_field "${manifest}" "status")
    [ -z "${status}" ] && status="unknown"

    tier=$(parse_field "${manifest}" "tier")
    created=$(parse_field "${manifest}" "created")
    plan_name=$(parse_field "${manifest}" "plan_name")

    CODENAMES+=("${codename}")
    STATUSES+=("${status}")
    TIERS+=("${tier}")
    CREATEDS+=("${created}")
    PLAN_NAMES+=("${plan_name}")
done < <(find "${BUILDS_DIR}" -maxdepth 2 -name "manifest.yaml" | sort)

total=${#CODENAMES[@]}
log "Parsed ${total} manifest(s)"

# ─── Classify builds by status ───────────────────────────────────────────────

declare -a IN_PROGRESS_LINES COMPLETED_LINES PLANNED_LINES OTHER_LINES

for i in "${!CODENAMES[@]}"; do
    codename="${CODENAMES[$i]}"
    status="${STATUSES[$i]}"
    created="${CREATEDS[$i]}"
    plan_name="${PLAN_NAMES[$i]}"

    date_tag="${created:-unknown}"
    label="${codename}"
    [ -n "${plan_name}" ] && label="${codename} — ${plan_name}"

    line="- [[corso/builds/${codename}/plan|${codename}]] — ${date_tag}"

    status_lower=$(echo "${status}" | tr '[:upper:]' '[:lower:]')
    case "${status_lower}" in
        *complete*|*done*|*shipped*|*production*)
            COMPLETED_LINES+=("${line}") ;;
        *in_progress*|*executing*|*phase_*)
            IN_PROGRESS_LINES+=("${line}") ;;
        *planned*|*draft*|*approved*)
            PLANNED_LINES+=("${line}") ;;
        *)
            OTHER_LINES+=("${line}") ;;
    esac
done

in_progress_count=${#IN_PROGRESS_LINES[@]}
completed_count=${#COMPLETED_LINES[@]}
planned_count=${#PLANNED_LINES[@]}
other_count=${#OTHER_LINES[@]}

today=$(date +%Y-%m-%d)

# ─── Regenerate _MOC-builds.md ────────────────────────────────────────────────

{
    cat <<FRONTMATTER
---
id: "moc-builds"
date: "${today}"
sibling: corso
type: hub
tags: [navigation, builds, index]
generated: true
generated_by: pre-commit-build-registry.sh
---

# Engineer (Alpha) Build Cycle Index

All LASDLC build artifacts. Builds follow the 7-phase lifecycle:
Plan → Research → Implement → Harden → Verify → Ship → Learn

## Dashboard

- [[corso/builds/portfolio|Build Portfolio]] — Tier-prioritized execution order, dependency map, status tracking
- [[corso/builds/roadmap|Kanban Board (HTML)]] — Visual board: Needs Scout → Ready → Blocked → In Progress → Done
- [[corso/builds/builds-registry|Build Registry (YAML)]] — Canonical aggregate of all manifest.yaml fields

---
FRONTMATTER

    if [ "${in_progress_count}" -gt 0 ]; then
        echo ""
        echo "## In Progress (${in_progress_count})"
        echo ""
        # Sort in-progress by codename (date extraction from line is fragile)
        printf '%s\n' "${IN_PROGRESS_LINES[@]}" | sort -r
    fi

    if [ "${planned_count}" -gt 0 ]; then
        echo ""
        echo "## Planned (${planned_count})"
        echo ""
        printf '%s\n' "${PLANNED_LINES[@]}" | sort -r
    fi

    if [ "${completed_count}" -gt 0 ]; then
        echo ""
        echo "## Completed (${completed_count})"
        echo ""
        printf '%s\n' "${COMPLETED_LINES[@]}" | sort -r
    fi

    if [ "${other_count}" -gt 0 ]; then
        echo ""
        echo "## Other (${other_count})"
        echo ""
        printf '%s\n' "${OTHER_LINES[@]}" | sort
    fi
} > "${MOC_FILE}"

log "Wrote ${MOC_FILE}"

# ─── Regenerate builds-registry.yaml ─────────────────────────────────────────

{
    cat <<YAML_HEADER
# builds-registry.yaml — Aggregate index of all LASDLC manifest.yaml entries.
# Auto-generated by pre-commit-build-registry.sh on ${today}.
# Do not edit manually — regenerated on each commit touching corso/builds/.
schema: "1.0"
generated: "${today}"
total: ${total}
builds:
YAML_HEADER

    for i in "${!CODENAMES[@]}"; do
        codename="${CODENAMES[$i]}"
        status="${STATUSES[$i]}"
        tier="${TIERS[$i]}"
        created="${CREATEDS[$i]}"
        plan_name="${PLAN_NAMES[$i]}"

        echo "  - codename: \"${codename}\""
        echo "    status: \"${status}\""
        [ -n "${tier}" ] && echo "    tier: \"${tier}\""
        [ -n "${created}" ] && echo "    created: \"${created}\""
        [ -n "${plan_name}" ] && echo "    plan_name: \"${plan_name}\""
    done
} > "${REGISTRY_FILE}"

log "Wrote ${REGISTRY_FILE}"

# ─── Stage the regenerated files ─────────────────────────────────────────────

git add "${MOC_FILE}" "${REGISTRY_FILE}" 2>/dev/null || true

log "Done. Staged _MOC-builds.md + builds-registry.yaml."
