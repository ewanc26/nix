#!/usr/bin/env bash
set -e

# --- CONFIGURATION ---
REPO_ROOT="/etc/nixos"
SECRETS_DIR="$REPO_ROOT/secrets"
DCONF_SECRET="gnome-dconf-settings.age"
AGE_KEY="$HOME/.config/age/keys.txt"
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

# 1. Workspace setup
# We work directly in /tmp to ensure canonicalization doesn't hit /etc permission issues
WORK_DIR=$(mktemp -d /tmp/ragenix-XXXXXX)
TEMP_RULES="$WORK_DIR/rules.nix"
TEMP_AGE="$WORK_DIR/$DCONF_SECRET"

echo "📥 Dumping current dconf settings..."
DCONF_CONTENT=$(dconf dump / | nix run nixpkgs#dconf2nix)

echo "🔐 Generating isolated rules..."
# IMPORTANT: We use the absolute path of TEMP_AGE inside the rules 
# to satisfy ragenix's strict path canonicalization.
cat > "$TEMP_RULES" <<EOF
{
  "$TEMP_AGE".publicKeys = [
    "age1xl8ptkqm03skrdadqgprnez3trrc0k9t0ex052lweewqre2zc9qq7ljm3z"
    "age10ysmz3603uupz0043mpznchtnh6jsnk5cu3eg05xalma4xjacppsgupgvj"
    "age1s4exn5venvd2rkrvw9g6g9rua05quut62m6le8k79st0dryhcy3qq4n55k"
  ];
}
EOF

# ragenix REQUIRES the file to exist before it can "edit" it via stdin
touch "$TEMP_AGE"

echo "🔐 Encrypting with ragenix..."
# Use --editor - to read from stdin. 
# We pass the absolute path to the temp age file.
if echo "$DCONF_CONTENT" | nix run github:yaxitech/ragenix -- \
    --rules "$TEMP_RULES" \
    --editor - \
    --edit "$TEMP_AGE" \
    -i "$AGE_KEY"; then
    
    echo "💾 Applying changes to $REPO_ROOT..."
    
    # 2. Move to final destination
    sudo mv "$TEMP_AGE" "$SECRETS_DIR/$DCONF_SECRET"
    sudo chown root:root "$SECRETS_DIR/$DCONF_SECRET"
    
    # 3. Git Operations
    cd "$REPO_ROOT"
    USER_NAME=$(git config user.name || echo "Ewan")
    USER_EMAIL=$(git config user.email || echo "ewan@laptop")

    sudo git add "$SECRETS_DIR/$DCONF_SECRET"
    
    if ! git diff --cached --quiet; then
        sudo git -c "user.name=$USER_NAME" -c "user.email=$USER_EMAIL" \
            commit -m "gnome: update dconf settings ($TIMESTAMP)"
        echo "✅ Success! Settings committed."
    else
        echo "✅ No changes detected."
    fi
else
    echo "❌ Encryption failed."
    rm -rf "$WORK_DIR"
    exit 1
fi

# Cleanup
rm -rf "$WORK_DIR"