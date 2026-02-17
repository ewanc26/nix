{
  # Server configuration

  # ─── Service toggles ─────────────────────────────────────────────────────────
  # Master on/off switches for every server service.
  # The detailed settings for each service live in their own files (e.g.
  # settings/config/forgejo.nix) — only the enable flag lives here so you
  # have one place to see what's running.
  services = {
    forgejo    = true;  # Forgejo git forge         (git.ewancroft.uk)
    pds        = true;  # Bluesky ATProto PDS        (pds.ewancroft.uk)
    matrix     = true;  # Matrix Synapse homeserver  (matrix.ewancroft.uk)
    cloudflare = true;  # Cloudflare tunnel          (outbound, all services)
  };

  # ─── Time Machine ─────────────────────────────────────────────────────────────
  # Exposes an SMB share (with the fruit VFS module) that macOS backs up to.
  # Requires AFP/Samba — AFP was dropped in Ventura so SMB + fruit is used.
  #
  # After deploying, create a Samba user for each Mac:
  #   sudo smbpasswd -a <username>
  # Then add the backup disk in macOS System Settings -> General -> Time Machine.
  timemachine = {
    enable     = false;  # set to true to activate
    shareName  = "TimeMachine";   # name shown to macOS
    path       = "/srv/timemachine";  # where backups are stored
    maxSizeGB  = 0;   # 0 = unlimited; set e.g. 500 to cap at 500 GB
    validUsers = [ ];  # e.g. [ "ewan" ] — must have a Samba password set
  };

  # ─── Storage ──────────────────────────────────────────────────────────────────
  # /srv is mounted as a separate partition to isolate all service data
  # (forgejo, matrix-synapse, postgresql, bluesky-pds, www) from the root volume.
  #
  # Point `device` at the raw block device you want to use.
  # Run `lsblk` on the server to find the right path, e.g. /dev/sdb or /dev/sdb1.
  #
  # The system will automatically:
  #   1. Format the partition with ext4 (only if it has no filesystem yet)
  #   2. Mount it at /srv
  #   3. Create all required subdirectories with correct ownership
  # No manual setup is needed — just set the device and deploy.
  storage = {
    srv = {
      device  = "/dev/sdb";  # ← set to your partition (use `lsblk` to find it)
      fsType  = "ext4";
      options = [ "defaults" "noatime" ];
      # Subdirectories created automatically under /srv
      # Each service uses its own subdirectory
    };
  };

  # ─── Cockpit dashboard ──────────────────────────────────────────────────────────
  # Web-based server status dashboard (services, journals, metrics, terminal).
  # Accessible only over Tailscale — not exposed publicly.
  cockpit = {
    enable = true;
    port   = 9090;  # Cockpit default
  };

  # ─── Shared systemd service restart policy ───────────────────────────────────
  # Applied by default to forgejo, matrix-synapse, and bluesky-pds.
  # Override per-service by reading this value in the module and using lib.mkForce.
  servicePolicy = {
    restartSec            = 5;   # seconds before restarting after a crash
    startLimitIntervalSec = 300; # window for startLimitBurst
    startLimitBurst       = 5;   # max restarts within the window before giving up
  };

  # SSH daemon
  sshd = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
    port = 22;
    maxAuthTries = 3;
    clientAliveInterval = 300;
    clientAliveCountMax = 2;
    x11Forwarding = false;
  };

  # Fail2ban intrusion prevention
  fail2ban = {
    enable = true;
    maxRetry = 5;
    banTime = 600;   # seconds – 10 minutes
    findTime = 600;  # seconds – detection window
  };

  # Firewall
  firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [ 22 ];  # Add ports as needed
    allowedUDPPorts = [ ];
  };
}
