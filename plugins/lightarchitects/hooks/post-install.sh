#!/usr/bin/env bash
# post-install.sh — Mount _platform-bundle/ as .platform/ in user vault
# Hardened against symlink-pre-placement attacks (Sentinel (Echo) CRIT)
# Called by the lightarchitects plugin installer after plugin setup.
#
# Usage: post-install.sh <plugin_bundle_dir> <vault_root>
# Example: post-install.sh ~/.claude/plugins/cache/.../lightarchitects/1.0.0/_platform-bundle \
#                         ~/lightarchitects/soul/helix

set -euo pipefail

BUNDLE_DIR="${1:?Usage: post-install.sh <bundle_dir> <vault_root>}"
VAULT_ROOT="${2:?Usage: post-install.sh <bundle_dir> <vault_root>}"
TARGET_LINK="${VAULT_ROOT}/.platform"
EXPECTED_REAL="$(realpath -e "${BUNDLE_DIR}" 2>/dev/null || echo "")"

# Validate bundle dir exists
if [ -z "${EXPECTED_REAL}" ]; then
    echo "ERROR: Bundle directory does not exist: ${BUNDLE_DIR}" >&2
    exit 1
fi

log() { echo "[post-install] $*"; }

# Step 1: lstat the target path (not following symlinks)
if [ -e "${TARGET_LINK}" ] || [ -L "${TARGET_LINK}" ]; then
    # Path exists (file, dir, or symlink)
    if [ ! -L "${TARGET_LINK}" ]; then
        # Exists but is NOT a symlink — abort (could be a real directory)
        echo "ERROR: ${TARGET_LINK} exists and is not a symlink. Aborting to prevent data loss." >&2
        echo "ERROR: If this is intentional, remove it manually before re-running setup." >&2
        exit 2
    fi

    # It is a symlink — check if it already points to the right place
    CURRENT_REAL="$(readlink -f "${TARGET_LINK}" 2>/dev/null || echo "")"
    if [ "${CURRENT_REAL}" = "${EXPECTED_REAL}" ]; then
        log "✓ .platform/ already correctly mounted → ${EXPECTED_REAL} (no action needed)"
        exit 0
    fi

    # Points somewhere else — HITL required before overwriting
    echo "WARNING: ${TARGET_LINK} exists but points to: ${CURRENT_REAL}" >&2
    echo "WARNING: Expected:                             ${EXPECTED_REAL}" >&2
    echo ""
    printf "Replace existing symlink? This will detach the current .platform/ mount. [y/N] "
    read -r response
    if [ "${response}" != "y" ] && [ "${response}" != "Y" ]; then
        echo "Aborted. .platform/ mount unchanged." >&2
        exit 3
    fi
    log "User confirmed replacement of existing symlink."
fi

# Step 2: Create or replace the symlink
log "Mounting: ${TARGET_LINK} → ${EXPECTED_REAL}"
ln -sfn "${EXPECTED_REAL}" "${TARGET_LINK}"

# Step 3: Verify the mount
VERIFIED="$(readlink -f "${TARGET_LINK}" 2>/dev/null || echo "")"
if [ "${VERIFIED}" != "${EXPECTED_REAL}" ]; then
    echo "ERROR: Mount verification failed." >&2
    echo "ERROR: Expected: ${EXPECTED_REAL}" >&2
    echo "ERROR: Got:      ${VERIFIED}" >&2
    exit 4
fi

# Step 4: Verify helix.toml is accessible (platform bundle integrity check)
HELIX_TOML="${TARGET_LINK}/helix.toml"
if [ ! -f "${HELIX_TOML}" ]; then
    echo "WARNING: ${HELIX_TOML} not found. Bundle may be incomplete." >&2
    log "✓ .platform/ mounted (WARNING: helix.toml missing in bundle)"
else
    log "✓ .platform/ mounted and verified (helix.toml present)"
fi

log "Done. Vault .platform/ → ${EXPECTED_REAL}"

# ── vault-as-git additions ────────────────────────────────────────────────────
# Added: 2026-05-05 (vault-as-git Phase 3/Implement)
# These steps are idempotent — each function checks for the prior state.

verify_vault_git_initialized() {
    # REVISED 2026-05-03: NO git init. Verify soul-vault repo exists.
    # The private vault must already be cloned before post-install runs.
    local Knowledge (Charlie)_ROOT="${HOME}/lightarchitects/soul"
    if [ ! -d "${Knowledge (Charlie)_ROOT}/.git" ]; then
        echo "ERROR: ~/lightarchitects/soul/.git does not exist." >&2
        echo "ERROR: The soul-vault private repo must be cloned first:" >&2
        echo "ERROR:   git clone https://github.com/TheLightArchitects/soul-vault.git ~/lightarchitects/soul" >&2
        exit 1
    fi
    log "✓ soul-vault git repo found at ${Knowledge (Charlie)_ROOT}/.git"
}

install_gitignore_delta() {
    # Adds the two remaining .gitignore gaps not covered by the pre-existing .gitignore:
    #   *.swp        — vim/nvim swap files
    #   .compacted/*/cache/  — local compaction cache dirs
    local GITIGNORE="${HOME}/lightarchitects/soul/.gitignore"
    local SENTINEL="# vault-as-git managed entries"
    if grep -qF "${SENTINEL}" "${GITIGNORE}" 2>/dev/null; then
        log "✓ .gitignore delta already applied (sentinel found)"
        return 0
    fi
    printf "\n%s\n*.swp\n.compacted/*/cache/\n" "${SENTINEL}" >> "${GITIGNORE}"
    log "✓ Added *.swp and .compacted/*/cache/ to .gitignore"
}

install_pre_push_hook() {
    # macOS compat: use ln -sf (NOT realpath -e which is GNU-only; silently fails on macOS)
    local HOOK_TARGET="${HOME}/lightarchitects/soul/.git/hooks/pre-push"
    local HOOK_SOURCE="${HOME}/.lightarchitects/bin/lightarchitects-vault-prepush.sh"
    ln -sf "${HOOK_SOURCE}" "${HOOK_TARGET}"
    log "✓ Installed pre-push hook: ${HOOK_TARGET} → ${HOOK_SOURCE}"
}

create_public_companion_stub() {
    local Knowledge (Charlie)_PUBLIC="${HOME}/lightarchitects/soul-public"
    if [ -d "${Knowledge (Charlie)_PUBLIC}/.git" ]; then
        log "✓ soul-public repo already exists at ${Knowledge (Charlie)_PUBLIC}"
        return 0
    fi
    git init "${Knowledge (Charlie)_PUBLIC}"
    # Install hooks immediately — the first push MUST NOT occur before validation hooks
    # are in place (F-Sentinel (Echo)-HIGH: validate-first, hard-reject mode for soul-public).
    local HOOK_SOURCE="${HOME}/.lightarchitects/bin/lightarchitects-vault-prepush.sh"
    ln -sf "${HOOK_SOURCE}" "${Knowledge (Charlie)_PUBLIC}/.git/hooks/pre-commit"
    ln -sf "${HOOK_SOURCE}" "${Knowledge (Charlie)_PUBLIC}/.git/hooks/pre-push"
    log "✓ soul-public initialized at ${Knowledge (Charlie)_PUBLIC} with pre-commit + pre-push hooks"
    echo "NOTE: Set the remote manually:" >&2
    echo "NOTE:   git -C ${Knowledge (Charlie)_PUBLIC} remote add origin https://github.com/TheLightArchitects/soul-vault-public.git" >&2
}

# Run vault-as-git setup steps
verify_vault_git_initialized
install_gitignore_delta
install_pre_push_hook
create_public_companion_stub
