{ lib, ... }:
{
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AllowUsers = [ "ewan" ];
      MaxAuthTries = 3;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      X11Forwarding = false;
    };
    ports = [ 22 ];
  };
}
