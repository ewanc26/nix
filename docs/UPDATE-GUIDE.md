# System Update Guide

This guide covers how to update your NixOS configuration across all your systems.

## Quick Commands

### Update Current System Only
```bash
update-all
```
This will:
1. Update flake.lock (all Nix inputs)
2. Rebuild the current system
3. Update Homebrew packages (macOS only)
4. Optionally run garbage collection

### Update All Systems at Once
```bash
update-everything
```
This will:
1. Check which systems are online via Tailscale
2. Update flake.lock on each system
3. Rebuild each system remotely over SSH
4. Show a summary of successes/failures

**Recommended**: Run this from **macmini** since it's always on.

## Manual Update Commands

### Update Just the Flake Inputs
```bash
cd ~/.config/nix-config
nix flake update
```

This updates all dependencies in flake.lock:
- nixpkgs (NixOS/Darwin packages)
- home-manager (user environment)
- nix-darwin (macOS system management)
- All other inputs

### Rebuild Current System
```bash
# NixOS (laptop, server)
nrs  # Alias for: sudo nixos-rebuild switch --flake .#hostname

# macOS (macmini)
nrs  # Alias for: sudo darwin-rebuild switch --flake .#macmini
```

### Update a Remote System
```bash
# Update laptop from any other machine
ssh laptop 'cd ~/.config/nix-config && nix flake update && sudo nixos-rebuild switch --flake .#laptop'

# Update server
ssh server 'cd ~/.config/nix-config && nix flake update && sudo nixos-rebuild switch --flake .#server'

# Update macmini
ssh macmini 'cd ~/.config/nix-config && nix flake update && sudo darwin-rebuild switch --flake .#macmini'
```

## Update Specific Components

### Update Only Specific Flake Inputs
```bash
cd ~/.config/nix-config

# Update just nixpkgs
nix flake lock --update-input nixpkgs

# Update just home-manager
nix flake lock --update-input home-manager

# Update multiple inputs
nix flake lock --update-input nixpkgs --update-input home-manager
```

### Homebrew Only (macOS)
```bash
brew update      # Update Homebrew itself
brew upgrade     # Upgrade all packages
brew upgrade tailscale  # Upgrade specific package
```

### Garbage Collection
```bash
# Alias (works on all systems)
cleanup

# Manual (NixOS)
sudo nix-collect-garbage -d  # System profiles
nix-collect-garbage -d       # User profiles

# Manual (macOS)
sudo nix-collect-garbage -d  # All profiles
```

## Update Workflow Recommendations

### Daily Updates (Automated)
NixOS systems (laptop, server) have automatic updates enabled:
- Runs daily with 45-minute random delay
- Updates only nixpkgs input
- Does NOT reboot automatically
- Configured in `settings/config/maintenance.nix`

### Manual Updates (Recommended Weekly)

**Option 1: Update Everything from One Machine**
```bash
# From macmini (recommended since it's always on)
update-everything
```

**Option 2: Update Each System Individually**
```bash
# On each system, run:
update-all
```

**Option 3: Hybrid Approach**
```bash
# Update macmini locally
update-all

# Update Linux systems remotely
ssh laptop 'cd ~/.config/nix-config && nix flake update && sudo nixos-rebuild switch --flake .#laptop'
ssh server 'cd ~/.config/nix-config && nix flake update && sudo nixos-rebuild switch --flake .#server'
```

## Checking for Updates

### View Available Updates
```bash
cd ~/.config/nix-config
nix flake lock --update-input nixpkgs --dry-run
```

### Compare Generations
```bash
# See what changed between generations
gen-diff  # Custom tool if available

# Or manually:
nix profile diff-closures --profile /nix/var/nix/profiles/system
```

### Check Current Versions
```bash
# System version
nixos-version        # NixOS
sw_vers             # macOS

# Nix version
nix --version

# Package versions
nix-env -q          # User packages
```

## Rollback If Needed

### NixOS
```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Boot into specific generation
sudo nixos-rebuild boot --rollback
```

### macOS (nix-darwin)
```bash
# List generations
darwin-rebuild --list-generations

# Rollback
sudo darwin-rebuild switch --rollback
```

## Troubleshooting Updates

### Flake Update Fails
```bash
# Try updating inputs individually
nix flake lock --update-input nixpkgs
nix flake lock --update-input home-manager

# Check for syntax errors
nix flake check
```

### Build Fails
```bash
# Try building without switching
sudo nixos-rebuild build --flake .#hostname

# Check for errors
nix-store --verify --check-contents
```

### Remote Update Fails
```bash
# Check SSH connectivity
ssh hostname echo "Connected"

# Check Tailscale
tailscale status

# Manually update
ssh hostname
cd ~/.config/nix-config
sudo nixos-rebuild switch --flake .#hostname
```

### Out of Disk Space
```bash
# Aggressive garbage collection
sudo nix-collect-garbage --delete-older-than 7d
nix-store --gc
nix-store --optimise
```

## Best Practices

1. **Always commit changes** before updating:
   ```bash
   cd ~/.config/nix-config
   git add -A
   git commit -m "Pre-update checkpoint"
   ```

2. **Test updates on one system first** (recommend laptop):
   ```bash
   ssh laptop 'cd ~/.config/nix-config && update-all'
   ```

3. **Update all systems regularly** (weekly recommended):
   ```bash
   update-everything
   ```

4. **Keep a rollback plan**:
   - NixOS can always rollback to previous generation
   - Commit flake.lock changes to git for easy reversion

5. **Monitor disk space**:
   ```bash
   df -h
   # Run cleanup if needed
   cleanup
   ```

## Update Schedule

### Recommended Schedule

- **Daily**: Let automatic updates run (NixOS only)
- **Weekly**: Run `update-everything` to update all systems
- **Monthly**: Run `cleanup` on all systems
- **After Major Changes**: Test on one system before deploying to all

### Automatic Updates

Current configuration (`settings/config/maintenance.nix`):
- **Enabled**: Yes (NixOS only)
- **Frequency**: Daily
- **Updates**: nixpkgs input
- **Auto-reboot**: No

To disable:
```nix
autoUpgrade = {
  enable = false;
  # ...
};
```
