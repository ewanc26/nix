# NixOS Configuration

A hyper-organized, flake-based NixOS configuration designed for flexibility across multiple machines.

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
├── modules/                     # Reusable NixOS modules
│   ├── desktop.nix             # Desktop environment (GNOME)
│   ├── packages.nix            # System packages (uses options where possible)
│   ├── services.nix            # System services
│   ├── gaming.nix              # Steam and gaming setup
│   └── secrets.nix             # Encrypted secrets configuration
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

### Option A: Switching from Existing NixOS

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
   sudo git clone <your-repo-url> .
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

## 🔄 Updating the System

```bash
sudo nixos-rebuild switch --flake .#<hostname>
nix flake update
sudo nixos-rebuild switch --flake .#<hostname>
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
* [Home Manager Manual](https://nix-community.github.io/home-manager/)
* [Nix Package Search](https://search.nixos.org/)
* [NixOS Wiki](https://nixos.wiki/)
* [Nix Flakes Tutorial](https://nixos.wiki/wiki/Flakes)

## 📄 License

This configuration is free to use and modify.
