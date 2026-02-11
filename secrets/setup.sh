#!/usr/bin/env bash
# Quick setup script for ragenix secrets

set -e

echo "=== Ragenix Secrets Setup ==="
echo ""

# Check if age keys directory exists
if [ ! -d "$HOME/.config/age" ]; then
    echo "Creating age keys directory..."
    mkdir -p "$HOME/.config/age"
fi

# Check if age key already exists
if [ -f "$HOME/.config/age/keys.txt" ]; then
    echo "✓ Age key already exists at ~/.config/age/keys.txt"
    echo ""
    echo "Your public key:"
    grep "# public key:" "$HOME/.config/age/keys.txt"
else
    echo "Generating new age key..."
    nix run github:yaxitech/ragenix -- --generate-age-key > "$HOME/.config/age/keys.txt"
    chmod 600 "$HOME/.config/age/keys.txt"
    echo "✓ Age key generated at ~/.config/age/keys.txt"
    echo ""
    echo "Your public key:"
    grep "# public key:" "$HOME/.config/age/keys.txt"
fi

echo ""
echo "=== Getting Host SSH Key ==="

if [ -f "/etc/ssh/ssh_host_ed25519_key.pub" ]; then
    echo "Converting SSH host key to age format..."
    if command -v ssh-to-age &> /dev/null; then
        echo "Host age key:"
        cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
    else
        echo "Installing ssh-to-age temporarily..."
        echo "Host age key:"
        nix-shell -p ssh-to-age --run "cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age"
    fi
else
    echo "⚠ Could not find /etc/ssh/ssh_host_ed25519_key.pub"
    echo "  You may need to generate host SSH keys or run this with sudo"
fi

echo ""
echo "=== Next Steps ==="
echo "1. Copy your public keys (shown above) into secrets/secrets.nix"
echo "2. Create a secret: nix run github:yaxitech/ragenix -- -e secrets/example.age"
echo "3. Uncomment the secret in modules/secrets.nix"
echo "4. Rebuild: sudo nixos-rebuild switch --flake .#laptop"
echo ""
echo "For more information, see secrets/README.md"
