##############################################################################
#  Caddy reverse proxy module.
#
#  Two classes of virtual host live here:
#
#  1. Cloudflare Tunnel vhosts  (defined in each service's module)
#     http://<hostname>:<caddyPort>  — plain HTTP on non-standard ports.
#     TLS is terminated by Cloudflare; Caddy never sees HTTPS here.
#
#  2. Tailnet vhosts  (defined in each service's module)
#     https://<hostname>            — HTTPS on port 443, Tailscale IP only.
#     Certs are provisioned via DNS-01 challenge using the Cloudflare API
#     token (no inbound firewall ports needed).  The caddy-cloudflare plugin
#     is required for this; see the `package` override below.
#
#  Cloudflare DNS plugin hash:
#    The `hash` field below uses lib.fakeHash as a placeholder.
#    On first rebuild after changing the plugin version, the build will fail
#    with a message like:
#      error: hash mismatch … got: sha256-XXXX…
#    Paste that sha256 value in place of lib.fakeHash and rebuild again.
##############################################################################
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # ── Package — Caddy with Cloudflare DNS plugin ────────────────────────────
  # Required for DNS-01 ACME challenges on the tailnet vhosts.
  services.caddy.package = pkgs.caddy.withPlugins {
    plugins = [
      "github.com/caddy-dns/cloudflare@v0.0.0-20250213193802-b06c2f803e7b"
    ];
    # !! Replace lib.fakeHash with the sha256 from the first failed build.
    hash = lib.fakeHash;
  };

  # ── Caddy service ─────────────────────────────────────────────────────────
  services.caddy = {
    enable = true;

    # Disable automatic HTTPS globally — CF tunnel vhosts are plain HTTP.
    # Tailnet vhosts use explicit `tls { dns cloudflare … }` blocks instead.
    globalConfig = ''
      auto_https off
    '';
  };

  # ── Cloudflare API token (for DNS-01 cert provisioning) ───────────────────
  # sops-nix renders the raw token into a KEY=value env file that systemd
  # loads before Caddy starts.  The token never hits the Nix store.
  sops.templates."caddy-cf-env" = {
    content = "CF_API_TOKEN=${config.sops.placeholder."cloudflare.token"}";
    path = "/run/secrets/caddy-cf-env";
    owner = "caddy";
    group = "caddy";
    mode = "0400";
  };

  # ── Caddy systemd service tweaks ──────────────────────────────────────────
  systemd.services.caddy = {
    # Wait for the sops template to be rendered before starting.
    after = lib.mkAfter [ "sops-nix.service" ];
    wants = lib.mkAfter [ "sops-nix.service" ];
    serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = lib.mkDefault "5s";
      # Inject CF_API_TOKEN into Caddy's environment.
      EnvironmentFile = "/run/secrets/caddy-cf-env";
    };
  };
}
