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
    ../../modules/darwin/xmrig.nix
  ];

  # Primary user for homebrew and user-specific options
  system.primaryUser = cfg.user.username;

  myConfig.isDesktop = true;
  myConfig.forgejo.userApiTokenFile = "/Users/${config.myConfig.user.username}/.config/forgejo-user-token";

  myConfig.services.xmrig.enable = true;
  myConfig.services.xmrig.threadsPercent = 50; # M2 thermals are fine
  myConfig.services.xmrig.randomxMode = "light";
  myConfig.services.xmrig.pauseOnActive = true;
  myConfig.services.xmrig.pool.user =
    "44yH2LpkSsrSmWQC3SVmrABw2MUhNjNCE365hG7Rr7veJYNPBD1f6dNgXNr2nc6ZcP3jEyj9vXnqmg7VBBPeS8uwMhJ4yXW";
  myConfig.services.xmrig.pool.pass = "macmini";

  networking = {
    hostName = "macmini";
    computerName = "MacMini";
  };

  # ── External disk (CT2000X9SSD9, APFS container on disk4s2) ───────────────
  # See docs/time-machine.md for first-time setup instructions.
  myConfig.darwin.externalDisk.timeMachineVolumeUUID = "9217DB34-722B-4596-8ADD-20C8060FC257";

  # Timezone — driven from myConfig.timeZone
  time.timeZone = cfg.timeZone;

  users.users.${cfg.user.username} = {
    home = "/Users/${cfg.user.username}";
    shell = pkgs.zsh;
  };

  # nix-darwin uses an integer for stateVersion
  system.stateVersion = 5;
}
