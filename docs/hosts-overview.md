# Hosts Overview

This document provides a comprehensive overview of all hosts in this configuration, their purposes, and how they relate to each other.

## Quick Reference

| Host | Type | OS | Purpose | Desktop | Status |
|---|---|---|---|---|---|
| **macmini** | Desktop | macOS | Primary workstation | macOS GUI | ✅ Active (Main) |
| **laptop** | Desktop/Laptop | NixOS | Secondary workstation | KDE Plasma 6 | ✅ Active |
| **server** | Server | NixOS | Headless server | None | 📋 Planned |

## Detailed Comparison

### macmini (PRIMARY)

**Hardware**: Apple Silicon Mac Mini (M2)
- Apple M2 chip (8-core CPU, 10-core GPU)
- Unified memory
- macOS Sequoia

**Purpose**: Primary daily driver for all computing tasks

**Use Cases**:
- Main development workstation
- macOS/iOS app development (when needed)
- Web browsing, email, communication
- Office work and productivity
- Multimedia consumption
- Apple ecosystem integration
- Unix development with native macOS apps

**Features**:
- ✅ nix-darwin for declarative macOS config
- ✅ Homebrew integration (GUI apps + formulae)
- ✅ macOS system defaults management
- ✅ Development tools (VSCode, Git, compilers)
- ✅ Native macOS applications
- ✅ Unified home-manager (same shell/git as Linux)
- ✅ Apple Silicon performance
- ✅ macOS native features (Touch ID, etc.)

**Documentation**: [hosts-macmini.md](hosts-macmini.md)

### laptop (SECONDARY)

**Hardware**: Dell Inspiron 3501
- Intel i3-1115G4 (2C/4T, 3.0-4.1 GHz)
- 8 GB DDR4-3200
- 256 GB NVMe SSD
- Intel UHD Graphics

**Purpose**: Secondary workstation for Linux-specific tasks and testing

**Use Cases**:
- Linux-specific development and testing
- KDE Plasma 6 experimentation
- Gaming (Steam, native Linux games)
- Backup workstation when Mac is unavailable
- NixOS testing and learning

**Features**:
- ✅ Full KDE Plasma 6 desktop
- ✅ Audio (PipeWire)
- ✅ Gaming (Steam, Gamemode)
- ✅ Development tools (VSCode, Git, compilers)
- ✅ Multimedia applications
- ✅ Auto-upgrades (configurable)
- ✅ Power management
- ✅ Hardware acceleration

**Documentation**: [hosts-laptop.md](hosts-laptop.md)

### server (PLANNED)

**Hardware**: To be determined

**Purpose**: Future headless server for services and remote access

**Planned Use Cases**:
- SSH remote access
- Self-hosted services (potential: web server, database, etc.)
- Home lab experimentation
- Always-on availability
- Learning server administration

**Planned Features**:
- 🔵 Hardened security profile
- 🔵 SSH server with key-based auth only
- 🔵 Fail2ban for intrusion prevention
- 🔵 Firewall (SSH-only by default)
- 🔵 Auto-upgrades (daily)
- 🔵 SMART disk monitoring
- 🔵 Minimal package set
- ❌ No GUI
- ❌ No gaming
- ❌ No multimedia

**Status**: Configuration exists but not yet deployed to hardware

**Documentation**: [hosts-server.md](hosts-server.md)



## Configuration Philosophy

### Unified Core, Specialized Edges

All three hosts share:
- **User configuration** (username, email, shell)
- **Shell environment** (zsh, aliases, prompt)
- **Git configuration**
- **SSH setup** (keys, agent)
- **Development tools** (languages, VSCode)
- **Secrets management**

Each host specializes:
- **laptop**: Full desktop experience + gaming
- **server**: Minimal, security-hardened
- **macmini**: macOS-native + Homebrew ecosystem

### Configuration Layers

```
┌─────────────────────────────────────────┐
│     settings/config/*.nix               │  ← Global values (DRY)
│  (user, packages, theme, git, etc.)     │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│        modules/*.nix                     │  ← Reusable components
│  (common, desktop, gaming, services)    │
└─────────────────────────────────────────┘
              ↓
┌──────────────┬──────────────┬───────────┐
│   laptop/    │   server/    │ macmini/  │  ← Host-specific
│ default.nix  │ default.nix  │default.nix│     (imports + overrides)
└──────────────┴──────────────┴───────────┘
```

## Module Matrix

Which modules does each host use?

| Module | laptop | server | macmini | Purpose |
|---|:---:|:---:|:---:|---|
| `common.nix` | ✅ | ✅ | ❌ | Base NixOS settings |
| `users.nix` | ✅ | ✅ | ❌ | User account creation |
| `desktop.nix` | ✅ | ❌ | ❌ | KDE Plasma 6 setup |
| `packages.nix` | ✅ | ❌ | ❌ | Desktop applications |
| `services.nix` | ✅ | ❌ | ❌ | Desktop services (printing, bluetooth) |
| `gaming.nix` | ✅ | ❌ | ❌ | Steam, Gamemode |
| `darwin/common.nix` | ❌ | ❌ | ✅ | macOS Nix settings |
| `darwin/packages.nix` | ❌ | ❌ | ✅ | macOS CLI tools |
| `darwin/homebrew.nix` | ❌ | ❌ | ✅ | Homebrew management |
| `darwin/system.nix` | ❌ | ❌ | ✅ | macOS system defaults |
| `profiles/server-hardened.nix` | ❌ | ✅ | ❌ | Security hardening |

## Settings Scope

How `settings/config/` values are used across hosts:

| Setting File | laptop | server | macmini | Notes |
|---|:---:|:---:|:---:|---|
| `user.nix` | ✅ | ✅ | ✅ | Used everywhere |
| `system.nix` | ✅ | ✅ | Partial | NixOS-specific |
| `nix.nix` | ✅ | ✅ | ✅ | Nix itself |
| `packages.nix` | ✅ | Minimal | ❌ | Linux packages |
| `git.nix` | ✅ | ✅ | ✅ | Via home-manager |
| `shell.nix` | ✅ | ✅ | ✅ | Via home-manager |
| `desktop.nix` | ✅ | ❌ | ❌ | Desktop-only |
| `ssh.nix` | ✅ | ✅ | ✅ | Via home-manager |
| `audio.nix` | ✅ | ❌ | ❌ | Desktop-only |
| `gaming.nix` | ✅ | ❌ | ❌ | Desktop-only |
| `server.nix` | ❌ | ✅ | ❌ | Server-only |
| `darwin.nix` | ❌ | ❌ | ✅ | macOS-only |
| `secrets.nix` | ✅ | ✅ | ✅ | All (via age) |
| `development.nix` | ✅ | ❌ | ✅ | Development hosts |

## Network Architecture

### SSH Key Matrix

All hosts have SSH keys registered in `modules/ssh-keys.nix`:

```
laptop  → can SSH to: server, macmini
server  → can SSH to: laptop, macmini  
macmini → can SSH to: laptop, server
```

Each host's `~/.ssh/authorized_keys` contains keys from all OTHER hosts.

### Secrets Distribution

Secrets are encrypted with age and distributed via:
```
secrets/age/*.age  (encrypted, committed to git)
    ↓
config.age.secrets.<name>.path  (decrypted at runtime)
```

Available on hosts that import `modules/secrets.nix`.

## Unified Home Manager

All three hosts share the same home-manager configuration:
- Same shell (zsh)
- Same prompt (Starship)
- Same Git config
- Same SSH client config
- Same VSCode settings

Platform-specific modules are conditionally imported:
```nix
# home/home.nix
imports = [
  ./programs/git.nix        # All platforms
  ./programs/zsh.nix        # All platforms
  ./programs/ssh.nix        # All platforms
  ./programs/starship.nix   # All platforms
  ./programs/vscode.nix     # All platforms
] ++ lib.optionals (!isDarwin) [
  ./programs/kde.nix        # Linux only
];
```

## Workflow Examples

### Scenario 1: Change Username Everywhere

```bash
# Edit once (on macmini, your primary computer)
vim settings/config/user.nix
# Change: username = "newname";

# Apply to macmini (local)
darwin-rebuild switch --flake .#macmini

# Apply to laptop (when you use it)
ssh laptop sudo nixos-rebuild switch --flake .#laptop

# Apply to server (when deployed)
ssh server sudo nixos-rebuild switch --flake .#server
```

### Scenario 2: Add Package to macOS (Primary)

```bash
# Edit on macmini
vim settings/config/darwin.nix
# Add to "packages" or "homebrew.casks"

# Apply immediately
darwin-rebuild switch --flake .#macmini

# Applies to: macmini ✅, laptop ❌, server ❌
```

### Scenario 3: Add Package to Linux Hosts Only

```bash
# Edit on macmini
vim settings/config/packages.nix
# Add to "linux" or "desktop" list

# Apply to laptop (when you use it)
ssh laptop sudo nixos-rebuild switch --flake .#laptop

# Applies to: laptop ✅, server ✅ (when deployed), macmini ❌
```

### Scenario 4: Test Config on Secondary Before Primary

```bash
# Make a risky change on macmini
vim settings/config/packages.nix

# Test on laptop first (secondary, less critical)
ssh laptop sudo nixos-rebuild test --flake .#laptop

# If it works, apply to macmini (primary)
darwin-rebuild switch --flake .#macmini
```

### Scenario 5: Change Shell Alias Everywhere

```bash
# Edit once on macmini (primary)
vim settings/config/shell.nix
# Add alias to "aliases"

# Apply to macmini immediately (you're using it now)
darwin-rebuild switch --flake .#macmini

# Apply to laptop next time you use it
ssh laptop sudo nixos-rebuild switch --flake .#laptop

# Propagates via home-manager to all hosts
```

## Rebuild Commands

### macmini (macOS - PRIMARY)

```bash
# Local rebuild (you're on macmini most of the time)
cd ~/.config/nix-config
darwin-rebuild switch --flake .#macmini

# Update flake inputs first
nix flake update
darwin-rebuild switch --flake .#macmini

# Just cleanup
sudo nix-collect-garbage -d
darwin-rebuild switch --flake .#macmini
```

### laptop (NixOS - SECONDARY)

```bash
# SSH into laptop from macmini
ssh laptop

# On the laptop
cd ~/.config/nix-config
sudo nixos-rebuild switch --flake .#laptop

# Or using aliases (if configured)
nrs

# Or remotely from macmini
nixos-rebuild switch --flake .#laptop \
  --target-host ewan@laptop-ip \
  --build-host localhost \
  --use-remote-sudo
```

### server (NixOS - NOT YET DEPLOYED)

```bash
# When you eventually deploy the server:

# On the server itself
cd /home/ewan/.config/nix-config
sudo nixos-rebuild switch --flake .#server

# Or remotely from macmini
nixos-rebuild switch --flake .#server \
  --target-host ewan@server-ip \
  --build-host localhost \
  --use-remote-sudo
```

## Maintenance

### Garbage Collection

**NixOS hosts** (laptop, server):
```bash
# Auto-runs weekly (configured in settings/config/nix.nix)
sudo nix-collect-garbage -d

# Manual cleanup
sudo nix-collect-garbage --delete-older-than 30d
```

**macOS host** (macmini):
```bash
# Manual only
sudo nix-collect-garbage -d
darwin-rebuild switch --flake .#macmini
```

### Updates

**Automated** (laptop, server):
- Configured in `settings/config/maintenance.nix`
- Daily auto-upgrades (if enabled)
- Weekly garbage collection

**Manual** (macmini):
- Update when needed
- No auto-upgrade configured (macOS best practice)

### Health Checks

All hosts can use the health-check tool:
```bash
# Compile once
nix run .#tools -- --help

# Run health check before rebuilding
tools/target/release/health-check

# Or use alias (after rebuild that includes it)
health-check
```

## When to Use Which Host

### Use **macmini** for (PRIMARY):
- Daily computing and primary workstation
- All general development work
- Web browsing, communication, productivity
- macOS/iOS development when needed
- Office work and documentation
- Multimedia consumption
- Apple ecosystem integration
- Any task that doesn't require Linux specifically

### Use **laptop** for:
- Linux-specific development
- Testing NixOS configurations
- KDE Plasma 6 customization and experimentation
- Gaming (especially native Linux games or Steam)
- When you need a portable Linux workstation
- Learning and experimenting with Linux

### Use **server** for (when deployed):
- Self-hosted services
- Home lab projects
- Always-on availability
- Remote access and SSH
- Background processing
- Learning server administration

## Migration Scenarios

### Moving laptop → server

If you want to repurpose laptop as a server:
```nix
# hosts/laptop/default.nix
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/users.nix
    ../../profiles/server-hardened.nix  # Add this
    # ../../modules/desktop.nix         # Remove desktop
    # ../../modules/gaming.nix          # Remove gaming
  ];
}
```

### Adding VM as 4th host

```bash
# 1. Generate hardware config on VM
sudo nixos-generate-config --show-hardware-config > hosts/vm/hardware-configuration.nix

# 2. Create hosts/vm/default.nix (use laptop or server as template)

# 3. Register in flake.nix
vm = mkNixOS {
  system   = "x86_64-linux";
  hostFile = ./hosts/vm;
  hostName = "vm";
};

# 4. Deploy
sudo nixos-rebuild switch --flake .#vm
```

## Troubleshooting Multi-Host Issues

### Same Username, Different Home Directories

Already handled via platform detection:
```nix
# home/home.nix
homeDir = if isDarwin 
  then "/Users/${cfg.user.username}"
  else "/home/${cfg.user.username}";
```

### SSH Between Hosts Not Working

Check ssh-keys.nix and authorized_keys:
```bash
# Verify keys are registered
cat modules/ssh-keys.nix

# Check authorized_keys was generated
cat ~/.ssh/authorized_keys

# Test connection
ssh -v ewan@other-host
```

### Config Change Affects Wrong Host

Check which modules import the setting:
```bash
# Find references
grep -r "cfg.gaming.enable" modules/
grep -r "../../modules/gaming.nix" hosts/
```

### Secrets Not Available on Host

Ensure host imports secrets module:
```nix
# hosts/<hostname>/default.nix
imports = [
  ../../modules/secrets.nix  # Must be imported
];
```

## Best Practices

1. **Keep hosts/*/default.nix minimal** — just imports and overrides
2. **Use settings/config/ for shared values** — edit once, apply everywhere
3. **Test on one host before deploying to all** — laptop → test → others
4. **Document host-specific quirks** — in host file comments
5. **Use version control** — commit after working changes
6. **Keep secrets separate** — never commit unencrypted secrets
7. **Regular backups** — especially of ~/.config/nix-config
8. **Monitor all hosts** — check logs after rebuild

## Resources

- [Host Modification Guide](hosts-modification.md) — How to modify and add hosts
- [Laptop Documentation](hosts-laptop.md) — Dell Inspiron 3501 specific
- [Server Documentation](hosts-server.md) — Headless server setup
- [macOS Documentation](hosts-macmini.md) — nix-darwin setup
- [Settings Reference](settings-config.md) — All configurable values
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nix-darwin Manual](https://github.com/LnL7/nix-darwin)
