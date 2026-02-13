#!/usr/bin/env bash
set -e

# --- CONFIGURATION ---
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SETTINGS_DIR="$REPO_ROOT/settings/darwin"
DEFAULTS_FILE="default.nix"
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')

# The core desktop environment domains
DESKTOP_DOMAINS=(
    "com.apple.dock"
    "com.apple.finder"
    "com.apple.screencapture"
    "com.apple.desktopservices"
    "com.apple.menuextra.clock"
    "com.apple.systemuiserver"
    "com.apple.AppleMultitouchTrackpad"
    "NSGlobalDomain"
)

echo "🍎 Exporting Desktop Settings with defaults2nix..."

TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR/exports"
mkdir -p "$SETTINGS_DIR/domains"

# 1. Run defaults2nix with filters to keep the config clean
echo "📥 Running defaults2nix..."
nix run github:joshryandavis/defaults2nix -- -split \
    -filter dates,state,uuids \
    -out "$TEMP_DIR/exports/"

# Start the Nix Module string
TEMP_COMBINED="$TEMP_DIR/combined.nix"
cat > "$TEMP_COMBINED" << 'EOF'
{ ... }:
{
  system.defaults.CustomUserPreferences = {
EOF

FOUND_COUNT=0

# 2. Match the exported files to our target list
for domain in "${DESKTOP_DOMAINS[@]}"; do
    # defaults2nix names files exactly as "domain.nix"
    EXPECTED_FILE="$TEMP_DIR/exports/$domain.nix"
    
    if [ -f "$EXPECTED_FILE" ]; then
        TARGET_FILE="$SETTINGS_DIR/domains/$domain.nix"
        cp "$EXPECTED_FILE" "$TARGET_FILE"
        
        # Add to the CustomUserPreferences set
        echo "    \"$domain\" = import ./domains/$domain.nix;" >> "$TEMP_COMBINED"
        FOUND_COUNT=$((FOUND_COUNT + 1))
        echo "    ✅ Captured: $domain"
    else
        # Fallback: Try a single-domain export if split skipped it
        echo "    🔍 $domain not in split export, trying direct capture..."
        if nix run github:joshryandavis/defaults2nix -- "$domain" -out "$SETTINGS_DIR/domains/$domain.nix" 2>/dev/null; then
             echo "    \"$domain\" = import ./domains/$domain.nix;" >> "$TEMP_COMBINED"
             FOUND_COUNT=$((FOUND_COUNT + 1))
             echo "    ✅ Captured (Direct): $domain"
        else
             echo "    ❌ Skipped: $domain (No data found)"
        fi
    fi
done

echo "  };" >> "$TEMP_COMBINED"
echo "}" >> "$TEMP_COMBINED"

# 3. Save the combined file (no encryption)
cp "$TEMP_COMBINED" "$SETTINGS_DIR/$DEFAULTS_FILE"

# 4. Git Sync
if git rev-parse --git-dir > /dev/null 2>&1; then
    cd "$REPO_ROOT"
    git add "$SETTINGS_DIR"
    git commit -m "darwin: update defaults via defaults2nix ($TIMESTAMP)" || true
fi

rm -rf "$TEMP_DIR"
echo "Done! 🎉 Successfully exported $FOUND_COUNT domains."
