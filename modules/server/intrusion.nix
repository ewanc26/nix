{ lib, ... }:

let
  cfg = import ../../settings/config.nix;
in
{
  services.fail2ban = {
    enable   = lib.mkDefault cfg.server.fail2ban.enable;
    maxretry = cfg.server.fail2ban.maxRetry;

    jails.sshd.settings = {
      enabled  = true;
      port     = toString cfg.server.sshd.port;
      filter   = "sshd";
      # NixOS uses the systemd journal — there is no /var/log/auth.log.
      backend  = "systemd";
      maxretry = cfg.server.fail2ban.maxRetry;
      findtime = cfg.server.fail2ban.findTime;
      bantime  = cfg.server.fail2ban.banTime;
    };
  };
}
