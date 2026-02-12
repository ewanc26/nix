# Automation Scripts

This directory contains scripts for automatic backup and maintenance of the Nix configuration.

## Scripts

### `auto-backup.sh`
Automatically commits and pushes configuration changes to git.

**Runs:**
- Every 6 hours via systemd timer (NixOS)
- Every 6 hours via launchd (macOS)
- Automatically after every manual commit (via post-commit hook)

**What it does:**
1. Checks for uncommitted changes
2. Adds all changes to git staging
3. Creates a commit with timestamp and hostname
4. **Checks network connectivity** (ping github.com or 8.8.8.8)
5. Pushes to remote repository **only if network is available**
6. If offline, commits locally and pushes on next successful run

**Network-Aware:**
- ✅ Always commits locally (never loses changes)
- ✅ Only pushes when network is detected
- ✅ Gracefully handles offline scenarios
- ✅ No errors when offline - just skips push

### `setup-hooks.sh`
Installs git hooks for the repository.

**Runs:**
- Automatically on every system activation
- Can be run manually: `./scripts/setup-hooks.sh`

**Installed hooks:**
- `pre-commit`: Validates Nix configuration before allowing commits
- `post-commit`: Automatically pushes commits to remote

### Git Hooks

#### `pre-commit`
Validates the Nix flake configuration before allowing a commit.

**Checks:**
- Nix syntax is valid
- Flake structure is correct

**Usage:**
- Runs automatically before every `git commit`
- Prevents invalid configurations from being committed

#### `post-commit`
Automatically pushes commits to the remote repository.

**Features:**
- Checks network connectivity before attempting push
- Only pushes from the main branch
- Skips push gracefully when offline (commit is saved locally)
- Silent on non-main branches
- No errors when network is down

**Usage:**
- Runs automatically after every successful commit
- Ensures your configuration is backed up remotely (when online)
- Commits stay local when offline and push later

## Automatic Backup Schedule

### NixOS (Linux)
- **Service:** `nix-config-backup.service`
- **Timer:** `nix-config-backup.timer`
- **Schedule:** Every 6 hours
- **First run:** 15 minutes after boot

**Check status:**
```bash
systemctl --user status nix-config-backup.timer
systemctl --user status nix-config-backup.service
```

**View logs:**
```bash
journalctl --user -u nix-config-backup.service
```

**Manual trigger:**
```bash
systemctl --user start nix-config-backup.service
```

### macOS (Darwin)
- **Agent:** `org.nixos.nix-config-backup`
- **Schedule:** Every 6 hours
- **First run:** On login

**Check status:**
```bash
launchctl list | grep nix-config-backup
```

**View logs:**
```bash
tail -f ~/Library/Logs/nix-config-backup.log
tail -f ~/Library/Logs/nix-config-backup.error.log
```

**Manual trigger:**
```bash
launchctl start org.nixos.nix-config-backup
```

## Manual Backup

You can always trigger a manual backup:

```bash
./scripts/auto-backup.sh
```

## Disabling Auto-Backup

If you want to disable automatic backups:

**NixOS:**
```bash
systemctl --user stop nix-config-backup.timer
systemctl --user disable nix-config-backup.timer
```

**macOS:**
```bash
launchctl unload ~/Library/LaunchAgents/org.nixos.nix-config-backup.plist
```

To re-enable, rebuild your system configuration.

## Troubleshooting

**Backup not running?**
- Check that git remote is configured: `git remote -v`
- Verify you have push access to the repository
- Check service/agent logs for errors

**Commits failing?**
- Ensure Nix configuration is valid: `nix flake check`
- Check for syntax errors in your `.nix` files

**Pushes failing?**
- Verify git credentials are set up
- Check network connectivity
- Ensure remote repository is accessible
