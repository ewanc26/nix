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

### 📌 Before You Start

This section assumes you want a **flake-enabled Nix/NixOS environment**. Flakes are experimental but widely used in the Nix community and required by this config. That means you’ll need a recent Nix installation with experimental features enabled.

---

### 🧠 Option A: Already on NixOS (Switch to This Config)

1. **Enable flakes support**
   Add this to your `/etc/nixos/configuration.nix`:

   ```nix
   nix.settings.experimental-features = [ "nix-command" "flakes" ];
   ```

   Then rebuild:

   ```bash
   sudo nixos-rebuild switch
   ```

2. **Backup your current config**

   ```bash
   sudo cp -r /etc/nixos /etc/nixos.backup
   ```

3. **Clone your dotfiles**

   ```bash
   git clone https://github.com/ewanc26/dotfiles-nix.git ~/dotfiles-nix
   cd ~/dotfiles-nix
   ```

4. **Copy your hardware config**

   ```bash
   sudo cp /etc/nixos/hardware-configuration.nix .
   sudo chown $USER:users hardware-configuration.nix
   ```

5. **Edit configs** as needed (hostname, git user/email, extra packages, etc.)

6. **Test your config**

   ```bash
   sudo nixos-rebuild test --flake .#laptop
   ```

7. **Apply permanently**

   ```bash
   sudo nixos-rebuild switch --flake .#laptop
   ```

8. **Optional: Move files to `/etc/nixos`**

   If you want this repo as your system’s canonical config:

   ```bash
   sudo rm -rf /etc/nixos/*
   sudo cp -r * /etc/nixos
   sudo chown -R root:root /etc/nixos
   ```

9. **Reboot**

   ```bash
   sudo reboot
   ```

---

### 🆕 Option B: Fresh NixOS Install (Flake-friendly)

> **Important**: Before installing the OS, get Nix itself set up if you’re on another distro or live environment — see the section below.

1. **Boot the NixOS installer** from USB or CD and partition your drive.

2. **Generate initial hardware config**

   ```bash
   sudo nixos-generate-config --root /mnt
   ```

3. **Install Nix (with flakes support) in the installer** (if you need nix commands):

   ```bash
   curl -L https://nixos.org/nix/install | sh -s -- --daemon
   . ~/.nix-profile/etc/profile.d/nix.sh
   ```

4. **Clone your config into the target**

   ```bash
   cd /mnt/etc/nixos
   sudo nix-shell -p git --run "git clone https://github.com/ewanc26/dotfiles-nix.git ."
   ```

5. **Replace the generated `hardware-configuration.nix`** with the one from the installer.

6. **Install NixOS with your flake**:

   ```bash
   sudo nixos-install --flake .#laptop
   ```

7. **Reboot into your new system**

---

### 🧰 Installing Nix (Non-NixOS Linux or macOS)

If you’re on another Linux distro (or doing stuff in the installer) and just want the **Nix package manager**:

```bash
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

- This sets up **multi-user mode** (recommended).
- After install, open a new terminal and verify:

```bash
nix --version
```

Then enable flakes by adding to your nix config (`~/.config/nix/nix.conf`):

```plaintext
experimental-features = nix-command flakes
```

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

4. **Update hardware configuration**:

   ```bash
   # Copy your current hardware configuration
   sudo cp /etc/nixos/hardware-configuration.nix ./hardware-configuration.nix
   
   # Make sure file permissions are correct
   sudo chown $USER:users ./hardware-configuration.nix
   ```

5. **Customize the configuration**:

   - **Edit `configuration.nix`**: Update the hostname if needed (currently set to "laptop")
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

10. **Post-installation cleanup**:

    After rebooting and confirming everything works, you can clean up old generations:

    ```bash
    # Remove old system generations (keeps last 3)
    sudo nix-collect-garbage --delete-older-than 3d
    
    # Or use the cleanup alias (if using the provided zsh config)
    cleanup
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

2. **Generate hardware config** (to get UUIDs):

   ```bash
   sudo nixos-generate-config --root /mnt
   ```

3. **Clone this repository**:

   ```bash
   cd /mnt/etc/nixos
   sudo nix-shell -p git
   sudo git clone https://github.com/ewanc26/dotfiles-nix .
   ```

4. **Update hardware-configuration.nix** with the UUIDs from the generated file:

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

## 🔄 Updating the System

After making changes to the configuration:

```bash
# Full system update (NixOS + Home Manager)
update

# Or separately:
nrs   # NixOS rebuild switch
hms   # Home Manager switch

# Update flake inputs to get latest packages
nix flake update
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

# Or manually clean up
sudo nix-collect-garbage --delete-older-than 7d
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

### Change Hostname

If you want to use a different hostname:

1. Edit `configuration.nix` and change the `networking.hostName` value
2. Edit `flake.nix` and rename the `laptop` configuration to match
3. Rebuild with the new name: `sudo nixos-rebuild switch --flake .#your-new-name`

## 📝 Notes

- **First Boot**: The first boot may take a while as Nix downloads and builds everything.
- **Updates**: Run `nix flake update` periodically to update your packages.
- **Rollbacks**: If something breaks, you can select an older generation from the boot menu.
- **Garbage Collection**: Run `cleanup` regularly to free up disk space.
- **Flakes**: This configuration uses Nix flakes for reproducibility and easier dependency management.

## 🔧 Troubleshooting

### Boot Issues

- Check that UUIDs in `hardware-configuration.nix` match your actual partitions
- Try booting from an older generation in the boot menu
- Use `sudo nixos-rebuild test` to test changes before making them permanent

### Graphics Issues

- Intel graphics should work out of the box
- If you experience issues, check `hardware-configuration.nix` graphics settings

### WiFi Not Working

- Ensure Intel WiFi firmware is loaded: `lsmod | grep iwlwifi`
- Check NetworkManager status: `systemctl status NetworkManager`

### Home Manager Issues

- If home-manager fails to build, try: `home-manager switch --flake .#ewan`
- Clear home-manager cache: `rm -rf ~/.cache/nix`

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

## 📄 License

This configuration is free to use and modify as needed.
