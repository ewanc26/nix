# Server base profile — foundational infra modules for any headless NixOS host.
# Imports packages, storage, services, maintenance, hardware health, and
# the disable-noise module. Extended by server-hardened.nix below.
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
