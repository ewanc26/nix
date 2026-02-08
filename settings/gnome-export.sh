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

# Extract headers
HEADERS=$(grep '^\[.*\]$' "$FULL_DUMP" | tr -d '[]')

echo "✂️  Extracting blocks..."
for header in $HEADERS; do
    safe_name=$(echo "$header" | sed 's|/|-|g; s|:|--|g')
    full_file_path="$TEMP_EXPORT/${safe_name}.nix"
    
    # Extract the block for this header
    block_content=$(awk "/^\[$(echo "$header" | sed 's/\//\\\//g')\]/{flag=1;next}/^\[/{flag=0}NF==0{flag=0}flag" "$FULL_DUMP")

    [ -z "$block_content" ] && continue

    {
        echo "{ ... }:"
        echo "{"
        echo "  dconf.settings.\"$header\" = {"
        echo "$block_content" | while read -r line; do
            if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
                key="${BASH_REMATCH[1]}"
                val="${BASH_REMATCH[2]}"
                
# TYPE DETECTION LOGIC
                if [[ "$val" =~ ^[0-9]+$ || "$val" =~ ^[0-9]+\.[0-9]+$ ]]; then
                    # Numbers
                    echo "    \"$key\" = $val;"
                elif [[ "$val" == "true" || "$val" == "false" ]]; then
                    # Booleans
                    echo "    \"$key\" = $val;"
                elif [[ "$val" =~ ^\[.*\]$ ]] && [[ ! "$val" =~ "<" ]] && [[ ! "$val" =~ "(" ]]; then
                    # Simple Lists: [ "a" "b" ]
                    # We exclude < (Variants) and ( (Tuples)
                    clean_list=$(echo "$val" | sed "s/'/\"/g" | sed "s/,//g")
                    echo "    \"$key\" = $clean_list;"
                else
                    # Fallback: Strings, GVariants, and Tuples
                    # We strip outer ' ' and wrap the whole thing in " "
                    clean_val=$(echo "$val" | sed "s/^'//;s/'$//")
                    clean_val=$(echo "$clean_val" | sed 's/"/\\"/g')
                    
                    echo "    \"$key\" = \"$clean_val\";"
                fi
            fi
        done
        echo "  };"
        echo "}"
    } > "$full_file_path"
done

# 2. Master default.nix
{
    echo "{ ... }:"
    echo "{"
    echo "  imports = ["
    find "$TEMP_EXPORT" -name "*.nix" ! -name "default.nix" -printf "    ./%P\n" | sort
    echo "  ];"
    echo "}"
} > "$TEMP_EXPORT/default.nix"

# 3. Apply and Sync
echo "🔄 Synchronizing to $TARGET_DIR..."
sudo mkdir -p "$TARGET_DIR"
sudo rsync -av --delete "$TEMP_EXPORT/" "$TARGET_DIR/"
sudo chown -R "$CURRENT_USER":users "$TARGET_DIR"

rm -rf "$TEMP_EXPORT"
rm "$FULL_DUMP"

# 4. Git Logic (CRITICAL FOR FLAKES)
cd "$REPO_ROOT" || exit
# We must 'git add' so the flake sees the new files in the store
git add "$TARGET_DIR"

if ! git diff --cached --quiet; then
  echo "📝 Committing changes..."
  git commit -m "dconf-export: $TIMESTAMP"
  echo "✅ Success! Files staged and committed."
else
  echo "✅ No changes detected."
fi