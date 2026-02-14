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
├── gnome/              # GNOME dconf settings (auto-generated)
│   ├── default.nix
│   └── dconf-settings.nix
├── darwin/             # macOS system defaults (auto-generated)
│   ├── default.nix
│   └── domains/
├── gnome-export.sh     # Export current GNOME state → dconf-settings.nix
└── darwin-export.sh    # Export current macOS state → domains/
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

### GNOME (Linux)

After changing settings through GNOME Settings:

```bash
./settings/gnome-export.sh
```

Exports to `settings/gnome/dconf-settings.nix`. Applied automatically on next Home Manager rebuild.

### macOS

After changing settings through System Settings:

```bash
./settings/darwin-export.sh
```

Exports to `settings/darwin/domains/`. Applied automatically on next `darwin-rebuild`.

## Further Reading

- [settings-config.md](settings-config.md) — full per-file reference and quick-edit map
- [settings-guide.md](settings-guide.md) — GNOME and macOS settings export workflow
- [settings-structure.md](settings-structure.md) — why the config is split into modules
