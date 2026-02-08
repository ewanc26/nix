# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, config, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${config.home.homeDirectory}/.config/wallpapers/wallpaper.jpg";
      picture-options = "zoom";
    };
  };
}
