# Wallpapers

Desktop wallpaper images used across the configuration.

## Current Wallpaper

- `wallpaper.jpg` — default desktop background and lock screen

## Usage

The wallpaper is referenced directly in `home/programs/gnome.nix`:

```nix
"org/gnome/desktop/background" = {
  picture-uri      = "file://${../../wallpapers/wallpaper.jpg}";
  picture-uri-dark = "file://${../../wallpapers/wallpaper.jpg}";
};
```

Applied automatically on every Home Manager rebuild.

## Changing the Wallpaper

1. Replace `wallpapers/wallpaper.jpg` with your image (keep the same filename), or
2. Add a new image and update the path in `home/programs/gnome.nix`
3. Rebuild: `sudo nixos-rebuild switch --flake .#laptop`

## Recommended Format

- **Format:** JPG or PNG
- **Resolution:** 1920×1080 or higher
