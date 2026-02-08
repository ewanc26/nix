# NixOS Configuration Reference Card

## 📁 File Structure
```
├── flake.nix                 # Main flake entry point
├── configuration.nix          # Main system config
├── hardware-configuration.nix # Hardware-specific settings
├── modules/
│   ├── desktop.nix           # Desktop environment (GNOME)
│   ├── packages.nix          # System packages
│   ├── services.nix          # System services
│   └── gaming.nix            # Gaming (Steam, GameMode)
└── home/
    ├── home.nix              # Home Manager entry point
    └── programs/
        ├── git.nix           # Git config
        ├── zsh.nix           # Shell config
        ├── starship.nix      # Prompt config
        └── vscode.nix        # VSCode config
```

## ⚡ Essential Commands
| Command | Description |
|---------|-------------|
| `make switch` | Apply configuration changes |
| `make update` | Update flake inputs |
| `make clean` | Remove old generations |
| `make check` | Check for errors |
| `nrs` | Quick rebuild (alias) |
| `update` | Full update (alias) |
| `cleanup` | Clean old gens (alias) |

## 🎯 Quick Edits
| What | Where |
|------|-------|
| Add package | `modules/packages.nix` |
| Change DE | `modules/desktop.nix` |
| Shell aliases | `home/programs/zsh.nix` |
| Git settings | `home/programs/git.nix` |
| VSCode config | `home/programs/vscode.nix` |
| Power tuning | `hardware-configuration.nix` |
| Wallpaper | `home/programs/gnome.nix` |
| GNOME settings | `home/programs/gnome.nix` |

## 🔧 Hardware Info
- **Model**: Dell Inspiron 3501
- **CPU**: Intel i3-1115G4 (Tiger Lake)
- **RAM**: 8GB DDR4-3200
- **Storage**: 256GB NVMe SSD
- **GPU**: Intel UHD Graphics
- **WiFi**: Intel 9462AC
- **Battery**: 42Wh

## 📦 Installed Software
- **Shell**: zsh + starship
- **Browser**: Firefox
- **Editor**: VSCode
- **Communication**: Discord
- **Media**: Spotify
- **Gaming**: Steam, Prism Launcher
- **Tools**: git, fastfetch

## 🆘 Emergency
```bash
# Boot older generation (from boot menu)
# Check logs
journalctl -xe

# Rollback
sudo nix-env --rollback --profile /nix/var/nix/profiles/system

# Safe mode (from installer)
nixos-enter
nix-env --rollback --profile /nix/var/nix/profiles/system
```

## 📋 Before Installation
1. ⚠️ Update UUIDs in `hardware-configuration.nix`
2. ✏️ Set git name/email in `home/programs/git.nix`
3. 🔍 Review `TODO.md`
4. 📖 Read `README.md` installation section

## 🌟 Features
- ✅ Flakes-based configuration
- ✅ Home Manager integration
- ✅ Modular structure
- ✅ Power management (TLP)
- ✅ Intel graphics optimized
- ✅ Gaming ready (Steam + Minecraft)
- ✅ Development tools
- ✅ Complete documentation
