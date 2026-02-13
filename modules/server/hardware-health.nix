{ lib, ... }:
{
  services.smartd = {
    enable = lib.mkDefault true;
    notifications = {
      x11.enable = false;
      wall.enable = true;
    };
  };
}
