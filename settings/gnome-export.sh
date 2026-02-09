#!/usr/bin/env bash
set -e

# --- CONFIGURATION ---
REPO_ROOT="/etc/nixos"
SETTINGS_DIR="$REPO_ROOT/settings/gnome"
OUTPUT_FILE="dconf.nix"
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

# --- 1. GENERATE SETTINGS (User Level) ---
echo "📥 Dumping current dconf settings..."
TEMP_NIX=$(mktemp)

# Pipe dconf into dconf2nix
dconf dump / | nix run nixpkgs#dconf2nix > "$TEMP_NIX"

if [ ! -s "$TEMP_NIX" ]; then
    echo "❌ Error: Generated file is empty."
    rm "$TEMP_NIX"
    exit 1
fi

# --- 2. MOVE TO TARGET (Sudo only for the write) ---
echo "🔒 Moving files to $SETTINGS_DIR..."

if [ ! -d "$SETTINGS_DIR" ]; then
    sudo mkdir -p "$SETTINGS_DIR"
fi

# Move and ensure your user owns it so git works without sudo
sudo mv "$TEMP_NIX" "$SETTINGS_DIR/$OUTPUT_FILE"
sudo chown "$USER":users "$SETTINGS_DIR/$OUTPUT_FILE"

# --- 3. GIT OPERATIONS (User Level) ---
cd "$REPO_ROOT" || exit

# Tell git it's okay to work in this directory even if it's in /etc
git config --global --add safe.directory "$REPO_ROOT"

echo "📝 Staging changes..."
git add "$SETTINGS_DIR/$OUTPUT_FILE"

if ! git diff --cached --quiet; then
    git commit -m "gnome: update dconf settings ($TIMESTAMP)"
    echo "✅ Success! Settings updated and committed as $USER."
else
    echo "✅ No changes detected."
fi