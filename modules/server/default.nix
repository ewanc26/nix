{ ... }:
{
  imports = [
    ./packages.nix
    ./maintenance.nix
    ./hardware-health.nix
    ./disable-noise.nix
    ./ssh.nix
    ./intrusion.nix
    ./firewall.nix
  ];
}
