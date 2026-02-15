# Hosts Documentation

Complete documentation for managing and configuring hosts in this NixOS/nix-darwin setup.

## Quick Start

- **New to this config?** Start with [Hosts Overview](hosts-overview.md)
- **Want to modify a host?** See [Host Modification Guide](hosts-modification.md)
- **Setting up a specific host?** Jump to the host-specific docs below

## Documentation Index

### Overview and Guides

| Document | Description |
|---|---|
| [**Hosts Overview**](hosts-overview.md) | Complete comparison of all three hosts, configuration philosophy, and multi-host workflows |
| [**Host Modification Guide**](hosts-modification.md) | How to modify existing hosts, add new hosts, and customize host-specific behavior |

### Host-Specific Documentation

| Host | Type | Documentation |
|---|---|---|
| **laptop** | NixOS Desktop | [hosts-laptop.md](hosts-laptop.md) |
| **server** | NixOS Server | [hosts-server.md](hosts-server.md) |
| **macmini** | macOS | [hosts-macmini.md](hosts-macmini.md) |

## Current Hosts

### macmini — Apple Silicon Mac Mini (PRIMARY)

**Purpose**: Primary daily driver with native macOS

**Key Features**:
- Apple M2 chip (8-core CPU, 10-core GPU)
- nix-darwin for declarative config
- Homebrew integration (casks + formulae)
- Development tools (VSCode, Git)
- Native macOS apps and ecosystem
- Unified home-manager

**Status**: Configuration exists but not yet deployed to hardware

**Common Tasks** (when deployed):
```bash
# Rebuild (on server)
sudo nixos-rebuild switch --flake .#server

# Rebuild (from macmini remotely)
nixos-rebuild switch --flake .#server \
  --target-host ewan@server-ip \
  --build-host localhost \
  --use-remote-sudo
```

**Documentation**: [hosts-server.md](hosts-server.md)

### laptop — Dell Inspiron 3501 (SECONDARY)

**Purpose**: Secondary workstation for Linux-specific tasks

**Key Features**:
- Intel i3-1115G4, 8GB RAM, 256GB SSD
- KDE Plasma 6 (Wayland)
- Gaming support (Steam, Gamemode)
- Development tools
- Audio, Bluetooth, WiFi
- Backup workstation

**Common Tasks**:
```bash
# Rebuild (on laptop)
sudo nixos-rebuild switch --flake .#laptop
# or: nrs

# Rebuild (from macmini remotely)
nixos-rebuild switch --flake .#laptop \
  --target-host ewan@laptop-ip \
  --build-host localhost \
  --use-remote-sudo

# Gaming
steam
```

**Documentation**: [hosts-laptop.md](hosts-laptop.md)

### server — Headless NixOS Server (PLANNED)

**Purpose**: Future minimal, security-hardened server (not yet deployed)

**Planned Features**:
- No GUI (headless)
- SSH with key-based auth only
- Fail2ban intrusion prevention
- Firewall (SSH-only by default)
- Auto-upgrades
- SMART disk monitoring

**Common Tasks**:
```bash
# Rebuild
darwin-rebuild switch --flake .#macmini

# Update
nix flake update && darwin-rebuild switch --flake .#macmini

# Cleanup
sudo nix-collect-garbage -d
darwin-rebuild switch --flake .#macmini
```

**Documentation**: [hosts-macmini.md](hosts-macmini.md)

## Repository Structure

```
hosts/
├── laptop/                    # NixOS desktop configuration
│   ├── default.nix           # Main config (imports modules)
│   └── hardware-configuration.nix  # Auto-generated hardware config
├── server/                    # NixOS server configuration
│   ├── default.nix           # Main config (minimal + hardened)
│   └── minimal-hardware.nix  # Minimal hardware config
└── macmini/                   # macOS configuration
    └── default.nix           # Main config (nix-darwin + homebrew)

modules/                       # Reusable modules imported by hosts
├── common.nix                # Base NixOS settings
├── desktop.nix               # KDE Plasma 6 + SDDM
├── gaming.nix                # Steam, Gamemode
├── packages.nix              # Desktop applications
├── services.nix              # System services (printing, bluetooth)
├── users.nix                 # User accounts
└── darwin/                   # macOS-specific modules
    ├── common.nix            # Base macOS settings
    ├── packages.nix          # CLI tools
    ├── homebrew.nix          # Homebrew management
    └── system.nix            # macOS system defaults

profiles/                      # Reusable configuration profiles
├── server-base.nix           # Base server config
└── server-hardened.nix       # Security-hardened server

settings/config/              # Global configuration values (DRY)
├── user.nix                  # Username, email, shell (ALL hosts)
├── system.nix                # Timezone, locale (NixOS hosts)
├── packages.nix              # Package lists (NixOS hosts)
├── desktop.nix               # Theme, fonts (laptop only)
├── gaming.nix                # Gaming config (laptop only)
├── server.nix                # Server config (server only)
├── darwin.nix                # macOS config (macmini only)
└── ...                       # Other shared settings
```

## Configuration Philosophy

### Three Layers

1. **Global Settings** (`settings/config/`) — Values shared across hosts
2. **Reusable Modules** (`modules/`) — Components imported by hosts
3. **Host Files** (`hosts/*/default.nix`) — Minimal, imports modules + overrides

### DRY Principle

Don't repeat yourself:
- ✅ Edit `settings/config/user.nix` once → applies to all hosts
- ✅ Edit `settings/config/packages.nix` once → applies to relevant hosts
- ❌ Don't hardcode values in host files
- ❌ Don't duplicate configuration across hosts

### Example: Changing Username

```bash
# ✅ Right way (edit once)
vim settings/config/user.nix
# Change: username = "newuser";

# Apply to all hosts
sudo nixos-rebuild switch --flake .#laptop
ssh server sudo nixos-rebuild switch --flake .#server
ssh macmini darwin-rebuild switch --flake .#macmini

# ❌ Wrong way (editing each host file)
# DON'T hardcode username in hosts/laptop/default.nix
# DON'T hardcode username in hosts/server/default.nix
# DON'T hardcode username in hosts/macmini/default.nix
```

## Common Workflows

### Adding a New Package

**To macOS (primary)** (macmini):
```bash
vim settings/config/darwin.nix
# Add to "packages" or "homebrew.casks"
darwin-rebuild switch --flake .#macmini
```

**To Linux hosts** (laptop, server when deployed):
```bash
vim settings/config/packages.nix
# Add to "common" or "desktop" list
ssh laptop sudo nixos-rebuild switch --flake .#laptop
```

**To laptop only** (gaming, Linux-specific):
```bash
vim settings/config/packages.nix
# Add to "desktop" list (already laptop-only)
# or edit laptop's default.nix for truly laptop-specific
```

### Changing a System Setting

**Timezone** (affects Linux hosts, macOS set separately):
```bash
vim settings/config/system.nix
# Change: timeZone = "America/New_York";
# Apply to laptop
ssh laptop sudo nixos-rebuild switch --flake .#laptop

# For macOS, edit hosts/macmini/default.nix
vim hosts/macmini/default.nix
# Change: time.timeZone = "America/New_York";
darwin-rebuild switch --flake .#macmini
```

**Shell alias** (all hosts via home-manager):
```bash
vim settings/config/shell.nix
# Add to "aliases"
# Apply to macmini (primary)
darwin-rebuild switch --flake .#macmini
# Apply to laptop
ssh laptop sudo nixos-rebuild switch --flake .#laptop
```

**Desktop theme** (laptop only, macOS uses native themes):
```bash
vim settings/config/desktop.nix
# Change: theme = "New-Theme-Name";
ssh laptop sudo nixos-rebuild switch --flake .#laptop
```

### Enabling/Disabling Features

**Gaming** (laptop only):
```bash
vim settings/config/gaming.nix
# Toggle: enable = true/false;
```

**Auto-upgrades** (all hosts):
```bash
vim settings/config/maintenance.nix
# Toggle: autoUpgrade.enable = true/false;
```

### Adding a New Host

See [Host Modification Guide](hosts-modification.md#adding-new-hosts) for complete instructions.

Quick overview:
1. Create `hosts/NEW-HOST/` directory
2. Generate `hardware-configuration.nix` (NixOS) or skip (macOS)
3. Create `default.nix` using a template
4. Register in `flake.nix`
5. Build and test

## Module Import Matrix

Which modules does each host import?

| Module | macmini | laptop | server |
|---|:---:|:---:|:---:|
| `common.nix` | ❌ | ✅ | ✅ |
| `users.nix` | ❌ | ✅ | ✅ |
| `desktop.nix` | ❌ | ✅ | ❌ |
| `packages.nix` | ❌ | ✅ | ❌ |
| `services.nix` | ❌ | ✅ | ❌ |
| `gaming.nix` | ❌ | ✅ | ❌ |
| `profiles/server-hardened.nix` | ❌ | ❌ | 🔵 |
| `darwin/common.nix` | ✅ | ❌ | ❌ |
| `darwin/packages.nix` | ✅ | ❌ | ❌ |
| `darwin/homebrew.nix` | ✅ | ❌ | ❌ |
| `darwin/system.nix` | ✅ | ❌ | ❌ |

## Troubleshooting

### Build Failures

```bash
# Check for syntax errors
nix flake check

# Build without activating
nixos-rebuild build --flake .#hostname

# Show detailed error trace
nixos-rebuild switch --flake .#hostname --show-trace
```

### Rollback

```bash
# NixOS
sudo nixos-rebuild --rollback

# macOS
# Use Time Machine or reinstall from backup
```

### Remote Deployment Issues

```bash
# Test SSH connection first
ssh ewan@remote-host

# Check if nix-daemon is running on remote
ssh ewan@remote-host systemctl status nix-daemon

# Use verbose mode
nixos-rebuild switch --flake .#server \
  --target-host ewan@server-ip \
  --build-host localhost \
  --use-remote-sudo \
  --verbose
```

### Configuration Not Applying

```bash
# Ensure you're targeting the right host
nixos-rebuild switch --flake .#CORRECT-HOSTNAME

# Check which modules are imported
cat hosts/HOSTNAME/default.nix | grep imports

# Verify the setting file is correct
cat settings/config/SETTING-FILE.nix
```

## Best Practices

1. **Always test changes** — Use `nixos-rebuild test` before `switch`
2. **Use version control** — Commit after working changes
3. **Keep hosts minimal** — Import modules, don't duplicate logic
4. **Centralize values** — Use `settings/config/`, not host files
5. **Document overrides** — Comment why host-specific overrides exist
6. **Regular backups** — Especially `~/.config/nix-config` and `/etc/nixos`
7. **Check flake inputs** — Run `nix flake check` before rebuilding
8. **Update regularly** — But test on one host first

## Additional Resources

### Internal Documentation
- [Hosts Overview](hosts-overview.md) — Comprehensive comparison and workflows
- [Host Modification Guide](hosts-modification.md) — How to modify and add hosts
- [Laptop Guide](hosts-laptop.md) — Dell Inspiron 3501 specifics
- [Server Guide](hosts-server.md) — Headless server setup
- [macOS Guide](hosts-macmini.md) — nix-darwin and Homebrew
- [Settings Reference](settings-config.md) — All configurable values
- [REFERENCE.md](REFERENCE.md) — Quick command reference

### External Resources
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Options Search](https://search.nixos.org/options)
- [nix-darwin Documentation](https://github.com/LnL7/nix-darwin)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [NixOS Wiki](https://nixos.wiki/)
