{ config, pkgs, lib, ... }:

{
  # Import all GNOME settings from the modular structure
  imports = [
    ../../settings/gnome
  ];
}
