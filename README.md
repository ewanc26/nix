# Nix Configuration

A hyper-organized, flake-based configuration for **NixOS** and **macOS** (via nix-darwin), designed for flexibility across multiple machines with shared dotfiles.

## 🖥️ Supported Platforms

- **NixOS** (Linux): Full system configuration with GNOME desktop
  - Host: `laptop` (configured)
- **macOS** (nix-darwin): System configuration with Homebrew integration  
  - Host: `macmini` (configured)

**Shared dotfiles** across all platforms:
- Git configuration
- Zsh shell with OS-specific aliases
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
├── wallpapers/                  # Wallpaper images
│   └── wallpaper.jpg           # Default wallpaper
├── modules/                     # Reusable modules
│   ├── desktop.nix             # Desktop environment (GNOME) - Linux only
│   ├── packages.nix            # System packages - Linux only
│   ├── services.nix            # System services - Linux only
│   ├── gaming.nix              # Steam and gaming setup - Linux only
│   ├── secrets.nix             # Encrypted secrets configuration
│   └── darwin/                 # macOS-specific modules
│       ├── packages.nix        # Nix-managed CLI packages
│       ├── homebrew.nix        # Homebrew formulae and casks
│       └── system.nix          # macOS system settings
├── secrets/                     # Encrypted secrets (ragenix)
│   ├── README.md               # Secrets management guide
│   ├── secrets.nix             # Public keys and secret definitions
│   └── *.age                   # Encrypted secret files
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
* **zsh** — Z Shell

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

## 🔄 Updating the System

### NixOS

```bash
sudo nixos-rebuild switch --flake .#<hostname>
nix flake update
sudo nixos-rebuild switch --flake .#<hostname>
```

### macOS

```bash
darwin-rebuild switch --flake ~/.config/nix-config#macmini
nix flake update
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

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

* **Desktop Environment**: Change DE/WM in `modules/desktop.nix`
* **Secrets**: Managed via [ragenix](https://github.com/yaxitech/ragenix)
* **Additional Packages**: Add via `modules/packages.nix`
* **Shell Configuration**: Edit `home/programs/zsh.nix`
* **Wallpaper**: Replace images in `wallpapers/` and update `home/programs/gnome.nix`

## 🔧 Troubleshooting

* Boot, graphics, WiFi, or Home Manager issues can usually be resolved by rebuilding or checking hardware configuration
* Use `nixos-rebuild test` to safely test changes
* Rollback to previous generations if needed

## 📚 Resources

* [NixOS Manual](https://nixos.org/manual/nixos/stable/)
* [nix-darwin](https://github.com/LnL7/nix-darwin) - Nix for macOS
* [Home Manager Manual](https://nix-community.github.io/home-manager/)
* [Nix Package Search](https://search.nixos.org/)
* [NixOS Wiki](https://nixos.wiki/)
* [Nix Flakes Tutorial](https://nixos.wiki/wiki/Flakes)
* [macOS Defaults](https://macos-defaults.com/) - macOS system settings reference

## 📄 License

This configuration is free to use and modify.
