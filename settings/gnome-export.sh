#!/usr/bin/env bash

# CONFIG
TARGET_DIR="/etc/nixos/settings/gnome"
REPO_ROOT="/etc/nixos"
CURRENT_USER=$(whoami)
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

# Flag defaults
DRY_RUN=false

status_msg() {
    local title="$1"
    local msg="$2"
    echo -e "\n**$title**: $msg"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$title" "$msg"
    fi
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--dry-run) DRY_RUN=true; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
done

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

    # FIXED TYPO HERE: /tmp/dconf_temp
    if echo "$raw_output" | dconf2nix > /tmp/dconf_temp 2>/dev/null; then
        mv /tmp/dconf_temp "$full_file_path"
    else
        {
            echo "{ ... }:"
            echo "{"
            echo "  dconf.settings.\"${dconf_path%/}\" = {"
            # Enhanced quoting to handle the GVariant error you saw earlier
            echo "$raw_output" | sed '/^\[.*\]$/d' | sed "s/^\([^=]*\)=\(.*\)$/    \"\1\" = \"\2\";/g"
            echo "  };"
            echo "}"
        } > "$full_file_path"
    fi
done

# 3. SAFETY CHECK: Abort if nothing was generated
FILE_COUNT=$(find "$TEMP_EXPORT" -name "*.nix" | wc -l)
if [ "$FILE_COUNT" -lt 2 ]; then
    echo "❌ ERROR: Export failed (only $FILE_COUNT files generated). Aborting to save existing config."
    rm -rf "$TEMP_EXPORT"
    exit 1
fi

# Master default.nix
{
    echo "{ ... }:"
    echo "{"
    echo "  imports = ["
    find "$TEMP_EXPORT" -name "*.nix" ! -name "default.nix" -printf "    ./%P\n" | sort
    echo "  ];"
    echo "}"
} > "$TEMP_EXPORT/default.nix"

# 4. Sync Logic
if [ "$DRY_RUN" = true ]; then
    diff -rN "$TARGET_DIR" "$TEMP_EXPORT" || true
    rm -rf "$TEMP_EXPORT"
    exit 0
fi

sudo mkdir -p "$TARGET_DIR"
sudo rsync -av --delete "$TEMP_EXPORT/" "$TARGET_DIR/"
sudo chown -R "$CURRENT_USER" "$TARGET_DIR"
rm -rf "$TEMP_EXPORT"

# 5. Git Logic
cd "$REPO_ROOT" || exit
if [ -d ".git" ]; then
    git add "$TARGET_DIR"
    if ! git diff --cached --quiet; then
        git commit -m "dconf-export: $TIMESTAMP"
        git push && status_msg "GNOME Sync" "Success" || status_msg "Git Error" "Push Failed"
    fi
fi