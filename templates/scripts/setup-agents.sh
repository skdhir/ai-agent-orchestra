#!/bin/bash
# setup-agents.sh — One-time setup: clone the repo for each agent role
#
# Usage:
#   ./scripts/setup-agents.sh
#
# Creates agents/{architect,fullstack,web,infra}/ with role-specific CLAUDE.md.
# Each clone gets a post-merge hook that auto-regenerates CLAUDE.md on git pull.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AGENTS_DIR="$PROJECT_ROOT/agents"

# Get git remote URL from current repo
REMOTE_URL=$(git -C "$PROJECT_ROOT" remote get-url origin 2>/dev/null)
if [[ -z "$REMOTE_URL" ]]; then
    echo "Error: Could not determine git remote URL. Run from within your repo."
    exit 1
fi

echo "AI Agent Orchestra — Setup"
echo "=========================="
echo "Remote: $REMOTE_URL"
echo "Agents dir: $AGENTS_DIR"
echo ""

# Define your roles here — customize to match your docs/roles/ files
CLONE_ROLES=(architect fullstack web infra)

# Create agents directory
mkdir -p "$AGENTS_DIR"

for role in "${CLONE_ROLES[@]}"; do
    target="$AGENTS_DIR/$role"

    if [[ -d "$target/.git" ]]; then
        echo "[$role] Already cloned at $target — pulling latest..."
        git -C "$target" checkout dev 2>/dev/null || git -C "$target" checkout main
        git -C "$target" pull 2>/dev/null || echo "  Warning: could not pull"
    else
        echo "[$role] Cloning to $target..."
        git clone "$REMOTE_URL" "$target"
        git -C "$target" checkout dev 2>/dev/null || true
    fi

    # Install post-merge hook — auto-regenerates CLAUDE.md after every git pull
    hook_dir="$target/.git/hooks"
    mkdir -p "$hook_dir"
    cat > "$hook_dir/post-merge" <<HOOKEOF
#!/bin/bash
# Auto-regenerate CLAUDE.md from latest role files after git pull
ROLE="$role"
if [[ -f "docs/roles/base.md" && -f "docs/roles/\$ROLE.md" ]]; then
    cat "docs/roles/base.md" "docs/roles/\$ROLE.md" > CLAUDE.md
fi
HOOKEOF
    chmod +x "$hook_dir/post-merge"
    echo "  [$role] post-merge hook installed"
done

echo ""
echo "Generating role-specific CLAUDE.md files..."

# Generate CLAUDE.md for each clone
bash "$SCRIPT_DIR/generate-claude-md.sh" --all

echo ""
echo "Setup complete!"
echo ""
echo "Each agent is self-sufficient:"
echo "  - On git pull, CLAUDE.md auto-regenerates via post-merge hook"
echo "  - No manual sync needed"
echo ""
echo "To start an agent session:"
echo "  1. Open VS Code on agents/fullstack/"
echo "  2. Your AI tool reads CLAUDE.md and self-identifies"
echo "  3. Agent checks tracker and proposes Ready items in scope"
echo ""
echo "Agent directories:"
for role in "${CLONE_ROLES[@]}"; do
    echo "  $AGENTS_DIR/$role/"
done
