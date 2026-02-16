# KDE Plasma desktop settings — desktop hosts only (not server).
# Terminal profile lives in terminal.nix and is imported separately for all
# non-Darwin hosts; this file is only the plasma-manager + wallpaper layer.
{ lib, cfgLib, ... }:

{
  imports = [
    ../../settings/plasma   # panels, KWin effects, shortcuts, fonts — all from cfg
  ];

  # Wallpaper path is relative to this file, so it must live here rather than
  # in settings/plasma/default.nix.
  programs.plasma.workspace.wallpaper = "${../../wallpapers/wallpaper.jpg}";
}
