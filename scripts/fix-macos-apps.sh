#!/bin/bash

echo "==================================="
echo "macOS Apps Auto-Fix Script"
echo "==================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CONFIG_DIR="$HOME/.config/nix-config"
CASKS_FILE="$CONFIG_DIR/modules/options.nix"

# Extract cask list from modules/options.nix (darwin.homebrew.casks default list)
CASKS=$(awk '
  /homebrew = \{/ { in_hb=1 }
  in_hb && /casks = mkOption/ { in_casks=1 }
  in_casks && /default = \[/ { in_list=1; next }
  in_list && /\];/ { exit }
  in_list && /"/ { gsub(/[[:space:]]*"/, ""); gsub(/".*/, ""); if (length > 0) print }
' "$CASKS_FILE")

echo "Checking all Homebrew cask apps from config..."
echo ""

ISSUES_FOUND=0
FIXED=0

# Function to get app path from cask name
get_app_path() {
    local cask="$1"
    case "$cask" in
        logitune) echo "/Applications/Logi Tune.app" ;;
        logitech-options) echo "/Applications/Logitech Options.app" ;;
        microsoft-excel) echo "/Applications/Microsoft Excel.app" ;;
        microsoft-powerpoint) echo "/Applications/Microsoft PowerPoint.app" ;;
        microsoft-teams) echo "/Applications/Microsoft Teams.app" ;;
        microsoft-word) echo "/Applications/Microsoft Word.app" ;;
        netnewswire) echo "/Applications/NetNewsWire.app" ;;
        prismlauncher) echo "/Applications/PrismLauncher.app" ;;
        spotify) echo "/Applications/Spotify.app" ;;
        tailscale-app) echo "/Applications/Tailscale.app" ;;
        element) echo "/Applications/Element.app" ;;
        *) echo "" ;;
    esac
}

# Check and fix each app
while IFS= read -r cask; do
    app_path=$(get_app_path "$cask")
    
    if [ -z "$app_path" ] || [ ! -d "$app_path" ]; then
        continue
    fi
    
    echo -n "Checking $(basename "$app_path")... "
    
    # Check for invalid signature
    if spctl -a -vv "$app_path" 2>&1 | grep -qi "invalid"; then
        echo -e "${RED}INVALID SIGNATURE${NC}"
        echo "  → Reinstalling $cask..."
        
        if brew reinstall --cask "$cask" 2>/dev/null; then
            echo -e "  ${GREEN}✅ Fixed${NC}"
            FIXED=$((FIXED + 1))
        else
            echo -e "  ${RED}❌ Failed to reinstall${NC}"
        fi
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        continue
    fi
    
    # Check for quarantine
    if xattr -l "$app_path" 2>/dev/null | grep -q quarantine; then
        echo -e "${YELLOW}HAS QUARANTINE${NC}"
        echo "  → Removing quarantine..."
        
        if sudo xattr -rd com.apple.quarantine "$app_path" 2>/dev/null; then
            echo -e "  ${GREEN}✅ Fixed${NC}"
            FIXED=$((FIXED + 1))
        else
            echo -e "  ${RED}❌ Failed${NC}"
        fi
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        continue
    fi
    
    echo -e "${GREEN}✅ OK${NC}"
    
done <<< "$CASKS"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Issues found: $ISSUES_FOUND"
echo "Fixed: $FIXED"
echo ""

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}All apps are healthy! ✅${NC}"
else
    echo "Rebuilding Launch Services database..."
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -gc -R -apps u,s,l 2>/dev/null
    
    echo "Restarting Dock..."
    killall Dock 2>/dev/null
    
    echo ""
    echo -e "${GREEN}Done! Try opening your apps now.${NC}"
fi

echo ""
