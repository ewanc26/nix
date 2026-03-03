# Module System — Developer Guide

> **Note**: The `cfgLib` helper library has been removed. All configuration is now accessed directly
> through the standard NixOS module system via `config.myConfig.*` (system modules) or
> `osConfig.myConfig.*` (home-manager modules). No custom abstraction or manual wiring is needed.

## Accessing config in system modules

```nix
# modules/my-module.nix
{ config, pkgs, lib, ... }:
let
  cfg = config.myConfig;
in
{
  time.timeZone = cfg.timeZone;
  users.users.${cfg.user.username} = { ... };
}
```

## Accessing config in home-manager modules

```nix
# home/programs/my-program.nix
{ osConfig, ... }:
let
  cfg = osConfig.myConfig;
in
{
  programs.git.userEmail = cfg.user.email;
}
```

## Resolving packages from a list of names

Use `resolveFrom` from `lib/default.nix`. It skips missing packages with a
warning instead of failing the build, and works with any package set.

```nix
{ config, pkgs, ... }:
let
  cfg = config.myConfig;
  resolvePackages = (import ../lib).resolveFrom pkgs;
in
{
  environment.systemPackages =
    resolvePackages cfg.packages.common
    ++ resolvePackages cfg.packages.development;
}
```

For `kdePackages` or another nested set, pass the sub-set as the first arg:

```nix
let resolveKde = (import ../lib).resolveFrom pkgs.kdePackages;
in
{
  environment.plasma6.excludePackages =
    resolveKde cfg.desktop.plasma.excludePackages;
}
```

## Authorized SSH keys

The `mkAuthorizedKeys` helper is replaced by the inline logic in `modules/users.nix`:

```nix
let
  allKeys = import ./ssh-keys.nix;
  authorizedKeys = lib.attrValues (
    lib.filterAttrs (name: _: name != config.networking.hostName) allKeys
  );
in
{
  users.users.ewan.openssh.authorizedKeys.keys = authorizedKeys;
}
```

## All option declarations

All options and their defaults live in `modules/options.nix`. See
[`docs/settings-config.md`](../docs/settings-config.md) for a full reference table.

## Adding a new option

```nix
# 1. Declare it in modules/options.nix
myNewThing = {
  enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable the new thing.";
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
