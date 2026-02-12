#!/usr/bin/env bash
set -e

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "/etc/nixos")"
SETTINGS_DIR="$REPO_ROOT/settings/gnome"
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

echo "📥 Dumping current dconf settings..."
DCONF_CONTENT=$(dconf dump / | nix run nixpkgs#dconf2nix)

echo "💾 Writing to $SETTINGS_DIR/dconf-settings.nix..."
cat > "$SETTINGS_DIR/dconf-settings.nix" << EOF
# GNOME dconf settings exported at $TIMESTAMP
$DCONF_CONTENT
EOF

cd "$REPO_ROOT"

echo "🧪 Running flake check..."
nix flake check

echo "📝 Committing changes..."
git add "$SETTINGS_DIR/dconf-settings.nix"

if ! git diff --cached --quiet; then
    git commit -m "gnome: update dconf settings ($TIMESTAMP)"
    echo "✅ Settings exported and committed."
else
    echo "✅ No changes detected."
fi