{
  # Bluesky ATProto Personal Data Server configuration.
  # Non-secret settings only. Secrets (PDS_JWT_SECRET, PDS_ADMIN_PASSWORD,
  # PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX, PDS_EMAIL_SMTP_URL,
  # PDS_EMAIL_FROM_ADDRESS) live in secrets/age/pds.env.age.

  enable = true;

  # Public hostname — also used as the Caddy virtual host and the Cloudflare
  # tunnel public hostname. Subdomains are used for account handles.
  hostname = "pds.ewancroft.uk";

  # Internal port the PDS process listens on. Never exposed publicly.
  port = 3000;

  # Email shown in the PDS admin panel.
  adminEmail = "pds@ewancroft.uk";

  # Additional handle domains. ".ewancroft.uk" lets users have @user.ewancroft.uk handles.
  serviceHandleDomains = [ ".ewancroft.uk" ];

  # ATProto relay crawlers — sourced from https://compare.hose.cam
  crawlers = [
    "https://bsky.network"
    "https://relay.cerulea.blue"
    "https://relay.fire.hose.cam"
    "https://relay2.fire.hose.cam"
    "https://relay3.fr.hose.cam"
    "https://relay.hayescmd.net"
    "https://relay.xero.systems"
    "https://relay.upcloud.world"
    "https://relay.feeds.blue"
    "https://atproto.africa"
  ];

  # Caddy internal listen port — Cloudflare tunnel routes here.
  caddyPort = 2020;

  # systemd restart policy
  restartSec = 5;
  startLimitIntervalSec = 300;
  startLimitBurst = 5;
}
