##############################################################################
#  Hardware health monitoring — smartd with HTML email alerts via Resend SMTP.
#
#  Alerts are styled to match the pds-landing terminal aesthetic
#  (Catppuccin-inspired forest-green palette, JetBrains Mono, terminal card).
#  The HTML template lives in ./smartd-alert-template.html.
#
#  smartd sets these env vars when calling the mailer script:
#    SMARTD_DEVICE        — device path (e.g. /dev/sda)
#    SMARTD_DEVICESTRING  — human-readable device description
#    SMARTD_FAILTYPE      — failure type (e.g. Temperature_Celsius)
#    SMARTD_SUBJECT       — generated subject line
#    SMARTD_MESSAGE       — full plain-text diagnostic message
#    SMARTD_HOSTNAME      — hostname
#    SMARTD_ADDRESS       — recipient address
#    SMARTD_TFIRST        — human-readable time of first failure
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

  # HTML template — read from the adjacent file and placed in the Nix store.
  # All $VARNAME placeholders are substituted at runtime by envsubst.
  alertTemplate = pkgs.writeText "smartd-alert-template.html" (
    builtins.readFile ./smartd-alert-template.html
  );

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
    passwordeval cat ${config.sops.secrets."smartd-smtp-pass".path}

    account default : resend
  '';

  # Mailer script — populates env vars (both smartd-provided and build-time),
  # runs envsubst over the HTML template, then sends via msmtp.
  # Ignores stdin (smartd's plain-text) in favour of the structured env vars.
  mailerScript = pkgs.writeShellScript "smartd-mailer" ''
    set -euo pipefail

    # ── Runtime vars from smartd ───────────────────────────────────────────
    export SUBJECT="''${SMARTD_SUBJECT:-Disk alert on ''${SMARTD_HOSTNAME:-server}}"
    export DEVICE="''${SMARTD_DEVICE:-unknown}"
    export DEVICE_STR="''${SMARTD_DEVICESTRING:-''${SMARTD_DEVICE:-unknown}}"
    export FAILTYPE="''${SMARTD_FAILTYPE:-unknown}"
    export HOST="''${SMARTD_HOSTNAME:-server}"
    export TFIRST="''${SMARTD_TFIRST:-unknown}"
    export MESSAGE="''${SMARTD_MESSAGE:-No details available.}"
    export RECIPIENT="''${SMARTD_ADDRESS:-${cfg.server.smartd.recipient}}"

    # ── Build-time values exported for envsubst ────────────────────────────
    export FROM_ADDRESS="${cfg.server.smartd.fromAddress}"

    # HTML-escape the diagnostic message before injecting into the template
    export ESCAPED_MSG=$(printf '%s' "$MESSAGE" | ${pkgs.gnused}/bin/sed \
      's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

    # Write the final email to a temp file — avoids heredoc expansion mangling the HTML
    TMPFILE=$(${pkgs.coreutils}/bin/mktemp)
    trap '${pkgs.coreutils}/bin/rm -f "$TMPFILE"' EXIT

    # Headers
    printf 'To: %s\nFrom: %s\nSubject: %s\nMIME-Version: 1.0\nContent-Type: text/html; charset=UTF-8\n\n' \
      "$RECIPIENT" "$FROM_ADDRESS" "$SUBJECT" > "$TMPFILE"

    # Substitute all placeholders in the template and append the body
    ${pkgs.envsubst}/bin/envsubst \
      '$SUBJECT $DEVICE $DEVICE_STR $FAILTYPE $HOST $TFIRST $ESCAPED_MSG $RECIPIENT $FROM_ADDRESS' \
      < ${alertTemplate} >> "$TMPFILE"

    ${pkgs.msmtp}/bin/msmtp \
      --file=${msmtpConfig} \
      "$RECIPIENT" < "$TMPFILE"
  '';
in
{
  sops.secrets."smartd-smtp-pass" = {
    sopsFile = ../../../../secrets/smartd-smtp-pass;
    format = "binary";
    owner = "root";
    mode = "0400";
  };

  services.smartd = {
    enable = lib.mkDefault true;
    notifications = {
      x11.enable = false;
      wall.enable = false;
      mail = {
        enable = true;
        mailer = "${mailerScript}";
        recipient = cfg.server.smartd.recipient;
      };
    };
  };
}
