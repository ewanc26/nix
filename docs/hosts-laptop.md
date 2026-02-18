# Laptop Host

Dell Inspiron 3501 running NixOS with KDE Plasma 6 desktop environment.

## Hardware Specifications

- **Model**: Dell Inspiron 3501
- **CPU**: Intel Core i3-1115G4 (Tiger Lake, 11th Gen)
  - 2 cores / 4 threads
  - Base: 3.0 GHz, Boost: 4.1 GHz
- **RAM**: 8 GB DDR4-3200
- **Storage**: 256 GB NVMe SSD
- **GPU**: Intel UHD Graphics (Xe)
- **Display**: 15.6" 1920x1080 (Full HD)
- **WiFi**: Intel Wi-Fi 6 AX201 (802.11ax)
- **Bluetooth**: 5.1
- **Ethernet**: Realtek RTL8111/8168/8411
- **Audio**: Realtek ALC3204
- **Webcam**: 720p

## Features

**Desktop Environment:**
- KDE Plasma 6 (Wayland session preferred)
- SDDM display manager
- Catppuccin Mocha theme with Green accent
- Kvantum Qt theming engine
- Papirus icon theme

**Included:**
- Full desktop environment with all KDE applications
- Audio via PipeWire (with ALSA, PulseAudio, and JACK compatibility)
- Gaming support (Steam, Gamemode, Mesa drivers)
- Development tools (VSCode, Git, languages)
- Multimedia packages
- Office applications
- Web browsers
- Communication tools
- System monitoring utilities

**System Features:**
- Auto-upgrades (configurable)
- Automatic garbage collection
- SSD TRIM support
- Power management optimizations
- Intel microcode updates
- Hardware video acceleration
- Bluetooth support

## Installation

### From NixOS Installer

1. **Boot installer and partition disks**
   ```bash
   # Example partitioning scheme (adjust to your needs)
   sudo parted /dev/nvme0n1 -- mklabel gpt
   sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
   sudo parted /dev/nvme0n1 -- set 1 esp on
   sudo parted /dev/nvme0n1 -- mkpart primary 512MiB 100%
   
   # Format partitions
   sudo mkfs.fat -F 32 -n boot /dev/nvme0n1p1
   sudo mkfs.ext4 -L nixos /dev/nvme0n1p2
   
   # Mount
   sudo mount /dev/disk/by-label/nixos /mnt
   sudo mkdir -p /mnt/boot
   sudo mount /dev/disk/by-label/boot /mnt/boot
   ```

2. **Generate hardware configuration**
   ```bash
   sudo nixos-generate-config --root /mnt
   # Copy the generated hardware-configuration.nix to your repo
   ```

3. **Clone or download configuration**
   ```bash
   cd /mnt/etc/nixos
   curl -L https://github.com/ewanc26/nix/archive/refs/heads/main.tar.gz | sudo tar -xz --strip-components=1
   ```

4. **Copy your hardware config**
   ```bash
   sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/laptop/
   ```

5. **Install**
   ```bash
   sudo nixos-install --flake .#laptop
   sudo reboot
   ```

### Switching from existing NixOS

```bash
cd ~/.config
curl -L https://github.com/ewanc26/nix/archive/refs/heads/main.tar.gz | tar -xz
mv nix-main nix-config && cd nix-config

# Generate fresh hardware config if needed
sudo nixos-generate-config --show-hardware-config > hosts/laptop/hardware-configuration.nix

# Switch to the new config
sudo nixos-rebuild switch --flake .#laptop
```

## Configuration Structure

```
hosts/laptop/
├── default.nix              # Main laptop configuration
└── hardware-configuration.nix   # Auto-generated hardware config

# Imported modules
modules/
├── common.nix               # Base NixOS settings (nix config, networking, locale)
├── users.nix                # User account creation
├── desktop.nix              # KDE Plasma 6 + SDDM
├── packages.nix             # Desktop applications
├── services.nix             # System services (printing, bluetooth, etc.)
└── gaming.nix               # Gaming packages and Steam

# Desktop configuration
home/programs/kde.nix        # User-level Plasma config (Konsole, fonts, theme)
settings/plasma/             # Declarative Plasma settings
```

## Daily Usage

### Rebuild System

```bash
# Quick rebuild (from within the repo)
sudo nixos-rebuild switch --flake .#laptop

# Or use the alias (defined in shell.nix)
nrs

# Test without making it the default boot entry
sudo nixos-rebuild test --flake .#laptop

# Build for next boot (no immediate activation)
sudo nixos-rebuild boot --flake .#laptop
```

### Update System

```bash
# Update all flake inputs
cd ~/.config/nix-config
nix flake update

# Or use the helper script
flake-bump

# Then rebuild
sudo nixos-rebuild switch --flake .#laptop

# Or use the update alias (updates + rebuilds)
update
```

### Rollback

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Boot into a specific generation (from GRUB bootloader)
# Select generation at boot time
```

### Maintenance

```bash
# Garbage collection (auto-runs weekly)
sudo nix-collect-garbage -d

# Or use the alias
cleanup

# Check system health before rebuilding
health-check

# View what changed between generations
gen-diff
```

## Customization

For values shared across all hosts, edit the defaults in `modules/options.nix`. For laptop-only behaviour, add `myConfig.*` overrides in `hosts/laptop/default.nix`.

### Common Customizations

| What to change | Where to edit |
|---|---|
| Username / email | `modules/options.nix` → `user.*` defaults |
| Desktop theme | `modules/options.nix` → `desktop.theme` / `desktop.iconTheme` |
| Fonts | `modules/options.nix` → `desktop.monoFontBase` |
| Add applications | `modules/options.nix` → `packages.desktop` list |
| Gaming enable/disable | `hosts/laptop/default.nix` → `myConfig.gaming.enable` |
| Audio backend | `modules/options.nix` → `audio.backend` |
| VSCode extensions | `home/programs/vscode.nix` |
| Shell aliases | `home/programs/zsh.nix` → `shellAliases` |
| Git settings | `modules/options.nix` → `git.*` or `home/programs/git.nix` |
| Plasma layout | `settings/plasma/default.nix` |
| Konsole theme | `home/programs/kde.nix` |

### Adding Packages

**System-wide packages** (available to all users):
```nix
# modules/options.nix
packages.desktop = mkOption {
  default = [
    # ... existing list ...
    "my-new-package"   # add here
  ];
};
```

**Linux-only user packages**:
```nix
# modules/options.nix
packages.linux = mkOption {
  default = [
    "vlc"
    "my-linux-tool"   # add here
  ];
};
```

### Disabling Gaming

Remove or comment out the override in the laptop host file:
```nix
# hosts/laptop/default.nix
# myConfig.gaming.enable = true;  ← remove this line
```

The default in `modules/options.nix` is `false`, so removing the override disables it.

### Changing Audio Backend

To switch from PipeWire to PulseAudio:
```nix
# modules/options.nix (changes all hosts) — or override in hosts/laptop/default.nix
myConfig.audio.backend = "pulseaudio";
```

### KDE Plasma Customization

**Declarative settings** (recommended):
```nix
# settings/plasma/default.nix
# Edit panel layout, workspace behavior, shortcuts, etc.

# home/programs/kde.nix
# Edit fonts, theme, Konsole profile, etc.
```

Changes are applied on the next `nixos-rebuild switch`.

**GUI settings**:
While Plasma settings are declarative, you can still use the GUI to preview changes. However, to make them permanent, you must translate them to Nix configuration. The `plasma-manager` module ensures reproducibility.

## Hardware-Specific Notes

### Intel Graphics

The laptop uses Intel UHD Graphics (Xe). Hardware acceleration is enabled by default:
- VA-API for video decoding
- Vulkan support
- OpenGL support

### WiFi

Intel AX201 WiFi 6 card is fully supported. No special configuration needed.

### Power Management

Power optimizations are automatically applied:
- CPU frequency scaling
- Laptop mode for disk
- WiFi power saving
- Automatic screen blanking

To customize power settings:
```nix
# hosts/laptop/default.nix
# Add:
services.tlp.enable = true;  # Advanced power management
# or
powerManagement.cpuFreqGovernor = "powersave";  # Manual governor
```

### Touchpad

KDE Plasma handles touchpad configuration through System Settings. Default gestures are enabled.

## Troubleshooting

### Display Issues

**Screen tearing:**
```nix
# hosts/laptop/default.nix
# Add to services.xserver:
services.xserver = {
  videoDrivers = [ "modesetting" ];  # Already set
  # Force compositor
};

# Or in KDE System Settings:
# System Settings → Display and Monitor → Compositor → VSync
```

**Brightness control not working:**
```bash
# Check if it works with:
brightnessctl set 50%

# If not, add to hosts/laptop/default.nix:
programs.light.enable = true;
```

### Audio Issues

**No sound:**
```bash
# Check PipeWire status
systemctl --user status pipewire pipewire-pulse

# Restart audio
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check output devices
pactl list sinks short
```

**Bluetooth audio crackling:**
```nix
# settings/config/audio.nix or hosts/laptop/default.nix
# Add PipeWire config for better Bluetooth quality
```

### WiFi Issues

**WiFi not working:**
```bash
# Check if device is recognized
lspci -k | grep -A 3 -i network

# Check status
nmcli device status

# Restart NetworkManager
sudo systemctl restart NetworkManager
```

### Gaming Issues

**Steam won't launch:**
```bash
# Check if gaming is enabled
# settings/config/gaming.nix → enable = true

# Reinstall Steam
nix-store --query --references $(which steam) | grep steam

# Clear Steam cache
rm -rf ~/.local/share/Steam
```

**Poor game performance:**
```nix
# Ensure Gamemode is enabled (should be by default)
# settings/config/gaming.nix → gamemode = true
```

### System Won't Boot

**Boot into previous generation:**
1. At GRUB menu, select "NixOS - All configurations"
2. Select a previous generation
3. Boot into it
4. Fix the issue in config
5. Rebuild

**From live USB:**
```bash
# Mount your system
sudo mount /dev/nvme0n1p2 /mnt
sudo mount /dev/nvme0n1p1 /mnt/boot

# Chroot into it
sudo nixos-enter

# Rollback
nix-env --rollback --profile /nix/var/nix/profiles/system

# Or manually activate a generation
ls /nix/var/nix/profiles/system-*-link
/nix/var/nix/profiles/system-XXX-link/bin/switch-to-configuration switch
```

## Performance Tuning

### Optimize for SSD

Already included by default:
- TRIM support (weekly automatic TRIM)
- Proper I/O scheduler
- noatime mount option

### Speed up boot

```nix
# hosts/laptop/default.nix
boot.kernelParams = [ "quiet" "splash" ];
systemd.services.NetworkManager-wait-online.enable = false;
```

### Reduce memory usage

```nix
# settings/config/desktop.nix
# Remove unused packages from plasma.excludePackages

# settings/config/packages.nix
# Comment out packages you don't use
```

## Backup and Recovery

### Backup important files

```bash
# Config
tar -czf ~/nixos-config-backup.tar.gz ~/.config/nix-config

# Home directory (excluding large dirs)
tar -czf ~/home-backup.tar.gz \
  --exclude='.cache' \
  --exclude='.local/share/Steam' \
  --exclude='Downloads' \
  ~/
```

### Restore config

```bash
cd ~/.config
tar -xzf ~/nixos-config-backup.tar.gz
cd nix-config
sudo nixos-rebuild switch --flake .#laptop
```

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [KDE Plasma Documentation](https://docs.kde.org/)
- [plasma-manager](https://github.com/pjones/plasma-manager)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Dell Inspiron on Linux](https://wiki.archlinux.org/title/Dell_Inspiron)
