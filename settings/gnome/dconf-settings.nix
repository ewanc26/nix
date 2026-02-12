{ config, lib, pkgs, ... }:

{
  # GNOME dconf settings
  # TODO: Copy your actual settings from the decrypted gnome-dconf-settings.age file here
  
  dconf.settings = {
    # Example settings - replace with your actual preferences
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
