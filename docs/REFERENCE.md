# NixOS Configuration Reference Card

## File Structure
```
├── flake.nix
├── configuration.nix          # Legacy entry point
├── hosts/
│   ├── laptop/
│   ├── server/
│   └── macmini/
├── modules/
│   ├── desktop.nix
│   ├── packages.nix
│   ├── services.nix
│   ├── gaming.nix
│   └── darwin/
├── home/
│   ├── home.nix
│   └── programs/
│       ├── git.nix
│       ├── zsh.nix
│       ├── starship.nix
│       ├── vscode.nix
│       └── kde.nix
└── settings/
    └── config/                # ⭐ Edit here
        ├── user.nix
        ├── packages.nix
        ├── desktop.nix
        └── ...
```

## Essential Commands

| Command | Description |
|---|---|
| `sudo nixos-rebuild switch --flake .#laptop` | Apply configuration |
| `sudo nixos-rebuild boot --flake .#laptop` | Apply on next boot |
| `sudo nixos-rebuild test --flake .#laptop` | Test without making default |
| `nix flake update` | Update all flake inputs |
| `sudo nix-collect-garbage -d` | Remove old generations |
| `nix flake check` | Check for errors |
| `nrs` | Quick rebuild (shell alias) |
| `update` | Full update (shell alias) |
| `cleanup` | Collect garbage (shell alias) |

## Quick Edits

| What | Where |
|---|---|
| Username / email | `settings/config/user.nix` |
| Add package (Linux) | `settings/config/packages.nix` |
| Add package (macOS) | `settings/config/darwin.nix` → `packages` |
| Add Homebrew cask | `settings/config/darwin.nix` → `homebrew.casks` |
| Theme / fonts | `settings/config/desktop.nix` |
| KDE Plasma settings | `settings/plasma/default.nix` and `home/programs/kde.nix` |
| Shell aliases | `settings/config/shell.nix` |
| Git settings | `settings/config/git.nix` |
| VS Code | `settings/config/development.nix` |
| Wallpaper | `wallpapers/wallpaper.jpg` |
| Firewall ports | `settings/config/server.nix` |

## Hardware (laptop)
- **Model**: Dell Inspiron 3501
- **CPU**: Intel i3-1115G4 (Tiger Lake)
- **RAM**: 8 GB DDR4-3200
- **Storage**: 256 GB NVMe SSD
- **GPU**: Intel UHD Graphics
- **WiFi**: Intel 9462AC

## Emergency Recovery
```bash
# Check logs
journalctl -xe

# Rollback active system generation
sudo nix-env --rollback --profile /nix/var/nix/profiles/system

# From installer (safe mode)
nixos-enter
nix-env --rollback --profile /nix/var/nix/profiles/system
```
