# Configuration — How It Works

All configurable values are expressed as **NixOS module options** in `modules/options.nix`. Every option has a typed default. Per-host overrides are set in the host's `default.nix` using the standard NixOS module system — no separate config file, no custom abstraction layer.

## Where settings live

```
modules/options.nix          # Declares all options with defaults
hosts/<name>/default.nix     # Per-host overrides (myConfig.* = ...)
```

## Accessing settings in modules

System-level modules (`modules/*.nix`):
```nix
{ config, ... }:
let cfg = config.myConfig; in
{
  time.timeZone = cfg.timeZone;
  users.users.${cfg.user.username} = { ... };
}
```

Home-manager modules (`home/**/*.nix`):
```nix
{ osConfig, ... }:
let cfg = osConfig.myConfig; in
{
  programs.git.userEmail = cfg.user.email;
}
```

## Option categories

| Category | Key options |
|---|---|
| `myConfig.user` | `username`, `fullName`, `email` |
| `myConfig` | `stateVersion`, `timeZone`, `locale`, `isDesktop` |
| `myConfig.audio` | `enable`, `backend` |
| `myConfig.gaming` | `enable`, `steam.*` |
| `myConfig.packages` | `common`, `development`, `fonts`, `linux`, `desktop`, `darwin` |
| `myConfig.desktop` | `environment`, `displayManager`, fonts, theme, KDE Plasma settings |
| `myConfig.ssh` | `keyFile` |
| `myConfig.git` | `defaultBranch`, `editor`, `lfs`, `signing` |
| `myConfig.development.vscode` | `enable`, theme, font, size settings |
| `myConfig.secrets` | `docker.enable`, `claude.enable`, `duckdns.enable` |
| `myConfig.services` | `forgejo.enable`, `pds.enable`, `matrix.enable`, `cloudflare.enable` |
| `myConfig.server` | `sshd.*`, `fail2ban.*`, `firewall.*`, `timemachine.*`, … |
| `myConfig.darwin` | `keyboard.*`, `startup.*`, `security.*`, `homebrew.*` |
| `myConfig.forgejo` | `hostname`, `port`, `appName`, … |
| `myConfig.pds` | `hostname`, `port`, `adminEmail`, `crawlers`, … |
| `myConfig.matrix` | `hostname`, `serverName`, `port`, … |
| `myConfig.cloudflare` | `tunnelId` |

## Making a change

### Change a value that has a suitable default

Most values default to something sensible in `modules/options.nix`. You rarely need to touch anything — just rebuild.

### Override a value for one host

```nix
# hosts/laptop/default.nix
{
  myConfig.isDesktop = true;
  myConfig.gaming.enable = true;
}
```

### Change a default that applies to all hosts

Edit the `default = ...` in `modules/options.nix`:

```nix
# modules/options.nix
timeZone = mkOption {
  type = str;
  default = "Europe/London";   # ← change here
};
```

## Quick-edit cheatsheet

| I want to change… | Where |
|---|---|
| Username / email | `modules/options.nix` → `user.*` defaults |
| Timezone / locale | `modules/options.nix` → `timeZone` / `locale` |
| Add a package (Linux) | `modules/options.nix` → `packages.common` or `packages.desktop` |
| Add a package (macOS) | `modules/options.nix` → `packages.darwin` |
| Add a Homebrew cask | `modules/options.nix` → `darwin.homebrew.casks` |
| Toggle desktop mode | `hosts/<n>/default.nix` → `myConfig.isDesktop = true` |
| Enable gaming | `hosts/<n>/default.nix` → `myConfig.gaming.enable = true` |
| Theme / icon theme | `modules/options.nix` → `desktop.theme` / `desktop.iconTheme` |
| Monospace font | `modules/options.nix` → `desktop.monoFontBase` |
| VS Code font / theme | `modules/options.nix` → `development.vscode.*` |
| SSH port (server) | `modules/options.nix` → `server.sshd.port` |
| Firewall ports | `modules/options.nix` → `server.firewall.allowedTCPPorts` |
| Enable a server service | `hosts/server/default.nix` → `myConfig.services.<n>.enable = true` |
| macOS Touch ID sudo | `modules/options.nix` → `darwin.security.touchIdForSudo` |
| macOS startup chime | `modules/options.nix` → `darwin.startup.chime` |

## macOS system.defaults

Fine-grained macOS defaults (Dock, Finder, trackpad, login window, etc.) live in `settings/darwin/default.nix`. This is a regular NixOS module imported by `modules/darwin/system.nix`. Edit it directly in Nix rather than exporting from System Settings — this ensures reproducibility.

## KDE Plasma settings

Plasma settings are managed declaratively via `plasma-manager`. Edit `settings/plasma/default.nix` for desktop layout and behaviour, and `home/programs/kde.nix` for user-level Plasma config. Changes are applied on the next `nixos-rebuild switch`.

## Further reading

- [REFERENCE.md](REFERENCE.md) — quick-reference command card
- [hosts-overview.md](hosts-overview.md) — how the three hosts relate to each other
- [secrets.md](secrets.md) — secrets management with sops-nix
