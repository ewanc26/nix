# Managing All Applications - Quick Reference

Complete guide to managing every application on your Mac through nix-darwin.

## 🚀 Quick Start (Rust Tools - Recommended)

### 1. Build the tools
```bash
cd ~/.config/nix-config/tools
cargo build --release
```

### 2. Categorize your apps
```bash
cargo run --bin categorize-apps
```

This shows which apps should be managed through:
- ✅ **nixpkgs** (best - fully reproducible)
- 🍺 **Homebrew casks** (good - widely available)
- 🍎 **Mac App Store** (last resort - requires Apple ID)
- ❌ **Manual** (games, custom apps, etc.)

### 3. Generate config
```bash
cargo run --bin generate-app-config > ~/Desktop/apps.nix
```

### 4. Update your config files

Copy the sections from `apps.nix` to:

**nixpkgs packages** → `settings/config/packages.nix`:
```nix
{
  development = [
    "firefox"
    "git"
  ];
}
```

**Homebrew casks** → `settings/config/darwin.nix`:
```nix
homebrew = {
  casks = [
    "discord"
    "visual-studio-code"
  ];
};
```

**Mac App Store** → `settings/config/darwin.nix`:
```nix
homebrew = {
  masApps = {
    "Xcode" = 497799835;
    "Amphetamine" = 937984704;
  };
};
```

### 5. Apply changes
```bash
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

## 📋 Alternative: Bash Scripts

If you prefer bash over Rust:

```bash
cd ~/.config/nix-config/scripts
bash categorize-apps.sh
bash generate-app-config.sh > ~/Desktop/apps.nix
```

**Note:** The Rust tools are faster and more reliable.

## 🔍 Finding App Information

### Search nixpkgs
```bash
nix search nixpkgs appname
```

### Search Homebrew
```bash
brew search --casks appname
brew info --cask appname
```

### Find Mac App Store IDs
```bash
# Install mas-cli first
brew install mas

# List installed apps
mas list

# Search for an app
mas search "App Name"
```

Or get the ID from the App Store URL:
```
https://apps.apple.com/us/app/app-name/id1234567890
                                          ^^^^^^^^^^ This is the ID
```

## ⚙️ Configuration Details

### Cleanup Settings

In `settings/config/darwin.nix`:

```nix
homebrew = {
  enable = true;
  
  # ... your apps ...
  
  onActivation = {
    autoUpdate = true;
    upgrade = true;
    cleanup = "uninstall";  # Remove apps not in config
  };
};
```

**Cleanup options:**
- `"none"` - Keep all apps (default)
- `"uninstall"` - Remove unlisted apps, keep data
- `"zap"` - Remove apps AND their data

### Priority Order (Why This Matters)

1. **nixpkgs** 
   - Fully reproducible
   - Works across NixOS and macOS
   - Best for command-line tools
   
2. **Homebrew casks**
   - Widely available GUI apps
   - Easy updates
   - Good community support
   
3. **Mac App Store**
   - Last resort for managed apps
   - Requires Apple ID
   - Limited to apps in your purchase history
   
4. **Manual**
   - Game launchers (Steam, Epic, EA)
   - Beta/custom builds
   - Apps not in any package manager

## 🎯 Common Workflows

### Adding a New App

```bash
# 1. Install it first (test it works)
brew install --cask notion

# 2. Add to your config
vim ~/.config/nix-config/settings/config/darwin.nix

# 3. Apply
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

### Syncing a New Machine

```bash
# 1. Clone your config
git clone your-repo ~/.config/nix-config

# 2. Install Nix and nix-darwin
# (follow nix-darwin setup instructions)

# 3. Apply your config - all apps install automatically!
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

### Keeping Config in Sync

```bash
# Periodically check for new apps
cd ~/.config/nix-config/tools
cargo run --bin categorize-apps

# Update any missing apps in your config
vim settings/config/darwin.nix

# Apply
darwin-rebuild switch --flake .#macmini
```

## 💡 Pro Tips

1. **Use `cleanup = "uninstall"`** to enforce your config (removes unlisted apps)
2. **Prefer nixpkgs** over Homebrew when available
3. **Keep game launchers manual** - they're not well-suited for declarative management
4. **Run `health-check`** before rebuilding to catch issues early:
   ```bash
   cd tools
   cargo run --bin health-check
   ```
5. **Commit your config** after every change to track history

## 🐛 Troubleshooting

### MAS apps won't install
- Sign into the Mac App Store
- The app must be in your purchase history (even if free)
- Verify: `mas account`

### Cask not found
```bash
brew search --casks appname
```

### Tool not found
```bash
# Rust tools
cd ~/.config/nix-config/tools
cargo build --release

# Bash scripts
cd ~/.config/nix-config/scripts
chmod +x *.sh
```

### Apps not being removed
- MAS apps won't auto-uninstall (Homebrew limitation)
- Manually uninstall first, or use `cleanup = "none"`

## 📚 More Information

- Full documentation: `docs/managing-all-apps.md`
- Rust tools: `tools/README.md`
- Bash scripts: `scripts/README.md`
- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [mas-cli GitHub](https://github.com/mas-cli/mas)
