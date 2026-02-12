# Settings Export Scripts

This directory contains scripts to export and encrypt your system settings.

## Available Scripts

### 1. GNOME Settings Export (`gnome-export.sh`)

Exports GNOME dconf settings on Linux systems.

**Usage:**
```bash
# Run from the repository root
sudo bash settings/gnome-export.sh
```

**What it does:**
1. Dumps current dconf settings using `dconf dump`
2. Converts to Nix format using `dconf2nix`
3. Encrypts the output with ragenix (if age key is available)
4. Saves to `secrets/gnome-dconf-settings.age` (encrypted) or `settings/gnome/dconf.nix` (plaintext)
5. Commits changes to git

**Requirements:**
- NixOS or Linux with GNOME
- Age key configured (run `bash secrets/setup.sh` first)
- dconf2nix (automatically fetched via nix)

**Setup:**
1. Uncomment in `secrets/secrets.nix`:
   ```nix
   "gnome-dconf-settings.age".publicKeys = [ systems.laptop ];
   ```

2. Uncomment in `modules/secrets.nix`:
   ```nix
   gnome-dconf-settings = {
     file = ../secrets/gnome-dconf-settings.age;
     mode = "0440";
   };
   ```

3. Import in your configuration:
   ```nix
   # The settings/gnome/dconf.nix file will automatically import the decrypted settings
   imports = [ ./settings/gnome ];
   ```

### 2. macOS Settings Export (`darwin-export.sh`)

Exports macOS defaults settings for nix-darwin.

**Usage:**
```bash
# Export all defaults to a single file (default)
bash settings/darwin-export.sh

# OR export individual domain files (more granular)
bash settings/darwin-export.sh split
```

**What it does:**
1. Exports macOS defaults using `defaults2nix`
2. Encrypts the output with ragenix (if age key is available)
3. Saves to `secrets/darwin-defaults-settings.age` (encrypted) or `settings/darwin/defaults.nix` (plaintext)
4. Commits changes to git

**Requirements:**
- macOS with nix-darwin
- Age key configured (run `bash secrets/setup.sh` first)
- defaults2nix (automatically fetched via nix)

**Setup:**
1. Uncomment in `secrets/secrets.nix`:
   ```nix
   "darwin-defaults-settings.age".publicKeys = [ systems.MacMini ];
   ```

2. Uncomment in `modules/secrets.nix`:
   ```nix
   darwin-defaults-settings = {
     file = ../secrets/darwin-defaults-settings.age;
     mode = "0440";
   };
   ```

3. Import in your nix-darwin configuration:
   ```nix
   imports = [ ./settings/darwin ];
   ```

## Encryption

Both scripts support automatic encryption using ragenix:

**With encryption (recommended):**
- Settings are encrypted and stored in `secrets/*.age`
- Safe to commit to public repositories
- Requires age key setup (run `bash secrets/setup.sh`)

**Without encryption (fallback):**
- Settings stored in plaintext in `settings/*/*.nix`
- May contain sensitive configuration data
- Only use if you're keeping the repo private

## Workflow

### Initial Setup

1. Set up encryption:
   ```bash
   bash secrets/setup.sh
   ```

2. Configure secrets.nix and modules/secrets.nix as shown above

### Regular Updates

When you change system settings:

**On Linux (GNOME):**
```bash
# Export and encrypt current settings
sudo bash settings/gnome-export.sh

# Rebuild system to apply
sudo nixos-rebuild switch

# Commit changes
git add secrets/gnome-dconf-settings.age settings/gnome/dconf.nix
git commit -m "gnome: update settings"
git push
```

**On macOS:**
```bash
# Export and encrypt current settings
bash settings/darwin-export.sh

# Rebuild system to apply
darwin-rebuild switch --flake .

# Commit changes
git add secrets/darwin-defaults-settings.age settings/darwin/defaults.nix
git commit -m "darwin: update settings"
git push
```

## Troubleshooting

### "No age key found"
Run `bash secrets/setup.sh` to create your encryption key.

### "Encryption failed"
The script will fall back to plaintext storage. Check that:
- Your age key exists at `~/.config/age/keys.txt`
- The secret is declared in `secrets/secrets.nix`
- You have write permissions

### "dconf dump failed" (GNOME)
Make sure you're running on a GNOME system with dconf installed.

### "defaults2nix export failed" (macOS)
Ensure you're running on macOS and defaults2nix can access system settings.
Some settings may require sudo.

## File Locations

```
settings/
├── gnome-export.sh          # GNOME export script
├── darwin-export.sh         # macOS export script
├── gnome/
│   ├── dconf.nix           # GNOME settings stub (imports decrypted secret)
│   └── default.nix         # GNOME module entry point
└── darwin/
    ├── defaults.nix        # macOS settings stub (imports decrypted secret)
    └── default.nix         # Darwin module entry point

secrets/
├── gnome-dconf-settings.age      # Encrypted GNOME settings
└── darwin-defaults-settings.age  # Encrypted macOS settings
```

## Advanced Usage

### Selective Export (macOS)

Export specific domains only:
```bash
# Export just Safari settings
nix run github:joshryandavis/defaults2nix -- com.apple.Safari -o safari.nix

# Export global domain
nix run github:joshryandavis/defaults2nix -- NSGlobalDomain -o global.nix
```

### Manual Encryption

Encrypt any file manually:
```bash
nix run github:yaxitech/ragenix -- \
  --rules secrets/secrets.nix \
  --editor "code --wait" \
  -e secrets/my-settings.age
```

### Testing Without Committing

Both scripts commit automatically. To test without committing:

1. Comment out the git commit section in the script
2. Run the script
3. Review changes with `git diff`
4. Manually commit if satisfied

## Security Notes

1. **Encrypted files are safe to commit** - They can only be decrypted with your private key
2. **Never commit** `~/.config/age/keys.txt` - This is your private key
3. **Back up your key** - Without it, you can't decrypt your settings
4. **Use Tailscale/SSH** to sync your key to other machines
5. **Settings may contain sensitive data** - Even if encrypted, be mindful of what you export

## See Also

- [Ragenix Documentation](../secrets/README.md)
- [Ragenix How-To Guide](../secrets/HOWTO.md)
- [Security Audit](../SECURITY-AUDIT.md)
