{ config, pkgs, ... }:

{
  # Import Darwin defaults (settings)
  # This will load all system.defaults settings from settings/darwin/default.nix
  imports = [
    ../../settings/darwin
  ];

  # Keyboard settings
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;  # Remap Caps Lock to Control
  };

  # Startup chime
  system.startup.chime = false;

  # NOTE: system.activationScripts.postUserActivation has been removed
  # All activation now runs as root, use postActivation if needed

  # Security settings (new format)
  security.pam.services.sudo_local.touchIdAuth = true;  # Enable Touch ID for sudo
}
