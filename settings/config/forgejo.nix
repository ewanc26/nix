{
  # Forgejo git forge configuration.
  # Non-secret settings only. Secrets (secret key, mailer password, etc.)
  # live in secrets/age/forgejo.env.age.

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
  # Restart policy is shared: see settings/config/server.nix → servicePolicy.
}
