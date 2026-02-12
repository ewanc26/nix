# Nix Configuration

My Nix-darwin and NixOS configurations

## ✨ Key Features

- 🔄 **Fully Automated** - Updates, backups, and file placement happen automatically
- 🔒 **Encrypted Settings** - All system preferences stored securely with ragenix
- 📦 **Git Backups** - Configuration automatically committed and pushed every 6 hours
- 🌐 **Network-Aware** - Always commits locally, only pushes when online - works perfectly offline
- 🔧 **Zero Maintenance** - Set it and forget it - everything just works
- 💎 **Cross-Platform** - Same dotfiles on NixOS and macOS
- 🧠 **Smart Hooks** - Git hooks validate config before commits and auto-push changes
- 📦 **DRY Architecture** - Common settings defined once, shared across all hosts

## 🖥️ Supported Platforms

- **NixOS** (Linux): Full system configuration with GNOME desktop
  - Host: `laptop` (configured)
- **NixOS** (Linux): Minimal server configuration
  - Host: `server` (configured)
- **macOS** (nix-darwin): System configuration with Homebrew integration  
  - Host: `macmini` (configured)

**Shared dotfiles** across all platforms:
- Git configuration
- Zsh shell (default on all hosts) with OS-specific aliases
- Starship prompt
- Fastfetch
- VSCode settings

## 📁 Structure

```
nix/
├── flake.nix                    # Main flake configuration
├── hosts/                       # Host-specific configurations
│   ├── README.md               # Guide for adding new hosts
│   └── <hostname>/             # Directory for a specific machine
│       ├── default.nix         # Main host configuration
│       └── hardware-configuration.nix  # Hardware-specific settings
├── scripts/                     # Automation scripts
│   ├── README.md               # Scripts documentation
│   ├── auto-backup.sh          # Automatic git backup script
│   ├── setup-hooks.sh          # Git hooks installation
│   ├── pre-commit              # Validates Nix config before commit
│   └── post-commit             # Auto-pushes commits to remote
├── settings/                    # System settings (encrypted)
│   ├── SETTINGS_GUIDE.md       # Settings management guide
│   ├── gnome/                  # GNOME settings
│   │   └── default.nix         # Imports encrypted dconf
│   └── darwin/                 # macOS settings
│       └── defaults.nix        # Imports encrypted defaults
├── wallpapers/                  # Wallpaper images
│   └── wallpaper.jpg           # Default wallpaper
├── modules/                     # Reusable modules
│   ├── common.nix              # Common NixOS settings (all hosts)
│   ├── users.nix               # Standard user configuration
│   ├── desktop.nix             # Desktop environment (GNOME) - Linux desktop
│   ├── packages.nix            # Desktop packages - Linux desktop
│   ├── services.nix            # Desktop services - Linux desktop
│   ├── gaming.nix              # Steam and gaming setup - Linux desktop
│   ├── server-packages.nix     # Server packages - Linux server
│   ├── server-services.nix     # Server services (SSH, fail2ban) - Linux server
│   ├── git-backup.nix          # Auto-backup service (Linux)
│   ├── secrets.nix             # Encrypted secrets configuration
│   └── darwin/                 # macOS-specific modules
│       ├── common.nix          # Common Darwin settings (all macOS hosts)
│       ├── packages.nix        # Nix-managed CLI packages
│       ├── homebrew.nix        # Homebrew formulae and casks
│       ├── system.nix          # macOS system settings
│       └── git-backup.nix      # Auto-backup agent (macOS)
├── secrets/                     # Encrypted secrets (ragenix)
│   ├── README.md               # Secrets management guide
│   ├── secrets.nix             # Public keys and secret definitions
│   └── *.age                   # Encrypted secret files
└── home/                        # Home Manager configuration
    ├── home.nix                # Main home-manager config
    └── programs/
        ├── git.nix             # Git configuration
        ├── zsh.nix             # Zsh shell setup (default on all hosts)
        ├── starship.nix        # Starship prompt
        ├── fastfetch.nix       # Fastfetch config
        ├── gnome.nix           # GNOME settings & wallpaper
        └── vscode.nix          # VSCode settings
```

## 🏗️ Architecture

### Hosts Directory

This configuration uses a **hosts-based architecture** for multi-machine management:

* Each physical machine gets its own directory under `hosts/`
* Host-specific settings (hostname, hardware config) are isolated
* Shared modules (desktop, packages, services) are imported by each host
* Easy to add new machines — see `hosts/README.md` for details

### Options vs System Packages

This configuration follows NixOS best practices by using **declarative options** instead of only adding packages:

**✅ Recommended (Using Options):**

```nix
programs.firefox.enable = true;
programs.steam.enable = true;
```

**❌ Less Ideal (Only System Packages):**

```nix
environment.systemPackages = with pkgs; [ firefox steam ];
```

**Benefits of Options:**

* Declarative and clear
* Additional configuration options available
* Better integration with NixOS
* Automatically enables/disables related services
* Some programs require options (e.g., Steam needs firewall rules)

**When to Use System Packages:**

* No official NixOS option exists
* Simple utilities without complex configuration
* See `modules/packages.nix` for details

## 📦 Included Software

### System Tools

* **git** — Version control
* **fastfetch** — System information
* **starship** — Modern shell prompt
* **zsh** — Z Shell (default shell on all hosts)

### Applications

* **Firefox** — Web browser
* **VSCode** — Code editor with extensions
* **Spotify** — Music streaming
* **Discord** — Communication
* **Steam** — Gaming platform (with GameMode)
* **Prism Launcher** — Minecraft launcher

### Desktop Environment

* **GNOME** — Default desktop environment
* **GDM** — Display manager

## 🚀 Installation

### For NixOS (Linux)

#### Option A: Switching from Existing NixOS

1. **Enable flakes and git** (if not already):

   ```nix
   nix.settings.experimental-features = [ "nix-command" "flakes" ];
   ```

2. **Backup your current configuration**:

   ```bash
   sudo cp -r /etc/nixos /etc/nixos.backup
   ```

3. **Clone this repository**:

   ```bash
   cd /tmp
   git clone https://github.com/ewanc26/nix nix-config
   cd nix-config
   ```

4. **Generate hardware configuration**:

   ```bash
   sudo nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix
   ```

5. **Customize your configuration**:

   * Edit `hosts/<hostname>/default.nix` for hostname and host-specific settings
   * Configure git, shell, or applications in `home/programs/`

6. **Test configuration**:

   ```bash
   sudo nixos-rebuild test --flake .#<hostname>
   ```

7. **Apply configuration**:

   ```bash
   sudo nixos-rebuild switch --flake .#<hostname>
   ```

### Option B: Fresh Installation

1. **Boot NixOS installer** and partition your disk.

2. **Clone repository** into `/mnt/etc/nixos`:

   ```bash
   sudo git clone https://github.com/ewanc26/nix .
   ```

3. **Generate hardware configuration**:

   ```bash
   sudo nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix
   ```

4. **Configure user settings** (git, shell, etc.)

5. **Install NixOS**:

   ```bash
   sudo nixos-install --flake .#<hostname>
   ```

6. **Reboot** and login.

### For macOS (nix-darwin)

See **[MACOS_SETUP.md](MACOS_SETUP.md)** for complete installation instructions.

**Quick start:**

```bash
# Install nix-darwin
nix run nix-darwin -- switch --flake ~/.config/nix-config#macmini

# Rebuild after changes
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

## 🛠️ Quick Commands

### Build Specific Hosts

**Desktop/Laptop (with GUI):**
```bash
sudo nixos-rebuild switch --flake /home/ewan/.config/nix-config#laptop
```

**Server (no GUI):**
```bash
sudo nixos-rebuild switch --flake /home/ewan/.config/nix-config#server
```

**macOS:**
```bash
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

### Test Before Applying
```bash
# Test configuration without switching
sudo nixos-rebuild test --flake /home/ewan/.config/nix-config#<hostname>

# Build and show what would change
sudo nixos-rebuild dry-build --flake /home/ewan/.config/nix-config#<hostname>
```

## 🔄 Updating the System

### Automatic Updates & Backups

All hosts are configured with **automatic updates and git backups**:

**Automatic Updates:**
* **NixOS**: Updates run daily with a random delay of up to 45 minutes
* **macOS**: Uses the system auto-upgrade feature
* Flake inputs are automatically updated and committed
* Configuration files are automatically placed in the correct system locations

**Automatic Git Backups:**
* Configuration changes are automatically committed and pushed every 6 hours
* Git hooks validate configuration before commits
* **Network-aware** - Always commits locally, only pushes when online
* Works perfectly offline - accumulated commits pushed when network available
* No manual intervention required - your config is always backed up
* See `scripts/README.md` for details and management

### Manual Updates

If you prefer to update manually:

#### NixOS

```bash
sudo nixos-rebuild switch --flake /home/ewan/.config/nix-config#<hostname>
nix flake update /home/ewan/.config/nix-config
sudo nixos-rebuild switch --flake /home/ewan/.config/nix-config#<hostname>
```

#### macOS

```bash
darwin-rebuild switch --flake ~/.config/nix-config#macmini
nix flake update ~/.config/nix-config
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

### File Management

* **NixOS**: Configuration is automatically symlinked from `/home/ewan/.config/nix-config` to `/etc/nixos`
* **macOS**: Configuration remains in `/Users/ewan/.config/nix-config` and is referenced directly
* All hosts automatically place configuration files in their correct system locations on activation

## 🖥️ Multi-Host Setup

1. **Create a new host directory**:

   ```bash
   mkdir -p hosts/<new-hostname>
   sudo nixos-generate-config --show-hardware-config > hosts/<new-hostname>/hardware-configuration.nix
   cp hosts/<existing-host>/default.nix hosts/<new-hostname>/
   ```

2. **Edit hostname and settings**:

   ```bash
   nano hosts/<new-hostname>/default.nix
   ```

3. **Build the new host**:

   ```bash
   sudo nixos-rebuild switch --flake .#<new-hostname>
   ```

## 🎨 Customization

### Settings Management

All system settings are managed through encrypted configuration files:

* **GNOME Settings** (Linux): Configured via `settings/gnome/default.nix` (encrypted dconf settings)
  - Automatically imported by `home/programs/gnome.nix`
  - To export current settings: `settings/gnome-export.sh`
  - Settings are always applied from the encrypted file, no hardcoded defaults

* **macOS Settings** (Darwin): Configured via `settings/darwin/defaults.nix` (encrypted system defaults)
  - Automatically imported by `modules/darwin/system.nix`
  - To export current settings: `settings/darwin-export.sh`
  - Settings are always applied from the encrypted file, no hardcoded defaults

### Other Customization Options

* **Desktop Environment**: Change DE/WM in `modules/desktop.nix`
* **Secrets**: Managed via [ragenix](https://github.com/yaxitech/ragenix)
* **Additional Packages**: Add via `modules/packages.nix`
* **Shell Configuration**: Edit `home/programs/zsh.nix`
* **Wallpaper**: Replace images in `wallpapers/` (wallpaper path configured in GNOME settings)

## 🔧 Troubleshooting

* Boot, graphics, WiFi, or Home Manager issues can usually be resolved by rebuilding or checking hardware configuration
* Use `nixos-rebuild test` to safely test changes
* Rollback to previous generations if needed

## 📚 Documentation

### This Repository
* **[BACKUP_SETUP.md](BACKUP_SETUP.md)** - Automatic git backup system
* **[SERVER_SETUP.md](SERVER_SETUP.md)** - NixOS server configuration guide
* **[DRY_REFACTORING.md](DRY_REFACTORING.md)** - DRY architecture and common modules
* **[settings/SETTINGS_GUIDE.md](settings/SETTINGS_GUIDE.md)** - Settings management guide
* **[scripts/README.md](scripts/README.md)** - Automation scripts documentation
* **[secrets/README.md](secrets/README.md)** - Secrets management with ragenix
* **[hosts/README.md](hosts/README.md)** - Adding new hosts
* **[hosts/server/README.md](hosts/server/README.md)** - Server host detailed setup

### External Resources
* [NixOS Manual](https://nixos.org/manual/nixos/stable/)
* [nix-darwin](https://github.com/LnL7/nix-darwin) - Nix for macOS
* [Home Manager Manual](https://nix-community.github.io/home-manager/)
* [Nix Package Search](https://search.nixos.org/)
* [NixOS Wiki](https://nixos.wiki/)
* [Nix Flakes Tutorial](https://nixos.wiki/wiki/Flakes)
* [macOS Defaults](https://macos-defaults.com/) - macOS system settings reference

## 📄 License

This configuration is free to use and modify.
