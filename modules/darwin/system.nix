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
  # activation script. Skipped entirely if timeMachineVolumeUUID is null.
  #
  # The volume is auto-mounted if it exists but isn't mounted yet.
  # Idempotent: skipped if the destination is already registered.
  #
  # NOTE: activation scripts must never call `exit` — that would abort the
  # entire nix-darwin activation.  Early returns are handled via a wrapper
  # function so we can use `return` safely.
  system.activationScripts.timeMachineDestination = lib.mkIf
    (cfg.darwin.externalDisk.timeMachineVolumeUUID != null)
    {
      text =
        let
          uuid = cfg.darwin.externalDisk.timeMachineVolumeUUID;
        in
        ''
          _setup_time_machine() {
            echo "Checking local Time Machine volume (UUID=${uuid})..."
            _info=$(/usr/sbin/diskutil info "${uuid}" 2>/dev/null) || {
              echo "  Disk not found — skipping Time Machine setup."
              return 0
            }

            _mount=$(echo "$_info" | /usr/bin/awk '/Mount Point/ { for(i=3;i<=NF;i++) printf "%s ", $i; print "" }' | /usr/bin/sed 's/ *$//')
            if [ -z "$_mount" ] || [ "$_mount" = "Not applicable (no file system)" ]; then
              echo "  Volume not mounted — mounting..."
              /usr/sbin/diskutil mount "${uuid}" 2>&1 || true
              _mount=$(/usr/sbin/diskutil info "${uuid}" 2>/dev/null | /usr/bin/awk '/Mount Point/ { for(i=3;i<=NF;i++) printf "%s ", $i; print "" }' | /usr/bin/sed 's/ *$//')
            fi

            if [ -z "$_mount" ] || [ "$_mount" = "Not applicable (no file system)" ]; then
              echo "  Could not mount volume — skipping Time Machine setup."
              return 0
            fi

            if /usr/bin/tmutil destinationinfo 2>/dev/null | /usr/bin/grep -qF "$_mount"; then
              echo "  Already registered as Time Machine destination, skipping."
            else
              echo "  Registering $_mount as Time Machine destination..."
              /usr/bin/tmutil setdestination -a "$_mount" 2>&1 || \
                echo "  WARNING: tmutil setdestination failed."
            fi

            # Weekly backup interval (604800 seconds = 7 days)
            /usr/bin/tmutil setbackupinterval 604800
          }
          _setup_time_machine
        '';
    };
}
