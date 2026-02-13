{ config, pkgs, ... }:

{
  imports = [
    ./minimal-hardware.nix
    ../../modules/common.nix
    ../../modules/users.nix
    ../../profiles/server-hardened.nix
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

  # Security settings
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # System version
  system.stateVersion = "25.11";
}
