# Nix Configuration

v0.3.0

Personal NixOS and nix-darwin configurations for managing multiple machines with a unified, centralized setup.

> **Note:** This is a personal configuration repository. While you're welcome to use it as reference, it's specifically tailored to my needs and setup.

> **🎯 Quick Start for Forkers:** Edit `modules/options.nix` to customise everything — username, email, git settings, desktop theme, packages, and more. Per-host overrides go in `hosts/<hostname>/default.nix`.

## Key Features

✨ **Centralized Configuration** - All option defaults in `modules/options.nix` (single source of truth)
🔄 **DRY Principles** - Zero duplication; the NixOS module system handles everything
🎯 **Easy Customization** - Change any default in one file, applies everywhere
📦 **Multi-System** - Unified config for NixOS and macOS
🏠 **Unified Home Manager** - Same shell, git, SSH config across all systems
🔐 **Secrets Management** - Encrypted secrets with sops-nix
🛠️ **Rust Tools** - `health-check`, `flake-bump`, `gen-diff` maintenance utilities

## Managed Systems

### macOS (nix-darwin) - PRIMARY

- **macmini** - Apple Silicon Mac Mini (M2, 16 GB) — Main daily driver

### Linux (NixOS) - SECONDARY

- **laptop** - Dell Inspiron 3501 with KDE Plasma 6 — Secondary workstation
- **server** - Minimal headless server — Bluesky PDS, Matrix, Forgejo, Cloudflare tunnel + hardened security

## Repository Structure

```
.
├── flake.nix                 # Main flake — defines all hosts
├── flake.lock                # Locked dependency versions
│
├── hosts/                    # Host-specific configurations
│   ├── laptop/               # Dell Inspiron 3501 (NixOS + KDE Plasma 6)
│   ├── server/               # Headless server (NixOS)
│   └── macmini/              # Mac Mini M2 (nix-darwin)
│
├── modules/                  # Reusable system modules
│   ├── options.nix           # ⭐ All option declarations + defaults
│   ├── common.nix            # Base NixOS settings (gc, auto-upgrade, etc.)
│   ├── desktop.nix           # KDE Plasma 6 + SDDM
│   ├── gaming.nix            # Steam + Gamemode
│   ├── packages.nix          # Desktop system packages
│   ├── services.nix          # Printing, Bluetooth, etc.
│   ├── users.nix             # User account configuration
│   ├── caddy.nix             # Caddy web server
│   ├── pds.nix               # Bluesky ATProto PDS
│   ├── matrix.nix            # Matrix Synapse
│   ├── forgejo.nix           # Forgejo git forge
│   ├── cloudflare-tunnel.nix # Cloudflare tunnel (outbound-only)
│   ├── cockpit.nix           # Cockpit web console
│   ├── ssh-keys.nix          # Public key registry for all hosts
│   ├── server/               # Headless server sub-modules
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
│   ├── default.nix           # Main entry point
│   └── programs/             # Per-program config (git, zsh, ssh, vscode, kde, ...)
│
├── settings/                 # Platform-specific declarative settings
│   ├── darwin/               # macOS system.defaults (Dock, Finder, trackpad, etc.)
│   └── plasma/               # KDE Plasma declarative settings
│
├── secrets/                  # sops-encrypted secrets (safe to commit)
│   ├── setup.sh              # Key management helper
│   └── *.env / *.json / ...  # Encrypted secret files
│
├── tools/                    # Rust maintenance tools
│   └── src/bin/              # health-check, flake-bump, gen-diff
└── wallpapers/
```

## Configuration Architecture

All options are declared with typed defaults in `modules/options.nix`. Every system module reads values via `config.myConfig.*`; home-manager modules use `osConfig.myConfig.*`. No custom abstraction layer — it's plain NixOS module system.

**To change a value for all hosts:**

```nix
# modules/options.nix
timeZone = mkOption {
  type = str;
  default = "Europe/London";  # ← change here
};
```

**To override for one host:**

```nix
# hosts/laptop/default.nix
myConfig.gaming.enable = true;
myConfig.isDesktop     = true;
```

See [`lib/USAGE.md`](lib/USAGE.md) for patterns used in modules.

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

## Customization

**All defaults live in `modules/options.nix`** — one option block per domain.

```bash
# Examples of what to edit
nano modules/options.nix        # Username, timezone, packages, themes, etc.
nano hosts/laptop/default.nix   # Enable gaming, desktop mode, etc.
nano hosts/server/default.nix   # Enable server services
nano settings/darwin/default.nix  # macOS Dock, Finder, trackpad
nano settings/plasma/default.nix  # KDE Plasma layout and behaviour
```

See [`docs/settings.md`](docs/settings.md) for the full guide and [`docs/settings-config.md`](docs/settings-config.md) for the complete option reference.

## Maintenance

### Health Check (Recommended Before Building)

```bash
# Compile the tools (one-time)
nix run .#tools -- --help

# Run health check
tools/target/release/health-check

# Or use the shell alias
health-check
```

### Update Flake Inputs

```bash
nix flake update
# Then rebuild
sudo nixos-rebuild switch --flake .#laptop
# or
nix run .#tools -- flake-bump
```

### Garbage Collection

```bash
# Runs automatically weekly on NixOS (configured in modules/common.nix)
sudo nix-collect-garbage -d

# Or use the alias
cleanup
```

## Secrets Management

Uses [sops-nix](https://github.com/Mic92/sops-nix) with age encryption.

- Secrets are encrypted with age using the host's SSH ed25519 host key
- Encrypted files in `secrets/` are safe to commit
- The key inventory and creation rules are in `.sops.yaml`
- Decrypted at activation via `/etc/ssh/ssh_host_ed25519_key`

See [docs/secrets.md](docs/secrets.md) for full details.

## Adding a New Host

See [docs/hosts.md](docs/hosts.md). Quick summary:

1. Create `hosts/YOUR-HOSTNAME/default.nix`
2. Generate hardware config: `nixos-generate-config --show-hardware-config`
3. Add entry to `flake.nix` → `nixosConfigurations`
4. Build: `sudo nixos-rebuild switch --flake .#YOUR-HOSTNAME`

## Inputs

| Input                                                             | Version          |
| ----------------------------------------------------------------- | ---------------- |
| [nixpkgs](https://github.com/NixOS/nixpkgs)                       | nixos-25.11      |
| [home-manager](https://github.com/nix-community/home-manager)     | release-25.11    |
| [nix-darwin](https://github.com/LnL7/nix-darwin)                  | nix-darwin-25.11 |
| [sops-nix](https://github.com/Mic92/sops-nix)                     | latest           |
| [plasma-manager](https://github.com/nix-community/plasma-manager) | latest           |

## Unified Configuration Benefits

### Same Shell Everywhere

- **zsh** with identical aliases, history, and key bindings on all systems
- **SSH** client configuration unified (connection multiplexing, agent integration)
- **Git** settings consistent across NixOS and macOS
- **Starship** prompt looks the same everywhere

### Platform-Specific When Needed

- **macOS**: SSH keys loaded at login via LaunchAgent (`ssh-add --apple-load-keychain`)
- **Linux desktop**: SSH keys loaded at login via systemd + ksshaskpass/KWallet
- **Server**: No agent needed — SSH connections go _into_ it, not out
- **KDE Plasma** settings only apply on Linux desktop
- **Homebrew** only on macOS

## Documentation

### Core Documentation

- [`lib/USAGE.md`](lib/USAGE.md) — module patterns for developers
- [`docs/settings.md`](docs/settings.md) — how configuration works _(start here)_
- [`docs/settings-config.md`](docs/settings-config.md) — full option reference
- [`docs/REFERENCE.md`](docs/REFERENCE.md) — quick-reference command card

### Host Management

- [`docs/hosts.md`](docs/hosts.md) — hosts documentation index
- [`docs/hosts-overview.md`](docs/hosts-overview.md) — complete comparison of all three hosts
- [`docs/hosts-modification.md`](docs/hosts-modification.md) — how to modify and add hosts
- [`docs/hosts-laptop.md`](docs/hosts-laptop.md) — Dell Inspiron 3501 (NixOS + KDE Plasma 6)
- [`docs/hosts-server.md`](docs/hosts-server.md) — headless server setup
- [`docs/hosts-macmini.md`](docs/hosts-macmini.md) — macOS with nix-darwin
- [`docs/TAILSCALE-SSH.md`](docs/TAILSCALE-SSH.md) — inter-host SSH over Tailscale

### Settings Management

- [`docs/settings.md`](docs/settings.md) — settings overview
- [`docs/settings-structure.md`](docs/settings-structure.md) — why the config is modular
- [`docs/secrets.md`](docs/secrets.md) — secrets management
