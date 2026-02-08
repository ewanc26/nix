#!/usr/bin/env bash

set -euo pipefail

TARGET_DIR="/etc/nixos/settings/gnome"
TEMP_DIR="/tmp/gnome-nix-export"
CURRENT_USER=$(whoami)

echo "🚀 Starting Robust GNOME settings export..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

declare -A MAPPINGS=(
    ["/org/gnome/desktop/interface/"]="desktop/interface/interface.nix"
    ["/org/gnome/desktop/wm/preferences/"]="desktop/wm/preferences.nix"
    ["/org/gnome/desktop/wm/keybindings/"]="desktop/wm/keybindings.nix"
    ["/org/gnome/shell/"]="shell/shell.nix"
    ["/org/gnome/shell/extensions/"]="shell/extensions/extensions.nix"
    ["/org/gnome/mutter/"]="mutter/mutter.nix"
    # Add other paths here as needed
)

for dconf_path in "${!MAPPINGS[@]}"; do
    rel_path="${MAPPINGS[$dconf_path]}"
    full_path="$TEMP_DIR/$rel_path"
    mkdir -p "$(dirname "$full_path")"

    raw_output=$(dconf dump "$dconf_path")

    if [ -z "$raw_output" ]; then
        echo "⚠️  Skipping empty: $dconf_path"
        continue
    fi

    echo "Settings found for $dconf_path. Processing..."

    # Check if the output contains complex characters that crash dconf2nix
    if [[ "$raw_output" == *"{"* ]] || [[ "$raw_output" == *"["* ]]; then
        echo "🔗 Complex data detected in $dconf_path. Generating raw Nix attribute set..."
        
        # Generate a standard Nix file that Home Manager can consume via 'dconf.settings'
        {
            echo "{ ... }:"
            echo "{"
            echo "  dconf.settings.\"${dconf_path%/}\" = {"
            # Clean up the dump to look like Nix keys
            echo "$raw_output" | sed '/^\[.*\]$/d' | sed 's/^\([^=]*\)=\(.*\)$/    "\1" = \2;/g'
            echo "  };"
            echo "}"
        } > "$full_path"
    else
        echo "✅ Simple data detected. Using dconf2nix..."
        if echo "$raw_output" | dconf2nix > "$full_path" 2>/dev/null; then
            : # Success
        else
            echo "❌ dconf2nix failed on $dconf_path, falling back to raw Nix..."
            # Fallback logic same as above
             {
                echo "{ ... }:"
                echo "{"
                echo "  dconf.settings.\"${dconf_path%/}\" = {"
                echo "$raw_output" | sed '/^\[.*\]$/d' | sed 's/^\([^=]*\)=\(.*\)$/    "\1" = \2;/g'
                echo "  };"
                echo "}"
            } > "$full_path"
        fi
    fi
done

echo "-----------------------------------------------------"
sudo mkdir -p "$TARGET_DIR"
sudo cp -r "$TEMP_DIR/"* "$TARGET_DIR/"
sudo chown -R "$CURRENT_USER" "$TARGET_DIR"
rm -rf "$TEMP_DIR"

echo "🎉 Export finished. Files moved to $TARGET_DIR"