{
  # Forgejo git forge configuration.
  # Non-secret settings only. Secrets (secret key, mailer password, etc.)
  # live in secrets/age/forgejo.env.age.

  enable = true;

  # Public hostname.
  hostname = "git.ewancroft.uk";

  # Internal port the Forgejo process listens on. Never exposed publicly.
  port = 3001;

  # Caddy internal listen port — Cloudflare tunnel routes here.
  caddyPort = 3002;

  # Display name shown in the UI.
  appName = "Ewan's Git";

  # Disable public registration — invite-only or admin-created accounts only.
  disableRegistration = true;

  # systemd restart policy
  restartSec = 5;
  startLimitIntervalSec = 300;
  startLimitBurst = 5;
}
