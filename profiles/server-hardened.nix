{ ... }:
{
  imports = [
    ./server-base.nix
    ../modules/server/ssh.nix
    ../modules/server/intrusion.nix
    ../modules/server/firewall.nix
  ];
}
