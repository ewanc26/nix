# Host Modification Guide

This guide explains how to modify existing hosts, add new hosts, and customize host-specific behavior in your NixOS/nix-darwin configuration.

## Table of Contents

- [Understanding Host Architecture](#understanding-host-architecture)
- [Modifying Existing Hosts](#modifying-existing-hosts)
- [Adding New Hosts](#adding-new-hosts)
- [Host-Specific Customization](#host-specific-customization)
- [Common Modification Patterns](#common-modification-patterns)
- [Testing Changes](#testing-changes)

## Understanding Host Architecture

### Directory Structure

```
hosts/
├── laptop/                    # NixOS desktop/laptop
│   ├── default.nix
│   └── hardware-configuration.nix
├── server/                    # NixOS headless server
│   ├── default.nix
│   └── minimal-hardware.nix
└── macmini/                   # macOS with nix-darwin
    └── default.nix

modules/
├── common.nix                 # Shared NixOS modules
├── desktop.nix
├── gaming.nix
├── packages.nix
├── services.nix
├── users.nix
└── darwin/                    # macOS-specific modules
    ├── common.nix
    ├── packages.nix
    ├── homebrew.nix
    └── system.nix

settings/config/               # Global configuration values
```

### The Three Types of Config

1. **Global settings** (`settings/config/`) — shared values used everywhere
2. **Host files** (`hosts/*/default.nix`) — host-specific imports and overrides
3. **Modules** (`modules/`) — reusable components imported by hosts

### Configuration Layers

```
flake.nix
    ↓
hosts/<hostname>/default.nix   ← Host-specific configuration
    ↓
modules/*.nix                  ← Reusable components
    ↓
settings/config/*.nix          ← Global values (DRY)
```

## Modifying Existing Hosts

### Rule of Thumb

**✅ DO:** Edit `settings/config/` files for values
**✅ DO:** Add/remove module imports in host files
**✅ DO:** Add host-specific overrides sparingly
**❌ DON'T:** Hardcode values in host files
**❌ DON'T:** Duplicate logic across hosts

### Example: Enable Gaming on Laptop

**❌ Wrong way** (hardcoding in host file):
```nix
# hosts/laptop/default.nix
{
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  # ... duplicating gaming module logic
}
```

**✅ Right way** (using centralized config):
```nix
# settings/config/gaming.nix
{
  enable = true;  # Just change this
  # ...
}

# hosts/laptop/default.nix already imports ../../modules/gaming.nix
# The module reads from settings/config/gaming.nix
```

### Adding a Module Import

If a host doesn't currently import a module you need:

```nix
# hosts/laptop/default.nix
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/users.nix
    ../../modules/desktop.nix
    ../../modules/packages.nix
    ../../modules/services.nix
    ../../modules/gaming.nix
    ../../modules/NEW_MODULE.nix  # Add new import here
  ];
}
```

### Removing a Module Import

Comment out or delete the import line:

```nix
# hosts/laptop/default.nix
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/users.nix
    # ../../modules/gaming.nix  # Commented out - gaming disabled
  ];
}
```

### Host-Specific Overrides

Sometimes you need to override a value for just one host:

```nix
# hosts/laptop/default.nix
let
  cfg = cfgLib.cfg;
in
{
  imports = [ ... ];

  # Override timezone just for this host
  time.timeZone = lib.mkForce "America/New_York";

  # Or conditionally enable something
  services.undervolt.enable = true;  # Only on laptop with Intel CPU

  # Use values from settings/config/ everywhere else
  system.stateVersion = cfg.system.stateVersion;
}
```

### When to Use Host Files vs Settings

| Use host file when... | Use settings/config/ when... |
|---|---|
| Hardware-specific (e.g., GPU drivers) | Shared across multiple hosts |
| One-off override needed | Value should be centralized |
| Testing something temporarily | Long-term configuration |
| Host-unique service | Reusable configuration |

## Adding New Hosts

### Step 1: Create Host Directory

```bash
mkdir -p hosts/NEW-HOST
```

### Step 2: Generate Hardware Config (NixOS only)

```bash
# On the target machine (or in installer)
sudo nixos-generate-config --show-hardware-config > hosts/NEW-HOST/hardware-configuration.nix

# Or if installing from USB
sudo nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/NEW-HOST/
```

For macOS, skip this step (nix-darwin doesn't need hardware config).

### Step 3: Create default.nix

Choose a template based on your host type:

#### Desktop/Laptop Template (NixOS)

```nix
# hosts/NEW-HOST/default.nix
{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/users.nix
    ../../modules/desktop.nix
    ../../modules/packages.nix
    ../../modules/services.nix
    ../../modules/gaming.nix  # Optional
  ];

  networking.hostName = "NEW-HOST";

  # Audio (if desktop/laptop)
  security.rtkit.enable = cfg.audio.enable;
  services.pipewire = lib.mkIf (cfg.audio.enable && cfg.audio.backend == "pipewire") {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
    jack.enable       = true;
  };

  system.stateVersion = cfg.system.stateVersion;
}
```

#### Server Template (NixOS)

```nix
# hosts/NEW-HOST/default.nix
{ config, pkgs, lib, ... }:

let
  cfg = import ../../settings/config.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/users.nix
    ../../profiles/server-hardened.nix
  ];

  networking.hostName = "NEW-HOST";

  boot.tmp.cleanOnBoot = true;

  security.sudo = {
    enable             = true;
    wheelNeedsPassword = true;
  };

  system.stateVersion = cfg.system.stateVersion;
}
```

#### macOS Template (nix-darwin)

```nix
# hosts/NEW-HOST/default.nix
{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  imports = [
    ../../modules/darwin/common.nix
    ../../modules/darwin/packages.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/system.nix
  ];

  system.primaryUser = cfg.user.username;

  networking = {
    hostName     = "NEW-HOST";
    computerName = "New Host Display Name";
  };

  system.defaults.smb.NetBIOSName = "NEW-HOST";

  time.timeZone = "Europe/London";

  users.users.${cfg.user.username} = {
    home  = "/Users/${cfg.user.username}";
    shell = pkgs.${cfg.user.shell};
  };

  system.stateVersion = 5;
}
```

### Step 4: Register in flake.nix

Add your new host to the appropriate section:

#### For NixOS hosts:

```nix
# flake.nix
nixosConfigurations = rec {
  laptop  = mkNixOS { ... };
  server  = mkNixOS { ... };
  
  # Add new host here
  NEW-HOST = mkNixOS {
    system   = "x86_64-linux";  # or "aarch64-linux"
    hostFile = ./hosts/NEW-HOST;
    hostName = "NEW-HOST";
  };
};
```

#### For macOS hosts:

```nix
# flake.nix
darwinConfigurations = {
  macmini = mkDarwin { ... };
  
  # Add new host here
  NEW-HOST = mkDarwin {
    system   = "aarch64-darwin";  # or "x86_64-darwin"
    hostFile = ./hosts/NEW-HOST;
    hostName = "NEW-HOST";
  };
};
```

### Step 5: Build and Test

```bash
# Check for syntax errors
nix flake check

# Build (don't activate)
nixos-build --flake .#NEW-HOST

# Test on target machine
sudo nixos-rebuild test --flake .#NEW-HOST

# Make it permanent
sudo nixos-rebuild switch --flake .#NEW-HOST
```

### Step 6: Add SSH Key (Optional)

If this host needs to SSH into others or be SSHed into:

```nix
# modules/ssh-keys.nix
{
  laptop  = "ssh-ed25519 AAAAC3... ewan@laptop";
  server  = "ssh-ed25519 AAAAC3... ewan@server";
  macmini = "ssh-ed25519 AAAAC3... ewan@macmini";
  NEW-HOST = "ssh-ed25519 AAAAC3... ewan@NEW-HOST";  # Add this
}
```

Generate the key on the new host:
```bash
ssh-keygen -t ed25519 -C "ewan@NEW-HOST"
cat ~/.ssh/id_ed25519.pub  # Copy this to ssh-keys.nix
```

## Host-Specific Customization

### Using lib.mkIf for Conditional Config

```nix
# hosts/laptop/default.nix
{
  # Only on laptop
  services.tlp.enable = true;
  
  # Only if gaming is enabled
  programs.steam.enable = lib.mkIf cfg.gaming.enable true;
  
  # Only if this is a laptop with Intel CPU
  services.undervolt = lib.mkIf (hostName == "laptop") {
    enable = true;
    coreOffset = -100;
  };
}
```

### Platform-Specific Logic

```nix
# A module that works on both NixOS and macOS
{ config, pkgs, lib, isDarwin ? false, ... }:

{
  home.packages = with pkgs; [
    git
    curl
  ] ++ lib.optionals (!isDarwin) [
    # Linux-only
    htop
    btop
  ] ++ lib.optionals isDarwin [
    # macOS-only  
    mas
  ];
}
```

### Per-Host Package Lists

If you want different packages per host, use conditionals:

```nix
# settings/config/packages.nix
{
  # Shared packages
  common = [ "git" "curl" "vim" ];
  
  # Desktop packages
  desktop = [
    "firefox"
    "vlc"
  ];
  
  # Host-specific
  laptop-only = [ "tlp" "powertop" ];
  server-only = [ "htop" "iotop" ];
}
```

Then in modules:
```nix
# modules/packages.nix
environment.systemPackages = 
  (map (p: pkgs.${p}) cfg.packages.common)
  ++ (map (p: pkgs.${p}) cfg.packages.desktop)
  ++ lib.optionals (hostName == "laptop") (map (p: pkgs.${p}) cfg.packages.laptop-only);
```

## Common Modification Patterns

### Pattern 1: Add a Service to One Host

```nix
# hosts/server/default.nix
{
  services.nginx = {
    enable = true;
    virtualHosts."example.com" = {
      root = "/var/www/example.com";
    };
  };
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

### Pattern 2: Override a Setting Globally for Testing

```nix
# settings/config/system.nix (TEMPORARY - test on all hosts)
{
  autoUpgrade = false;  # Disable auto-upgrades while testing
}
```

### Pattern 3: Different Desktop Environments per Host

```nix
# settings/config/desktop.nix
{
  # Change per rebuild or make this host-conditional
  environment = "plasma6";  # laptop uses this
  # environment = "gnome";  # another-host could use this
}
```

Or with host-specific logic in the desktop module:
```nix
# modules/desktop.nix
{
  services.desktopManager.plasma6.enable = 
    (cfg.desktop.environment == "plasma6");
  services.xserver.desktopManager.gnome.enable = 
    (cfg.desktop.environment == "gnome");
}
```

### Pattern 4: Sharing Secrets Between Hosts

```nix
# settings/config/secrets.nix
{
  files = [
    "wifi-home"      # Available on: laptop, NEW-HOST
    "ssh-passphrase" # Available on: all hosts
    "api-keys"       # Available on: laptop, server
  ];
}

# Then in hosts that need them:
# hosts/laptop/default.nix
{
  imports = [ ../../modules/secrets.nix ];
  
  # Now config.age.secrets.wifi-home.path is available
}
```

### Pattern 5: Host-Specific Hardware Config

```nix
# hosts/laptop/default.nix
{
  # Laptop-specific: enable touchpad
  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };
  
  # Laptop-specific: power management
  services.tlp.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";
}

# hosts/server/default.nix
{
  # Server doesn't need touchpad or power management
  # But might need:
  services.smartd.enable = true;  # Disk health monitoring
}
```

## Testing Changes

### Local Testing Workflow

```bash
# 1. Edit configuration
vim settings/config/packages.nix

# 2. Check syntax
nix flake check

# 3. Build without activating (NixOS)
nixos-rebuild build --flake .#laptop

# 4. Test without making it default boot entry
sudo nixos-rebuild test --flake .#laptop

# 5. If all looks good, make it permanent
sudo nixos-rebuild switch --flake .#laptop

# 6. If something breaks, rollback
sudo nixos-rebuild --rollback
```

### Testing on a Different Host Remotely

```bash
# From your main machine, deploy to remote host
nixos-rebuild switch --flake .#server \
  --target-host ewan@192.168.1.100 \
  --build-host localhost \
  --use-remote-sudo
```

### Testing Host-Specific Changes Without Affecting Others

Each host is independent:
```bash
# Test on laptop (doesn't affect server)
sudo nixos-rebuild test --flake .#laptop

# Test on server (doesn't affect laptop)
ssh server
sudo nixos-rebuild test --flake /home/ewan/.config/nix-config#server
```

### Dry Run Mode

```bash
# See what would change without applying
nixos-rebuild dry-build --flake .#laptop

# Or just check evaluation
nix eval .#nixosConfigurations.laptop.config.system.build.toplevel
```

## Advanced: Creating Host Profiles

If you have similar hosts, create reusable profiles:

```nix
# profiles/workstation.nix
{ config, pkgs, lib, cfgLib, ... }:

{
  imports = [
    ../modules/common.nix
    ../modules/users.nix
    ../modules/desktop.nix
    ../modules/packages.nix
    ../modules/services.nix
    ../modules/gaming.nix
  ];
  
  # Common workstation settings
  security.rtkit.enable = true;
  services.pipewire.enable = true;
}

# Then in host files:
# hosts/laptop/default.nix
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/workstation.nix  # Pulls in all common workstation config
  ];
  
  # Just host-specific overrides here
  networking.hostName = "laptop";
}
```

## Best Practices

1. **Keep host files minimal** — import modules, set hostname, done
2. **Use settings/config/ for values** — one source of truth
3. **Put reusable logic in modules** — not in host files
4. **Use profiles for similar hosts** — reduce duplication
5. **Test before committing** — `nix flake check` and test builds
6. **Document host-specific quirks** — in comments or docs/hosts-*.md
7. **Use version control** — commit after each working change
8. **Keep hardware-configuration.nix separate** — don't edit it manually

## Common Pitfalls

❌ **Duplicating configuration across hosts:**
```nix
# DON'T DO THIS in multiple host files
time.timeZone = "Europe/London";
```
✅ **Use centralized config:**
```nix
# settings/config/system.nix
{ timeZone = "Europe/London"; }
```

❌ **Hardcoding values in host files:**
```nix
# DON'T
home.username = "ewan";
```
✅ **Reference centralized config:**
```nix
# DO
home.username = cfg.user.username;
```

❌ **Complex logic in host files:**
```nix
# DON'T put business logic here
services.nginx = { /* 50 lines of config */ };
```
✅ **Extract to a module:**
```nix
# Create modules/nginx.nix
# Import it in host file
imports = [ ../../modules/nginx.nix ];
```

## Getting Help

- **Syntax errors**: Run `nix flake check`
- **Module conflicts**: Check which modules are imported
- **Can't find option**: Use `man configuration.nix` or search [NixOS options](https://search.nixos.org)
- **Host won't build**: Check logs with `nixos-rebuild switch --show-trace`
- **Rollback needed**: Use GRUB menu or `nixos-rebuild --rollback`

## Resources

- [NixOS Manual - Configuration](https://nixos.org/manual/nixos/stable/#sec-configuration-file)
- [NixOS Options Search](https://search.nixos.org/options)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [nix-darwin Manual](https://github.com/LnL7/nix-darwin/blob/master/README.md)
