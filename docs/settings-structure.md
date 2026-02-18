# Configuration Structure

> **Note**: The `settings/config/` directory and `settings/config.nix` have been removed. This document describes the current structure.

## How configuration is organised

All options are declared once in `modules/options.nix` with typed defaults. Hosts override what they need in their own `default.nix`. There is no separate config file layer, no custom abstraction, and no manual dependency injection.

```
modules/options.nix          # Single source of truth for all option declarations + defaults
hosts/<n>/default.nix        # Per-host overrides using the module system
```

## Why this approach?

The previous approach imported a plain Nix attrset (`settings/config.nix`) and threaded it through a custom `cfgLib` helper. This had several downsides:

- No type checking — typos and wrong types silently produced bad configs
- No documentation — `nix-option` couldn't introspect the values
- Manual wiring — every module had to receive the config as an argument
- Duplication — defaults lived in `settings/config/` *and* had to be mirrored in `modules/options.nix` definitions

Using the NixOS module system directly gives type checking, proper `mkDefault`/`mkForce` priority, and means every module gets `config.myConfig` automatically — no wiring needed.

## Directory layout

```
settings/
├── darwin/             # macOS system.defaults — a plain NixOS module
│   └── default.nix    # Dock, Finder, NSGlobalDomain, trackpad, etc.
└── plasma/             # KDE Plasma declarative settings (plasma-manager)
    └── default.nix
```

Both remaining directories in `settings/` are standard NixOS modules imported by their respective platform modules (`modules/darwin/system.nix` and `home/programs/kde.nix`). They are **not** part of any custom abstraction — they're just modules.

## Edit frequency guide

| File | Edit frequency | When |
|---|---|---|
| `modules/options.nix` | 🟡 Occasional | Adding/changing global defaults |
| `hosts/laptop/default.nix` | 🔴 Rare | Laptop-specific overrides |
| `hosts/server/default.nix` | 🔴 Rare | Service toggles, server-specific config |
| `hosts/macmini/default.nix` | 🔴 Rare | macOS-specific overrides |
| `settings/darwin/default.nix` | 🟡 Occasional | macOS UI defaults (Dock, Finder, etc.) |
| `settings/plasma/default.nix` | 🟡 Occasional | KDE Plasma layout and behaviour |
| `home/programs/kde.nix` | 🟡 Occasional | KDE fonts, theme, Konsole |

## Adding a new option

```nix
# 1. Declare it in modules/options.nix
myNewThing = {
  enable = mkOption {
    type = bool;
    default = false;
    description = "Enable the new thing.";
  };
  port = mkOption {
    type = int;
    default = 9000;
  };
};

# 2. Use it in a module
lib.mkIf config.myConfig.myNewThing.enable {
  # ...
}

# 3. Override per-host if needed
# hosts/server/default.nix
myConfig.myNewThing.enable = true;
```

## Further reading

- [settings.md](settings.md) — practical how-to guide
- [settings-config.md](settings-config.md) — full option reference
