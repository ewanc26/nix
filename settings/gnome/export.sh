#!/usr/bin/env bash

# CONFIG
TARGET_DIR="/etc/nixos/settings/gnome"
CURRENT_USER=$(whoami)

echo "🚀 Starting REFINED DYNAMIC GNOME settings export..."

# 1. Clean up old generated files
find "$TARGET_DIR" -name "*.nix" -type f -delete

# 2. Get all dconf paths
# We use a more robust way to capture headers and ensure they are valid paths
PATHS=$(dconf dump / | grep '^\[.*\]' | tr -d '[]' | sort -u)

for path in $PATHS; do
    # Ensure dconf_path starts and ends with /
    [[ $path != /* ]] && dconf_path="/$path" || dconf_path="$path"
    [[ $dconf_path != */ ]] && dconf_path="$dconf_path/"

    # --- DYNAMIC PATH LOGIC ---
    # Strip common prefixes for a cleaner folder structure
    # We remove /org/gnome/ and /org/gtk/ but keep the rest
    rel_dir=$(echo "$dconf_path" | sed 's|^/org/gnome/||; s|^/org/gtk/||; s|^/||')
    
    # Determine filename from the last segment
    filename=$(echo "$rel_dir" | sed 's|/$||; s|.*/||')
    
    # Fallback if the path was emptied by the sed above
    if [[ -z "$rel_dir" || "$rel_dir" == "/" ]]; then
        rel_dir="misc/"
        filename="extra"
    fi
    
    full_path_dir="$TARGET_DIR/$rel_dir"
    full_file_path="$full_path_dir${filename}.nix"
    # --------------------------

    raw_output=$(dconf dump "$dconf_path")
    if [ -z "$raw_output" ]; then continue; fi

    sudo mkdir -p "$full_path_dir"

    # Attempt dconf2nix
    if echo "$raw_output" | dconf2nix > /tmp/dconf_temp 2>/dev/null; then
        sudo mv /tmp/dconf_temp "$full_file_path"
        echo "✅ Exported $dconf_path"
    else
        echo "🔗 Complex data in $dconf_path - Using fallback"
        {
            echo "{ ... }:"
            echo "{"
            echo "  dconf.settings.\"${dconf_path%/}\" = {"
            # Improved sed to handle values with spaces and special characters
            echo "$raw_output" | sed '/^\[.*\]$/d' | sed 's/^\([^=]*\)=\(.*\)$/    "\1" = \2;/g'
            echo "  };"
            echo "}"
        } | sudo tee "$full_file_path" > /dev/null
    fi
done

# 3. Generate master default.nix
echo "🛠️  Generating master default.nix..."
{
    echo "{ ... }:"
    echo "{"
    echo "  imports = ["
    # Find all .nix files, format for Nix, and exclude default.nix
    find "$TARGET_DIR" -name "*.nix" ! -name "default.nix" -printf "    ./%P\n" | sort
    echo "  ];"
    echo "}"
} | sudo tee "$TARGET_DIR/default.nix" > /dev/null

# 4. Finalizing
sudo chown -R "$CURRENT_USER" "$TARGET_DIR"

echo "🎉 Done! Everything is organized in $TARGET_DIR"