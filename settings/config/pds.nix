{ config, pkgs, ... }:

{
  services.pds = {
    enable = true;
    environmentFile = config.age.secrets."pds.env.age".path;
  };

  networking.firewall.allowedTCPPorts = [ 3000 80 443 ];

  systemd.services.pds.serviceConfig = {
    Restart = "always";
    RestartSec = 5;
  };

  systemd.services.pds.unitConfig = {
    StartLimitIntervalSec = 300;
    StartLimitBurst = 5;
  };
}
