{ config, pkgs, cfgLib, ... }:

let
  cfg = cfgLib.cfg;
in
{
  # Import Darwin system-defaults (auto-exported values from settings/darwin/domains/)
  imports = [
    ../../settings/darwin
  ];

  # Keyboard – driven from settings/config/darwin.nix
  system.keyboard = {
    enableKeyMapping       = cfg.darwin.keyboard.enableKeyMapping;
    remapCapsLockToControl = cfg.darwin.keyboard.remapCapsLockToControl;
  };

  # Startup chime – driven from settings/config/darwin.nix
  system.startup.chime = cfg.darwin.startup.chime;

  # Touch ID for sudo – driven from settings/config/darwin.nix
  security.pam.services.sudo_local.touchIdAuth = cfg.darwin.security.touchIdForSudo;
}
