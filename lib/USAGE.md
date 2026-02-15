# Using cfgLib - Developer Guide

## Overview

The `cfgLib` library is automatically available in all modules through `specialArgs`. You no longer need to manually import `settings/config.nix` in each module.

## Basic Usage

### Standard System Module

```nix
{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;  # Get the central config
in
{
  # Your module code here
  services.myservice.enable = cfg.myoption;
}
```

### Home Manager Program Module

```nix
{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  programs.myprogram = {
    enable = true;
    setting = cfg.mysetting;
  };
}
```

### Home Manager Program with Platform Detection

```nix
{ isDarwin }:
{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  programs.myprogram = {
    enable = true;
    # macOS-specific option
    option = lib.mkIf isDarwin cfg.macos.option;
  };
}
```

## Helper Functions

### 1. resolvePackages

Safely resolve package names, skipping any that don't exist:

```nix
{ config, pkgs, cfgLib, ... }:

let
  resolve = cfgLib.resolvePackages pkgs;
in
{
  environment.systemPackages = resolve [
    "firefox"
    "vscode"
    "nonexistent-package"  # Will be skipped with warning
  ];
}
```

### 2. mkAuthorizedKeys

Get SSH authorized keys excluding the current host:

```nix
{ config, cfgLib, ... }:

{
  users.users.myuser = {
    openssh.authorizedKeys.keys = 
      cfgLib.mkAuthorizedKeys config.networking.hostName;
  };
}
```

### 3. cfg (Central Config)

Access any config value without importing:

```nix
let
  cfg = cfgLib.cfg;
in
{
  # Instead of: import ../settings/config.nix
  # Just use:
  time.timeZone = cfg.system.timeZone;
  users.users.${cfg.user.username} = { ... };
  programs.firefox.enable = cfg.packages.firefox.enable;
}
```

## Complete Example

Here's a complete module using cfgLib:

```nix
{ config, pkgs, lib, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
  resolve = cfgLib.resolvePackages pkgs;
in
{
  # Use config values
  services.myservice = {
    enable = cfg.myservice.enable;
    port = cfg.myservice.port;
  };

  # Resolve packages safely
  environment.systemPackages = 
    resolve cfg.myservice.packages
    ++ [ pkgs.myapp ];

  # Access user config
  users.users.${cfg.user.username} = {
    extraGroups = [ "mygroup" ];
  };
}
```

## Migration Checklist

When updating an old module to use cfgLib:

1. Add `cfgLib` to the module arguments:
   ```nix
   { config, pkgs, lib, cfgLib, ... }:  # Add cfgLib here
   ```

2. Replace config import:
   ```nix
   # Old:
   let cfg = import ../settings/config.nix;
   
   # New:
   let cfg = cfgLib.cfg;
   ```

3. Use helpers where applicable:
   ```nix
   # Old:
   let
     toPkg = name: if pkgs ? ${name} then pkgs.${name} else null;
     resolve = names: filter (x: x != null) (map toPkg names);
   
   # New:
   let resolve = cfgLib.resolvePackages pkgs;
   ```

4. Test with `nix flake check`
