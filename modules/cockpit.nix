##############################################################################
#  Cockpit — web-based server status dashboard.
#
#  Provides: service status, systemd journal, CPU/RAM/disk metrics,
#            network interfaces, and a built-in terminal.
#
#  Access:
#    Cockpit is intentionally NOT exposed publicly via Caddy or Cloudflare.
#    It is only reachable over Tailscale (the trusted internal network).
#
#    Once connected to Tailscale, open:
#      https://<server-tailscale-ip>:9090
#    or (if you've set a Tailscale MagicDNS hostname):
#      https://server:9090
#
#    Log in with any local system user that is a member of the wheel group.
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig.server.cockpit;
in
lib.mkIf cfg.enable {

  services.cockpit = {
    enable = true;
    port = cfg.port;
    settings.WebService.AllowUnencrypted = true;
  };

  # ── Firewall ────────────────────────────────────────────────────────────────
  # Allow Cockpit only on the Tailscale interface (tailscale0).
  # The trusted interface already bypasses the firewall (set in firewall.nix),
  # so this rule is belt-and-braces — it blocks access from every other interface.
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ cfg.port ];
}
