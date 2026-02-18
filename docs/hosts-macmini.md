# macOS (nix-darwin) — macmini

Host configuration for the Mac Mini running macOS with nix-darwin.

## Initial Setup

### 1. Download the repository

```bash
mkdir -p ~/.config
curl -L https://github.com/ewanc26/nix/archive/refs/heads/main.tar.gz | tar -xz -C ~/.config
mv ~/.config/nix-main ~/.config/nix-config
```

> Once nix-darwin is applied, `git` is available via Nix. Convert to a proper repo:
> `cd ~/.config/nix-config && git init && git remote add origin https://github.com/ewanc26/nix.git`

### 2. Install Nix (if not already)

```bash
sh <(curl -L https://nixos.org/nix/install)
```

### 3. Enable Flakes

Add to `~/.config/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

### 4. Install nix-darwin

```bash
nix run nix-darwin -- switch --flake ~/.config/nix-config#macmini
```

### 5. Add nix-darwin to PATH

```bash
echo 'export PATH="/run/current-system/sw/bin:$PATH"' >> ~/.zshrc
```

## Daily Usage

### Rebuild

```bash
sudo darwin-rebuild switch --flake ~/.config/nix-config#macmini
# or from inside the repo directory:
sudo darwin-rebuild switch --flake .#macmini
```

### Update flake inputs

```bash
cd ~/.config/nix-config
nix flake update
sudo darwin-rebuild switch --flake .#macmini
```

### Homebrew

`darwin-rebuild switch` manages Homebrew automatically (installs, upgrades, cleans). To run manually:

```bash
brew update && brew upgrade && brew cleanup
```

## Configuration Structure

```
hosts/macmini/
└── default.nix             # host-specific imports and myConfig.* overrides

modules/darwin/
├── common.nix              # Shared macOS nix settings (gc, flakes, zsh)
├── packages.nix            # Nix-managed CLI tools
├── homebrew.nix            # Homebrew formulae and casks
└── system.nix              # macOS system settings + Time Machine activation

modules/options.nix         # ⭐ All darwin.* option values live here

settings/darwin/
└── default.nix             # macOS system.defaults (Dock, Finder, login window, etc.)
```

## Package Management

### What goes in Nix (`modules/options.nix` → `packages.darwin`)
CLI tools, development tools, languages — anything with good Nix packaging.

### What goes in Homebrew (`modules/options.nix` → `darwin.homebrew`)
- **`casks`** — GUI apps
- **`brews`** — Complex media codecs and libraries that work better via brew
- **`masApps`** — Mac App Store apps

Edit `modules/options.nix` (the `darwin.homebrew` defaults) to add packages to either list.

## System Settings

High-level toggles are options in `modules/options.nix`:
- `darwin.keyboard.*` — key mapping, Caps Lock
- `darwin.startup.chime` — boot chime
- `darwin.security.touchIdForSudo` — Touch ID for sudo

Fine-grained defaults (Dock, Finder, trackpad, login window, etc.) live in `settings/darwin/default.nix`. Edit them directly in Nix rather than exporting from System Settings.

## Architecture

Assumes **Apple Silicon (aarch64-darwin)**. For Intel, change in `flake.nix`:

```nix
system = "x86_64-darwin";
```

## Troubleshooting

**Homebrew not in PATH:**
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"      # Intel
```

**Permission issues:**
```bash
sudo chown -R $(whoami) /nix
```

**Full rebuild:**
```bash
sudo darwin-rebuild switch --flake .#macmini --recreate-lock-file
```

## Resources

- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [macOS system defaults reference](https://macos-defaults.com/)
- [Homebrew documentation](https://docs.brew.sh/)
