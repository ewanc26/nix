# Nix Configuration

v0.5.0

Personal NixOS and nix-darwin configurations for managing multiple
machines with a unified, centralized setup.

> **Note:** This is a personal configuration repository. While
> you're welcome to use it as reference, it's specifically tailored
> to my needs and setup.
>
> **🎯 Quick Start for Forkers:** Edit `modules/options.nix` to
> customise everything — username, email, git settings, desktop
> theme, packages, and more. Per-host overrides go in
> `hosts/<hostname>/default.nix`.

## Key Features

✨ **Centralized Configuration** — All option defaults in `modules/options.nix` (single source of truth)
🔄 **DRY Principles** — Zero duplication; the NixOS module system handles everything
🎯 **Easy Customization** — Change any default in one file, applies everywhere
📦 **Multi-System** — Unified config for NixOS and macOS
🏠 **Unified Home Manager** — Same shell, git, SSH config across all systems
🔐 **Secrets Management** — Encrypted secrets with sops-nix
🗺️ **Infrastructure Diagrams** — Auto-generated topology SVGs via nix-topology
🛠️ **Rust Tools** — `health-check`, `flake-bump`, `gen-diff` maintenance utilities

## Managed Systems

### macOS (nix-darwin) — PRIMARY

- **macmini** — Apple Silicon Mac Mini (M2, 16 GB) — Main daily driver

### Linux (NixOS) — SECONDARY

- **laptop** — Dell Inspiron 3501 with KDE Plasma 6 — Secondary workstation
- **server** — Minimal headless server — Bluesky PDS, Forgejo, Nextcloud,
  Immich, Jellyfin, Cloudflare tunnel + hardened security

## Configuration Architecture

All options are declared with typed defaults in `modules/options.nix`.
Every system module reads values via `config.myConfig.*`;
home-manager modules use `osConfig.myConfig.*`. No custom
abstraction layer — it's plain NixOS module system.

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
curl -L \
  https://github.com/ewanc26/nix/archive/refs/heads/main.tar.gz \
  | tar -xz -C ~/.config
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

## Infrastructure Diagrams

Uses [nix-topology](https://github.com/oddlama/nix-topology) to automatically
generate SVG diagrams of the infrastructure from the NixOS configurations.
Physical connections and networks that can't be inferred automatically are
defined in `topology.nix`.

**Render the diagrams** (must run on Linux — SSH to the server or use a remote builder):

```bash
# On the server:
ssh server
nix build ~/.config/nix-config#topology.x86_64-linux.config.output

# Or from macOS with the server as a remote builder:
nix build .#topology.x86_64-linux.config.output \
  --builders 'ssh://server x86_64-linux'
```

This produces two diagrams:

- `main.svg` — physical host/interface layout
- `network.svg` — network-centric view showing which hosts share which networks

**Updating topology:**

Edit `topology.nix` to reflect physical changes (new cables, new networks, etc.).
Service and interface information is extracted automatically from the NixOS configs.

## Customization

**All defaults live in `modules/options.nix`** — one option block per domain.

```bash
# Examples of what to edit
nano modules/options.nix           # Username, timezone, packages, themes, etc.
nano hosts/laptop/default.nix      # Enable gaming, desktop mode, etc.
nano hosts/server/default.nix      # Enable server services
nano topology.nix                  # Physical network connections
nano settings/darwin/default.nix   # macOS Dock, Finder, trackpad
nano settings/plasma/default.nix   # KDE Plasma layout and behaviour
```

See [`docs/settings.md`](docs/settings.md) for the full guide and
[`docs/settings-config.md`](docs/settings-config.md) for the
complete option reference.

## Maintenance

### Health Check (Recommended Before Building)

```bash
health-check
```

### Update Flake Inputs

```bash
nix flake update
# or selectively
flake-bump
```

### Garbage Collection

```bash
# Runs automatically weekly (configured in modules/common.nix)
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
4. Add the host's interfaces/connections to `topology.nix`
5. Build: `sudo nixos-rebuild switch --flake .#YOUR-HOSTNAME`

## Inputs

| Input | Version |
| --- | --- |
| [nixpkgs][nixpkgs] | nixos-25.11 |
| [home-manager][home-manager] | release-25.11 |
| [nix-darwin][nix-darwin] | nix-darwin-25.11 |
| [sops-nix][sops-nix] | latest |
| [nix-topology][nix-topology] | latest |
| [plasma-manager][plasma-manager] | latest |
| [catppuccin][catppuccin] | latest |
| [nix-vscode-extensions][nix-vscode-extensions] | latest |
| [mac-app-util][mac-app-util] | latest |

[nixpkgs]: https://github.com/NixOS/nixpkgs
[home-manager]: https://github.com/nix-community/home-manager
[nix-darwin]: https://github.com/LnL7/nix-darwin
[sops-nix]: https://github.com/Mic92/sops-nix
[nix-topology]: https://github.com/oddlama/nix-topology
[plasma-manager]: https://github.com/nix-community/plasma-manager
[catppuccin]: https://github.com/catppuccin/nix
[nix-vscode-extensions]: https://github.com/nix-community/nix-vscode-extensions
[mac-app-util]: https://github.com/hraban/mac-app-util

## Unified Configuration Benefits

### Same Shell Everywhere

- **zsh** with identical aliases, history, and key bindings on all systems
- **SSH** client configuration unified (connection multiplexing, agent integration)
- **Git** settings consistent across NixOS and macOS
- **Starship** prompt looks the same everywhere
- **Ghostty** terminal configured identically on Linux and macOS

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

## ☕ Support

If you found this useful, consider [buying me a ko-fi](https://ko-fi.com/ewancroft)!
