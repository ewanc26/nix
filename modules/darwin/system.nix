{ config, pkgs, ... }:

{
  # Import Darwin defaults (encrypted settings)
  # This will load all system.defaults settings from settings/darwin/defaults.nix
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

  # Additional system configuration
  system.activationScripts.postUserActivation.text = ''
    # Restart affected apps after configuration changes
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

  # Security settings
  security.pam.enableSudoTouchIdAuth = true;  # Enable Touch ID for sudo
}
