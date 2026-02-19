##############################################################################
#  /srv partition — automatic format, mount, and directory setup.
#
#  What this module does:
#    1. Runs a one-shot systemd service BEFORE the mount that formats the
#       device with ext4 if it has no filesystem yet (safe: skipped if already
#       formatted). Set the device via myConfig.server.storage.srv.device.
#    2. Declares the /srv fileSystem entry (NixOS handles the actual mount).
#    3. Uses systemd-tmpfiles to create every required subdirectory with the
#       correct ownership, after the mount is up.
#
#  Subdirectory layout:
#    /srv/forgejo          — Forgejo git forge data
#    /srv/matrix-synapse   — Matrix Synapse homeserver data
#    /srv/postgresql       — PostgreSQL database files
#    /srv/bluesky-pds      — Bluesky ATProto PDS data
#    /srv/www              — Static websites / reverse-proxied web roots
##############################################################################
{
  config,
  pkgs,
  ...
}:
let
  srv = config.myConfig.server.storage.srv;
  device = srv.device;
in
{
  # ── 1. Auto-format ──────────────────────────────────────────────────────────
  # Runs before the filesystem is mounted. Formats with ext4 + label "srv"
  # only if blkid reports no filesystem type on the device.
  systemd.services."srv-autoformat" = {
    description = "Auto-format ${device} as ext4 if unformatted";

    # Must complete before the mount unit tries to mount /srv
    before = [ "srv.mount" ];
    wantedBy = [ "srv.mount" ];

    # Only attempt if the device node actually exists (won't run in VM/CI
    # if the disk isn't attached)
    unitConfig.ConditionPathExists = device;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [
      pkgs.util-linux
      pkgs.e2fsprogs
    ];

    script = ''
      if blkid "${device}" | grep -q 'TYPE='; then
        echo "srv-autoformat: ${device} already has a filesystem, skipping"
      else
        echo "srv-autoformat: formatting ${device} as ext4 with label 'srv'"
        mkfs.ext4 -L srv "${device}"
      fi
    '';
  };

  # ── 2. /srv mount ──────────────────────────────────────────────────────────
  fileSystems."/srv" = {
    inherit (srv) device fsType;
    # nofail: boot succeeds even if the drive is absent.
    # noatime: reduce unnecessary writes.
    options = srv.options ++ [ "nofail" "x-systemd.device-timeout=5" ];
    depends = [ "srv-autoformat.service" ];
    neededForBoot = false;
  };

  # ── 3. Subdirectory creation ────────────────────────────────────────────────
  # systemd-tmpfiles creates these after /srv is mounted.
  # 'd' = create directory if missing, set mode/owner, never remove on cleanup.
  systemd.tmpfiles.rules = [
    # Service data dirs — owned by their respective service users
    "d /srv/forgejo         0750 forgejo        forgejo        -"
    "d /srv/matrix-synapse  0750 matrix-synapse  matrix-synapse -"
    "d /srv/postgresql      0750 postgres        postgres       -"
    "d /srv/bluesky-pds     0750 pds             pds            -"

    # Web root — owned by root, readable by caddy/nginx
    "d /srv/www             0755 root            root           -"
    "d /srv/www/default     0755 root            root           -"
  ];
}
