#!/usr/bin/env bash
set -e

# --- CONFIGURATION ---
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "/etc/nixos")"
SETTINGS_DIR="$REPO_ROOT/settings/gnome"
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

echo "📥 Dumping current dconf settings..."
DCONF_CONTENT=$(dconf dump / | nix run nixpkgs#dconf2nix)

echo "💾 Writing to $SETTINGS_DIR/dconf-settings.nix..."
cat > "$SETTINGS_DIR/dconf-settings.nix" << EOF
# GNOME dconf settings exported at $TIMESTAMP
{ config, lib, pkgs, ... }:

{
  dconf.settings = 
$DCONF_CONTENT
  ;
}
EOF

echo "📝 Committing changes..."
cd "$REPO_ROOT"
git add "$SETTINGS_DIR/dconf-settings.nix"

if ! git diff --cached --quiet; then
    git commit -m "gnome: update dconf settings ($TIMESTAMP)" || true
    echo "✅ Success! Settings exported and committed."
else
    echo "✅ No changes detected."
fi
