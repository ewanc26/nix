# Wallpapers

This directory contains wallpaper images used in the NixOS configuration.

## Current Wallpaper

- **wallpaper.jpg** - Default desktop background and lock screen wallpaper

## Usage

The wallpaper is automatically set as:
- Desktop background
- Lock screen background

Configuration is managed in `home/programs/gnome.nix`.

## Adding New Wallpapers

1. Add your wallpaper image to this directory
2. Update `home/programs/gnome.nix` to reference the new file
3. Run `make switch` to apply changes

## Format

Wallpapers should be in common image formats:
- JPG/JPEG
- PNG
- SVG (for vector wallpapers)

Recommended resolution: 1920x1080 or higher
