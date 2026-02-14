# Settings Export Guide

GNOME and macOS settings are exported from the live system and committed to version control, so every rebuild restores your exact preferences.

## GNOME (Linux)

### How it works

1. `home/programs/gnome.nix` imports `settings/gnome/default.nix`
2. `settings/gnome/default.nix` imports `dconf-settings.nix` (auto-generated)
3. Config-driven overrides (theme, fonts, extensions) layer on top
4. Settings are applied via dconf on every Home Manager activation

### Exporting your current settings

```bash
./settings/gnome-export.sh
```

Writes your current GNOME state to `settings/gnome/dconf-settings.nix`.

### Applying changes

```bash
sudo nixos-rebuild switch --flake .#laptop
```

## macOS (Darwin)

### How it works

1. `modules/darwin/system.nix` imports `settings/darwin/default.nix`
2. `settings/darwin/default.nix` loads all domain files from `settings/darwin/domains/`
3. Applied via `system.defaults.CustomUserPreferences` on every `darwin-rebuild`

### Exporting your current settings

```bash
./settings/darwin-export.sh
```

Writes your current macOS defaults to `settings/darwin/domains/`.

### Applying changes

```bash
sudo darwin-rebuild switch --flake .#macmini
```

## Workflow

### GUI-first (recommended)

1. Make changes through GNOME Settings or macOS System Settings
2. Run the export script
3. Commit to git
4. Rebuild

### Edit-first

1. Edit `settings/gnome/dconf-settings.nix` or a file in `settings/darwin/domains/` directly
2. Commit to git
3. Rebuild

## Notes

- **UI preferences are not secrets** — these files are plain Nix, safe to commit
- **Actual secrets** (passwords, API keys) belong in `secrets/` — see [secrets.md](secrets.md)
- Config-driven values (theme, fonts, extension list) live in `settings/config/desktop.nix`, not in the exported files — edit those directly rather than re-exporting
