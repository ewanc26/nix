# Settings Management Guide

This configuration uses encrypted settings files that are **automatically applied** on every system activation. No hardcoded defaults are used.

## How It Works

### GNOME (Linux)

**File Structure:**
```
settings/gnome/
├── default.nix          # Imports encrypted dconf settings
└── *.age                # Encrypted dconf configuration
```

**Configuration Flow:**
1. `home/programs/gnome.nix` imports `settings/gnome/default.nix`
2. `settings/gnome/default.nix` imports the encrypted dconf settings from `secrets/gnome-dconf-settings.age`
3. Settings are automatically applied via dconf on every Home Manager activation
4. **No hardcoded defaults** - all settings come from the encrypted file

**Exporting Your Current Settings:**
```bash
./settings/gnome-export.sh
```
This will export your current GNOME dconf settings to a Nix file that can be encrypted and used.

### macOS (Darwin)

**File Structure:**
```
settings/darwin/
├── defaults.nix         # Imports encrypted system defaults
└── *.age                # Encrypted defaults configuration
```

**Configuration Flow:**
1. `modules/darwin/system.nix` imports `settings/darwin/defaults.nix`
2. `settings/darwin/defaults.nix` imports the encrypted settings from `secrets/darwin-defaults-settings.age`
3. Settings are automatically applied via `system.defaults` on every darwin-rebuild
4. **No hardcoded defaults** - all settings come from the encrypted file

**Exporting Your Current Settings:**
```bash
./settings/darwin-export.sh
```
This will export your current macOS defaults to a Nix file that can be encrypted and used.

## Making Changes

### Method 1: Through the GUI/System Preferences (Recommended)

1. Change settings through GNOME Settings or macOS System Preferences
2. Export the new settings:
   - **GNOME**: Run `./settings/gnome-export.sh`
   - **macOS**: Run `./settings/darwin-export.sh`
3. Encrypt the new settings file (see secrets/README.md)
4. Rebuild your system:
   - **GNOME**: `sudo nixos-rebuild switch --flake .#laptop`
   - **macOS**: `darwin-rebuild switch --flake .#macmini`

### Method 2: Edit Encrypted Files Directly

1. Decrypt the settings file:
   ```bash
   cd secrets
   ragenix -e <settings-file>.age
   ```
2. Make your changes
3. Save and rebuild your system

## Important Notes

- **Settings are always loaded from encrypted files** on every activation
- **No manual defaults** are set in the configuration files
- This ensures:
  - Your settings are encrypted and secure
  - Settings are consistent across rebuilds
  - Changes made through GUI are the source of truth (after export)
  - Version controlled settings history

## File Locations

### Encrypted Settings Files
- `secrets/gnome-dconf-settings.age` - GNOME dconf settings
- `secrets/darwin-defaults-settings.age` - macOS system defaults

### Settings Modules
- `settings/gnome/default.nix` - GNOME settings loader
- `settings/darwin/defaults.nix` - Darwin settings loader

### Import Locations
- `home/programs/gnome.nix` - Imports GNOME settings for Home Manager
- `modules/darwin/system.nix` - Imports Darwin settings for nix-darwin

## Troubleshooting

**Settings not applying?**
- Make sure the encrypted file exists and is readable
- Check that you've added your SSH key to `secrets/secrets.nix`
- Verify the decrypted file has valid Nix syntax
- Check system activation output for errors

**Want to reset to defaults?**
- Simply change settings through GUI and export again
- Or remove the encrypted file and create a new one with desired defaults
