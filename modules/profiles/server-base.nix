{ ... }:
{
  imports = [
    ../server/infra/system/packages.nix
    ../server/infra/system/storage.nix
    ../server/infra/system/services.nix
    ../server/infra/system/maintenance.nix
    ../server/infra/system/hardware-health.nix
    ../server/infra/system/disable-noise.nix
  ];
}
