#!/usr/bin/env bash
# Setup git hooks for automatic backup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$CONFIG_DIR/.git/hooks"

echo "Setting up git hooks in $HOOKS_DIR..."

# Make scripts executable
chmod +x "$SCRIPT_DIR/pre-commit"
chmod +x "$SCRIPT_DIR/post-commit"
chmod +x "$SCRIPT_DIR/auto-backup.sh"

# Install hooks
cp "$SCRIPT_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
cp "$SCRIPT_DIR/post-commit" "$HOOKS_DIR/post-commit"
chmod +x "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/post-commit"

echo "✓ Git hooks installed successfully!"
echo ""
echo "Installed hooks:"
echo "  - pre-commit: Validates Nix configuration"
echo "  - post-commit: Auto-pushes to remote"
echo ""
echo "Auto-backup will run:"
echo "  - On every commit (via post-commit hook)"
echo "  - Periodically via systemd timer (Linux) or launchd (macOS)"
