#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$(dirname "$SCRIPT_DIR")")"
SECRETS_DIR="$ROOT/secrets"
SECRETS_FILE="$SECRETS_DIR/secrets.nix"
AGE_KEY="$HOME/.config/age/keys.txt"

fail() { echo "❌ $1"; exit 1; }

echo "=== Ragenix Flake Bootstrap ==="

USERNAME="$(id -un)"
HOSTNAME="$(hostname -s)"
OS="$(uname -s)"

mkdir -p "$(dirname "$AGE_KEY")"

# --- 1. Master Age Key Logic ---
if [ ! -s "$AGE_KEY" ]; then
    echo "⚠️ No key found at $AGE_KEY. Generating..."
    nix run nixpkgs#age-keygen -- -o "$AGE_KEY"
    chmod 600 "$AGE_KEY"
fi

echo "Extracting public key..."
# Method A: Try to grep it from the comment (Fastest)
USER_KEY=$(grep "# public key:" "$AGE_KEY" | awk '{print $4}' | tr -d '\r\n' || echo "")

# Method B: Fallback to age -y if grep failed
if [ -z "$USER_KEY" ]; then
    USER_KEY=$(nix run nixpkgs#age -- -y "$AGE_KEY" 2>/dev/null | tr -d '\r\n' || echo "")
fi

if [ -z "$USER_KEY" ]; then
    fail "Could not extract public key from $AGE_KEY. Is it a valid age key?"
fi

echo "✅ Master Identity ($USERNAME): $USER_KEY"

# --- 2. Derive Host Key ---
HOST_KEY=""
if [ -f /etc/ssh/ssh_host_ed25519_key.pub ]; then
    echo "Deriving host key..."
    # Using 'nix run' with specific binary selection
    HOST_KEY=$(nix run nixpkgs#ssh-to-age -- < /etc/ssh/ssh_host_ed25519_key.pub 2>/dev/null | tr -d '\r\n' || echo "")
fi

# --- 3. Update secrets.nix ---
mkdir -p "$SECRETS_DIR"

if [ ! -f "$SECRETS_FILE" ]; then
    echo "Creating $SECRETS_FILE..."
    cat > "$SECRETS_FILE" <<EOF
let
  users = {
    $USERNAME = "$USER_KEY";
  };

  systems = {
    $HOSTNAME = "$HOST_KEY";
  };

  all = (builtins.attrValues users) ++ (builtins.attrValues systems);
in
{
}
EOF
else
    echo "Updating $SECRETS_FILE..."
    SED_I=(sed -i '')
    [ "$OS" != "Darwin" ] && SED_I=(sed -i)

    # Sync User
    if grep -q "$USERNAME =" "$SECRETS_FILE"; then
        "${SED_I[@]}" "s|$USERNAME = \".*\";|$USERNAME = \"$USER_KEY\";|" "$SECRETS_FILE"
    else
        "${SED_I[@]}" "/users = {/a\\
    $USERNAME = \"$USER_KEY\";" "$SECRETS_FILE"
    fi

    # Sync System
    if [ -n "$HOST_KEY" ] && ! grep -q "$HOSTNAME =" "$SECRETS_FILE"; then
        echo "Adding system: $HOSTNAME"
        "${SED_I[@]}" "/systems = {/a\\
    $HOSTNAME = \"$HOST_KEY\";" "$SECRETS_FILE"
    fi
fi

# --- 4. Verify Nix syntax ---
if nix-instantiate --parse "$SECRETS_FILE" > /dev/null; then
    echo "✅ secrets.nix is valid Nix"
else
    fail "secrets.nix has syntax errors!"
fi

# --- 5. Rekey ---
SECRETS_COUNT=$(find "$SECRETS_DIR" -name "*.age" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SECRETS_COUNT" -gt 0 ]; then
    echo "Re-keying $SECRETS_COUNT secrets..."
    nix run github:yaxitech/ragenix -- -r || echo "⚠️ Rekey failed"
fi

echo -e "\nDone."