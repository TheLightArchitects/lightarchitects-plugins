#!/bin/bash
# PreToolUse hook: DISABLED 2026-05-31
# Reason: overly-broad substring match on "rm -rf ~" blocked legitimate
# subpath deletes (e.g., worktree target cleanup). Registration removed
# from hooks.json; this script is a no-op pass-through for backward
# compatibility with any session that still references it.
exit 0
