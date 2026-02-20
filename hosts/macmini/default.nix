{
  config,
  pkgs,
  ...
}:
let
  cfg = config.myConfig;
in
{
  imports = [
    ../../modules/darwin/common.nix
    ../../modules/darwin/packages.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/system.nix
    ../../modules/darwin/launch-services.nix
    ../../modules/darwin/gatekeeper.nix
  ];

  # Primary user for homebrew and user-specific options
  system.primaryUser = cfg.user.username;

  myConfig.isDesktop = true;

  networking = {
    hostName = "macmini";
    computerName = "MacMini";
  };


  # ── External disk (CT2000X9SSD9, APFS container on disk4s2) ───────────────
  # See docs/time-machine.md for first-time setup instructions.
  myConfig.darwin.externalDisk.timeMachineVolumeUUID = "9217DB34-722B-4596-8ADD-20C8060FC257";

  # Tailscale — auto-start at login so SSH ProxyCommand never fails on boot.
  launchd.user.agents."com.tailscale.tailscaled-launcher" = {
    serviceConfig = {
      ProgramArguments = [ "/usr/bin/open" "-a" "/Applications/Tailscale.app" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  # AltServer is a menu bar app (LSUIElement = true) so macOS intentionally
  # hides it from Spotlight — this is by design and cannot be changed.
  # Launch it automatically at login via a launchd user agent instead.
  launchd.user.agents."com.rileytestut.AltServer-launcher" = {
    serviceConfig = {
      ProgramArguments = [ "/usr/bin/open" "-a" "/Applications/AltServer.app" ];
      RunAtLoad = true;
      KeepAlive = false;  # one-shot: open the app then exit
    };
  };

  # Timezone — driven from myConfig.timeZone
  time.timeZone = cfg.timeZone;

  users.users.${cfg.user.username} = {
    home = "/Users/${cfg.user.username}";
    shell = pkgs.zsh;
  };

  # nix-darwin uses an integer for stateVersion
  system.stateVersion = 5;
}
