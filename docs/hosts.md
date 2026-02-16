# Hosts Documentation

Complete documentation for managing and configuring hosts in this NixOS/nix-darwin setup.

## Quick Start

- **New to this config?** Start with [Hosts Overview](hosts-overview.md)
- **Want to modify a host?** See [Host Modification Guide](hosts-modification.md)
- **Setting up a specific host?** Jump to the host-specific docs below

## Documentation Index

| Document | Description |
|---|---|
| [**Hosts Overview**](hosts-overview.md) | Full comparison of all hosts, configuration philosophy, and multi-host workflows |
| [**Host Modification Guide**](hosts-modification.md) | How to modify existing hosts and add new ones |
| [**Tailscale SSH**](TAILSCALE-SSH.md) | Inter-host SSH over Tailscale mesh |

## Current Hosts

### macmini — Apple Silicon Mac Mini (PRIMARY)

**Purpose**: Primary daily driver

**Key Features**:
- Apple M2 (8-core CPU, 10-core GPU), 16 GB RAM
- nix-darwin for declarative macOS config
- Homebrew integration (casks + formulae via `tailscale-app`, Office, etc.)
- SSH keys auto-loaded at login via LaunchAgent (`ssh-add --apple-load-keychain`)
- Unified home-manager (same shell, git, prompt as other hosts)

**Common Tasks**:
```bash
# Rebuild (on macmini)
nrs

# Rebuild macmini then laptop in one shot
nrs && ssh laptop 'cd ~/.config/nix-config && sudo nixos-rebuild switch --flake .#laptop'
```

**Documentation**: [hosts-macmini.md](hosts-macmini.md)

---

### laptop — Dell Inspiron 3501 (SECONDARY)

**Purpose**: Secondary workstation for Linux-specific tasks

**Key Features**:
- Intel Core i3-1115G4, 8 GB RAM, 256 GB NVMe
- KDE Plasma 6 (Wayland)
- Gaming support (Steam, Gamemode)
- SSH keys auto-loaded via systemd + ksshaskpass/KWallet at login

**Common Tasks**:
```bash
# Rebuild (on laptop)
nrs

# Rebuild remotely from macmini
ssh laptop 'cd ~/.config/nix-config && sudo nixos-rebuild switch --flake .#laptop'
```

**Documentation**: [hosts-laptop.md](hosts-laptop.md)

---

### server — Headless NixOS Server

**Purpose**: Minimal security-hardened server (Bluesky PDS + services)

**Key Features**:
- Headless (no GUI, no desktop packages)
- SSH key-based auth only; Fail2ban; firewall
- Bluesky ATProto PDS via Caddy + Cloudflare tunnel
- Auto-upgrades and SMART disk monitoring
- Configuration is complete and ready to deploy

**Common Tasks**:
```bash
# Rebuild (on server)
nrs

# Rebuild remotely from macmini
ssh server 'cd ~/.config/nix-config && sudo nixos-rebuild switch --flake .#server'
```

**Documentation**: [hosts-server.md](hosts-server.md)

---

## Repository Structure

```
hosts/
├── laptop/
│   ├── default.nix
│   └── hardware-configuration.nix
├── server/
│   ├── default.nix
│   └── minimal-hardware.nix
└── macmini/
    └── default.nix

modules/
├── common.nix                # Base NixOS settings
├── desktop.nix               # KDE Plasma 6 + SDDM
├── gaming.nix                # Steam, Gamemode
├── packages.nix              # Desktop applications
├── services.nix              # Printing, Bluetooth, etc.
├── users.nix                 # User accounts
├── caddy.nix                 # Caddy web server
├── pds.nix                   # Bluesky PDS
├── ssh-keys.nix              # Public key registry (all hosts)
├── server/                   # Server-specific modules
│   ├── default.nix           # Imports all server sub-modules
│   ├── firewall.nix
│   ├── intrusion.nix         # fail2ban
│   ├── ssh.nix               # sshd hardening
│   ├── hardware-health.nix   # SMART monitoring
│   ├── maintenance.nix       # Auto-upgrades, GC
│   ├── packages.nix          # Server package set
│   ├── services.nix          # Server services
│   └── disable-noise.nix     # Quieten unnecessary logging
└── darwin/
    ├── common.nix
    ├── packages.nix
    ├── homebrew.nix
    └── system.nix

profiles/
├── server-base.nix           # Base server config
└── server-hardened.nix       # Security hardening (imports server-base)

settings/config/              # ⭐ Global values — edit here
home/scripts/                 # verify-tailscale-ssh, update-all, update-everything, relts
```

## Module Import Matrix

| Module | macmini | laptop | server |
|---|:---:|:---:|:---:|
| `common.nix` | ❌ | ✅ | ✅ |
| `users.nix` | ❌ | ✅ | ✅ |
| `desktop.nix` | ❌ | ✅ | ❌ |
| `packages.nix` | ❌ | ✅ | ❌ |
| `services.nix` | ❌ | ✅ | ❌ |
| `gaming.nix` | ❌ | ✅ | ❌ |
| `caddy.nix` | ❌ | ❌ | ✅ |
| `pds.nix` | ❌ | ❌ | ✅ |
| `profiles/server-hardened.nix` | ❌ | ❌ | ✅ |
| `darwin/common.nix` | ✅ | ❌ | ❌ |
| `darwin/packages.nix` | ✅ | ❌ | ❌ |
| `darwin/homebrew.nix` | ✅ | ❌ | ❌ |
| `darwin/system.nix` | ✅ | ❌ | ❌ |

## Configuration Philosophy

### Three Layers

1. **Global Settings** (`settings/config/`) — values shared across hosts
2. **Reusable Modules** (`modules/`) — components imported by hosts
3. **Host Files** (`hosts/*/default.nix`) — minimal; just imports + overrides

### DRY Principle

- ✅ Edit `settings/config/user.nix` once → applies to all hosts
- ✅ Edit `settings/config/shell.nix` once → shell is identical everywhere
- ❌ Don't hardcode values in host files
- ❌ Don't duplicate configuration across hosts

## Common Workflows

### Adding a Package

**macOS only** (`darwin.nix` → `packages` or `homebrew.casks`):
```bash
vim settings/config/darwin.nix
nrs
```

**Linux hosts** (`packages.nix` → `desktop` or `common`):
```bash
vim settings/config/packages.nix
nrs && ssh laptop 'cd ~/.config/nix-config && sudo nixos-rebuild switch --flake .#laptop'
```

### Changing a Shell Alias (all hosts)
```bash
vim settings/config/shell.nix
nrs
ssh laptop 'cd ~/.config/nix-config && sudo nixos-rebuild switch --flake .#laptop'
```

### Enabling/Disabling Features
```bash
vim settings/config/gaming.nix   # toggle gaming
vim settings/config/maintenance.nix  # toggle auto-upgrades
```

## Troubleshooting

```bash
# Syntax check
nix flake check

# Build without activating
sudo nixos-rebuild build --flake .#laptop

# Detailed error trace
sudo nixos-rebuild switch --flake .#laptop --show-trace

# Rollback
sudo nixos-rebuild switch --rollback
```

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nix-darwin Manual](https://github.com/LnL7/nix-darwin)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS Options Search](https://search.nixos.org/options)
