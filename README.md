# Nix Configuration

Personal NixOS and nix-darwin configurations for managing multiple machines with a unified, centralized setup.

> **Note:** This is a personal configuration repository. While you're welcome to use it as reference, it's specifically tailored to my needs and setup.

> **🎯 Quick Start for Forkers:** Edit `settings/config/` files to customise everything — username, email, git settings, desktop theme, packages, and more.

## Key Features

✨ **Centralized Configuration** - All settings in `settings/config/` (single source of truth)
🔄 **DRY Principles** - No duplication, every value defined once
🎯 **Easy Customization** - Change any setting in one file, applies everywhere
📦 **Multi-System** - Unified config for NixOS and macOS
🔐 **Secrets Management** - Encrypted secrets with ragenix

## Managed Systems

### Linux (NixOS)

- **laptop** - Dell Inspiron 3501 with GNOME desktop environment
- **server** - Minimal headless server configuration

### macOS (nix-darwin)

- **macmini** - Apple Silicon Mac Mini (M2)

## Repository Structure

```
.
├── flake.nix                 # Main flake configuration
├── flake.lock                # Locked dependency versions
├── configuration.nix         # Legacy entry point (superseded by hosts/)
│
├── hosts/                    # Host-specific configurations
│   ├── laptop/               # Dell Inspiron 3501 (NixOS + GNOME)
│   ├── server/               # Headless server (NixOS)
│   └── macmini/              # Mac Mini (nix-darwin)
│
├── modules/                  # Reusable system modules
│   ├── common.nix            # Shared settings across all NixOS hosts
│   ├── desktop.nix           # GNOME desktop environment
│   ├── gaming.nix            # Gaming packages and Steam
│   ├── packages.nix          # Desktop system packages
│   ├── services.nix          # System services
│   ├── secrets.nix           # Secret management with ragenix
│   ├── users.nix             # User account configuration
│   └── darwin/               # macOS-specific modules
│       ├── common.nix
│       ├── homebrew.nix
│       ├── packages.nix
│       └── system.nix
│
├── home/                     # Home Manager configurations
│   ├── home.nix              # Main home-manager entry point
│   ├── configs/              # Application config files
│   │   ├── fastfetch.jsonc
│   │   └── starship.toml
│   └── programs/
│       ├── fastfetch.nix
│       ├── git.nix
│       ├── gnome.nix
│       ├── starship.nix
│       ├── vscode.nix
│       └── zsh.nix
│
├── settings/                 # ⭐ Centralized configuration — edit here
│   ├── config.nix            # Entry point (imports config/)
│   ├── config/               # All configurable values (one file per domain)
│   ├── gnome/                # GNOME dconf settings (auto-exported)
│   ├── darwin/               # macOS defaults (auto-exported)
│   ├── gnome-export.sh       # Export current GNOME settings
│   └── darwin-export.sh      # Export current macOS settings
│
├── secrets/                  # Encrypted secrets (ragenix / age)
│   ├── secrets.nix           # Public key mappings
│   ├── setup.sh              # Key management helper
│   └── age/*.age             # Encrypted secret files
│
├── wallpapers/               # Desktop wallpapers
└── docs/                     # All documentation
    ├── REFERENCE.md          # Quick-reference card
    ├── settings-config.md    # Settings file map and cheatsheet
    ├── settings.md           # Settings overview
    ├── settings-guide.md     # GNOME/macOS export workflow
    ├── settings-structure.md # Why config is modular
    ├── hosts.md              # Adding/configuring hosts
    ├── hosts-macmini.md      # macOS setup guide
    ├── hosts-server.md       # Server setup guide
    ├── secrets.md            # Secrets management
    └── wallpapers.md         # Wallpaper usage
```

## Customization

**All settings live in `settings/config/`** — one file per domain, each small and focused.

```bash
# Examples
vim settings/config/user.nix       # Username, email, shell
vim settings/config/packages.nix   # Add/remove packages
vim settings/config/desktop.nix    # Theme, fonts, GNOME extensions
vim settings/config/darwin.nix     # macOS packages, Homebrew, keyboard
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

### GNOME (Linux)

Export your current GNOME settings after making changes via the GUI:

```bash
./settings/gnome-export.sh
```

Settings are automatically applied via dconf on every Home Manager activation.

### macOS

Export your current macOS defaults:

```bash
./settings/darwin-export.sh
```

## Maintenance

### Update Flake Inputs

```bash
nix flake update
sudo nixos-rebuild switch --flake .#laptop   # or darwin-rebuild
```

### Garbage Collection

```bash
# NixOS (auto-runs weekly — see settings/config/nix.nix)
sudo nix-collect-garbage -d

# macOS
sudo nix-collect-garbage -d
sudo darwin-rebuild switch --flake .#macmini
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

## Documentation

- [`docs/settings-config.md`](docs/settings-config.md) — full settings reference *(start here)*
- [`docs/hosts.md`](docs/hosts.md) — adding/configuring hosts
- [`docs/secrets.md`](docs/secrets.md) — secrets management
- [`docs/settings-guide.md`](docs/settings-guide.md) — GNOME/macOS settings export
- [`docs/REFERENCE.md`](docs/REFERENCE.md) — quick-reference card
- [`docs/settings.md`](docs/settings.md) — settings overview
- [`docs/settings-structure.md`](docs/settings-structure.md) — why the config is modular
- [`docs/hosts-macmini.md`](docs/hosts-macmini.md) — macOS setup guide
- [`docs/hosts-server.md`](docs/hosts-server.md) — server setup guide
