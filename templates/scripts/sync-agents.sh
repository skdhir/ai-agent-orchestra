#!/bin/bash
# sync-agents.sh — Pull latest dev + regenerate CLAUDE.md for all agent clones
#
# Usage:
#   ./scripts/sync-agents.sh
#
# Note: If you have post-merge hooks installed (via setup-agents.sh),
# CLAUDE.md regenerates automatically on git pull. This script is a
# manual backup for when you need to force-sync all clones.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AGENTS_DIR="$PROJECT_ROOT/agents"

CLONE_ROLES=(architect fullstack web infra)

echo "Syncing all agent clones..."
echo ""

for role in "${CLONE_ROLES[@]}"; do
    target="$AGENTS_DIR/$role"

    if [[ ! -d "$target/.git" ]]; then
        echo "[$role] Not found at $target — run setup-agents.sh first"
        continue
    fi

    echo "[$role] Syncing..."

    # Stash any uncommitted changes (safety)
    if ! git -C "$target" diff --quiet 2>/dev/null; then
        echo "  Warning: uncommitted changes detected — stashing"
        git -C "$target" stash
    fi

    # Checkout dev and pull
    git -C "$target" checkout dev 2>/dev/null || true
    git -C "$target" pull 2>/dev/null || echo "  Warning: could not pull"

    echo "  Pulled latest"
done

echo ""
echo "Regenerating CLAUDE.md files..."
bash "$SCRIPT_DIR/generate-claude-md.sh" --all

echo ""
echo "All agents synced and CLAUDE.md files regenerated."
