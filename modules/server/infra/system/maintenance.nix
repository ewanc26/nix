{ lib, ... }:

{
  # Trim SSD blocks weekly
  services.fstrim.enable = lib.mkDefault true;

  # Time synchronisation
  services.timesyncd.enable = lib.mkDefault true;

  # Cap journal size and retention
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';

  # Vacuum the journal weekly via a systemd timer (not cron — NixOS is systemd-native)
  systemd.services.journal-vacuum = {
    description     = "Vacuum systemd journal older than 30 days";
    serviceConfig   = {
      Type            = "oneshot";
      ExecStart       = "/run/current-system/sw/bin/journalctl --vacuum-time=30d";
    };
  };

  systemd.timers.journal-vacuum = {
    description             = "Weekly systemd journal vacuum";
    wantedBy                = [ "timers.target" ];
    timerConfig = {
      OnCalendar  = "weekly";
      Persistent  = true;   # run on next boot if the scheduled time was missed
    };
  };
}
