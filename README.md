# Nix Configuration

Personal NixOS and nix-darwin configurations for managing multiple machines with a unified setup.

> **Note:** This is a personal configuration repository. While you're welcome to use it as reference, it's specifically tailored to my needs and setup.

## Managed Systems

### Linux Systems (NixOS)

- **laptop** - Dell Inspiron 3501 with GNOME desktop environment
- **server** - Minimal headless server configuration

### macOS Systems (nix-darwin)

- **macmini** - Apple Silicon Mac Mini (M1/M2/M3)

## Repository Structure

```
.
├── flake.nix                 # Main flake configuration
├── flake.lock               # Locked dependency versions
├── configuration.nix        # Legacy configuration (deprecated in favor of modular setup)
├── Makefile                 # Convenience commands for building/updating
│
├── hosts/                   # Host-specific configurations
│   ├── laptop/              # Dell Inspiron 3501 (NixOS + GNOME)
│   ├── server/              # Headless server (NixOS)
│   └── macmini/             # Mac Mini (nix-darwin)
│
├── modules/                 # Reusable system modules
│   ├── common.nix           # Shared settings across all hosts
│   ├── desktop.nix          # GNOME desktop environment
│   ├── gaming.nix           # Gaming packages and Steam
│   ├── packages.nix         # Common packages for desktop systems
│   ├── services.nix         # System services configuration
│   ├── secrets.nix          # Secret management with ragenix
│   ├── users.nix            # User account configuration
│   ├── server-packages.nix  # Server-specific tools
│   ├── server-services.nix  # Server services (SSH, fail2ban, etc.)
│   └── darwin/              # macOS-specific modules
│       ├── common.nix       # Shared macOS settings
│       ├── homebrew.nix     # Homebrew package management
│       ├── packages.nix     # macOS packages
│       └── system.nix       # macOS system preferences
│
├── home/                    # Home Manager configurations
│   ├── home.nix             # Main home-manager config
│   ├── configs/             # Application config files
│   │   ├── fastfetch.jsonc
│   │   └── starship.toml
│   └── programs/            # Program-specific configs
│       ├── fastfetch.nix
│       ├── git.nix
│       ├── gnome.nix
│       ├── starship.nix
│       ├── vscode.nix
│       └── zsh.nix
│
├── settings/                # System settings export/import
│   ├── gnome/               # GNOME dconf settings
│   ├── darwin/              # macOS defaults
│   ├── gnome-export.sh      # Script to export GNOME settings
│   └── darwin-export.sh     # Script to export macOS settings
│
├── secrets/                 # Encrypted secrets with ragenix
│   ├── secrets.nix          # Public key mappings
│   ├── setup.sh             # Automated key management
│   └── *.age                # Encrypted secret files
│
├── wallpapers/              # Desktop wallpapers
├── scripts/                 # Utility scripts
└── docs/                    # Additional documentation
    ├── BACKUP_SETUP.md
    └── REFERENCE.md
```

## Quick Start

### Prerequisites

- **NixOS:** Install NixOS on your system
- **macOS:** Install Nix using the [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)

### Initial Setup

1. Clone this repository:

   ```bash
   git clone https://github.com/ewanc26/nix.git ~/.config/nix-config
   cd ~/.config/nix-config
   ```

2. For NixOS systems, build and activate:

   ```bash
   # For laptop
   sudo nixos-rebuild switch --flake .#laptop

   # For server
   sudo nixos-rebuild switch --flake .#server
   ```

3. For macOS systems:

   ```bash
   # First time setup
   sudo nix run nix-darwin -- switch --flake .#macmini

   # Subsequent updates
   sudo darwin-rebuild switch --flake .#macmini
   ```

### Using the Makefile (NixOS only)

The Makefile provides convenient shortcuts for common operations:

```bash
make switch    # Build and activate configuration
make boot      # Build for next boot
make test      # Test without setting default
make update    # Update flake inputs
make clean     # Garbage collection
make fmt       # Format Nix files
make check     # Check flake for errors
```

## Features

### Common Features (All Systems)

- **Flakes-based configuration** for reproducible builds
- **Home Manager** for user environment management
- **Automatic updates** with configurable schedules
- **Secrets management** with ragenix (age encryption)
- **Unified dotfiles** across all machines
- **Git configuration** with global gitignore
- **Shell configuration** (Zsh with Starship prompt)
- **VS Code** with extensions and settings sync

### NixOS-Specific Features

- **GNOME desktop** (laptop only) with custom settings
- **Gaming support** with Steam and necessary libraries
- **PipeWire** audio system
- **NetworkManager** for network management
- **Automatic garbage collection** (weekly, keeps last 30 days)
- **systemd-boot** bootloader
- **Latest kernel** packages

### macOS-Specific Features

- **Homebrew integration** for GUI apps
- **macOS defaults** configuration
- **nix-darwin** system management

### Server Features (NixOS server)

- **Headless configuration** (no GUI)
- **SSH server** with security hardening
- **fail2ban** for intrusion prevention
- **Minimal package set** optimized for servers

## Secrets Management

This configuration uses [ragenix](https://github.com/yaxitech/ragenix) for managing encrypted secrets. See [secrets/README.md](secrets/README.md) for detailed usage instructions.

Key points:

- Secrets are encrypted using age with SSH keys
- Run `bash ./secrets/setup.sh` to initialize keys
- Master key stored in `~/.config/age/keys.txt` (NEVER commit this!)
- Encrypted `.age` files are safe to commit to git

## Adding a New Host

See [hosts/README.md](hosts/README.md) for detailed instructions on adding new machines to this configuration.

Quick summary:

1. Create a new directory under `hosts/YOUR-HOSTNAME`
2. Generate hardware configuration: `nixos-generate-config --show-hardware-config`
3. Create `default.nix` based on templates in hosts/README.md
4. Add entry to `flake.nix`
5. Build with `sudo nixos-rebuild switch --flake .#YOUR-HOSTNAME`

## Settings Management

### GNOME Settings (Linux)

Export current GNOME settings to Nix:

```bash
cd settings
./gnome-export.sh
```

Settings are automatically applied via dconf during system activation.

### macOS Settings

Export current macOS defaults:

```bash
cd settings
./darwin-export.sh
```

Settings are stored in `settings/darwin/default.nix` and applied during rebuild.

## Updating

### Update Flake Inputs

```bash
nix flake update
# Then rebuild with your preferred method
```

### Update Individual Input

```bash
nix flake lock --update-input nixpkgs
```

## Maintenance

### Garbage Collection (NixOS)

Automatic weekly garbage collection is enabled, keeping generations from the last 30 days.

Manual cleanup:

```bash
make clean  # Or:
sudo nix-collect-garbage -d
nix-collect-garbage -d
```

### Garbage Collection (macOS)

```bash
nix-collect-garbage -d
darwin-rebuild switch --flake .#macmini
```

## Inputs

This configuration uses the following major inputs:

- [nixpkgs](https://github.com/NixOS/nixpkgs) (25.11 stable)
- [home-manager](https://github.com/nix-community/home-manager) (release-25.11)
- [nix-darwin](https://github.com/LnL7/nix-darwin) (nix-darwin-25.11)
- [ragenix](https://github.com/yaxitech/ragenix) (for secrets management)

## Documentation

Additional documentation can be found in:

- [hosts/README.md](hosts/README.md) - Host configuration guide
- [secrets/README.md](secrets/README.md) - Secrets management
- [settings/SETTINGS_GUIDE.md](settings/SETTINGS_GUIDE.md) - Settings export/import
- [docs/BACKUP_SETUP.md](docs/BACKUP_SETUP.md) - Backup configuration
- [docs/REFERENCE.md](docs/REFERENCE.md) - Additional reference material

## Contributing

This is a personal configuration repository. While I don't accept pull requests unless asked for, feel free to fork and adapt it for your own use!

## License

This configuration is provided as-is for personal use. See individual package licenses for included software.

## Acknowledgments

This configuration was inspired by and built upon the excellent work of the Nix community, particularly:

- The NixOS and nix-darwin documentation
- Various community dotfiles repositories
- The Home Manager project
