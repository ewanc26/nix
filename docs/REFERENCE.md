# NixOS Configuration Reference Card

## File Structure
```
├── flake.nix
├── flake.lock
├── .sops.yaml                # sops age key and creation rules
├── hosts/
│   ├── laptop/               # NixOS desktop (Dell Inspiron 3501)
│   ├── server/               # NixOS headless server
│   └── macmini/              # macOS (nix-darwin)
├── modules/
│   ├── options.nix           # ⭐ All option declarations + defaults
│   ├── common.nix            # Base NixOS settings
│   ├── desktop.nix           # KDE Plasma 6 + SDDM
│   ├── packages.nix          # Desktop applications
│   ├── services.nix          # Printing, Bluetooth, etc.
│   ├── gaming.nix            # Steam, Gamemode
│   ├── users.nix             # User accounts
│   ├── caddy.nix             # Caddy web server
│   ├── pds.nix               # Bluesky PDS service
│   ├── matrix.nix            # Matrix Synapse
│   ├── forgejo.nix           # Forgejo git forge
│   ├── cloudflare-tunnel.nix # Cloudflare tunnel
│   ├── ssh-keys.nix          # Public key registry
│   ├── server/               # Headless server modules
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
│   ├── default.nix           # ⭐ Home-manager entry point (all hosts)
│   ├── programs/             # git, zsh, ssh, starship, vscode, kde, ...
│   └── scripts/              # verify-tailscale-ssh, update-all, update-everything, relts
├── secrets/
│   ├── setup.sh              # Key management helper
│   └── *.env / *.json / ...  # sops-encrypted secret files (safe to commit)
├── settings/
│   ├── darwin/               # macOS system.defaults (Dock, Finder, trackpad, etc.)
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
| `update-all` | Update flake inputs + rebuild |
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
| Username / email | `modules/options.nix` → `user.*` defaults |
| Timezone / locale | `modules/options.nix` → `timeZone` / `locale` |
| Add package (Linux) | `modules/options.nix` → `packages.common` or `packages.desktop` |
| Add package (macOS) | `modules/options.nix` → `packages.darwin` |
| Add Homebrew cask | `modules/options.nix` → `darwin.homebrew.casks` |
| Theme / fonts | `modules/options.nix` → `desktop.*` |
| KDE Plasma settings | `settings/plasma/default.nix` + `home/programs/kde.nix` |
| macOS system defaults | `settings/darwin/default.nix` |
| Toggle desktop mode | `hosts/<n>/default.nix` → `myConfig.isDesktop = true` |
| Enable gaming | `hosts/laptop/default.nix` → `myConfig.gaming.enable = true` |
| Enable server service | `hosts/server/default.nix` → `myConfig.services.<n>.enable = true` |
| Firewall ports | `modules/options.nix` → `server.firewall.allowedTCPPorts` |
| SSH hosts | `home/programs/ssh.nix` → `internalHosts` |
| SSH public keys | `modules/ssh-keys.nix` |
| Wallpaper | `wallpapers/wallpaper.jpg` |

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

## Secrets

Secrets are encrypted with [sops](https://github.com/getsops/sops) using age keys. Encrypted files live in `secrets/` and are safe to commit. The key inventory and creation rules are in `.sops.yaml`.

```bash
sops secrets/pds.env               # Edit a secret
sops --encrypt secrets/new.env > secrets/new.env   # Create a new secret
sops updatekeys secrets/pds.env    # Re-encrypt after adding a host key
```

See [secrets.md](secrets.md) for full documentation.

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
