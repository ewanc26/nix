{
  config,
  ...
}:
let
  cfg = config.myConfig;

  # Casks that self-update their own .app bundle (auto_updates = true in the
  # cask definition).  Forcing greedy = true on these causes brew upgrade to
  # remove the current .app and re-stage a fresh download, which can leave the
  # bundle absent if the download or staging step fails.  Let the app manage
  # its own updates instead.
  selfUpdatingCasks = [
    "element"
    "spotify"
    "discord"
    "signal"
    "obsidian"
    "claude"
    "docker"
    "firefox"
    "github"
    "steam"
  ];

  # Normalise every cask entry to an attrset.  Force greedy = true only for
  # casks that do NOT self-update, so `brew upgrade` keeps them current
  # without risking the broken-receipt problem seen with auto_updating apps.
  makeGreedy =
    cask:
    let
      name = if builtins.isString cask then cask else cask.name;
      isSelfUpdating = builtins.elem name selfUpdatingCasks;
    in
    if builtins.isString cask then
      {
        inherit name;
        greedy = !isSelfUpdating;
      }
    else
      cask // { greedy = !(isSelfUpdating); };
in
{
  # Clear stale Homebrew download lock files (.incomplete) that accumulate
  # when a previous activation is interrupted mid-fetch.  These cause the
  # next `brew bundle` to refuse to re-download the same file.
  system.activationScripts.preActivation.text = ''
    stale_dir="/Users/${cfg.user.username}/Library/Caches/Homebrew/downloads"
    if [ -d "$stale_dir" ]; then
      find "$stale_dir" -maxdepth 1 -name '*.incomplete' -delete
    fi
  '';

  # Homebrew configuration — all values driven from myConfig.darwin.homebrew
  homebrew = {
    inherit (cfg.darwin.homebrew)
      enable
      taps
      brews
      masApps
      ;
    casks = map makeGreedy cfg.darwin.homebrew.casks;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
      extraFlags = [ "--verbose" ];
    };
  };
}
