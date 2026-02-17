#!/usr/bin/env bash
# Check the actual containment wallpaper settings

echo "Checking wallpaper settings in containments..."
echo ""

CONFIG="/home/ewan/.config/plasma-org.kde.plasma.desktop-appletsrc"

# Find all containment IDs
CONTAINMENTS=$(grep "^\[Containments\]\[[0-9]*\]$" "$CONFIG" | grep -o "[0-9]*")

for id in $CONTAINMENTS; do
    echo "=== Containment $id ==="
    
    # Check if it's a desktop containment
    TYPE=$(grep -A 50 "^\[Containments\]\[$id\]$" "$CONFIG" | grep "^activityId=" | head -1)
    
    if [ -n "$TYPE" ]; then
        echo "Type: Desktop containment"
        echo ""
        echo "Wallpaper config:"
        # Get the wallpaper section
        sed -n "/^\[Containments\]\[$id\]\[Wallpaper\]/,/^\[/p" "$CONFIG" | head -30
        echo ""
    fi
done

echo ""
echo "=== Looking for Image= setting ==="
grep -n "^Image=" "$CONFIG" || echo "No Image= setting found!"
echo ""

echo "=== Current plasmarc wallpapers section ==="
grep -A 10 "\[Wallpapers\]" ~/.config/plasmarc
