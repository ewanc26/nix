# macOS (nix-darwin) Configuration

This host configuration is for the MacMini running macOS with nix-darwin.

## Initial Setup

### 1. Install Nix (if not already installed)

```bash
sh <(curl -L https://nixos.org/nix/install)
```

### 2. Enable Flakes

Add to `~/.config/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

### 3. Install nix-darwin

```bash
nix run nix-darwin -- switch --flake ~/.config/nix-config#macmini
```

### 4. Add nix-darwin to your PATH

After the first installation, add this to your shell profile:
```bash
# For zsh (default on macOS)
echo 'export PATH="/run/current-system/sw/bin:$PATH"' >> ~/.zshrc
```

## Daily Usage

### Rebuild System Configuration

```bash
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

Or use the alias (after zsh is configured):
```bash
nrs
```

### Update Flake Inputs

```bash
cd ~/.config/nix-config
nix flake update
darwin-rebuild switch --flake .#macmini
```

### Homebrew Management

The configuration manages Homebrew automatically. When you run `darwin-rebuild switch`, it will:
- Install missing brew formulae and casks
- Upgrade existing packages (if `onActivation.upgrade = true`)
- Clean up old versions (if `onActivation.cleanup = "zap"`)

To manually run Homebrew commands:
```bash
brew update
brew upgrade
brew cleanup
```

## Configuration Structure

```
hosts/macmini/
├── default.nix          # Main host configuration

modules/darwin/
├── packages.nix         # Nix-managed CLI tools (converted from brew)
├── homebrew.nix         # Homebrew-managed packages (GUI apps + complex libs)
└── system.nix           # macOS system settings (dock, finder, etc.)

settings/darwin/
└── defaults.nix         # Encrypted macOS defaults (via ragenix)
```

## Package Management

### Nix Packages
CLI tools and development tools are managed by Nix (in `modules/darwin/packages.nix`):
- Core utilities (coreutils, htop, tree, etc.)
- Development tools (git, gh, etc.)
- Programming languages (go, nodejs, python, ruby, etc.)
- Media tools (ffmpeg, exiftool, etc.)

### Homebrew Packages
GUI applications and complex media libraries stay in Homebrew (in `modules/darwin/homebrew.nix`):
- **Casks**: VLC, OrbStack, Ice, etc.
- **Formulae**: Media codecs (x264, x265, etc.), complex libraries

### Why the Split?

- **Nix**: Better for reproducibility, version pinning, and CLI tools
- **Homebrew**: Better for macOS GUI apps, media codecs, and some proprietary software

## System Settings

System settings are configured in `modules/darwin/system.nix`:
- Dock behavior (autohide, size, orientation)
- Finder settings (show extensions, list view, etc.)
- Trackpad settings (tap to click)
- Keyboard settings (key repeat, Caps Lock → Control)
- Dark mode
- Touch ID for sudo

## Switching Between Hosts

If you're also using the laptop (NixOS) configuration:

```bash
# On macOS
darwin-rebuild switch --flake ~/.config/nix-config#macmini

# On NixOS
sudo nixos-rebuild switch --flake /etc/nixos#laptop
```

## Troubleshooting

### Homebrew Not Found
If Homebrew is not in your PATH after installation:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
# or
eval "$(/usr/local/bin/brew shellenv)"     # Intel
```

### Permission Issues
If you get permission errors:
```bash
sudo chown -R $(whoami) /nix
```

### Reset Everything
To completely rebuild:
```bash
darwin-rebuild switch --flake ~/.config/nix-config#macmini --recreate-lock-file
```

## Architecture Notes

This configuration assumes **Apple Silicon (M1/M2/M3)** with `aarch64-darwin`.

For Intel Macs, change in `flake.nix`:
```nix
system = "x86_64-darwin";
```

## Additional Resources

- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [macOS system defaults](https://macos-defaults.com/)
- [Homebrew documentation](https://docs.brew.sh/)
