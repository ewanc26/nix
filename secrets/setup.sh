#!/usr/bin/env bash
set -euo pipefail

# Pathing
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SECRETS_DIR="$ROOT/secrets"
SECRETS_FILE="$SECRETS_DIR/secrets.nix"
AGE_KEY="$HOME/.config/age/keys.txt"

fail() { echo "❌ $1"; exit 1; }

echo "=== Ragenix Flake Bootstrap ==="

USERNAME="$(id -un)"
HOSTNAME="$(hostname)"

# 1. Ensure Age Key exists
if [ ! -f "$AGE_KEY" ]; then
  echo "Generating age key..."
  mkdir -p "$(dirname "$AGE_KEY")"
  nix shell nixpkgs#age -c "age-keygen -o $AGE_KEY"
  chmod 600 "$AGE_KEY"
fi

USER_KEY="$(grep "# public key:" "$AGE_KEY" | awk '{print $4}')"
[ -n "$USER_KEY" ] || fail "Could not read age public key"

# 2. Derive Host Key
echo "Deriving host key from SSH..."
# We wrap the ssh-to-age call to ensure we get a clean string
HOST_KEY=$(sudo nix shell nixpkgs#ssh-to-age -c sh -c "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub" 2>/dev/null || echo "")

# 3. Generate secrets.nix 
# We use a variable to hold the template to keep it clean
echo "Generating $SECRETS_FILE..."
mkdir -p "$SECRETS_DIR"

# Note the explicit double quotes around the variables below
NEW_CONTENT=$(cat <<EOF
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
  # Add your secrets here, e.g.:
  # "secret1.age".publicKeys = all;
}
EOF
)

# Write the file
echo "$NEW_CONTENT" > "$SECRETS_FILE"

# 4. Verification
echo "Verifying Nix syntax..."
if nix-instantiate --parse "$SECRETS_FILE" > /dev/null; then
  echo "✅ secrets.nix is valid Nix"
else
  echo "--- Current File Content ---"
  cat "$SECRETS_FILE"
  echo "----------------------------"
  fail "secrets.nix still has syntax errors!"
fi

# 5. Auto-Rekey (only if secrets exist)
SECRETS_COUNT=$(find "$SECRETS_DIR" -name "*.age" 2>/dev/null | wc -l)
if [ "$SECRETS_COUNT" -gt 0 ]; then
  echo "Re-keying $SECRETS_COUNT secrets..."
  nix run github:yaxitech/ragenix -- -r || echo "⚠️ Rekey failed"
fi

echo -e "\nDone."