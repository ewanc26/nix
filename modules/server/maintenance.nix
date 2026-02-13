{ lib, ... }:
{
  system.autoUpgrade = {
    allowReboot = false;
    rebootWindow = {
      lower = "02:00";
      upper = "05:00";
    };
  };

  services.fstrim.enable = lib.mkDefault true;
  services.timesyncd.enable = lib.mkDefault true;

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';

  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 2 * * 0 root journalctl --vacuum-time=30d"
    ];
  };
}
