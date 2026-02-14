#!/usr/bin/env bash
# Quick build and test script for Rust tools

set -e

cd "$(dirname "$0")/src"

echo "🦀 Building Rust tools..."

# Build all tools
for tool in darwin-export.rs gnome-export.rs secrets-setup.rs; do
    name="${tool%.rs}"
    echo "  Building $name..."
    rustc --edition 2021 -O "$tool" -o "$name"
    echo "  ✅ $name built successfully"
done

echo ""
echo "📦 Built tools:"
ls -lh darwin-export gnome-export secrets-setup

echo ""
echo "Usage:"
echo "  ./src/darwin-export     # Run darwin export"
echo "  ./src/gnome-export      # Run gnome export"
echo "  ./src/secrets-setup     # Run secrets setup"
echo ""
echo "Or use nix:"
echo "  nix run .#darwin-export"
echo "  nix run .#gnome-export"
echo "  nix run .#secrets-setup"
