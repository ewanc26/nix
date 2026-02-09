#!/usr/bin/env bash
set -e

# --- CONFIGURATION ---
REPO_ROOT="/etc/nixos"
SETTINGS_DIR="$REPO_ROOT/settings/gnome"
DCONF_FILE="dconf.nix"
DEFAULT_FILE="default.nix"
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

echo "📥 Dumping current dconf settings..."
TEMP_NIX=$(mktemp)

# 1. Convert dconf to Nix using the reliable tool
# We run it via 'nix run' so it's always available without manual install
dconf dump / | nix run nixpkgs#dconf2nix > "$TEMP_NIX"

if [ ! -s "$TEMP_NIX" ]; then
    echo "❌ Error: Generated file is empty. dconf dump failed."
    rm "$TEMP_NIX"
    exit 1
fi

# 2. Setup Target Directory (Sudo)
if [ ! -d "$SETTINGS_DIR" ]; then
    sudo mkdir -p "$SETTINGS_DIR"
fi

# 3. Move and fix permissions immediately
echo "🚚 Moving files to $SETTINGS_DIR..."
sudo mv "$TEMP_NIX" "$SETTINGS_DIR/$DCONF_FILE"

# Ensure default.nix exists so the folder is importable
if [ ! -f "$SETTINGS_DIR/$DEFAULT_FILE" ]; then
    echo "{ ... }: { imports = [ ./$DCONF_FILE ]; }" | sudo tee "$SETTINGS_DIR/$DEFAULT_FILE" > /dev/null
fi

# Make sure your user owns these so Git can read/stage them
sudo chown -R "$USER":users "$SETTINGS_DIR"

# 4. Git Operations
cd "$REPO_ROOT" || exit

# We use -c to pass the safe directory config since your global config is read-only
GIT_CMD="git -c safe.directory=$REPO_ROOT"

echo "📝 Staging changes for Nix Flake..."
$GIT_CMD add "$SETTINGS_DIR/$DCONF_FILE" "$SETTINGS_DIR/$DEFAULT_FILE"

if ! $GIT_CMD diff --cached --quiet; then
    $GIT_CMD commit -m "gnome: update dconf settings ($TIMESTAMP)"
    echo "✅ Success! Settings committed."
else
    echo "✅ No changes detected."
fi