{
  config,
  ...
}:
let
  cfg = config.myConfig;
in
{
  imports = [
    ./settings
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
  # tmutil setdestination requires root + Full Disk Access (TCC). macOS does
  # not allow FDA to be granted to activation scripts or launchd daemons
  # without MDM, so this cannot be automated via nrs.
  #
  # The destination only needs to be set once manually (see docs/time-machine.md).
  # It persists across reboots and nrs runs, so no automation is needed.
}
