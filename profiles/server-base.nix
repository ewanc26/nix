{ ... }:
{
  imports = [
    ../modules/server/packages.nix
    ../modules/server/maintenance.nix
    ../modules/server/hardware-health.nix
    ../modules/server/disable-noise.nix
  ];
}
