# AGENTS.md

Guidance for the personal Nix flake managing `macmini` (aarch64-darwin), `laptop` (x86_64 NixOS/KDE), and `server`/`server-arm` (headless NixOS). A change here can alter live machines, public services, firewall exposure, storage, and secret deployment; build evidence is not authorization to activate it.

## Configuration model

- `flake.nix` pins nixpkgs 25.11, nix-darwin, Home Manager, sops-nix, topology, and service/package inputs and assembles every host. Change `flake.lock` only for an intentional input update and review all changed revisions.
- `modules/options.nix` is the typed source of shared defaults under `myConfig`. System modules consume `config.myConfig`; Home Manager consumes `osConfig.myConfig`. Declare new cross-host settings there and use ordinary module merging/`mkIf` rather than restoring the removed `cfgLib` abstraction.
- `hosts/<name>/default.nix` selects modules and holds genuine machine overrides. Hardware files, hostnames, platform/state versions, disk UUIDs, Tailscale addresses, and service enablement stay host-specific.
- `modules/darwin/`, `modules/server/`, shared `modules/`, and `home/` own platform/service and per-user configuration. Follow `lib/USAGE.md` for package resolution and module patterns.
- `secrets/` contains SOPS-encrypted files tracked by Git; `.sops.yaml` defines recipients. Decryption uses the host SSH key during activation and the user's explicit age key for manual work.
- `topology.nix` adds physical/network facts to generated Linux topology. The embedded `modules/server/services/atproto/pds-landing/` is a separate pnpm/SvelteKit app with its own lockfile.
- `tools/` is retained historical Rust source. Its README marks it deprecated in favour of the `pkgs-monorepo` input; use `nix run ~/Developer/Git/pkgs#<tool>` or the configured aliases, not the stale local tool flake, unless explicitly repairing history.

## Safety and operational rules

- Never expose plaintext secrets, age/SSH private keys, tokens, passwords, environment files, or decrypted command output in source, diffs, logs, or tool output. Do not assume a file is safe merely because it is under `secrets/`; verify it retains valid SOPS metadata and encrypted values.
- Keep public, Cloudflare-tunnel, tailnet-only, and loopback-only services distinct. Review Caddy, tunnel ingress, firewall ports/interfaces, DNS, proxy headers, authentication, and service bind addresses together whenever exposure changes.
- Storage cleanup, garbage collection, migration, PDS/Forgejo/Sharkey purge/setup, ACME repair, and macOS app scripts can destroy or mutate live state. Read the whole script and its caller; never run it as validation or broaden its targets without explicit authorization and a recovery plan.
- Activation and maintenance units must be idempotent, correctly ordered, and safe on partial failure. Preserve ownership/modes for SOPS credentials, service state, backups, Time Machine, databases, media, and external disks.
- Adding or renaming an option requires updating consumers and relevant docs (`docs/settings-config.md` and host/service guidance). Adding a host requires its flake output, host/hardware module, SSH-key relationships, topology, and documentation.
- Do not add impure developer-machine paths or unpinned fetches. The flake's `pkgs-monorepo` and `tgirlpkgs` inputs are deployment dependencies; changes can affect service packages/modules even when this tree's source is unchanged.
- The pre-commit hook formats and re-stages changed Nix, shell, Rust, TOML, and web files, then lints shell/Rust/Markdown. Inspect the staged diff again after it runs; do not let it absorb unrelated edits.

## Validation without activation

- Format Nix with `nix fmt`; run `nix flake check`. For focused evidence build, without `switch`, the affected output: `nix build .#nixosConfigurations.laptop.config.system.build.toplevel`, `.#nixosConfigurations.server.config.system.build.toplevel`, `.#nixosConfigurations.server-arm.config.system.build.toplevel`, or `.#darwinConfigurations.macmini.system`.
- Evaluate all consumers of a changed shared option/module, not just the machine where it was noticed. Home Manager is integrated into each host build.
- For shell changes run `shfmt -d` and `shellcheck`; for the landing app use pnpm in its directory and run its declared checks/build. For topology changes build `.#topology.x86_64-linux.config.output` on Linux or an x86_64-linux remote builder.
- `health-check` is an operational preflight and may complain about an intentionally dirty tree; it does not replace host builds. Do not run `nixos-rebuild switch`, `darwin-rebuild switch`, `nix flake update`, `flake-bump --update*`, secret decryption/rotation, service restarts, migrations, or cleanup as routine validation.
- Before committing, inspect `git diff --cached`, confirm no plaintext or unintended `flake.lock` churn, and preserve unrelated worktree changes. Never commit `result` links, build outputs, decrypted files, host-local credentials, database/state data, or generated topology unless explicitly requested.
