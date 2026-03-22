{ lib, ... }:
{
  services.avahi.enable = lib.mkDefault false;
  services.printing.enable = lib.mkDefault false;
}
