#!/usr/bin/env bash

# CONFIG
TARGET_DIR="/etc/nixos/settings/gnome"
REPO_ROOT="/etc/nixos"
CURRENT_USER=$(whoami)
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

# 1. Temporary Build Space
TEMP_EXPORT=$(mktemp -d)
FULL_DUMP="/tmp/dconf_full_dump.txt"

echo "📥 Creating master dconf dump..."
dconf dump / > "$FULL_DUMP"

HEADERS=$(grep '^\[.*\]$' "$FULL_DUMP" | tr -d '[]')

echo "✂️  Extracting blocks..."
for header in $HEADERS; do
    safe_name=$(echo "$header" | sed 's|/|-|g; s|:|--|g')
    full_file_path="$TEMP_EXPORT/${safe_name}.nix"
    block_content=$(awk "/^\[$(echo $header | sed 's/\//\\\//g')\]/{flag=1;next}/^\[/{flag=0}NF==0{flag=0}flag" "$FULL_DUMP")

    [ -z "$block_content" ] && continue

    {
        echo "{ lib, ... }:"
        echo "{"
        echo "  dconf.settings.\"$header\" = {"
        echo "$block_content" | while read -r line; do
            if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
                key="${BASH_REMATCH[1]}"
                val="${BASH_REMATCH[2]}"
                # GVariant protection
                if [[ "$val" =~ ^(int64|uint32|uint64|int32|byte|boolean|handle|double|string) ]] || [[ "$val" =~ ^\< ]]; then
                    [[ ! "$val" =~ ^\" ]] && val="\"$val\""
                fi
                echo "    \"$key\" = lib.mkDefault $val;"
            fi
        done
        echo "  };"
        echo "}"
    } > "$full_file_path"
done

# 2. Master default.nix
{
    echo "{ lib, ... }:"
    echo "{"
    echo "  imports = ["
    find "$TEMP_EXPORT" -name "*.nix" ! -name "default.nix" -printf "    ./%P\n" | sort
    echo "  ];"
    echo "}"
} > "$TEMP_EXPORT/default.nix"

# 3. Apply and Sync (The sudo part)
echo "🔄 Synchronizing to $TARGET_DIR..."
sudo mkdir -p "$TARGET_DIR"
# Sync files, then immediately ensure THEY ARE OWNED BY YOU
sudo rsync -av --delete "$TEMP_EXPORT/" "$TARGET_DIR/"
sudo chown -R "$CURRENT_USER":users "$TARGET_DIR"

rm -rf "$TEMP_EXPORT"
rm "$FULL_DUMP"

# 4. Git Logic (Running as YOU)
cd "$REPO_ROOT" || exit
git add "$TARGET_DIR"
if ! git diff --cached --quiet; then
    git commit -m "dconf-export: $TIMESTAMP"
    echo "☁️  Pushing to Git..."
    git push
    echo "✅ Success!"
else
    echo "✅ No changes to push."
fi