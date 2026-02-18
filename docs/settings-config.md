# Configuration Options Reference

All configurable values are declared in `modules/options.nix` as typed NixOS module options. Defaults are set there; per-host overrides go in `hosts/<n>/default.nix`.

> This file was previously the reference for the now-removed `settings/config/` directory. That directory and `settings/config.nix` have been deleted — see [settings.md](settings.md) for the current approach.

## Option map

### User (`myConfig.user`)

| Option | Default | Description |
|---|---|---|
| `username` | `"ewan"` | Unix username |
| `fullName` | `"Ewan Croft"` | Display name for Git, etc. |
| `email` | `"git@ewancroft.uk"` | Email for Git commits |

### System

| Option | Default | Description |
|---|---|---|
| `stateVersion` | `"25.11"` | NixOS / home-manager state version |
| `timeZone` | `"Europe/London"` | System timezone |
| `locale` | `"en_GB.UTF-8"` | Default locale |
| `isDesktop` | `false` | Whether this is an interactive desktop — set `true` in the host file |

### Audio (`myConfig.audio`)

| Option | Default |
|---|---|
| `enable` | `true` |
| `backend` | `"pipewire"` |

### Gaming (`myConfig.gaming`)

| Option | Default | Notes |
|---|---|---|
| `enable` | `false` | Set `true` in `hosts/laptop/default.nix` |
| `steam.enable` | `true` | |
| `steam.openFirewall` | `false` | |

### Packages (`myConfig.packages`)

| Option | Description |
|---|---|
| `common` | CLI tools on every host |
| `development` | Languages and tooling (laptop + macmini) |
| `fonts` | Nerd Font names to install via home-manager |
| `linux` | Linux-only GUI extras (e.g. `vlc`) |
| `desktop` | Linux desktop GUI apps |
| `gaming` | Gaming packages |
| `server` | Server-only extras |
| `darwin` | macOS-specific Nix packages |

### Desktop (`myConfig.desktop`)

| Option | Default |
|---|---|
| `environment` | `"plasma6"` |
| `displayManager` | `"sddm"` |
| `uiFont` / `uiFontSize` | `"Noto Sans"` / `10` |
| `monoFontBase` | `"FiraCode"` |
| `monoFontFamily` | `"FiraCode Nerd Font Mono"` |
| `monoFontSize` | `11` |
| `theme` | `"Catppuccin-Mocha-Standard-Green-Dark"` |
| `iconTheme` | `"Papirus-Dark"` |
| `plasma.colorScheme` | `"CatppuccinMochaGreen"` |
| `plasma.desktopTheme` | `"breeze-dark"` |
| `plasma.excludePackages` | `["oxygen" "elisa"]` |

### Git (`myConfig.git`)

| Option | Default |
|---|---|
| `defaultBranch` | `"main"` |
| `editor` | `"code --wait"` |
| `lfs.enable` | `true` |
| `signing.enabled` | `true` |
| `signing.format` | `"ssh"` |

### Development / VS Code (`myConfig.development.vscode`)

| Option | Default |
|---|---|
| `enable` | `true` |
| `colorTheme` | `"Catppuccin Mocha"` |
| `iconTheme` | `"catppuccin-vsc-icons"` |
| `fontSize` | `14` |
| `terminalFontSize` | `13` |
| `lineHeight` | `22` |
| `fontLigatures` | `true` |

### Secrets (`myConfig.secrets`)

| Option | Default | What it enables |
|---|---|---|
| `docker.enable` | `true` | `~/.docker/config.json` |
| `claude.enable` | `true` | `~/.claude.json` |
| `duckdns.enable` | `false` | `~/.duckdns/` bundle |

### Server services (`myConfig.services`)

| Option | Default | Set in |
|---|---|---|
| `forgejo.enable` | `false` | `hosts/server/default.nix` |
| `pds.enable` | `false` | `hosts/server/default.nix` |
| `matrix.enable` | `false` | `hosts/server/default.nix` |
| `cloudflare.enable` | `false` | `hosts/server/default.nix` |

### Server SSH (`myConfig.server.sshd`)

| Option | Default |
|---|---|
| `enable` | `true` |
| `permitRootLogin` | `"no"` |
| `passwordAuthentication` | `false` |
| `port` | `22` |
| `maxAuthTries` | `3` |
| `x11Forwarding` | `false` |

### Firewall (`myConfig.server.firewall`)

| Option | Default |
|---|---|
| `enable` | `true` |
| `allowPing` | `true` |
| `allowedTCPPorts` | `[22]` |
| `allowedUDPPorts` | `[]` |

### Darwin (`myConfig.darwin`)

| Option | Default |
|---|---|
| `keyboard.enableKeyMapping` | `true` |
| `keyboard.remapCapsLockToControl` | `false` |
| `startup.chime` | `true` |
| `security.touchIdForSudo` | `true` |
| `homebrew.enable` | `true` |
| `homebrew.taps` | `[]` |
| `homebrew.brews` | *(media codec list — see options.nix)* |
| `homebrew.casks` | *(GUI app list — see options.nix)* |
| `homebrew.masApps` | *(Mac App Store apps — see options.nix)* |

## Further reading

- [settings.md](settings.md) — how to make changes
- [REFERENCE.md](REFERENCE.md) — command reference
