{
  # Backup & maintenance configuration

  # Automatic system updates (NixOS only – nix-darwin does not support system.autoUpgrade)
  autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "daily";
    randomizedDelaySec = "45min";
    updateInputs = [ "nixpkgs" ];  # Inputs to update on each run
  };

  # Backup configuration
  backup = {
    enable = false;
    paths = [
      "/home"
      "/etc/nixos"
    ];
  };
}
