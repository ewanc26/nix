# CLAUDE.md — nix-config

Guide for AI assistants working in this repository.

## What This Repo Is

A unified NixOS + nix-darwin (macOS) configuration managed as a single Nix flake. It targets three hosts:

| Host      | Platform                             | Role                                   |
| --------- | ------------------------------------ | -------------------------------------- |
| `macmini` | nix-darwin (aarch64-darwin)          | Primary daily driver (Apple M2)        |
| `laptop`  | NixOS (x86_64-linux)                 | Secondary desktop — KDE Plasma 6       |
| `server`  | NixOS (x86_64-linux / aarch64-linux) | Headless — Bluesky PDS, Forgejo, Caddy |

## Key Concepts

### Single Source of Truth

All configurable values — username, timezone, theme, packages, feature flags — are declared
with typed defaults in **`modules/options.nix`**. Everything else reads from there.

- System modules: `config.myConfig.*`
- Home-manager modules: `osConfig.myConfig.*`
- Per-host overrides: `hosts/<hostname>/default.nix`

Never hard-code values that belong in `options.nix`.

### Module Pattern

```nix
# System module
{ config, pkgs, lib, ... }:
let cfg = config.myConfig; in { ... }

# Home-manager module
{ osConfig, pkgs, lib, ... }:
let cfg = osConfig.myConfig; in { ... }
```

Use `lib.mkIf` for conditional config. Use `lib.mkOption` with explicit types when adding new options.

### No Custom Abstraction

The old `cfgLib` helper was removed. Use the plain NixOS module system.
See `lib/USAGE.md` for patterns including package resolution and authorized SSH keys.

## Building

```bash
# NixOS
sudo nixos-rebuild switch --flake .#laptop
sudo nixos-rebuild switch --flake .#server

# macOS — first time
sudo nix run nix-darwin -- switch --flake .#macmini

# macOS — subsequent
sudo darwin-rebuild switch --flake .#macmini
```

Shell aliases (set up by `home/programs/zsh.nix`):

- `nrs` — nixos-rebuild switch
- `cleanup` — nix-collect-garbage -d

## Maintenance Tools (Rust, in `tools/`)

Run via flake or shell aliases — no manual `cargo build`:

```bash
health-check          # pre-rebuild preflight (run this first)
flake-bump            # show stale inputs / bump selectively
gen-diff              # diff packages between generations
```

Run `health-check` before rebuilding to catch common issues early (daemon, lock file,
git cleanliness, disk space).

Note: `health-check` still probes for `~/.config/age/keys.txt`, which no longer exists —
that check is stale and lives in the `pkgs-monorepo` input, not this repo.

## Infrastructure Diagrams (nix-topology)

SVG diagrams are auto-generated from NixOS configs. Physical connections and networks are defined in `topology.nix`.

```bash
# On the server (renderer requires Linux):
ssh server
nix build ~/.config/nix-config#topology.x86_64-linux.config.output
```

When adding a new host, add its interfaces and physical connections to `topology.nix`.
Service/interface data is extracted automatically from the NixOS module.

## Secrets

Uses [sops-nix](https://github.com/Mic92/sops-nix). Every secret is encrypted to two
kinds of recipient:

- **Your PGP key** — for reading, editing and re-keying secrets by hand.
- **Each host's age key** — derived from its `/etc/ssh/ssh_host_ed25519_key`, used by
  sops-nix to decrypt at activation. Hosts stay on age because activation runs as root
  with no terminal, so a PGP passphrase could never be entered.

Other notes:

- Encrypted files in `secrets/` are safe to commit.
- Recipients are defined in `.sops.yaml`. `pgp:` and `age:` must stay in a **single** key
  group — two groups would enable Shamir sharing and require both keys.
- There is no personal age key any more. The only age identities are the host keys, so
  re-keying an existing secret needs one derived from a host's SSH key — see
  "Recovering secrets" in `docs/secrets.md`.

Manual use needs no key file — sops finds your PGP key via `gpg-agent`:

```bash
nix run nixpkgs#sops -- secrets/pds.env
```

Re-key every secret after changing `.sops.yaml`:

```bash
./secrets/setup.sh --rekey-only && ./scripts/check-secrets.sh
```

See `docs/secrets.md` for the full migration runbook.

## Flake Inputs

| Input                 | Pinned version   | Notes                                          |
| --------------------- | ---------------- | ---------------------------------------------- |
| nixpkgs               | nixos-25.11      |                                                |
| nixpkgs-unstable      | nixos-unstable   | passed to the server as `pkgs-unstable`        |
| home-manager          | release-25.11    |                                                |
| nix-darwin            | nix-darwin-25.11 |                                                |
| sops-nix              | latest           |                                                |
| nix-topology          | latest           |                                                |
| plasma-manager        | latest           |                                                |
| nix-vscode-extensions | latest           |                                                |
| mac-app-util          | latest           |                                                |
| pkgs-monorepo         | latest           | `ewanc26/pkgs` — maintenance tools             |
| tgirlpkgs             | latest           | `tgirlcloud/pkgs` — provides `pds-gatekeeper`  |

Run `nix flake update` to update all inputs, or `flake-bump --update <input>` to bump selectively.

## Checks

`nix flake check --all-systems` evaluates every host — `laptop`, `server`,
`server-arm` and `macmini` — without building any of them. Evaluating the
nix-darwin host does **not** require macOS, so this runs anywhere.

CI (`.github/workflows/check.yml`) runs the same command on every push and pull
request, plus a `nixfmt` check. Run it locally before pushing:

```bash
nix flake check --all-systems --no-build
```

## Running Tools

Unless a tool is explicitly listed as a shell alias or known to be installed,
always use `nix run` rather than assuming it's on `$PATH`:

```bash
nix run nixpkgs#<package> -- <args>
```

Examples:

```bash
nix run nixpkgs#sops -- --decrypt secrets/pds.env
nix run nixpkgs#ssh-to-age -- --help
nix run nixpkgs#nixfmt-rfc-style -- file.nix
```

The maintenance tools (`health-check`, `flake-bump`, `gen-diff`) are the exception —
they have shell aliases and are available after a rebuild.

## Code Style

- Formatter: `nixfmt-rfc-style` (run `nix fmt`)
- Follow existing patterns in the file you're editing
- Keep options in `modules/options.nix` grouped by domain with
  `# ── Domain ──` headers
- Prefer `lib.mkIf` over `if/then/else` blocks at the top level

## Common Tasks

**Add a new system option:**

1. Declare it in `modules/options.nix` with a type and default
2. Use `config.myConfig.yourOption` in the relevant module
3. Override per-host in `hosts/<hostname>/default.nix` if needed

**Add a new host:**

1. Create `hosts/<hostname>/default.nix`
2. Add hardware config (NixOS: `nixos-generate-config`)
3. Add entry in `flake.nix` under `nixosConfigurations` or
   `darwinConfigurations`
4. See `docs/hosts.md` for the full guide

**Add a new home-manager program:**

1. Create `home/programs/<name>.nix`
2. Import it from `home/default.nix`
3. Access host config via `osConfig.myConfig.*`

## Documentation

- `lib/USAGE.md` — module patterns
- `docs/settings.md` — how configuration works
- `docs/settings-config.md` — full option reference
- `docs/REFERENCE.md` — quick command card
- `docs/hosts.md` — host management index
- `docs/secrets.md` — secrets management
