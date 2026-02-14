# Nix Config Tools (Rust)

Rust-based utilities for managing your nix-darwin configuration.

## Building

```bash
cd tools
cargo build --release
```

The compiled binaries will be in `target/release/`.

## Available Tools

### App Management

#### sync-apps ⭐ (RECOMMENDED)
**Automatically updates your nix config files** with currently installed apps.

```bash
cargo run --release --bin sync-apps
```

**What it does:**
1. Scans `/Applications` and categorizes each app
2. Updates `settings/config/darwin.nix` with casks and MAS apps
3. Shows nixpkgs apps to add manually
4. Creates a git commit with the changes

**Safety features:**
- Checks for uncommitted changes (use `--force` to override)
- Creates a git commit so you can easily revert
- Shows a summary of what was updated

**This is the easiest way to keep your config in sync!**

#### categorize-apps
Scans `/Applications` and shows where each app should be managed.

```bash
cargo run --release --bin categorize-apps
```

**Priority order:** nixpkgs → Homebrew casks → Mac App Store → manual

**Output:**
- ✅ Apps available in nixpkgs
- 🍺 Apps available as Homebrew casks
- 🍎 Apps only in Mac App Store
- ❌ Apps not available (manual install)

#### generate-app-config
Generates ready-to-paste nix configuration from your `/Applications`.

```bash
cargo run --release --bin generate-app-config > ~/Desktop/my-apps.nix
```

Creates formatted config sections for:
- nixpkgs packages
- Homebrew casks
- Mac App Store apps

### System Management

#### health-check
Pre-rebuild preflight check for your nix config.

```bash
cargo run --release --bin health-check
```

Checks:
- Nix daemon status
- flake.lock validity
- Flake evaluation
- Git tree state
- Age key presence
- SSH keys
- Homebrew installation (macOS)
- Disk space

#### darwin-export
Export current macOS system settings to nix config format.

```bash
cargo run --release --bin darwin-export
```

#### gnome-export
Export GNOME/dconf settings to nix config format.

```bash
cargo run --release --bin gnome-export
```

### Maintenance

#### flake-bump
Update flake.lock and commit the changes.

```bash
cargo run --release --bin flake-bump
```

#### gen-diff
Generate a diff showing what would change with a rebuild.

```bash
cargo run --release --bin gen-diff
```

#### secrets-setup
Initialize age encryption for secrets management.

```bash
cargo run --release --bin secrets-setup
```

## Quick Start: Managing All Applications

### The Easy Way (Automatic)

```bash
cd ~/.config/nix-config/tools

# Build once
cargo build --release

# Sync your apps automatically
cargo run --release --bin sync-apps

# Apply the changes
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

That's it! `sync-apps` does everything for you:
- ✅ Scans your apps
- ✅ Updates your config files
- ✅ Creates a git commit
- ✅ Shows you what changed

### The Manual Way

If you prefer more control:

```bash
# 1. See what you have
cargo run --release --bin categorize-apps

# 2. Generate config snippets
cargo run --release --bin generate-app-config > ~/Desktop/apps.nix

# 3. Manually copy to your config files
# 4. Apply
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

## Workflow Examples

### Regular Maintenance

```bash
# After installing new apps, sync your config
cd ~/.config/nix-config/tools
cargo run --release --bin sync-apps
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

### Before Rebuilding

```bash
# Check if everything is healthy
cargo run --release --bin health-check

# If all checks pass, rebuild
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

### Setting Up a New Machine

```bash
# Clone your config
git clone your-repo ~/.config/nix-config

# Install Nix and nix-darwin (follow official docs)

# Build the tools
cd ~/.config/nix-config/tools
cargo build --release

# Your apps are already in the config!
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

## Development

### Adding a new tool

1. Create `src/bin/your-tool.rs`
2. Add to `Cargo.toml`:
   ```toml
   [[bin]]
   name = "your-tool"
   path = "src/bin/your-tool.rs"
   ```
3. Use the common utilities from `tools_common` crate

### Common utilities (lib.rs)

```rust
use tools_common::*;

// Get the git root of the config
let root = git_root();

// Get current timestamp
let timestamp = get_timestamp();

// Get hostname
let host = get_hostname();

// Run nix command and capture to file
capture_nix_to_file(&["eval", "..."], &out_path);

// Git commit and push
git_sync("path/to/file", "Auto-update");
```

## Installing System-Wide

You can install these tools to make them available everywhere:

```bash
cd tools
cargo install --path .
```

Then use them directly:

```bash
sync-apps
categorize-apps
health-check
```

## Tips

- **Use `sync-apps`** regularly to keep your config in sync
- **Run `health-check` before every rebuild** to catch issues early
- **Prefer nixpkgs over Homebrew** when available for better reproducibility
- **Keep game launchers manual** - they're not well-suited for declarative management
- **The `--force` flag** on `sync-apps` skips the uncommitted changes check

## Troubleshooting

### sync-apps says I have uncommitted changes

This is a safety feature. Either commit your changes first, or use:
```bash
cargo run --release --bin sync-apps -- --force
```

### MAS apps not detected

Make sure `mas` is installed:
```bash
brew install mas
```

And sign into the App Store.

### Build errors

Make sure you have Rust installed:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
