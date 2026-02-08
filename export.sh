#!/usr/bin/env bash

# CONFIG
TARGET_DIR="/etc/nixos/settings/gnome"
REPO_ROOT="/etc/nixos"
CURRENT_USER=$(whoami)
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

# Flag defaults
DRY_RUN=false

# Helper for notifications
status_msg() {
    local title="$1"
    local msg="$2"
    echo -e "\n📦 **$title**: $msg"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$title" "$msg"
    else
        # Fallback: Log to system journal so you can audit via journalctl -t gnome-sync
        echo "[$title] $msg" | systemd-cat -t gnome-sync
    fi
}

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--dry-run) DRY_RUN=true; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
done

if [ "$DRY_RUN" = true ]; then
    echo "🔍 DRY RUN MODE: No changes will be written to disk or Git."
fi

# 1. Temporary Build Space
TEMP_EXPORT=$(mktemp -d)

# 2. Capture and Convert
echo "📥 Extracting dconf settings..."
PATHS=$(dconf dump / | grep '^\[.*\]' | tr -d '[]' | sort -u)

for path in $PATHS; do
    [[ $path != /* ]] && dconf_path="/$path" || dconf_path="$path"
    [[ $dconf_path != */ ]] && dconf_path="$dconf_path/"

    rel_dir=$(echo "$dconf_path" | sed 's|^/org/gnome/||; s|^/org/gtk/||; s|^/||' | tr ':' '-')
    filename=$(echo "$rel_dir" | sed 's|/$||; s|.*/||')
    
    [[ -z "$rel_dir" || "$rel_dir" == "/" ]] && { rel_dir="misc/"; filename="extra"; }
    
    full_path_dir="$TEMP_EXPORT/$rel_dir"
    full_file_path="$full_path_dir/${filename}.nix"

    raw_output=$(dconf dump "$dconf_path")
    [ -z "$raw_output" ] && continue

    mkdir -p "$full_path_dir"

    if echo "$raw_output" | dconf2nix > /tmp/dconf_temp 2>/dev/null; then
        mv /tmp/dcgitonf_temp "$full_file_path"
    else
        # Fallback for complex types (like GVariant layouts)
        {
            echo "{ ... }:"
            echo "{"
            echo "  dconf.settings.\"${dconf_path%/}\" = {"
            # Enhanced sed to wrap values in double quotes if they look like GVariant/complex data
            echo "$raw_output" | sed '/^\[.*\]$/d' | sed "s/^\([^=]*\)=\(.*\)$/    \"\1\" = \"\2\";/g"
            echo "  };"
            echo "}"
        } > "$full_file_path"
    fi
done

# Master default.nix
{
    echo "{ ... }:"
    echo "{"
    echo "  imports = ["
    find "$TEMP_EXPORT" -name "*.nix" ! -name "default.nix" -printf "    ./%P\n" | sort
    echo "  ];"
    echo "}"
} > "$TEMP_EXPORT/default.nix"

# 3. Synchronize Logic
if [ "$DRY_RUN" = true ]; then
    echo -e "\n--- DIFF OF PROPOSED CHANGES ---"
    diff -rN "$TARGET_DIR" "$TEMP_EXPORT" || true
    echo "--------------------------------"
    rm -rf "$TEMP_EXPORT"
    exit 0
fi

# Apply Changes Locally
sudo mkdir -p "$TARGET_DIR"
sudo rsync -av --delete "$TEMP_EXPORT/" "$TARGET_DIR/"
sudo chown -R "$CURRENT_USER" "$TARGET_DIR"
rm -rf "$TEMP_EXPORT"

# 4. Git Logic
cd "$REPO_ROOT" || exit
if [ -d ".git" ]; then
    git add "$TARGET_DIR"
    
    if ! git diff --cached --quiet; then
        git commit -m "dconf-export: $TIMESTAMP"
        echo "☁️  Pushing to remote..."
        if git push; then
            status_msg "GNOME Sync" "Settings synced and pushed successfully."
        else
            status_msg "Git Error" "Commit created, but push failed."
        fi
    else
        echo "✅ No changes to sync."
    fi
else
    status_msg "Nix Config" "Not a git repo. Settings updated locally only."
fi