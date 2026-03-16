##############################################################################
#  Hardware health monitoring — smartd with email alerts via Resend SMTP.
#
#  smartd watches all drives and emails on failure, prefailure, and
#  temperature changes. Alerts go via msmtp → Resend → the configured
#  recipient address.
#
#  Secret (sops-encrypted, age backend):
#    secrets/smartd-smtp-pass — raw Resend API key (no KEY= prefix, no newline)
#
#    Create and encrypt:
#      printf '%s' 're_xxxx...' > secrets/smartd-smtp-pass
#      SOPS_AGE_KEY_FILE=~/.config/age/keys.txt \
#        nix run nixpkgs#sops -- --encrypt --in-place secrets/smartd-smtp-pass
##############################################################################
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig;

  # msmtp config — mirrors the pattern used by Forgejo, Vaultwarden, etc.
  # Port 465 + tls_starttls off = implicit TLS (not STARTTLS).
  msmtpConfig = pkgs.writeText "msmtp-smartd.conf" ''
    defaults
    auth           on
    tls            on
    tls_starttls   off
    tls_trust_file /etc/ssl/certs/ca-certificates.crt

    account        resend
    host           smtp.resend.com
    port           465
    from           ${cfg.server.smartd.fromAddress}
    user           resend
    passwordfile   ${config.sops.secrets."smartd-smtp-pass".path}

    account default : resend
  '';

  # Drop-in sendmail replacement that smartd's mailer option expects.
  mailerScript = pkgs.writeShellScript "smartd-mailer" ''
    exec ${pkgs.msmtp}/bin/msmtp --config=${msmtpConfig} "$@"
  '';
in
{
  sops.secrets."smartd-smtp-pass" = {
    sopsFile = ../../secrets/smartd-smtp-pass;
    format = "binary";
    owner = "root";
    mode = "0400";
  };

  services.smartd = {
    enable = lib.mkDefault true;
    notifications = {
      x11.enable = false;
      # wall is useless on a headless server — email instead.
      wall.enable = false;
      mail = {
        enable = true;
        mailer = "${mailerScript}";
        recipient = cfg.server.smartd.recipient;
      };
    };
  };
}
