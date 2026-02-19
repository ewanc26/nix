{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
in
{
  imports = [
    ../../settings/darwin
  ];

  # Keyboard – driven from myConfig.darwin.keyboard
  system.keyboard = {
    enableKeyMapping = cfg.darwin.keyboard.enableKeyMapping;
    remapCapsLockToControl = cfg.darwin.keyboard.remapCapsLockToControl;
  };

  # Startup chime – driven from myConfig.darwin.startup.chime
  system.startup.chime = cfg.darwin.startup.chime;

  # Touch ID for sudo – driven from myConfig.darwin.security.touchIdForSudo
  security.pam.services.sudo_local.touchIdAuth = cfg.darwin.security.touchIdForSudo;

  # ── Time Machine destination ──────────────────────────────────────────────
  # No native nix-darwin option exists for tmutil setdestination, so we use an
  # activation script. Priority order:
  #   1. Local APFS volume on external disk (myConfig.darwin.externalDisk.timeMachineVolumeUUID)
  #   2. SMB server share (myConfig.server.timemachine.enable = true)
  #   3. Skip — no Time Machine configured
  #
  # Server first-time setup (one-off, interactive — stores password in macOS keychain):
  #   sudo tmutil setdestination -p smb://<user>@server/TimeMachine
  # After that, nrs registers it automatically on every rebuild without prompting.
  system.activationScripts.timeMachineDestination = lib.mkIf
    (cfg.darwin.externalDisk.timeMachineVolumeUUID != null || cfg.server.timemachine.enable)
    {
      text =
        let
          localUUID = cfg.darwin.externalDisk.timeMachineVolumeUUID;
          hasLocal = localUUID != null;
          serverUrl = "smb://${cfg.user.username}@server/${cfg.server.timemachine.shareName}";
          hasServer = cfg.server.timemachine.enable;
        in
        ''
          _register_tm() {
            local dest="$1"
            if /usr/bin/tmutil destinationinfo 2>/dev/null | /usr/bin/grep -qF "$dest"; then
              echo "  Time Machine: $dest already registered, skipping"
            else
              echo "  Time Machine: registering $dest"
              # -a adds alongside existing destinations rather than replacing.
              # For SMB, credentials must already be in the macOS keychain.
              /usr/bin/tmutil setdestination -a "$dest" 2>&1 || \
                echo "  WARNING: could not register $dest"
            fi
          }

          ${lib.optionalString hasLocal ''
            # ── Priority 1: local APFS volume ──────────────────────────────────
            echo "Checking local Time Machine volume (UUID=${localUUID})..."
            _info=$(/usr/sbin/diskutil info "${localUUID}" 2>/dev/null)
            if [ $? -eq 0 ]; then
              _mount=$(echo "$_info" | /usr/bin/awk '/Mount Point/ { for(i=3;i<=NF;i++) printf "%s ", $i; print "" }' | /usr/bin/sed 's/ *$//')
              if [ -z "$_mount" ] || [ "$_mount" = "Not applicable (no file system)" ]; then
                echo "  Volume exists but not mounted — mounting..."
                /usr/sbin/diskutil mount "${localUUID}" 2>&1
                _mount=$(/usr/sbin/diskutil info "${localUUID}" 2>/dev/null | /usr/bin/awk '/Mount Point/ { for(i=3;i<=NF;i++) printf "%s ", $i; print "" }' | /usr/bin/sed 's/ *$//')
              fi
              if [ -n "$_mount" ] && [ "$_mount" != "Not applicable (no file system)" ]; then
                _register_tm "$_mount"
                # Local disk found and registered — skip server check.
                return 0 2>/dev/null || exit 0
              else
                echo "  Could not mount local TM volume; falling back to server."
              fi
            else
              echo "  Local disk not found (UUID=${localUUID}); falling back to server."
            fi
          ''}

          # ── Backup schedule: weekly (604800 seconds) ───────────────────────────
          /usr/bin/tmutil setbackupinterval 604800

          ${lib.optionalString hasServer ''
            # ── Priority 2: SMB server share ───────────────────────────────────
            echo "Checking server Time Machine share (${serverUrl})..."
            if /sbin/ping -c1 -W1 server &>/dev/null; then
              _register_tm "${serverUrl}"
            else
              echo "  Server unreachable — skipping Time Machine setup."
            fi
          ''}
        '';
    };
}
