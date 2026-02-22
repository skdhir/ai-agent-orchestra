#!/bin/bash
# generate-claude-md.sh — Generate role-specific CLAUDE.md from base + role profile
#
# Usage:
#   ./scripts/generate-claude-md.sh <role> [target-dir]
#   ./scripts/generate-claude-md.sh --all
#
# Examples:
#   ./scripts/generate-claude-md.sh fullstack
#   ./scripts/generate-claude-md.sh fullstack /tmp/test
#   ./scripts/generate-claude-md.sh --all

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ROLES_DIR="$PROJECT_ROOT/docs/roles"
AGENTS_DIR="$PROJECT_ROOT/agents"

# Define your roles here — must match files in docs/roles/
AVAILABLE_ROLES=(architect fullstack web infra)

generate_one() {
    local role="$1"
    local target_dir="${2:-$AGENTS_DIR/$role}"

    # Validate role
    local valid=false
    for r in "${AVAILABLE_ROLES[@]}"; do
        if [[ "$r" == "$role" ]]; then
            valid=true
            break
        fi
    done

    if [[ "$valid" != "true" ]]; then
        echo "Error: Unknown role '$role'. Available: ${AVAILABLE_ROLES[*]}"
        exit 1
    fi

    # Validate source files exist
    if [[ ! -f "$ROLES_DIR/base.md" ]]; then
        echo "Error: $ROLES_DIR/base.md not found."
        exit 1
    fi

    if [[ ! -f "$ROLES_DIR/$role.md" ]]; then
        echo "Error: $ROLES_DIR/$role.md not found."
        exit 1
    fi

    # Validate target directory exists
    if [[ ! -d "$target_dir" ]]; then
        echo "Warning: $target_dir does not exist. Run setup-agents.sh first."
        echo "Skipping $role."
        return 1
    fi

    # Generate CLAUDE.md = base + role
    cat "$ROLES_DIR/base.md" "$ROLES_DIR/$role.md" > "$target_dir/CLAUDE.md"
    echo "Generated: $target_dir/CLAUDE.md ($role)"
}

# Main
if [[ "${1:-}" == "--all" ]]; then
    echo "Generating CLAUDE.md for all roles..."
    for role in "${AVAILABLE_ROLES[@]}"; do
        generate_one "$role" || true
    done
    echo "Done."
elif [[ -n "${1:-}" ]]; then
    generate_one "$1" "${2:-}"
else
    echo "Usage: $0 <role> [target-dir]"
    echo "       $0 --all"
    echo ""
    echo "Available roles: ${AVAILABLE_ROLES[*]}"
    exit 1
fi
