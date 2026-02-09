# NixOS Configuration for Dell Inspiron 3501

A hyper-organized, flake-based NixOS configuration for a Dell Inspiron 3501 laptop with Intel Core i3-1115G4.

## 📁 Structure

```
dotfiles-nix/
├── flake.nix                    # Main flake configuration
├── hosts/                       # Host-specific configurations
│   ├── README.md               # Guide for adding new hosts
│   └── laptop/                 # Dell Inspiron 3501 configuration
│       ├── default.nix         # Main host configuration
│       └── hardware-configuration.nix  # Hardware-specific settings
├── wallpapers/                  # Wallpaper images
│   └── wallpaper.jpg           # Default wallpaper
├── modules/                     # Reusable NixOS modules
│   ├── desktop.nix             # Desktop environment (GNOME)
│   ├── packages.nix            # System packages (uses options where possible)
│   ├── services.nix            # System services
│   └── gaming.nix              # Steam and gaming setup
└── home/                        # Home Manager configuration
    ├── home.nix                # Main home-manager config
    └── programs/
        ├── git.nix             # Git configuration
        ├── zsh.nix             # Zsh shell setup
        ├── starship.nix        # Starship prompt
        ├── fastfetch.nix       # Fastfetch config
        ├── gnome.nix           # GNOME settings & wallpaper
        └── vscode.nix          # VSCode settings
```

## 🏗️ Architecture

### Hosts Directory

This configuration uses a **hosts-based architecture** for easy multi-system management:

- Each physical machine gets its own directory under `hosts/`
- Host-specific settings (hostname, hardware config) are isolated
- Shared modules (desktop, packages, services) are imported by each host
- Easy to add new machines - see `hosts/README.md` for details

### Options vs System Packages

This configuration follows NixOS best practices by using **declarative options** instead of just adding packages:

**✅ Good (Using Options):**
```nix
programs.firefox.enable = true;
programs.steam.enable = true;
```

**❌ Less Ideal (Only System Packages):**
```nix
environment.systemPackages = with pkgs; [ firefox steam ];
```

**Why Options are Better:**
- More declarative and clear
- Provides additional configuration options
- Better integration with NixOS
- Enables/disables related services automatically
- Some programs require options (e.g., Steam needs firewall rules)

**When to Use System Packages:**
- When no official NixOS option exists for the program
- For simple utilities that don't need configuration
- See `modules/packages.nix` for our approach

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

- **git** - Version control (via `programs.git`)
- **fastfetch** - System information
- **starship** - Modern shell prompt
- **zsh** - Z Shell (via `programs.zsh`)

### Applications

- **Firefox** - Web browser (via `programs.firefox`)
- **VSCode** - Code editor with extensions (via `programs.vscode`)
- **Spotify** - Music streaming
- **Discord** - Communication
- **Steam** - Gaming platform (via `programs.steam` with GameMode)
- **Prism Launcher** - Minecraft launcher

### Desktop Environment

- **GNOME** - Default desktop environment
- **GDM** - Display manager

## 🚀 Installation

### Option A: Switching from Stock NixOS (Recommended)

If you already have NixOS installed and want to switch to this configuration:

1. **Enable flakes and git** (if not already enabled):

   ```bash
   # Temporarily enable flakes for this session
   nix-shell -p git nixFlakes
   ```

2. **Backup your current configuration**:

   ```bash
   sudo cp -r /etc/nixos /etc/nixos.backup
   ```

3. **Clone this repository**:

   ```bash
   cd /tmp
   git clone https://github.com/ewanc26/dotfiles-nix
   cd dotfiles-nix
   ```

4. **Generate and update hardware configuration**:

   ```bash
   # Generate fresh hardware config
   sudo nixos-generate-config --show-hardware-config > hosts/laptop/hardware-configuration.nix
   
   # Make sure file permissions are correct
   sudo chown $USER:users hosts/laptop/hardware-configuration.nix
   ```

5. **Customize the configuration**:

   - **Edit `hosts/laptop/default.nix`**: Update the hostname if needed
   - **Edit `home/programs/git.nix`**: Set your git username and email
   - **Review `modules/packages.nix`**: Add or remove packages as needed

6. **Test the configuration** (optional but recommended):

   ```bash
   sudo nixos-rebuild test --flake .#laptop
   ```

   This will apply the configuration temporarily without making it permanent. If something goes wrong, just reboot to go back to your old config.

7. **Apply the configuration**:

   ```bash
   sudo nixos-rebuild switch --flake .#laptop
   ```

8. **Move configuration to /etc/nixos** (optional but recommended):

   ```bash
   sudo rm -rf /etc/nixos/*
   sudo cp -r * /etc/nixos/
   sudo chown -R root:root /etc/nixos
   ```

9. **Reboot and enjoy**:

   ```bash
   sudo reboot
   ```

### Option B: Fresh Installation

If you're installing NixOS from scratch:

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

2. **Clone this repository**:

   ```bash
   cd /mnt/etc/nixos
   sudo nix-shell -p git
   sudo git clone https://github.com/ewanc26/dotfiles-nix .
   ```

3. **Generate hardware configuration**:

   ```bash
   sudo nixos-generate-config --show-hardware-config > hosts/laptop/hardware-configuration.nix
   ```

4. **Customize git config** in `home/programs/git.nix`:
   - Update `userName` and `userEmail`

5. **Install NixOS**:

   ```bash
   sudo nixos-install --flake .#laptop
   ```

6. **Reboot** and login with your user account.

## 🔄 Updating the System

After making changes to the configuration:

```bash
# Rebuild and switch to the new configuration
sudo nixos-rebuild switch --flake .#laptop

# Update flake inputs to get latest packages
nix flake update

# Then rebuild
sudo nixos-rebuild switch --flake .#laptop
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

# Clean up old generations (keeps last 7 days)
sudo nix-collect-garbage --delete-older-than 7d

# List system generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

## 🖥️ Multi-Host Setup

This configuration is designed to support multiple machines. To add a new host:

1. **See the detailed guide**: `hosts/README.md`

2. **Quick steps**:
   ```bash
   # Create new host directory
   mkdir -p hosts/my-desktop
   
   # Generate hardware config
   sudo nixos-generate-config --show-hardware-config > hosts/my-desktop/hardware-configuration.nix
   
   # Copy and customize default.nix from laptop
   cp hosts/laptop/default.nix hosts/my-desktop/
   
   # Edit the hostname and other settings
   nano hosts/my-desktop/default.nix
   
   # Add to flake.nix (see hosts/README.md for example)
   nano flake.nix
   ```

3. **Build the new host**:
   ```bash
   sudo nixos-rebuild switch --flake .#my-desktop
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

#### Using Options (Preferred)

Edit `modules/packages.nix` and add to the `programs` section:

```nix
programs = {
  neovim.enable = true;  # Uses NixOS option
};
```

#### Using System Packages (When No Option Exists)

```nix
environment.systemPackages = with pkgs; [
  my-custom-package  # No official option available
];
```

### Modify Shell Configuration

Edit `home/programs/zsh.nix` for shell aliases and settings.

### Change Wallpaper

The wallpaper is configured in `home/programs/gnome.nix`:

1. Add your new wallpaper image to the `wallpapers/` directory
2. Update the file reference in `home/programs/gnome.nix`:
   ```nix
   home.file.".config/wallpapers/wallpaper.jpg" = {
     source = ../../wallpapers/your-new-wallpaper.jpg;
   };
   ```
3. Run `sudo nixos-rebuild switch --flake .#laptop` to apply

## 📝 Notes

- **First Boot**: The first boot may take a while as Nix downloads and builds everything.
- **Updates**: Run `nix flake update` periodically to update your packages.
- **Rollbacks**: If something breaks, you can select an older generation from the boot menu.
- **Garbage Collection**: Run `sudo nix-collect-garbage --delete-older-than 7d` regularly to free up disk space.
- **Flakes**: This configuration uses Nix flakes for reproducibility and easier dependency management.
- **Options Over Packages**: We use `programs.*.enable` options instead of `environment.systemPackages` where possible for better integration.

## 🔧 Troubleshooting

### Boot Issues

- Check that UUIDs in `hosts/laptop/hardware-configuration.nix` match your actual partitions
- Try booting from an older generation in the boot menu
- Use `sudo nixos-rebuild test --flake .#laptop` to test changes before making them permanent

### Graphics Issues

- Intel graphics should work out of the box
- If you experience issues, check hardware-configuration.nix graphics settings

### WiFi Not Working

- Ensure Intel WiFi firmware is loaded: `lsmod | grep iwlwifi`
- Check NetworkManager status: `systemctl status NetworkManager`

### Home Manager Issues

- If home-manager fails to build, try rebuilding the whole system: `sudo nixos-rebuild switch --flake .#laptop`
- Check for syntax errors: `nix flake check`

### Configuration Errors

- Use `nixos-rebuild test` instead of `switch` to test changes
- Check syntax with: `nix flake check`
- Rollback to previous generation from boot menu if needed

## 📚 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Package Search](https://search.nixos.org/)
- [NixOS Wiki](https://nixos.wiki/)
- [Nix Flakes Tutorial](https://nixos.wiki/wiki/Flakes)
- [NixOS Options Search](https://search.nixos.org/options)

## 📄 License

This configuration is free to use and modify as needed.
