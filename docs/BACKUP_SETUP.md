# Automatic Backup Setup

This document explains the automatic backup system for your Nix configuration.

## Overview

Your Nix configuration is automatically backed up to git with:
- ✅ Automatic commits every 6 hours
- ✅ Automatic pushes to remote repository  
- ✅ Git hooks that validate and auto-push manual commits
- ✅ Works on both NixOS and macOS
- ✅ Zero manual intervention required

## How It Works

### 1. Scheduled Backups

**NixOS (systemd):**
- Service: `nix-config-backup.service`
- Timer: `nix-config-backup.timer`
- Runs every 6 hours
- First run: 15 minutes after boot

**macOS (launchd):**
- Agent: `org.nixos.nix-config-backup`
- Runs every 6 hours
- First run: On login

**Network-Aware Behavior:**
- ✅ **Always commits locally** - Your changes are never lost
- ✅ **Checks network connectivity** before attempting push
- ✅ **Only pushes when online** - No errors when offline
- ✅ **Accumulated commits pushed** when network becomes available
- ✅ **Graceful degradation** - Works perfectly offline or online

### 2. Git Hooks

**Pre-commit Hook:**
- Validates Nix configuration syntax
- Runs `nix flake check --no-build`
- Prevents broken configs from being committed

**Post-commit Hook:**
- Checks network connectivity before push
- Automatically pushes commits to remote (when online)
- Only pushes from main branch
- Skips push gracefully when offline
- Commits are always saved locally

### 3. Activation Scripts

On every system rebuild, the git hooks are automatically installed/updated.

## What Gets Backed Up

Every change to your Nix configuration, including:
- Configuration files (`.nix` files)
- Settings exports
- Flake lock file updates
- Any other tracked files in the repository

## Commit Messages

Automatic commits use this format:
```
Auto-backup from <hostname> at <timestamp>
```

Example:
```
Auto-backup from laptop at 2025-02-12 14:30:00
Auto-backup from macmini at 2025-02-12 15:45:00
```

## Monitoring Backups

### NixOS

Check timer status:
```bash
systemctl --user status nix-config-backup.timer
```

View last backup:
```bash
systemctl --user status nix-config-backup.service
```

View logs:
```bash
journalctl --user -u nix-config-backup.service -f
```

### macOS

Check agent status:
```bash
launchctl list | grep nix-config-backup
```

View logs:
```bash
tail -f ~/Library/Logs/nix-config-backup.log
tail -f ~/Library/Logs/nix-config-backup.error.log
```

## Manual Operations

### Trigger Manual Backup

Run the backup script directly:
```bash
cd ~/.config/nix-config
./scripts/auto-backup.sh
```

### Reinstall Git Hooks

```bash
cd ~/.config/nix-config
./scripts/setup-hooks.sh
```

### Check Git Status

```bash
cd ~/.config/nix-config
git status
git log --oneline -n 10
```

## Troubleshooting

### Backups Not Running

1. **Check if service/timer is active:**
   ```bash
   # NixOS
   systemctl --user list-timers | grep nix-config
   
   # macOS
   launchctl list | grep nix-config
   ```

2. **Check logs for errors:**
   ```bash
   # NixOS
   journalctl --user -u nix-config-backup.service -e
   
   # macOS
   cat ~/Library/Logs/nix-config-backup.error.log
   ```

3. **Verify git remote is configured:**
   ```bash
   cd ~/.config/nix-config
   git remote -v
   ```

### Push Failures

Common causes:
- No network connection (handled automatically - commits stay local)
- Git credentials not configured
- Remote repository not accessible
- Merge conflicts with remote

**Network Issues:**
If you're offline, the script will:
1. Commit changes locally
2. Skip the push attempt
3. Push accumulated commits on next run when online

**Manual Resolution:**
If pushes fail for other reasons (auth, conflicts):
```bash
cd ~/.config/nix-config
git status
git pull
git push
```

### Pre-commit Hook Failing

If commits are rejected:
1. Check Nix syntax errors:
   ```bash
   nix flake check
   ```

2. Fix the errors in your configuration

3. Try committing again

### Disabling Auto-Backup

**Temporarily (until next rebuild):**

NixOS:
```bash
systemctl --user stop nix-config-backup.timer
```

macOS:
```bash
launchctl unload ~/Library/LaunchAgents/org.nixos.nix-config-backup.plist
```

**Permanently:**

Remove the git-backup module import from your host configuration:
- NixOS: `hosts/laptop/default.nix`
- macOS: `hosts/macmini/default.nix`

Then rebuild your system.

## Configuration Files

All backup-related files are in the repository:

```
nix-config/
├── scripts/
│   ├── auto-backup.sh      # Main backup script
│   ├── setup-hooks.sh      # Hook installation script  
│   ├── pre-commit          # Git pre-commit hook
│   ├── post-commit         # Git post-commit hook
│   └── README.md           # Scripts documentation
├── modules/
│   ├── git-backup.nix      # NixOS backup service
│   └── darwin/
│       └── git-backup.nix  # macOS backup agent
```

## Benefits

✅ **Always backed up** - Never lose configuration changes
✅ **Automatic** - No manual git commands needed  
✅ **Version controlled** - Full history of all changes
✅ **Validated** - Pre-commit hooks prevent broken configs
✅ **Cross-platform** - Works on both NixOS and macOS
✅ **Resilient** - Retries on failure, stores locally if push fails

## Security Notes

- Backup script runs as your user (not root)
- Uses your existing git credentials
- No sensitive data in commit messages
- All secrets remain encrypted in the repository
