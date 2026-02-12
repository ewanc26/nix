{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/users.nix
    ../../modules/server-packages.nix
    ../../modules/server-services.nix
  ];

  # Networking
  networking = {
    hostName = "server";
    
    # Firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ]; # SSH
      # Add more ports as needed: 80 443 for web, etc.
    };
  };

  # Boot configuration - clean /tmp on boot
  boot.tmp.cleanOnBoot = true;

  # User SSH keys for remote access
  users.users.ewan.openssh.authorizedKeys.keys = [
    # Add your SSH public keys here
    # "ssh-ed25519 AAAAC3... user@host"
  ];

  # Security settings
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # System version
  system.stateVersion = "25.11";
}
