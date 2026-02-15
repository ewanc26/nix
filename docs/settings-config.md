# Configuration Directory — Single Source of Truth

Every configurable value for the entire NixOS / nix-darwin setup lives here, split into focused files. **No module or host file should contain a hardcoded value that belongs here.**

## File Map

| File | What it controls |
|---|---|
| `user.nix` | Username, full name, email, shell |
| `system.nix` | State version, timezone, locale, boot, kernel, network |
| `nix.nix` | Experimental features, store optimisation, garbage collection |
| `packages.nix` | Package lists — common, fonts, linux, desktop, gaming, server |
| `git.nix` | Branch, editor, LFS, commit signing, aliases, global gitignore |
| `shell.nix` | Aliases, git shortcuts, platform aliases, history |
| `desktop.nix` | Theme, icon theme, mono fonts, display manager, KDE Plasma settings |
| `ssh.nix` | Key file path, SSH agent |
| `audio.nix` | Backend (pipewire / pulseaudio) |
| `gaming.nix` | Enable flag, Steam, Gamemode |
| `server.nix` | sshd, fail2ban, firewall |
| `darwin.nix` | Homebrew brews/casks, nixpkgs packages, keyboard, startup, security |
| `secrets.nix` | Age key path, secret file list |
| `development.nix` | Languages, VS Code theme/fonts/extensions |
| `maintenance.nix` | Auto-upgrade, backup |
| `paths.nix` | Config repo path, home-manager path |

## Usage

```nix
let
  cfg = import ../../settings/config.nix;
in {
  home.username            = cfg.user.username;
  programs.git.userEmail   = cfg.user.email;
  home.stateVersion        = cfg.system.stateVersion;
  environment.systemPackages = map (p: pkgs.${p}) cfg.packages.common;
  programs.vscode.profiles.default.extensions =
    map toExt cfg.development.vscode.extensions;
}
```

## Quick-edit cheatsheet

| I want to change… | Edit |
|---|---|
| Username / email | `user.nix` |
| Timezone / locale | `system.nix` |
| Add a package (Linux) | `packages.nix` → `common` or `desktop` |
| Add a package (macOS) | `darwin.nix` → `packages` |
| Add a Homebrew cask | `darwin.nix` → `homebrew.casks` |
| Git alias | `git.nix` → `aliases` |
| Shell alias | `shell.nix` → `aliases` |
| Theme / icon theme | `desktop.nix` → `theme` / `iconTheme` |
| Monospace font | `desktop.nix` → `monoFont` / `monoFontConsole` |
| KDE Plasma packages | `desktop.nix` → `plasma.excludePackages` |
| VS Code extensions | `development.nix` → `vscode.extensions` |
| VS Code font | `development.nix` → `vscode.fontFamily` |
| Enable gaming | `gaming.nix` → `enable = true` |
| SSH port | `server.nix` → `sshd.port` |
| Firewall ports | `server.nix` → `firewall.allowedTCPPorts` |
| Auto-upgrade | `maintenance.nix` → `autoUpgrade.enable` |
| Add a secret | `secrets.nix` → `files` list, then create the `.age` file |
| macOS Touch ID sudo | `darwin.nix` → `security.touchIdForSudo` |
| macOS startup chime | `darwin.nix` → `startup.chime` |

## Adding a new secret

```bash
# 1. Encrypt it
rage -e -r "$(cat ~/.ssh/id_ed25519.pub)" my-secret.txt > secrets/age/my-secret.age

# 2. Register in settings/config/secrets.nix
#    files = [ "ssh-passphrase" "wifi-home" "my-secret" ];

# 3. Rebuild — available at config.age.secrets.my-secret.path
```

## Adding a new settings category

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

## Further Reading

- [settings.md](settings.md) — overview and export workflow
- [settings-structure.md](settings-structure.md) — why the config is modular
- [REFERENCE.md](REFERENCE.md) — quick-reference command card
