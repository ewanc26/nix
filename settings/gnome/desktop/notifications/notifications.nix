# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "" = {
      application-children = [ "firefox" "gnome-about-panel" "gnome-power-panel" ];
    };

    "application/firefox" = {
      application-id = "firefox.desktop";
    };

    "application/gnome-about-panel" = {
      application-id = "gnome-about-panel.desktop";
    };

    "application/gnome-power-panel" = {
      application-id = "gnome-power-panel.desktop";
    };

  };
}
