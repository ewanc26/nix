#!/usr/bin/env bash
# Wallpaper diagnostic script for KDE Plasma

echo "=========================================="
echo "KDE PLASMA WALLPAPER DIAGNOSTIC"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Check if wallpaper file exists
echo "1. Checking wallpaper file..."
WALLPAPER_PATH="$HOME/.config/nix-config/wallpapers/wallpaper.jpg"
if [ -f "$WALLPAPER_PATH" ]; then
    echo -e "${GREEN}✓${NC} Wallpaper file exists: $WALLPAPER_PATH"
    ls -lh "$WALLPAPER_PATH"
    file "$WALLPAPER_PATH"
else
    echo -e "${RED}✗${NC} Wallpaper file NOT found: $WALLPAPER_PATH"
fi
echo ""

# 2. Check if file is in nix store
echo "2. Checking if wallpaper is in Nix store..."
NIX_WALLPAPER=$(find /nix/store -name "wallpaper.jpg" 2>/dev/null | grep -v "\.drv$" | head -1)
if [ -n "$NIX_WALLPAPER" ]; then
    echo -e "${GREEN}✓${NC} Found in Nix store: $NIX_WALLPAPER"
else
    echo -e "${YELLOW}⚠${NC} Not found in Nix store (may be normal)"
fi
echo ""

# 3. Check plasma configuration files
echo "3. Checking KDE Plasma config files..."
PLASMA_CONFIG="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [ -f "$PLASMA_CONFIG" ]; then
    echo -e "${GREEN}✓${NC} Config file exists: $PLASMA_CONFIG"
    echo "   Searching for wallpaper settings..."
    grep -i "wallpaper\|image" "$PLASMA_CONFIG" | head -20
else
    echo -e "${RED}✗${NC} Config file NOT found: $PLASMA_CONFIG"
fi
echo ""

# 4. Check plasmashell wallpaper plugin config
echo "4. Checking wallpaper plugin config..."
WALLPAPER_CONFIG="$HOME/.config/plasmarc"
if [ -f "$WALLPAPER_CONFIG" ]; then
    echo -e "${GREEN}✓${NC} plasmarc exists"
    grep -A 5 "\[Wallpaper\]" "$WALLPAPER_CONFIG" || echo "   No [Wallpaper] section found"
else
    echo -e "${YELLOW}⚠${NC} plasmarc not found"
fi
echo ""

# 5. Check if plasma-manager generated config
echo "5. Checking Home Manager generation..."
CURRENT_GEN=$(readlink -f ~/.local/state/home-manager/gcroots/current-home)
if [ -n "$CURRENT_GEN" ]; then
    echo -e "${GREEN}✓${NC} Current generation: $CURRENT_GEN"
    
    # Look for plasma configuration in the generation
    if [ -d "$CURRENT_GEN/home-files/.config" ]; then
        echo "   Searching for plasma configs in generation..."
        find "$CURRENT_GEN/home-files/.config" -name "*plasma*" -o -name "*wallpaper*" 2>/dev/null | head -10
    fi
else
    echo -e "${YELLOW}⚠${NC} Could not find current Home Manager generation"
fi
echo ""

# 6. Check kwriteconfig5 / kreadconfig5
echo "6. Checking current plasma wallpaper setting..."
if command -v kreadconfig5 &> /dev/null; then
    echo "   Using kreadconfig5..."
    # Try different possible locations
    kreadconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group Wallpaper --group org.kde.image --group General --key Image 2>/dev/null || echo "   (Could not read with kreadconfig5 method 1)"
else
    echo -e "${YELLOW}⚠${NC} kreadconfig5 not available"
fi
echo ""

# 7. Check if plasma-manager service ran
echo "7. Checking systemd user services..."
if systemctl --user list-units --all | grep -q plasma-manager; then
    echo -e "${GREEN}✓${NC} plasma-manager service found"
    systemctl --user status plasma-manager-apply.service --no-pager -l || true
else
    echo -e "${YELLOW}⚠${NC} No plasma-manager service found"
fi
echo ""

# 8. Check desktop containments
echo "8. Checking desktop containments..."
if [ -f "$PLASMA_CONFIG" ]; then
    echo "   Containment IDs:"
    grep "^\[Containments\]\[" "$PLASMA_CONFIG" | head -10
fi
echo ""

# 9. Direct search in all plasma configs
echo "9. Searching ALL plasma config files for wallpaper references..."
find ~/.config -name "*plasma*" -type f 2>/dev/null | while read config; do
    if grep -qi "wallpaper\|image.*jpg\|image.*png" "$config" 2>/dev/null; then
        echo -e "${GREEN}Found in:${NC} $config"
        grep -i "wallpaper\|image.*jpg\|image.*png" "$config" | head -5
        echo ""
    fi
done
echo ""

# 10. Check if the path in nix config is valid
echo "10. Checking Nix configuration..."
if [ -f "$HOME/.config/nix-config/settings/plasma/default.nix" ]; then
    echo -e "${GREEN}✓${NC} Plasma config exists"
    echo "   Wallpaper line:"
    grep -A 1 "wallpaper" "$HOME/.config/nix-config/settings/plasma/default.nix" | head -3
else
    echo -e "${RED}✗${NC} Plasma config not found"
fi
echo ""

echo "=========================================="
echo "DIAGNOSTIC COMPLETE"
echo "=========================================="
echo ""
echo "NEXT STEPS:"
echo "1. If wallpaper file exists but isn't being applied:"
echo "   - Try: systemctl --user restart plasma-plasmashell"
echo "   - Or log out and back in"
echo ""
echo "2. If plasma-manager service failed:"
echo "   - Check: journalctl --user -u plasma-manager-apply.service"
echo ""
echo "3. If wallpaper is not in any config files:"
echo "   - Rebuild: sudo nixos-rebuild switch"
echo "   - Then log out/in"
