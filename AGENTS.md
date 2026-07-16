# AGENTS.md

Guidance for agents working on the personal Nix configuration for macOS and NixOS.

## Architecture

- `flake.nix`/`flake.lock` define inputs and outputs.
- `modules/options.nix` is the centralized option/default source; reusable modules live in `modules/` and `lib/`.
- `hosts/<hostname>/` contains machine overrides. Do not move host-specific hardware or secrets into shared modules.
- `home/` owns Home Manager configuration; `secrets/` contains encrypted declarations/material only.
- `hooks/`, `scripts/`, and `tools/` support activation and maintenance.

## Safety rules

- Never commit decrypted secrets, private keys, passwords, tokens, or host-local generated credentials.
- Preserve the macOS-primary/NixOS-secondary architecture and explicit host boundaries.
- Avoid impure absolute paths and unpinned fetches. Update `flake.lock` only intentionally and review every input change.
- Activation scripts must be idempotent and should not delete unmanaged user data.
- Do not run a live switch as routine validation; building is safe evidence, activation changes the machine.

## Validation

Run `nix flake check`, format changed Nix files with the configured formatter, and build the affected `darwinConfigurations` or `nixosConfigurations` output without switching. Evaluate affected Home Manager outputs and run focused script checks. Inspect diffs for secret material and unintended lockfile churn before committing.
