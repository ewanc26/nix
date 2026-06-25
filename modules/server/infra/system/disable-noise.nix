# Disable desktop-oriented services that are meaningless on a headless server.
# Avahi (mDNS) and printing are enabled by services.nix on the laptop but
# should never run on the server.
{ lib, ... }:
{
  services.avahi.enable = lib.mkDefault false;
  services.printing.enable = lib.mkDefault false;
}
