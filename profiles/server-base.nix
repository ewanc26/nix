{ ... }:
{
  imports = [
    ../modules/server/packages.nix
    ../modules/server/storage.nix
    ../modules/server/services.nix
    ../modules/server/maintenance.nix
    ../modules/server/hardware-health.nix
    ../modules/server/disable-noise.nix
    ../modules/server/timemachine.nix
  ];
}
