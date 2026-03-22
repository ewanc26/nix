# KDE Plasma desktop settings — desktop hosts only (not server).
# Terminal profile lives in terminal.nix and is imported separately for all
# non-Darwin hosts; this file is the plasma-manager layer + wallpaper service.
#
# Why a systemd service for wallpaper?
# plasma-manager applies the wallpaper via D-Bus at home-manager activation
# time. Activation runs before the Plasma session is live (no D-Bus), so it
# silently fails. The service below runs plasma-apply-wallpaperimage *after*
# the graphical session has started, which is the only reliable method.
{ pkgs, lib, ... }:

let
  wallpaper = "${../../wallpapers/wallpaper.jpg}";
in
{
  imports = [
    ../settings/plasma.nix
  ];

  # ── Wallpaper systemd user service ─────────────────────────────────────────
  systemd.user.services.set-plasma-wallpaper = {
    Unit = {
      Description = "Apply KDE Plasma wallpaper";
      After = [ "plasma-plasmashell.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-wallpaperimage ${wallpaper}";
      # Restart on failure in case plasmashell wasn't fully ready yet
      Restart = "on-failure";
      RestartSec = "2s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
