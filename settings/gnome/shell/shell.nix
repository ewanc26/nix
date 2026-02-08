# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/shell" = {
      welcome-dialog-last-shown-version = "49.2";
    };

    "org/gnome/shell/world-clocks" = {
      locations = [];
    };
  };
}
