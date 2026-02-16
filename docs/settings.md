# Settings — Central Configuration

`settings/config.nix` is the **single source of truth** for all configuration values across the NixOS and nix-darwin setup. Every module and host reads from here; nothing is hardcoded elsewhere.

## Structure

```
settings/
├── config.nix          # Entry point — imports config/
├── config/             # All configurable values (one file per domain)
│   ├── default.nix     # Imports all sub-modules
│   ├── user.nix
│   ├── system.nix
│   ├── packages.nix
│   ├── desktop.nix
│   ├── darwin.nix
│   └── ...
├── plasma/             # KDE Plasma declarative settings
│   └── default.nix
└── darwin/             # macOS system defaults (Dock, Finder, trackpad, etc.)
    └── default.nix
```

## Usage

```nix
let
  cfg = import ../settings/config.nix;
in {
  home.username          = cfg.user.username;
  programs.git.userEmail = cfg.user.email;
  home.stateVersion      = cfg.system.stateVersion;
}
```

## Benefits

- **Single source of truth** — change one value, updates everywhere
- **DRY** — no duplication across modules or hosts
- **Discoverable** — clear file names, each file focused on one domain
- **Safe** — impossible to have inconsistent settings across hosts

## Exporting GUI Settings

### KDE Plasma (Linux)

KDE Plasma settings are managed declaratively via `plasma-manager`. Instead of exporting settings from the GUI, you should:

1. Edit `settings/plasma/default.nix` for desktop layout and behavior
2. Edit `home/programs/kde.nix` for user-level Plasma configuration

Changes are applied automatically on next Home Manager rebuild. This ensures your configuration is reproducible and version-controlled.

### macOS

macOS system defaults are managed declaratively in `settings/darwin/default.nix`. Edit the Nix values directly rather than exporting from System Settings — this ensures the config is reproducible and version-controlled.

## Further Reading

- [settings-config.md](settings-config.md) — full per-file reference and quick-edit map
- [settings-structure.md](settings-structure.md) — why the config is split into modules
