# Starship prompt — cross-shell, minimal, fast.
# Settings are loaded from the companion starship.toml config file.
{ config, pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    
    # Import settings from starship.toml in configs directory
    settings = lib.importTOML ../configs/starship.toml;
  };
}
