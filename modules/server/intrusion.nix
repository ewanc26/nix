{ lib, ... }:
{
  services.fail2ban = {
    enable = lib.mkDefault true;
    maxretry = 5;
    jails.sshd.settings = {
      enabled = true;
      port = "22";
      filter = "sshd";
      logpath = "/var/log/auth.log";
      maxretry = 5;
      findtime = 600;
      bantime = 3600;
    };
  };
}
