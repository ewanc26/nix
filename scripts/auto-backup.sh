#!/usr/bin/env bash
# Automatic backup script for nix-config
# Commits changes locally and pushes when network is available

set -e

CONFIG_DIR="/home/ewan/.config/nix-config"
if [[ "$(uname)" == "Darwin" ]]; then
    CONFIG_DIR="/Users/ewan/.config/nix-config"
fi

cd "$CONFIG_DIR"

# Check if there are changes
if [[ -z $(git status --porcelain) ]]; then
    echo "No changes to commit"
    exit 0
fi

# Add all changes
git add -A

# Create commit with timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
git commit -m "Auto-backup from $HOSTNAME at $TIMESTAMP" || {
    echo "Commit failed, possibly nothing to commit"
    exit 0
}

echo "✓ Changes committed locally"

# Check network connectivity before attempting push
check_network() {
    # Try to reach GitHub (or your git remote)
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS: use ping with timeout
        if ping -c 1 -W 2 github.com &>/dev/null || ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
            return 0
        fi
    else
        # Linux: use ping with timeout
        if ping -c 1 -W 2 github.com &>/dev/null || ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Attempt to push if network is available
if check_network; then
    echo "Network available, attempting push..."
    if git push origin main 2>/dev/null; then
        echo "✓ Successfully pushed to remote"
    else
        echo "⚠️  Push failed (possible auth or merge conflict)"
        echo "Changes are committed locally and will be pushed on next successful run"
    fi
else
    echo "⚠️  No network connectivity detected"
    echo "Changes are committed locally and will be pushed when network is available"
fi

exit 0
