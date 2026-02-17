# macOS Application Management Summary

## Overview

All non-system apps are now managed declaratively via Nix. This document lists all applications found in `/Applications` and their management status.

---

## ✅ Managed by Homebrew Casks

These apps are installed and managed via `settings/config/darwin.nix` → `homebrew.casks`:

### Communication
- Discord
- Element (Matrix client)
- Signal
- WhatsApp

### Productivity
- Claude
- GitHub Desktop
- Obsidian
- Visual Studio Code

### Browsers
- Firefox

### Media & Entertainment
- HandBrake
- OBS Studio
- Spotify

### Gaming
- Epic Games Launcher
- Prism Launcher (Minecraft)
- Steam
- Steam Link
- UTM (Virtual Machines)

### Utilities
- Cloudflare WARP
- FileZilla (FTP)
- Mos (Mouse/trackpad)
- OneDrive
- OnyX (System maintenance)
- Parsec (Remote desktop)
- Tailscale (VPN)
- The Unarchiver
- Transmission (BitTorrent)

### Office & Documents
- LibreOffice
- Microsoft Excel
- Microsoft PowerPoint
- Microsoft Teams
- Microsoft Word

### Hardware
- Logi Tune (Logitech webcam)
- Logitech Options (Logitech devices)

### Other
- NetNewsWire (RSS reader)

---

## ✅ Managed by Mac App Store (MAS)

These apps are installed via `settings/config/darwin.nix` → `masApps`:

- Amphetamine (ID: 937984704)
- EA app (ID: 1246969117)
- Mini Motorways (ID: 1453901000)
- OP Auto Clicker (ID: 6754914118)
- Roblox (ID: 1319456934)
- TestFlight (ID: 899247664)
- Zone Bar (ID: 6755328989)

---

## 🔧 System Apps (Not Managed)

These are built-in macOS applications and don't need to be managed:

- FaceTime → `/System/Applications/FaceTime.app`
- iPhone Mirroring → `/System/Applications/iPhone Mirroring.app`
- Mail → `/System/Applications/Mail.app`
- Messages → `/System/Applications/Messages.app`
- Phone → `/System/Applications/Phone.app`
- Safari → `/Applications/Safari.app`
- Terminal → `/System/Applications/Utilities/Terminal.app`

---

## ❌ Not Managed (Manual Installation)

These apps cannot be easily managed via Nix and must be installed manually:

### Adobe Suite
- **Adobe Creative Cloud** - Requires Adobe account and subscription
- **Adobe Photoshop 2026** - Installed via Creative Cloud

### Other
- **2FHey** - Not available in Homebrew/MAS
- **Letta Desktop** - Not available in Homebrew/MAS

### Folders (Not Apps)
- Development
- EA Games
- Emulation
- get_iplayer
- Nix Apps (managed by Nix itself)
- Utilities (system folder)

---

## 📊 Summary Statistics

- **Total apps in /Applications:** ~50
- **Managed by Homebrew:** 37 apps
- **Managed by MAS:** 7 apps
- **System apps:** 7 apps
- **Manual installation required:** 4 items
- **Folders:** 6 folders

**Management Coverage:** 44/50 apps (88%) are declaratively managed!

---

## 🚀 Applying Changes

To install all managed applications:

```bash
darwin-rebuild switch --flake ~/.config/nix-config#macmini
```

This will:
1. Install all Homebrew cask apps
2. Install all Mac App Store apps (via `mas`)
3. Configure your Dock
4. Apply system settings

---

## 📝 Adding New Apps

### Via Homebrew Cask

1. Search for the app:
   ```bash
   brew search <app-name>
   ```

2. Add to `settings/config/darwin.nix` → `homebrew.casks`:
   ```nix
   casks = [
     # ...
     "new-app-name"
   ];
   ```

3. Rebuild:
   ```bash
   darwin-rebuild switch --flake ~/.config/nix-config#macmini
   ```

### Via Mac App Store

1. Find the app ID:
   ```bash
   mas search "App Name"
   ```

2. Add to `settings/config/darwin.nix` → `masApps`:
   ```nix
   masApps = {
     # ...
     "App Name" = 123456789;
   };
   ```

3. Rebuild:
   ```bash
   darwin-rebuild switch --flake ~/.config/nix-config#macmini
   ```

---

## 🔍 Verifying Installation

Check which apps are installed:

```bash
# Homebrew casks
brew list --cask

# Mac App Store apps
mas list

# All apps in /Applications
ls /Applications
```

---

## ⚠️ Important Notes

1. **Finder** - Always shown in Dock, doesn't need to be listed in `persistent-apps`
2. **Adobe apps** - Must be installed manually via Creative Cloud
3. **App updates** - Homebrew apps update via `brew upgrade`, MAS apps via App Store
4. **Homebrew cleanup** - Run `brew cleanup` periodically to remove old versions

---

## 🎯 Current Dock Configuration

Order (left to right):
1. Finder (always shown)
2. Mail
3. WhatsApp
4. Phone
5. iPhone Mirroring
6. FaceTime
7. Messages
8. Signal
9. Element
10. Discord
11. Spotify
12. Firefox
13. Obsidian
14. Visual Studio Code
15. Terminal

All configured in `settings/darwin/default.nix` → `system.defaults.dock.persistent-apps`
