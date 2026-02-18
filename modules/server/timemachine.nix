##############################################################################
#  Time Machine backup target
#
#  Exposes a Samba share with the `fruit` VFS module so macOS clients can
#  use this server as a Time Machine destination. AFP was dropped in macOS
#  Ventura, so SMB + fruit is the correct modern approach.
#
#  Setup (one-time, after deploying):
#    - Add a Samba user for every Mac that will back up:
#        sudo smbpasswd -a <username>
#    - In macOS System Settings -> General -> Time Machine, click "Add Backup
#      Disk...", choose the advertised share, and authenticate.
#
#  Settings knobs (myConfig.server.timemachine):
#    enable        - master toggle
#    shareName     - name visible to macOS (default "TimeMachine")
#    path          - filesystem path for backup data (default /srv/timemachine)
#    maxSizeGB     - soft storage cap reported to macOS (0 = unlimited)
#    validUsers    - list of Samba usernames allowed to write backups
##############################################################################
{
  config,
  lib,
  ...
}:
let
  tm = config.myConfig.server.timemachine;
  cap = if tm.maxSizeGB > 0 then toString tm.maxSizeGB + " G" else "";
  users = lib.concatStringsSep " " tm.validUsers;
in
lib.mkIf tm.enable {

  # ── Samba ──────────────────────────────────────────────────────────────────
  services.samba = {
    enable = true;
    openFirewall = false; # ports managed explicitly below

    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = config.networking.hostName;
        "server role" = "standalone server";

        "load printers" = "no";
        "printcap name" = "/dev/null";

        # macOS interoperability — fruit VFS stack
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";

        "security" = "user";
        "map to guest" = "Never";
        "ntlm auth" = "yes"; # required for older macOS clients
        "min protocol" = "SMB2";
        "smb encrypt" = "desired";
      };

      ${tm.shareName} =
        {
          "path" = tm.path;
          "valid users" = users;
          "public" = "no";
          "writable" = "yes";
          "browseable" = "yes";
          "create mask" = "0600";
          "directory mask" = "0700";
          "fruit:time machine" = "yes";
        }
        // lib.optionalAttrs (cap != "") {
          "fruit:time machine max size" = cap;
        };
    };
  };

  # WS-Discovery so macOS/Windows can find the server by name on the LAN
  services.samba-wsdd = {
    enable = true;
    interface = ""; # all interfaces
  };

  # ── Avahi (mDNS) — Macs discover the share automatically ──────────────────
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };

    # Three records macOS looks for when scanning for Time Machine targets:
    #   _smb._tcp         — the actual file-sharing service
    #   _device-info._tcp — icon hint (shows as a NAS/Time Capsule in Finder)
    #   _adisk._tcp       — Time Machine share advertisement
    extraServiceFiles.timemachine = lib.mkAfter ''
      <?xml version="1.0" standalone='no'?>
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name replace-wildcards="yes">%h</name>
        <service>
          <type>_smb._tcp</type>
          <port>445</port>
        </service>
        <service>
          <type>_device-info._tcp</type>
          <port>0</port>
          <txt-record>model=TimeCapsule8,119</txt-record>
        </service>
        <service>
          <type>_adisk._tcp</type>
          <port>9</port>
          <txt-record>dk0=adVN=${tm.shareName},adVF=0x82</txt-record>
          <txt-record>sys=waMa=0,adVF=0x100</txt-record>
        </service>
      </service-group>
    '';
  };

  # ── Firewall ────────────────────────────────────────────────────────────────
  # Samba needs TCP 445 (SMB) + 139 (NetBIOS session) and UDP 137-138 (NetBIOS).
  # WS-Discovery uses UDP 3702.
  networking.firewall = {
    allowedTCPPorts = [
      445
      139
    ];
    allowedUDPPorts = [
      137
      138
      3702
    ];
  };

  # ── Storage directory ──────────────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d ${tm.path} 0750 root sambashare -"
  ];
}
