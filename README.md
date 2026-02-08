# NixOS Configuration for Dell Inspiron 3501

A hyper-organized, flake-based NixOS configuration for a Dell Inspiron 3501 laptop with Intel Core i3-1115G4.

## 📁 Structure

```
dotfiles-nix/
├── flake.nix                    # Main flake configuration
├── configuration.nix            # Main NixOS configuration
├── hardware-configuration.nix   # Hardware-specific settings
├── wallpapers/                  # Wallpaper images
│   └── wallpaper.jpg           # Default wallpaper
├── modules/
│   ├── desktop.nix             # Desktop environment (GNOME)
│   ├── packages.nix            # System packages
│   ├── services.nix            # System services
│   └── gaming.nix              # Steam and gaming setup
└── home/
    ├── home.nix                # Main home-manager config
    └── programs/
        ├── git.nix             # Git configuration
        ├── zsh.nix             # Zsh shell setup
        ├── starship.nix        # Starship prompt
        ├── fastfetch.nix       # Fastfetch config
        ├── gnome.nix           # GNOME settings & wallpaper
        └── vscode.nix          # VSCode settings
```

## 🖥️ Hardware Specifications

- **Model**: Dell Inspiron 3501
- **CPU**: Intel Core i3-1115G4 (11th Gen Tiger Lake)
- **RAM**: 8GB DDR4-3200
- **Storage**: 256GB PCIe NVMe SSD (Toshiba BG4)
- **Graphics**: Intel UHD Graphics (integrated)
- **Display**: 15.6" FHD (1920x1080) non-touch
- **WiFi**: Intel 9462AC
- **Battery**: 42Wh 3-cell

## 📦 Included Software

### System Tools

- **git** - Version control
- **fastfetch** - System information
- **starship** - Modern shell prompt
- **zsh** - Z Shell

### Applications

- **Firefox** - Web browser
- **VSCode** - Code editor with extensions
- **Spotify** - Music streaming
- **Discord** - Communication
- **Steam** - Gaming platform (with GameMode)
- **Prism Launcher** - Minecraft launcher

### Desktop Environment

- **GNOME** - Default desktop environment
- **GDM** - Display manager

## 🚀 Installation

### First-time Setup

1. **Boot NixOS installer** and partition your disk:

   ```bash
   # Example partitioning (adjust as needed)
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

2. **Generate hardware config** (to get UUIDs):

   ```bash
   sudo nixos-generate-config --root /mnt
   ```

3. **Clone this repository**:

   ```bash
   cd /mnt/etc/nixos
   git clone https://github.com/ewanc26/dotfiles-nix .
   ```

4. **Update hardware-configuration.nix** with the UUIDs from `/mnt/etc/nixos/hardware-configuration.nix`:

   ```bash
   # Copy the UUIDs from the generated file
   cat /mnt/etc/nixos/hardware-configuration.nix
   # Update the UUIDs in our hardware-configuration.nix
   ```

5. **Customize git config** in `home/programs/git.nix`:
   - Update `userName` and `userEmail`

6. **Install NixOS**:

   ```bash
   sudo nixos-install --flake .#laptop
   ```

7. **Reboot** and login with your user account.

### Updating the System

After making changes to the configuration:

```bash
# Full system update (NixOS + Home Manager)
update

# Or separately:
nrs   # NixOS rebuild switch
hms   # Home Manager switch
```

### Useful Commands

```bash
# Rebuild and switch
sudo nixos-rebuild switch --flake .#laptop

# Rebuild for next boot (doesn't switch immediately)
sudo nixos-rebuild boot --flake .#laptop

# Test configuration without making it default
sudo nixos-rebuild test --flake .#laptop

# Update flake inputs
nix flake update

# Clean up old generations
cleanup
```

## 🎨 Customization

### Change Desktop Environment

Edit `modules/desktop.nix` to use a different DE/WM. For example, to use KDE Plasma:

```nix
services.xserver = {
  enable = true;
  displayManager.sddm.enable = true;
  desktopManager.plasma5.enable = true;
};
```

### Add More Packages

Edit `modules/packages.nix` or `home/home.nix` to add more packages.

### Modify Shell Configuration

Edit `home/programs/zsh.nix` for shell aliases and settings.

### Adjust Power Management

Edit the TLP settings in `hardware-configuration.nix` to tune battery life vs performance.

### Change Wallpaper

The wallpaper is configured in `home/programs/gnome.nix`:

1. Add your new wallpaper image to the `wallpapers/` directory
2. Update the file reference in `home/programs/gnome.nix`:
   ```nix
   home.file.".config/wallpapers/wallpaper.jpg" = {
     source = ../../wallpapers/your-new-wallpaper.jpg;
   };
   ```
3. Run `make switch` to apply

The wallpaper is automatically set for both the desktop background and lock screen.

## 📝 Notes

- **First Boot**: The first boot may take a while as Nix downloads and builds everything.
- **Updates**: Run `nix flake update` periodically to update your packages.
- **Rollbacks**: If something breaks, you can select an older generation from the boot menu.
- **Garbage Collection**: Run `cleanup` regularly to free up disk space.

## 🔧 Troubleshooting

### Boot Issues

- Check that UUIDs in `hardware-configuration.nix` match your actual partitions
- Try booting from an older generation in the boot menu

### Graphics Issues

- Intel graphics should work out of the box
- If you experience issues, check `hardware-configuration.nix` graphics settings

### WiFi Not Working

- Ensure Intel WiFi firmware is loaded: `lsmod | grep iwlwifi`
- Check NetworkManager status: `systemctl status NetworkManager`

## 📚 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Package Search](https://search.nixos.org/)
- [NixOS Wiki](https://nixos.wiki/)

## 📄 License

This configuration is free to use and modify as needed.
