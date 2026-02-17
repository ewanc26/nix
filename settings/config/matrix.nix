{
  # Matrix Synapse homeserver configuration.
  # Non-secret settings only. Secrets (registration_shared_secret, macaroon_secret_key)
  # should be stored in secrets/age/matrix.env.age.

  # Public hostname — also used as the Caddy virtual host and the Cloudflare
  # tunnel public hostname.
  hostname = "matrix.ewancroft.uk";

  # The base domain used for Matrix IDs (@user:domain).
  # Using your apex domain so users have clean Matrix IDs like @username:ewancroft.uk
  serverName = "ewancroft.uk";

  # Internal port the Synapse process listens on. Never exposed publicly.
  port = 8008;

  # Caddy internal listen port — Cloudflare tunnel routes here.
  caddyPort = 8448;
  # Restart policy is shared: see settings/config/server.nix → servicePolicy.
}
