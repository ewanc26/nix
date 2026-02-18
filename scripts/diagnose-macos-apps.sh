#!/bin/bash

echo "==================================="
echo "macOS Apps Diagnostic Script"
echo "==================================="
echo ""

# Get list of Homebrew casks from nix config
CONFIG_DIR="$HOME/.config/nix-config"
CASKS_FILE="$CONFIG_DIR/modules/options.nix"

# Extract cask list from modules/options.nix (darwin.homebrew.casks default list)
echo "Reading cask list from config..."
CASKS=$(awk '
  /homebrew = \{/ { in_hb=1 }
  in_hb && /casks = mkOption/ { in_casks=1 }
  in_casks && /default = \[/ { in_list=1; next }
  in_list && /\];/ { exit }
  in_list && /"/ { gsub(/[[:space:]]*"/, ""); gsub(/".*/, ""); if (length > 0) print }
' "$CASKS_FILE")

echo ""
echo "Found casks in config:"
echo "$CASKS" | sed 's/^/  - /'
echo ""

# Function to check an app
check_app() {
    local cask_name="$1"
    local app_name="$2"
    local app_path="/Applications/$app_name"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Checking: $app_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if app exists
    if [ ! -d "$app_path" ]; then
        echo "❌ NOT FOUND at $app_path"
        
        # Try to find it elsewhere
        echo "   Searching system..."
        local found=$(mdfind "kMDItemDisplayName == '$app_name'" 2>/dev/null | head -1)
        if [ -n "$found" ]; then
            echo "   ℹ️  Found at: $found"
            app_path="$found"
        else
            echo "   ❌ Not found anywhere on system"
            return 1
        fi
    else
        echo "✅ Found at: $app_path"
    fi
    
    # Check quarantine
    if xattr -l "$app_path" 2>/dev/null | grep -q quarantine; then
        echo "❌ HAS quarantine attribute"
        echo "   Fix: sudo xattr -rd com.apple.quarantine '$app_path'"
    else
        echo "✅ No quarantine attribute"
    fi
    
    # Check executable
    local exe_path=$(find "$app_path/Contents/MacOS" -type f -perm +111 2>/dev/null | head -1)
    if [ -n "$exe_path" ]; then
        echo "✅ Executable found: $(basename "$exe_path")"
    else
        echo "❌ No executable found"
    fi
    
    # Check Gatekeeper/signature
    local spctl_output=$(spctl -a -vv "$app_path" 2>&1)
    if echo "$spctl_output" | grep -q "accepted"; then
        echo "✅ Gatekeeper: accepted"
    elif echo "$spctl_output" | grep -qi "invalid"; then
        echo "❌ Gatekeeper: INVALID SIGNATURE"
        echo "   $(echo "$spctl_output" | grep -i invalid)"
        echo "   Fix: brew reinstall --cask $cask_name"
    elif echo "$spctl_output" | grep -qi "rejected"; then
        echo "⚠️  Gatekeeper: rejected (may need manual approval)"
    else
        echo "⚠️  Gatekeeper: $spctl_output"
    fi
    
    # Check Launch Services
    if /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump 2>/dev/null | grep -q "$(basename "$app_path" .app)"; then
        echo "✅ Registered with Launch Services"
    else
        echo "⚠️  NOT registered with Launch Services"
    fi
    
    echo ""
}

# Check each cask
# Map cask names to app names (common patterns)
while IFS= read -r cask; do
    case "$cask" in
        logitune) check_app "$cask" "Logi Tune.app" ;;
        logitech-options) check_app "$cask" "Logitech Options.app" ;;
        microsoft-excel) check_app "$cask" "Microsoft Excel.app" ;;
        microsoft-powerpoint) check_app "$cask" "Microsoft PowerPoint.app" ;;
        microsoft-teams) check_app "$cask" "Microsoft Teams.app" ;;
        microsoft-word) check_app "$cask" "Microsoft Word.app" ;;
        netnewswire) check_app "$cask" "NetNewsWire.app" ;;
        prismlauncher) check_app "$cask" "PrismLauncher.app" ;;
        spotify) check_app "$cask" "Spotify.app" ;;
        tailscale-app) check_app "$cask" "Tailscale.app" ;;
        element) check_app "$cask" "Element.app" ;;
        *) 
            # Generic check - try to guess the app name
            app_name=$(echo "$cask" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1' | sed 's/ //g').app
            check_app "$cask" "$app_name"
            ;;
    esac
done <<< "$CASKS"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary of Issues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for any apps with invalid signatures
echo "Apps with invalid signatures (need reinstall):"
while IFS= read -r cask; do
    case "$cask" in
        spotify) app_path="/Applications/Spotify.app" ;;
        element) app_path="/Applications/Element.app" ;;
        tailscale-app) app_path="/Applications/Tailscale.app" ;;
        microsoft-excel) app_path="/Applications/Microsoft Excel.app" ;;
        microsoft-word) app_path="/Applications/Microsoft Word.app" ;;
        microsoft-powerpoint) app_path="/Applications/Microsoft PowerPoint.app" ;;
        *) continue ;;
    esac
    
    if [ -d "$app_path" ]; then
        if spctl -a -vv "$app_path" 2>&1 | grep -qi "invalid"; then
            echo "  ❌ $cask - run: brew reinstall --cask $cask"
        fi
    fi
done <<< "$CASKS"

echo ""
echo "Apps with quarantine attribute:"
while IFS= read -r cask; do
    case "$cask" in
        spotify) app_path="/Applications/Spotify.app" ;;
        element) app_path="/Applications/Element.app" ;;
        tailscale-app) app_path="/Applications/Tailscale.app" ;;
        *) continue ;;
    esac
    
    if [ -d "$app_path" ]; then
        if xattr -l "$app_path" 2>/dev/null | grep -q quarantine; then
            echo "  ⚠️  $cask - run: sudo xattr -rd com.apple.quarantine '$app_path'"
        fi
    fi
done <<< "$CASKS"

echo ""
echo "==================================="
echo "Quick Fixes"
echo "==================================="
echo ""
echo "Rebuild Launch Services database:"
echo "  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -gc -R -apps u,s,l"
echo ""
echo "Remove all quarantine attributes:"
echo "  sudo find /Applications -name '*.app' -maxdepth 1 -exec xattr -dr com.apple.quarantine {} \\;"
echo ""
echo "Rebuild nix-darwin config:"
echo "  darwin-rebuild switch --flake ~/.config/nix-config#macmini"
echo ""
