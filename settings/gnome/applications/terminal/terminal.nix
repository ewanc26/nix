# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/terminal/legacy" = {
      theme-variant = "dark";
    };

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      background-color = "rgb(23,20,33)";
      font = "RobotoMono Nerd Font 11";
      foreground-color = "rgb(208,207,204)";
      use-system-font = false;
      use-theme-colors = false;
      visible-name = "Default";
    };
  };
}
