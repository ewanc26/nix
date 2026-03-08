##############################################################################
#  Time Machine backup target — Samba + vfs_fruit (SMB) over Tailscale.
#
#  Architecture:
#    macOS Time Machine client
#      ↓ SMB (port 445) over Tailscale WireGuard tunnel
#    Samba — shares /srv/timemachine with vfs_fruit Apple extensions
#      ↓ mDNS (Avahi) + wsdd — advertises the share so macOS discovers it
#    Avahi + samba-wsdd daemons
#
#  vfs_fruit makes Samba look like a native Apple Time Capsule to macOS:
#    - catia         : maps macOS-illegal NTFS characters transparently
#    - fruit         : Apple SMB2+ extensions (metadata, resource forks, TM)
#    - streams_xattr : stores alternate data streams as xattrs on ext4
#
#  Access control:
#    Only Tailscale CGNAT addresses (100.64.0.0/10) are allowed via the
#    `hosts allow` directive. Port 445 is opened in the NixOS firewall but
#    only Tailscale traffic reaches the server anyway.
#
#  User setup (one-time, manual):
#    Samba maintains its own password database separate from /etc/shadow.
#    After deploying, add your user to Samba's database on the server:
#
#      sudo smbpasswd -a ewan
#
#    On the Mac: System Settings → General → Time Machine → Add Backup Disk.
#    The share will appear automatically via mDNS. Enter the server username
#    and the smbpasswd password you set above when prompted.
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  tm = cfg.timemachine;
in
lib.mkIf cfg.services.timemachine.enable {

  # ── Samba (SMB + vfs_fruit) ──────────────────────────────────────────────
  services.samba = {
    enable = true;
    openFirewall = false; # managed explicitly below — Tailscale only

    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = config.networking.hostName;
        "server role" = "standalone server";

        # Apple protocol extensions — applied globally so fruit is always active
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "TimeCapsule6,106"; # shows as Time Capsule in Finder
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";

        # Restrict access to Tailscale CGNAT range
        "hosts allow" = "100.64.0.0/10 127.0.0.1";
        "hosts deny" = "0.0.0.0/0";

        # Disable printing/cups noise
        "load printers" = "no";
        "printcap name" = "/dev/null";
      };

      "TimeMachine" = {
        "path" = tm.path;
        "valid users" = cfg.user.username;
        "read only" = "no";
        "browseable" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:time machine" = "yes";
        "fruit:time machine max size" = "${toString tm.volSizeLimitMiB}M";
      };
    };
  };

  systemd.services.samba-smbd = {
    after = [ "srv.mount" ];
    wants = [ "srv.mount" ];
    serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = cfg.server.servicePolicy.restartSec;
    };
    unitConfig = {
      StartLimitIntervalSec = cfg.server.servicePolicy.startLimitIntervalSec;
      StartLimitBurst = cfg.server.servicePolicy.startLimitBurst;
    };
  };

  # ── Avahi (mDNS — makes the share appear in Finder's sidebar) ───────────
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  # ── wsdd (WS-Discovery — Windows/SMB share announcement over mDNS) ──────
  services.samba-wsdd = {
    enable = true;
    openFirewall = false; # Tailscale only, no need to open externally
  };

  # ── Firewall — SMB port, reachable only via Tailscale ───────────────────
  # Port 445 is opened so smbd is reachable, but `hosts allow` in smb.conf
  # restricts it to 100.64.0.0/10 (Tailscale CGNAT) at the app layer.
  networking.firewall.allowedTCPPorts = [ 445 ];
}
