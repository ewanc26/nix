{ config, pkgs, ... }:

{
  imports = [
    ../../modules/darwin/common.nix
    ../../modules/darwin/packages.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/system.nix
  ];

  # Primary user for homebrew and user-specific options
  system.primaryUser = "ewan";

  # System configuration
  networking = {
    hostName = "macmini";
    computerName = "MacMini";
  };

  # User configuration
  users.users.ewan = {
    home = "/Users/ewan";
    shell = pkgs.zsh;
  };

  # Used for backwards compatibility
  system.stateVersion = 5;
}
