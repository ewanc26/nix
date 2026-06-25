# Standard user definition for the primary system user (ewan).
# Assigns groups, shell, and SSH authorized keys from ssh-keys.nix.
# Each host automatically excludes its own SSH key from its own config.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myConfig;

  allKeys = import ./ssh-keys.nix;
  authorizedKeys = lib.attrValues (
    lib.filterAttrs (name: _: name != config.networking.hostName) allKeys
  );
in
{
  users.users.${cfg.user.username} = {
    isNormalUser = true;
    description = cfg.user.fullName;
    extraGroups =
      [
        "networkmanager"
        "wheel"
      ]
      ++ lib.optionals config.services.pipewire.enable [
        "audio"
        "video"
      ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = authorizedKeys;
  };
}
