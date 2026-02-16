# NixOS Configuration Reference Card

## File Structure
```
├── flake.nix
├── flake.lock
├── hosts/
│   ├── laptop/               # NixOS desktop (Dell Inspiron 3501)
│   ├── server/               # NixOS headless server
│   └── macmini/              # macOS (nix-darwin)
├── modules/
│   ├── common.nix            # Base NixOS settings
│   ├── desktop.nix           # KDE Plasma 6 + SDDM
│   ├── packages.nix          # Desktop applications
│   ├── services.nix          # Printing, Bluetooth, etc.
│   ├── gaming.nix            # Steam, Gamemode
│   ├── users.nix             # User accounts
│   ├── caddy.nix             # Caddy web server
│   ├── pds.nix               # Bluesky PDS service
│   ├── ssh-keys.nix          # Public key registry
│   ├── server/               # Headless server modules
│   │   ├── default.nix
│   │   ├── firewall.nix
│   │   ├── intrusion.nix     # fail2ban
│   │   ├── ssh.nix
│   │   └── ...
│   └── darwin/               # macOS-specific modules
│       ├── common.nix
│       ├── packages.nix
│       ├── homebrew.nix
│       └── system.nix
├── profiles/
│   ├── server-base.nix
│   └── server-hardened.nix
├── home/
│   ├── home.nix
│   ├── programs/             # git, zsh, ssh, starship, vscode, kde, ...
│   └── scripts/              # verify-tailscale-ssh, update-all, update-everything, relts
├── lib/
│   ├── default.nix           # cfgLib helpers
│   └── USAGE.md
├── secrets/
│   ├── secrets.nix           # age public key mappings
│   ├── setup.sh              # Key management helper
│   └── age/*.age             # Encrypted secret files
├── settings/
│   ├── config.nix            # Entry point
│   ├── config/               # ⭐ Edit here — one file per domain
│   ├── darwin/               # macOS system defaults
│   └── plasma/               # KDE Plasma declarative settings
├── tools/                    # Rust maintenance tools
│   └── src/bin/              # health-check, flake-bump, gen-diff
└── wallpapers/
```

## Essential Commands

| Command | Description |
|---|---|
| `nrs` | Rebuild and switch (shell alias) |
| `nrt` | Test build without switching |
| `nrb` | Build for next boot (NixOS only) |
| `update` | Update flake inputs + rebuild |
| `cleanup` | Garbage collect old generations |
| `health-check` | Pre-build validation |
| `gen-diff` | Compare generations |
| `nix flake check` | Check for errors |
| `verify-tailscale-ssh` | Test Tailscale SSH connectivity |

## Remote Rebuild (one-liner)

```bash
# Rebuild local then remote in one shot
nrs && ssh laptop 'cd ~/.config/nix-config && sudo nixos-rebuild switch --flake .#laptop'
```

## Quick Edits

| What | Where |
|---|---|
| Username / email | `settings/config/user.nix` |
| Add package (Linux) | `settings/config/packages.nix` |
| Add package (macOS) | `settings/config/darwin.nix` → `packages` |
| Add Homebrew cask | `settings/config/darwin.nix` → `homebrew.casks` |
| Theme / fonts | `settings/config/desktop.nix` |
| KDE Plasma settings | `settings/plasma/default.nix` + `home/programs/kde.nix` |
| Shell aliases | `settings/config/shell.nix` |
| Git settings | `settings/config/git.nix` |
| VS Code | `settings/config/development.nix` |
| Wallpaper | `wallpapers/wallpaper.jpg` |
| Firewall ports | `settings/config/server.nix` |
| SSH hosts | `home/programs/ssh.nix` → `internalHosts` |
| SSH public keys | `modules/ssh-keys.nix` |

## Hardware (laptop)
- **Model**: Dell Inspiron 3501
- **CPU**: Intel Core i3-1115G4 (Tiger Lake, 11th Gen)
- **RAM**: 8 GB DDR4-3200
- **Storage**: 256 GB NVMe SSD
- **GPU**: Intel UHD Graphics (Xe)
- **WiFi**: Intel Wi-Fi 6 AX201

## Hardware (macmini)
- **Model**: Apple Mac Mini (M2, 2023)
- **CPU**: Apple M2 (8-core)
- **RAM**: 16 GB unified
- **GPU**: Apple M2 (10-core)

## SSH / Tailscale

All inter-host SSH goes through Tailscale (`tailscale nc` ProxyCommand):
```bash
ssh laptop    # → Tailscale → laptop
ssh server    # → Tailscale → server
ssh macmini   # → Tailscale → macmini (self — usually skipped)
```

macOS binary path: `/Applications/Tailscale.app/Contents/MacOS/Tailscale`

## Emergency Recovery

```bash
# Rollback active generation (NixOS)
sudo nixos-rebuild switch --rollback

# From GRUB: select "NixOS — All configurations" → pick older generation

# From installer (chroot)
sudo mount /dev/nvme0n1p2 /mnt
sudo mount /dev/nvme0n1p1 /mnt/boot
sudo nixos-enter
nixos-rebuild switch --rollback
```
