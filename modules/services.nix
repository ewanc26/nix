# Desktop system services — printing, avahi, SSH, locate, Tailscale.
# Applied on all NixOS hosts that import this module (currently the laptop).
# Server infra services are managed separately under modules/server/.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myConfig;
in
{
  services.printing.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = cfg.server.sshd.permitRootLogin;
      PasswordAuthentication = true; # Desktop: allow password login.
    };
  };

  services.locate = {
    enable = true;
    package = pkgs.plocate;
  };

  services.gvfs.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  services.dbus.enable = true;
  services.udisks2.enable = true;

  # ── Tailscale ──────────────────────────────────────────────────────────────
  # authKeyFile causes a one-shot systemd service (tailscale-autoconnect) to run
  # `tailscale up --auth-key <key>` on boot if the node is not already authed.
  # Generate a reusable (or ephemeral) key at https://login.tailscale.com/admin/settings/keys
  # then encrypt it:  echo -n "tskey-auth-..." > secrets/tailscale-auth-key
  #                   sops --encrypt --in-place secrets/tailscale-auth-key
  sops.secrets."tailscale-auth-key" = {
    sopsFile = ../secrets/tailscale-auth-key;
    format = "binary";
  };

  services.tailscale = {
    enable = true;
    # Open the Tailscale UDP port so direct (non-relay) connections work.
    openFirewall = true;
    # Auto-authenticate on first boot using the pre-provisioned auth key.
    authKeyFile = config.sops.secrets."tailscale-auth-key".path;
  };
}
