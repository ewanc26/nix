# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "" = {
      clock-show-weekday = true;
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
      show-battery-percentage = true;
    };

  };
}
