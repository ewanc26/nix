#!/usr/bin/env bash
set -e

# --- CONFIGURATION ---
REPO_ROOT="/etc/nixos"
SETTINGS_DIR="$REPO_ROOT/settings/gnome"
SECRETS_DIR="$REPO_ROOT/secrets"
DCONF_FILE="dconf.nix"
DCONF_SECRET="gnome-dconf-settings.age"
DEFAULT_FILE="default.nix"
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

echo "📥 Dumping current dconf settings..."
TEMP_NIX=$(mktemp)
TEMP_PLAIN=$(mktemp)

# 1. Convert dconf to Nix using dconf2nix
dconf dump / | nix run nixpkgs#dconf2nix > "$TEMP_NIX"

if [ ! -s "$TEMP_NIX" ]; then
    echo "❌ Error: Generated file is empty. dconf dump failed."
    rm "$TEMP_NIX" "$TEMP_PLAIN"
    exit 1
fi

# 2. Check if ragenix should be used (check for age key)
AGE_KEY="$HOME/.config/age/keys.txt"
USE_ENCRYPTION=false

if [ -f "$AGE_KEY" ]; then
    echo "🔐 Age key found, will encrypt settings..."
    USE_ENCRYPTION=true
else
    echo "⚠️  No age key found at $AGE_KEY"
    echo "    Settings will be stored in plaintext."
    echo "    Run: bash $REPO_ROOT/secrets/setup.sh to set up encryption."
fi

# 3. Setup directories
if [ ! -d "$SETTINGS_DIR" ]; then
    sudo mkdir -p "$SETTINGS_DIR"
fi

if [ ! -d "$SECRETS_DIR" ]; then
    sudo mkdir -p "$SECRETS_DIR"
fi

# 4. Handle encryption or plain storage
if [ "$USE_ENCRYPTION" = true ]; then
    echo "🔐 Encrypting dconf settings..."
    
    # Create encrypted version
    cat "$TEMP_NIX" | nix run github:yaxitech/ragenix -- \
        --rules "$SECRETS_DIR/secrets.nix" \
        -e "$SECRETS_DIR/$DCONF_SECRET" || {
        echo "❌ Encryption failed. Storing in plaintext as fallback."
        sudo mv "$TEMP_NIX" "$SETTINGS_DIR/$DCONF_FILE"
        USE_ENCRYPTION=false
    }
    
    if [ "$USE_ENCRYPTION" = true ]; then
        # Create a stub file that imports the decrypted secret
        cat > "$TEMP_PLAIN" << 'EOF'
# GNOME dconf settings (encrypted)
# The actual settings are stored in an encrypted file and decrypted at runtime
# Decrypted file location: /run/agenix/gnome-dconf-settings
#
# To update these settings:
# 1. Run: sudo bash settings/gnome-export.sh
# 2. This will update the encrypted file: secrets/gnome-dconf-settings.age
# 3. Commit both the encrypted file and this stub

{ config, lib, ... }:

let
  # Read the decrypted settings at build time
  dconfSettings = import config.age.secrets.gnome-dconf-settings.path;
in
{
  # Import the decrypted dconf settings
  dconf.settings = dconfSettings.dconf.settings or {};
}
EOF
        sudo mv "$TEMP_PLAIN" "$SETTINGS_DIR/$DCONF_FILE"
        echo "✅ Settings encrypted to: $SECRETS_DIR/$DCONF_SECRET"
        
        # Update secrets.nix if needed
        if ! grep -q "\"$DCONF_SECRET\"" "$SECRETS_DIR/secrets.nix"; then
            echo "⚠️  Please add the following to $SECRETS_DIR/secrets.nix:"
            echo "    \"$DCONF_SECRET\".publicKeys = all;"
        fi
    fi
else
    # Plain text storage
    sudo mv "$TEMP_NIX" "$SETTINGS_DIR/$DCONF_FILE"
    echo "📝 Settings saved (unencrypted) to: $SETTINGS_DIR/$DCONF_FILE"
fi

# 5. Ensure default.nix exists
if [ ! -f "$SETTINGS_DIR/$DEFAULT_FILE" ]; then
    echo "{ ... }: { imports = [ ./$DCONF_FILE ]; }" | sudo tee "$SETTINGS_DIR/$DEFAULT_FILE" > /dev/null
fi

# 6. Fix permissions
sudo chown -R "$USER":users "$SETTINGS_DIR"
if [ "$USE_ENCRYPTION" = true ]; then
    sudo chown -R "$USER":users "$SECRETS_DIR/$DCONF_SECRET"
fi

# 7. Git operations
cd "$REPO_ROOT" || exit
GIT_CMD="git -c safe.directory=$REPO_ROOT"

echo "📝 Staging changes..."
$GIT_CMD add "$SETTINGS_DIR/$DCONF_FILE" "$SETTINGS_DIR/$DEFAULT_FILE"
if [ "$USE_ENCRYPTION" = true ]; then
    $GIT_CMD add "$SECRETS_DIR/$DCONF_SECRET"
fi

if ! $GIT_CMD diff --cached --quiet; then
    $GIT_CMD commit -m "gnome: update dconf settings ($TIMESTAMP)"
    echo "✅ Success! Settings committed."
else
    echo "✅ No changes detected."
fi

# Cleanup
rm -f "$TEMP_NIX" "$TEMP_PLAIN"
