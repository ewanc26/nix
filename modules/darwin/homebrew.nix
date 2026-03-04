{
  config,
  ...
}:
let
  cfg = config.myConfig;

  # Normalise every cask entry to an attrset and force greedy = true so
  # that `brew upgrade` always overwrites out-of-date casks — including
  # those that declare auto_updates or version :latest.
  makeGreedy =
    cask:
    if builtins.isString cask then
      {
        name = cask;
        greedy = true;
      }
    else
      cask // { greedy = true; };
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
