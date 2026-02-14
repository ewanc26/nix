{ lib, ... }:

let
  cfg = import ../../settings/config.nix;
in
{
  # Trim SSD blocks weekly
  services.fstrim.enable = lib.mkDefault true;

  # Time synchronisation
  services.timesyncd.enable = lib.mkDefault true;

  # Journal size limits
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';

  # Weekly journal vacuum via cron
  services.cron = {
    enable          = true;
    systemCronJobs  = [ "0 2 * * 0 root journalctl --vacuum-time=30d" ];
  };
}
