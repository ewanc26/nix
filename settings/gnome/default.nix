{ config, lib, pkgs, ... }:

{
  # Import GNOME settings from a regular file (not encrypted)
  imports = [
    ./dconf-settings.nix
  ];
}
