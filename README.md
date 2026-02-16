# Nix Configuration

Personal NixOS and nix-darwin configurations for managing multiple machines with a unified, centralized setup.

> **Note:** This is a personal configuration repository. While you're welcome to use it as reference, it's specifically tailored to my needs and setup.

> **🎯 Quick Start for Forkers:** Edit `settings/config/` files to customise everything — username, email, git settings, desktop theme, packages, and more.

## Key Features

✨ **Centralized Configuration** - All settings in `settings/config/` (single source of truth)
🔄 **DRY Principles** - Zero duplication, config imported once via `lib/`
🎯 **Easy Customization** - Change any setting in one file, applies everywhere
📦 **Multi-System** - Unified config for NixOS and macOS
🏠 **Unified Home Manager** - Same shell, git, SSH config across all systems
🔐 **Secrets Management** - Encrypted secrets with ragenix
🛠️ **Reusable Helpers** - Custom library with common functions

## Managed Systems

### macOS (nix-darwin) - PRIMARY

- **macmini** - Apple Silicon Mac Mini (M2, 16 GB) — Main daily driver

### Linux (NixOS) - SECONDARY

- **laptop** - Dell Inspiron 3501 with KDE Plasma 6 — Secondary workstation
- **server** - Minimal headless server — Bluesky PDS + hardened security (configuration complete, pending hardware deployment)

## Repository Structure

```
.
├── flake.nix                 # Main flake — defines all hosts
├── flake.lock                # Locked dependency versions
│
├── lib/                      # ⭐ Custom library (DRY helpers)
│   ├── default.nix           # cfgLib: reusable functions and config singleton
│   └── USAGE.md              # Developer guide
│
├── hosts/                    # Host-specific configurations
│   ├── laptop/               # Dell Inspiron 3501 (NixOS + KDE Plasma 6)
│   ├── server/               # Headless server (NixOS)
│   └── macmini/              # Mac Mini M2 (nix-darwin)
│
├── modules/                  # Reusable system modules
│   ├── common.nix            # Base NixOS settings
│   ├── desktop.nix           # KDE Plasma 6 + SDDM
│   ├── gaming.nix            # Steam + Gamemode
│   ├── packages.nix          # Desktop system packages
│   ├── services.nix          # Printing, Bluetooth, etc.
│   ├── users.nix             # User account configuration
│   ├── caddy.nix             # Caddy web server
│   ├── pds.nix               # Bluesky ATProto PDS
│   ├── ssh-keys.nix          # Public key registry for all hosts
│   ├── server/               # Headless server sub-modules
│   │   ├── default.nix       # Imports all server sub-modules
│   │   ├── firewall.nix
│   │   ├── intrusion.nix     # fail2ban
│   │   ├── ssh.nix           # sshd hardening
│   │   ├── hardware-health.nix
│   │   ├── maintenance.nix
│   │   ├── packages.nix
│   │   ├── services.nix
│   │   └── disable-noise.nix
│   └── darwin/               # macOS-specific modules
│       ├── common.nix
│       ├── homebrew.nix
│       ├── packages.nix
│       └── system.nix
│
├── profiles/                 # Reusable configuration profiles
│   ├── server-base.nix       # Base server config
│   └── server-hardened.nix   # Security hardening
│
├── home/                     # Home Manager (unified across all hosts)
│   ├── home.nix              # Main entry point
│   ├── configs/              # Raw config files (fastfetch, starship)
│   ├── programs/             # Per-program config (git, zsh, ssh, vscode, kde, ...)
│   └── scripts/              # Shell scripts on PATH
│       ├── verify-tailscale-ssh
│       ├── update-all
│       ├── update-everything
│       └── relts
│
├── settings/                 # ⭐ Centralized configuration — edit here
│   ├── config.nix            # Entry point (imports config/)
│   ├── config/               # All configurable values (one file per domain)
│   ├── plasma/               # KDE Plasma declarative settings
│   └── darwin/               # macOS system defaults
│
├── secrets/                  # Encrypted secrets (ragenix / age)
│   ├── secrets.nix           # Public key mappings (users + systems)
│   ├── setup.sh              # Key management helper
│   └── age/*.age             # Encrypted secret files
│
├── tools/                    # Rust maintenance tools
│   └── src/bin/              # health-check, flake-bump, gen-diff
├── wallpapers/
└── docs/
```

## DRY Architecture

This config uses a custom library (`lib/default.nix`) to eliminate repetition:

- **Single config import**: Config is imported once in `lib/`, not 20+ times across modules
- **Reusable helpers**: Common functions like `resolvePackages` and `mkAuthorizedKeys`
- **Zero boilerplate**: Every module automatically gets `cfgLib` via `specialArgs`

**Before (every module):**
```nix
{ config, pkgs, lib, ... }:
let
  cfg = import ../settings/config.nix;
  # Duplicate package resolution logic...
in
{ ... }
```

**After (using cfgLib):**
```nix
{ config, pkgs, lib, cfgLib, ... }:
let
  cfg = cfgLib.cfg;  # Config already imported!
  resolve = cfgLib.resolvePackages pkgs;  # Reusable helper
in
{ ... }
```

See [`lib/USAGE.md`](lib/USAGE.md) for details on using `cfgLib` helpers.

## Customization

**All settings live in `settings/config/`** — one file per domain, each small and focused.

```bash
# Examples
nano settings/config/user.nix       # Username, email, shell
nano settings/config/packages.nix   # Add/remove packages
nano settings/config/desktop.nix    # Theme, fonts, KDE settings
nano settings/config/darwin.nix     # macOS packages, Homebrew, keyboard
```

See [`settings/config/README.md`](settings/config/README.md) for the full map.

## Quick Start

### Prerequisites

- **NixOS:** Install NixOS on your system
- **macOS:** Install Nix via the [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)

### Initial Setup

```bash
mkdir -p ~/.config
curl -L https://github.com/ewanc26/nix/archive/refs/heads/main.tar.gz | tar -xz -C ~/.config
mv ~/.config/nix-main ~/.config/nix-config
cd ~/.config/nix-config
```

### Building

**NixOS:**
```bash
sudo nixos-rebuild switch --flake .#laptop
sudo nixos-rebuild switch --flake .#server
```

**macOS (first time):**
```bash
sudo nix run nix-darwin -- switch --flake .#macmini
```

**macOS (subsequent):**
```bash
sudo darwin-rebuild switch --flake .#macmini
```

## Settings Management

### KDE Plasma (Linux)

KDE Plasma settings are managed declaratively via `plasma-manager` in:
- `home/programs/kde.nix` - User-level Plasma configuration
- `settings/plasma/default.nix` - Desktop layout and behavior preferences

Changes are applied automatically on every Home Manager activation. To customize Plasma settings, edit these files directly rather than using the GUI.

### macOS

Export your current macOS defaults:

```bash
./settings/darwin-export.sh
```

## Maintenance

### Health Check (Recommended Before Building)

Run the health check script to validate your config before rebuilding:

```bash
# Compile the tools (one-time)
nix run .#tools -- --help

# Run health check
tools/target/release/health-check

# Or use the shell alias
health-check
```

The health check validates:
- Nix daemon is responding
- flake.lock is valid
- Config evaluates cleanly
- Age keys are present
- SSH keys are configured
- Disk space is sufficient
- Git tree status

### Update Flake Inputs

```bash
# Update all inputs
nix flake update

# Or use the helper
flake-bump

# Then rebuild
sudo nixos-rebuild switch --flake .#laptop   # or darwin-rebuild
```

### Garbage Collection

```bash
# NixOS (auto-runs weekly — see settings/config/nix.nix)
sudo nix-collect-garbage -d

# macOS
sudo nix-collect-garbage -d
sudo darwin-rebuild switch --flake .#macmini

# Or use the shell alias
cleanup
```

### Compare Generations

```bash
# See what changed between generations
gen-diff
```

## Secrets Management

Uses [ragenix](https://github.com/yaxitech/ragenix) for encrypted secrets.

- Secrets are encrypted with age using SSH keys
- Run `bash ./secrets/setup.sh` to initialise keys
- Master key stored at `~/.config/age/keys.txt` — **never commit this**
- Encrypted `.age` files are safe to commit
- Add new secrets to `settings/config/secrets.nix` → `files` list

See [docs/secrets.md](docs/secrets.md) for full details.

## Adding a New Host

See [docs/hosts.md](docs/hosts.md). Quick summary:

1. Create `hosts/YOUR-HOSTNAME/default.nix`
2. Generate hardware config: `nixos-generate-config --show-hardware-config`
3. Add entry to `flake.nix` → `nixosConfigurations`
4. Build: `sudo nixos-rebuild switch --flake .#YOUR-HOSTNAME`

## Inputs

| Input | Version |
|---|---|
| [nixpkgs](https://github.com/NixOS/nixpkgs) | nixos-25.11 |
| [home-manager](https://github.com/nix-community/home-manager) | release-25.11 |
| [nix-darwin](https://github.com/LnL7/nix-darwin) | nix-darwin-25.11 |
| [ragenix](https://github.com/yaxitech/ragenix) | latest |

## Unified Configuration Benefits

### Same Shell Everywhere
- **zsh** with identical aliases, history, and key bindings on all systems
- **SSH** client configuration unified (connection multiplexing, agent integration)
- **Git** settings consistent across NixOS and macOS
- **Starship** prompt looks the same everywhere

### Platform-Specific When Needed
- **macOS**: SSH keys loaded at login via LaunchAgent (`ssh-add --apple-load-keychain`)
- **Linux desktop**: SSH keys loaded at login via systemd + ksshaskpass/KWallet
- **Server**: No agent needed — SSH connections go *into* it, not out
- **KDE Plasma** settings only apply on Linux desktop
- **Homebrew** only on macOS

## Documentation

### Core Documentation
- [`lib/USAGE.md`](lib/USAGE.md) — using the cfgLib helpers *(for developers)*
- [`docs/settings-config.md`](docs/settings-config.md) — full settings reference *(start here)*
- [`docs/REFERENCE.md`](docs/REFERENCE.md) — quick-reference card

### Host Management
- [`docs/hosts.md`](docs/hosts.md) — hosts documentation index *(start here)*
- [`docs/hosts-overview.md`](docs/hosts-overview.md) — complete comparison of all three hosts
- [`docs/hosts-modification.md`](docs/hosts-modification.md) — how to modify and add hosts
- [`docs/hosts-laptop.md`](docs/hosts-laptop.md) — Dell Inspiron 3501 (NixOS + KDE Plasma 6)
- [`docs/hosts-server.md`](docs/hosts-server.md) — headless server + Bluesky PDS setup
- [`docs/hosts-macmini.md`](docs/hosts-macmini.md) — macOS with nix-darwin
- [`docs/TAILSCALE-SSH.md`](docs/TAILSCALE-SSH.md) — inter-host SSH over Tailscale

### Settings Management
- [`docs/settings.md`](docs/settings.md) — settings overview
- [`docs/settings-structure.md`](docs/settings-structure.md) — why the config is modular
- [`docs/secrets.md`](docs/secrets.md) — secrets management
