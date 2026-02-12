# macOS Setup Complete! 🎉

Your nix-darwin configuration for the MacMini has been created. Here's what was set up:

## Files Created

```
hosts/macmini/
├── default.nix          # Main macOS configuration
└── README.md           # Detailed documentation

modules/darwin/
├── packages.nix         # Nix packages (CLI tools from your brew list)
├── homebrew.nix         # Homebrew-managed apps (GUI apps + media codecs)
└── system.nix           # macOS system settings (Dock, Finder, etc.)
```

## What Was Converted

### ✅ Nix Packages (from brew)
These CLI tools are now managed by Nix:
- **Development**: git, gh, go, nodejs, python, ruby, deno, ollama
- **Core utils**: coreutils, curl, wget, htop, tree, rsync, stow, nmap
- **Media tools**: ffmpeg, exiftool, atomicparsley, get_iplayer
- **Build tools**: cmake, autoconf, libtool, pkgconf
- **Other**: fastfetch, neofetch, tailscale, jq, tesseract, and more

### 🍺 Homebrew (Casks & Complex Libs)
These stay in Homebrew for better compatibility:
- **GUI Apps**: VLC, OrbStack, Ice, ImgBrd-Grabber, AltServer
- **Media codecs**: x264, x265, xvid, dav1d, svt-av1, aom, etc.
- **Complex libraries**: libmediainfo, media-info, various codec libraries

## Installation Steps

### 1. First-Time Setup

```bash
# Install nix-darwin
nix run nix-darwin -- switch --flake ~/.config/nix-config#macmini

# Add to PATH (add to ~/.zshrc)
echo 'export PATH="/run/current-system/sw/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Daily Usage

```bash
# Rebuild system (from ~/.config/nix-config directory)
darwin-rebuild switch --flake .#macmini

# Or use the alias (after first rebuild)
nrs

# Update all flake inputs
nix flake update
nrs
```

### 3. Clean Up Old Brew Packages

After confirming everything works, you can remove packages now managed by Nix:

```bash
# These are now in Nix (you can remove from brew)
brew uninstall git gh go node python ruby deno ollama
brew uninstall coreutils curl wget htop tree rsync stow nmap
brew uninstall ffmpeg exiftool fastfetch neofetch tailscale jq
# ... and many others (see modules/darwin/packages.nix for full list)

# Keep these in brew (GUI apps and complex codecs)
# vlc, orbstack, jordanbaird-ice, imgbrd-grabber, altserver
# x264, x265, xvid, libmediainfo, etc.
```

## System Settings Configured

The following macOS settings are managed by `modules/darwin/system.nix`:

**Dock:**
- Auto-hide enabled
- No recent apps
- Size: 48px
- Empty by default (no pinned apps)

**Finder:**
- Show all file extensions
- List view by default
- Show path bar and status bar
- Quit menu item enabled

**Keyboard:**
- Fast key repeat
- Caps Lock remapped to Control
- No auto-capitalization or spell correction

**Trackpad:**
- Tap to click enabled

**General:**
- Dark mode enabled
- Touch ID for sudo enabled
- Screenshot shadows disabled

## Architecture Note

This configuration assumes **Apple Silicon (M1/M2/M3)** (`aarch64-darwin`).

If you have an Intel Mac, change this in `flake.nix`:
```nix
system = "x86_64-darwin";  # Change from aarch64-darwin
```

## Shared Dotfiles

Your dotfiles in `home/` are **shared** between the MacMini and laptop:
- ✅ Git config (same on both)
- ✅ Zsh config (with OS-specific aliases)
- ✅ Starship prompt (same on both)
- ✅ Fastfetch (same on both)
- ✅ VSCode settings (same on both)

The home-manager config automatically detects the OS and:
- Includes GNOME settings only on Linux
- Sets correct home directory (`/Users/ewan` vs `/home/ewan`)
- Enables GTK/Qt theming only on Linux
- Adjusts zsh aliases (darwin-rebuild vs nixos-rebuild)

## Next Steps

1. **Test the configuration:**
   ```bash
   cd ~/.config/nix-config
   nix flake check
   ```

2. **Do the first rebuild:**
   ```bash
   nix run nix-darwin -- switch --flake ~/.config/nix-config#macmini
   ```

3. **Verify packages:**
   ```bash
   which git  # Should be from /nix/store
   which brew  # Should still work for GUI apps
   ```

4. **Customize system settings:**
   Edit `modules/darwin/system.nix` to adjust Dock, Finder, etc.

5. **Add more packages:**
   - CLI tools → `modules/darwin/packages.nix`
   - GUI apps → `modules/darwin/homebrew.nix` (casks)

## Troubleshooting

See `hosts/macmini/README.md` for detailed troubleshooting steps.

## Resources

- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [Nix package search](https://search.nixos.org/packages)
- [macOS defaults](https://macos-defaults.com/)
