# Settings Structure

## Why split into modules?

A single monolithic `config.nix` becomes hard to navigate as it grows. Splitting by domain gives each setting a clear home and keeps files small.

```
settings/
├── config.nix          # 3 lines — just imports config/
└── config/
    ├── default.nix     # Combines all modules into one attrset
    ├── user.nix        # Username, email, shell
    ├── system.nix      # Timezone, locale, boot, kernel
    ├── nix.nix         # Flakes, store optimisation, GC
    ├── packages.nix    # Package lists per context
    ├── git.nix         # Branch, editor, signing, aliases
    ├── shell.nix       # Aliases, history
    ├── desktop.nix     # Theme, fonts, KDE Plasma settings
    ├── ssh.nix         # Key file, agent
    ├── audio.nix       # Backend (pipewire / pulseaudio)
    ├── gaming.nix      # Enable flag, Steam
    ├── server.nix      # sshd, fail2ban, firewall
    ├── darwin.nix      # Homebrew, nixpkgs packages, keyboard, security
    ├── secrets.nix     # Age key path, secret file list
    ├── development.nix # Languages, VS Code
    ├── maintenance.nix # Auto-upgrade, backup
    └── paths.nix       # Config repo and home-manager paths
```

## Usage

The API is unchanged from a flat file — everything is accessed via `cfg.<domain>.<key>`:

```nix
let
  cfg = import ../settings/config.nix;
in {
  home.username            = cfg.user.username;
  programs.git.userEmail   = cfg.user.email;
  home.packages            = map (p: pkgs.${p}) cfg.packages.common;
  time.timeZone            = cfg.system.timeZone;
}
```

## Edit frequency guide

| File | Edit frequency |
|---|---|
| `user.nix` | 🔴 Rare |
| `system.nix` | 🔴 Rare |
| `nix.nix` | 🔴 Rare |
| `ssh.nix` | 🔴 Rare |
| `audio.nix` | 🔴 Rare |
| `paths.nix` | 🔴 Rare |
| `secrets.nix` | 🔴 Per-secret |
| `server.nix` | 🔴 Per-host |
| `gaming.nix` | 🔴 Per-host |
| `packages.nix` | 🟡 Occasional |
| `git.nix` | 🟡 Occasional |
| `desktop.nix` | 🟡 Occasional |
| `darwin.nix` | 🟡 Occasional |
| `development.nix` | 🟡 Occasional |
| `maintenance.nix` | 🟡 Occasional |
| `shell.nix` | 🟢 Frequent |

## Adding a new category

```bash
# 1. Create the file
cat > settings/config/monitoring.nix << 'EOF'
{
  prometheus = { enable = false; port = 9090; };
  grafana    = { enable = false; port = 3000; };
}
EOF

# 2. Register in default.nix
#    monitoring = import ./monitoring.nix;

# 3. Use anywhere
#    cfg.monitoring.prometheus.enable
```
