# GNOME Settings - Modular Structure

This directory contains all GNOME desktop settings organized in a granular, modular structure.

## Structure

```
settings/gnome/
├── default.nix              # Main aggregator - imports all modules
├── desktop/                 # Desktop-level settings
│   ├── interface/          # UI theme, colors, hot corners
│   ├── wm/                 # Window manager preferences & keybindings
│   ├── peripherals/        # Mouse, touchpad, keyboard
│   ├── background/         # Desktop wallpaper
│   ├── screensaver/        # Lock screen wallpaper
│   ├── notifications/      # Notification settings
│   ├── privacy/            # Privacy settings
│   ├── sound/              # Sound settings
│   └── a11y/               # Accessibility settings
├── shell/                   # GNOME Shell settings
│   ├── shell.nix           # Core shell settings
│   ├── extensions/         # Extension settings
│   └── keybindings/        # Shell keybindings
├── mutter/                  # Window manager (Mutter)
├── settings-daemon/         # GNOME settings daemon
└── applications/            # Application-specific settings
    ├── terminal/           # GNOME Terminal
    ├── nautilus/           # Files (Nautilus)
    ├── gedit/              # Text Editor
    ├── calculator/         # Calculator
    └── calendar/           # Calendar

## Usage

The main `gnome.nix` in `home/programs/` imports this entire structure:

```nix
{
  imports = [ ../../settings/gnome ];
}
```

## Updating Settings

To update your settings:

1. Make changes in GNOME
2. Re-export specific sections:
   ```bash
   dconf dump /org/gnome/desktop/interface/ | dconf2nix > desktop/interface/interface.nix
   ```
3. Fix the dconf path (change `""` to proper path like `"org/gnome/desktop/interface"`)
4. Rebuild your system

## Benefits

- **Granular control**: Each setting category in its own file
- **Easy to track**: Git shows exactly what changed
- **Selective imports**: Can comment out specific modules if needed
- **Clear organization**: Know exactly where each setting lives
- **Reusable**: Share specific modules across different systems

## Generated Files

All `.nix` files in subdirectories were generated via `dconf2nix`:
https://github.com/gvolpe/dconf2nix
