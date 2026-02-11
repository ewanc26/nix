#!/usr/bin/env bash
# Quick setup script for ragenix secrets

set -e

echo "=== Ragenix Secrets Setup ==="
echo ""

AGE_DIR="$HOME/.config/age"
AGE_KEY="$AGE_DIR/keys.txt"

# Ensure age dir exists
if [ ! -d "$AGE_DIR" ]; then
    echo "Creating age keys directory..."
    mkdir -p "$AGE_DIR"
fi

# Generate age key if missing
if [ -f "$AGE_KEY" ]; then
    echo "✓ Age key already exists at ~/.config/age/keys.txt"
else
    echo "Generating new age key..."

    if command -v age-keygen >/dev/null 2>&1; then
        age-keygen -o "$AGE_KEY"
    else
        echo "age-keygen not found — using nix to run it..."
        nix shell nixpkgs#age -c age-keygen -o "$AGE_KEY"
    fi

    chmod 600 "$AGE_KEY"
    echo "✓ Age key generated at ~/.config/age/keys.txt"
fi

echo ""
echo "Your public key:"
grep "# public key:" "$AGE_KEY" || echo "(public key line not found — check file)"

echo ""
echo "=== Getting Host SSH Key ==="

if [ -f "/etc/ssh/ssh_host_ed25519_key.pub" ]; then
    echo "Converting SSH host key to age format..."

    if command -v ssh-to-age >/dev/null 2>&1; then
        cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
    else
        echo "ssh-to-age not found — using nix shell..."
        nix shell nixpkgs#ssh-to-age -c ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
    fi
else
    echo "⚠ Could not find /etc/ssh/ssh_host_ed25519_key.pub"
    echo "  You may need to run this with sudo or ensure SSH host keys exist"
fi

echo ""
echo "=== Next Steps ==="
echo "1. Copy your public keys into secrets/secrets.nix"
echo "2. Create a secret: nix run github:yaxitech/ragenix -- -e secrets/example.age"
echo "3. Uncomment the secret in modules/secrets.nix"
echo "4. Rebuild: sudo nixos-rebuild switch --flake .#laptop"
echo ""
echo "Done."