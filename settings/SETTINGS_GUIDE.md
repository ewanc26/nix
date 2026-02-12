# Settings Management Guide

This configuration uses settings files that are **automatically applied** on every system activation.

## How It Works

### GNOME (Linux)

**File Structure:**
```
settings/gnome/
├── default.nix          # Imports dconf settings
└── dconf-settings.nix   # Your GNOME preferences
```

**Configuration Flow:**
1. `home/programs/gnome.nix` imports `settings/gnome/default.nix`
2. `settings/gnome/default.nix` imports `dconf-settings.nix`
3. Settings are automatically applied via dconf on every Home Manager activation

**Exporting Your Current Settings:**
```bash
./settings/gnome-export.sh
```
This will export your current GNOME dconf settings to `settings/gnome/dconf-settings.nix`.

### macOS (Darwin)

**File Structure:**
```
settings/darwin/
├── defaults.nix         # Your macOS system defaults
└── domains/             # Individual domain settings
```

**Configuration Flow:**
1. `modules/darwin/system.nix` imports `settings/darwin/defaults.nix`
2. Settings are automatically applied via `system.defaults` on every darwin-rebuild

**Exporting Your Current Settings:**
```bash
./settings/darwin-export.sh
```
This will export your current macOS defaults to `settings/darwin/defaults.nix`.

## Making Changes

### Method 1: Through the GUI/System Preferences (Recommended)

1. Change settings through GNOME Settings or macOS System Preferences
2. Export the new settings:
   - **GNOME**: Run `./settings/gnome-export.sh`
   - **macOS**: Run `./settings/darwin-export.sh`
3. Commit the changes to git
4. Rebuild your system:
   - **GNOME**: `sudo nixos-rebuild switch --flake .#laptop`
   - **macOS**: `darwin-rebuild switch --flake .#macmini`

### Method 2: Edit Settings Files Directly

1. Edit the settings file directly:
   - **GNOME**: `settings/gnome/dconf-settings.nix`
   - **macOS**: `settings/darwin/defaults.nix`
2. Commit and rebuild your system

## Important Notes

- **UI preferences are NOT encrypted** - they're just personal settings, not secrets
- **Actual secrets** (passwords, API keys, SSH keys) belong in `secrets/` and use ragenix
- Settings are version controlled and consistent across rebuilds
- Changes made through GUI are the source of truth (after export)

## File Locations

### Settings Files
- `settings/gnome/dconf-settings.nix` - GNOME dconf settings
- `settings/darwin/defaults.nix` - macOS system defaults

### Settings Modules
- `settings/gnome/default.nix` - GNOME settings loader
- `settings/darwin/defaults.nix` - Darwin settings (self-contained)

### Import Locations
- `home/programs/gnome.nix` - Imports GNOME settings for Home Manager
- `modules/darwin/system.nix` - Imports Darwin settings for nix-darwin

## Troubleshooting

**Settings not applying?**
- Make sure the settings file exists
- Check for valid Nix syntax
- Check system activation output for errors
- Try rebuilding with --show-trace for more details

**Want to reset to defaults?**
- Simply change settings through GUI and export again
- Or edit the settings file directly
